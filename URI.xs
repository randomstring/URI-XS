/*
 * Uri.xs
 *
 * Copyright (C) 2014  Blekko Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <float.h>
#include <stdarg.h>

#include "uri.h"

#define F_DEFAULT   0x00000000UL

#define URI_STASH uri_stash

static HV *uri_stash;

static unsigned char *bad_url_chars = NULL;

#define  URI_RESERVED_CHAR    0x01
#define  URI_MARK_CHAR        0x02
#define  URI_UNRESERVED_CHAR  0x04


typedef struct {
  apr_uri_t *uptr;
} URI;

#define APR_CHARSET_EBCDIC        0
#define APR_OS_START_ERROR        1000
#define APR_SUCCESS               0
#define APR_EGENERAL              (APR_OS_START_ERROR + 14)


typedef struct schemes_t schemes_t;

/** Structure to store various schemes and their default ports */
struct schemes_t {
    /** The name of the scheme */
    const char *name;
    /** The default port for the scheme */
    apr_port_t default_port;
};

/* Some WWW schemes and their default ports; this is basically /etc/services */
/* This will become global when the protocol abstraction comes */
/* As the schemes are searched by a linear search, */
/* they are sorted by their expected frequency */
static schemes_t schemes[] =
{
    {"http",     APR_URI_HTTP_DEFAULT_PORT},
    {"https",    APR_URI_HTTPS_DEFAULT_PORT},
    {"ftp",      APR_URI_FTP_DEFAULT_PORT},
    {"gopher",   APR_URI_GOPHER_DEFAULT_PORT},
    {"ldap",     APR_URI_LDAP_DEFAULT_PORT},
    {"nntp",     APR_URI_NNTP_DEFAULT_PORT},
    {"snews",    APR_URI_SNEWS_DEFAULT_PORT},
    {"imap",     APR_URI_IMAP_DEFAULT_PORT},
    {"pop",      APR_URI_POP_DEFAULT_PORT},
    {"sip",      APR_URI_SIP_DEFAULT_PORT},
    {"rtsp",     APR_URI_RTSP_DEFAULT_PORT},
    {"wais",     APR_URI_WAIS_DEFAULT_PORT},
    {"z39.50r",  APR_URI_WAIS_DEFAULT_PORT},
    {"z39.50s",  APR_URI_WAIS_DEFAULT_PORT},
    {"prospero", APR_URI_PROSPERO_DEFAULT_PORT},
    {"nfs",      APR_URI_NFS_DEFAULT_PORT},
    {"tip",      APR_URI_TIP_DEFAULT_PORT},
    {"acap",     APR_URI_ACAP_DEFAULT_PORT},
    {"telnet",   APR_URI_TELNET_DEFAULT_PORT},
    {"ssh",      APR_URI_SSH_DEFAULT_PORT},
    { NULL,      0 }     /* unknown port */
};


apr_port_t apr_uri_port_of_scheme(const char *scheme_str)
{
    schemes_t *scheme;

    if (scheme_str) {
        for (scheme = schemes; scheme->name != NULL; ++scheme) {
            if (strcasecmp(scheme_str, scheme->name) == 0) {
                return scheme->default_port;
            }
        }
    }
    return 0;
}

/* Here is the hand-optimized parse_uri_components().  There are some wild
 * tricks we could pull in assembly language that we don't pull here... like we
 * can do word-at-time scans for delimiter characters using the same technique
 * that fast memchr()s use.  But that would be way non-portable. -djg
 */

/* We have a apr_table_t that we can index by character and it tells us if the
 * character is one of the interesting delimiters.  Note that we even get
 * compares for NUL for free -- it's just another delimiter.
 */

#define T_COLON           0x01        /* ':' */
#define T_SLASH           0x02        /* '/' */
#define T_QUESTION        0x04        /* '?' */
#define T_HASH            0x08        /* '#' */
#define T_NUL             0x80        /* '\0' */

/* Delimiter table for the EBCDIC character set */
static const unsigned char ebcdic_uri_delims[256] = {
    T_NUL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,T_SLASH,0,0,0,0,0,0,0,0,0,0,0,0,0,T_QUESTION,
    0,0,0,0,0,0,0,0,0,0,T_COLON,T_HASH,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

/* Delimiter table for the ASCII character set */
static const unsigned char uri_delims[256] = {
    T_NUL,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,T_HASH,0,0,0,0,0,0,0,0,0,0,0,T_SLASH,
    0,0,0,0,0,0,0,0,0,0,T_COLON,0,0,0,0,T_QUESTION,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

/* list of characters that we consider space:
 * ' ', \f, \n, \r, \t, \v
 * Does NOT handle UTF-8 spaces like: &ensp; &emsp; &thinsp;
 */
static const unsigned char is_space[256] = {
    0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

/*
 * Valid hostname chars include a-zA-Z0-9-. (alpha-numeric, dash and period)
 */
static const unsigned char valid_hostname_char[256] = {
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,
  1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
  0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
  0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

/*
 * URI unreserved chars include a-zA-Z0-9-. (alpha-numeric, dash and period)
 */
/*
 * $mark       = q(-_.!~*'());                                    #'; #emacs
 * $unreserved = "A-Za-z0-9\Q$mark\E";
 */
static const unsigned char uri_unreserved_char[256] = {
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,1,0,0,0,0,0,1,1,1,1,0,0,1,1,0,  /* !'()*-. */
  1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,  /* 0123456789 */
  0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  /* ABCDEFGHIJKLMNO */
  1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,  /* PQRSTUVWXYZ_ */
  0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  /* abcdefghijklmno */
  1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,  /* pqrstuvwxyz~ */
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
};

void
free_uptr(URI *self)
{
    int i;
    char **fakearray = (char **)self->uptr;
    if (self->uptr->is_initialized) {
        for (i=0; i < 10 ;i++) {
            if (fakearray[i]) {
                /* printf("freeing: %s\n",fakearray[i]); */
                safefree(fakearray[i]);
            }
            fakearray[i] = NULL;
        }
        self->uptr->is_initialized = 0;
    }
}


/* it works like this:
    if (uri_delims[ch] & NOTEND_foobar) {
        then we're not at a delimiter for foobar
    }
*/

/* Note that we optimize the scheme scanning here, we cheat and let the
 * compiler know that it doesn't have to do the & masking.
 */
#define NOTEND_SCHEME     (0xff)
#define NOTEND_HOSTINFO   (T_SLASH | T_QUESTION | T_HASH | T_NUL)
#define NOTEND_PATH       (T_QUESTION | T_HASH | T_NUL)

/* parse_uri_components():
 * Parse a given URI, fill in all supplied fields of a uri_components
 * structure. This eliminates the necessity of extracting host, port,
 * path, query info repeatedly in the modules.
 * Side effects:
 *  - fills in fields of uri_components *uptr
 *  - none on any of the r->* fields
 */
int uri_parse(SV *uri_sv,
              URI *self)
{
    unsigned char *s;
    unsigned const char *s1;
    unsigned const char *hostinfo;
    unsigned char *uri;
    unsigned char *end;
    apr_uri_t *uptr = self->uptr;

    unsigned char *endstr;
    int port;
    int v6_offset1 = 0, v6_offset2 = 0;

    /* uri = "http://www.example.com/static.cgi?foo=1&bar=5"; */
    uri = (unsigned char *)SvPV_nolen(uri_sv);

    /* delete leading and trailing whitespace */
    while(is_space[(*uri)]) { uri++; }
    uri = (unsigned char *)savepv((char *)uri);
    end = (unsigned char *)uri + strlen((char *)uri) - 1;
    while((end >= uri) && is_space[*end]) { *end-- = '\0'; }

    /* Initialize the structure. parse_uri() and parse_uri_components()
     * can be called more than once per request.
     */

    if (uptr->is_initialized)
        free_uptr(self);

    memset (uptr, '\0', sizeof(*uptr));
    uptr->is_initialized = 1;
    uptr->raw = (char *)uri;

    /* We assume the processor has a branch predictor like most --
     * it assumes forward branches are untaken and backwards are taken.  That's
     * the reason for the gotos.  -djg
     */
    if (uri[0] == '/') {
        /* RFC2396 #4.3 says that two leading slashes mean we have an
         * authority component, not a path!  Fixing this looks scary
         * with the gotos here.  But if the existing logic is valid,
         * then presumably a goto pointing to deal_with_authority works.
         *
         * RFC2396 describes this as resolving an ambiguity.  In the
         * case of three or more slashes there would seem to be no
         * ambiguity, so it is a path after all.
         */
        if (uri[1] == '/' && uri[2] != '/') {
            s = uri + 2 ;
            goto deal_with_authority ;
        }

deal_with_path:
        /* we expect uri to point to first character of path ... remember
         * that the path could be empty -- http://foobar?query for example
         */
        s = uri;
        while ((uri_delims[*(unsigned char *)s] & NOTEND_PATH) == 0) {
            if ('\\' == *s ) { *s = '/'; }
            ++s;
        }
        if (s != uri) {
            uptr->path = savepvn((char *)uri, s - uri);
        }
        if (*s == 0) {
            return 0;    /* success */
        }
        if (*s == '?') {
            ++s;
            s1 = (unsigned char *) strchr((char *)s, '#');
            if (s1) {
                uptr->fragment = savepv((char *)s1 + 1);
                uptr->query = savepvn((char *)s, s1 - s);
            }
            else {
                uptr->query = savepv((char *)s);
            }
            return 0;    /* success */
        }
        /* otherwise it's a fragment */
        uptr->fragment = savepv((char *)(s + 1));
        return 0;  /* success */
    }

    /* find the scheme: */
    s = uri;
    while ((uri_delims[*(unsigned char *)s] & NOTEND_SCHEME) == 0) {
        ++s;
    }
    /* scheme must be non-empty and followed by :// */
/*    if (s == uri || s[0] != ':' || s[1] != '/' || s[2] != '/') {
 *        goto deal_with_path;
 *    }
 *
 */

    if (s == uri || s[0] != ':') {
        goto deal_with_path;        /* backwards predicted taken! */
    }

    uptr->scheme = savepvn((char *)uri, s - uri);

    if (s[1] != '/' || s[2] != '/') {
        return 0;       /* success, but URI w/o path, authority, etc */
    }

    s += 3;

    uptr->port = apr_uri_port_of_scheme(uptr->scheme);
    /*    printf("parse() setting DEFAULT port=%d\n",uptr->port); */

deal_with_authority:
    while(is_space[(unsigned char)*s]) { s++; }
    hostinfo = s;
    while ((uri_delims[*(unsigned char *)s] & NOTEND_HOSTINFO) == 0) {
        ++s;
    }
    uri = s;        /* whatever follows hostinfo is start of uri */
    uptr->hostinfo = savepvn((char *)hostinfo, uri - hostinfo);

    /* If there's a username:password@host:port, the @ we want is the last @...
     * too bad there's no memrchr()... For the C purists, note that hostinfo
     * is definately not the first character of the original uri so therefore
     * &hostinfo[-1] < &hostinfo[0] ... and this loop is valid C.
     */
    do {
        --s;
    } while (s >= hostinfo && *s != '@');
    if (s < hostinfo) {
        /* again we want the common case to be fall through */
deal_with_host:
        /* We expect hostinfo to point to the first character of
         * the hostname.  If there's a port it is the first colon,
         * except with IPv6.
         */
        if (*hostinfo == '[') {
            v6_offset1 = 1;
            v6_offset2 = 2;
            s = memchr(hostinfo, ']', uri - hostinfo);
            if (s == NULL) {
                return APR_EGENERAL;
            }
            if (*++s != ':') {
                s = NULL; /* no port */
            }
        }
        else {
            s = memchr(hostinfo, ':', uri - hostinfo);
        }
        if (s == NULL) {
            /* we expect the common case to have no port */
            uptr->hostname = savepvn((char *)hostinfo + v6_offset1,
                                     uri - hostinfo - v6_offset2);
            goto deal_with_path;
        }
        uptr->hostname = savepvn((char *)hostinfo + v6_offset1,
                                 s - hostinfo - v6_offset2);
        ++s;
        uptr->port_str = savepvn((char *)s, uri - s);
        if (uri != s) {
            port = strtol(uptr->port_str, (char **)&endstr, 10);
            uptr->port = port;
            if (*endstr == '\0') {
                goto deal_with_path;
            }
            /* Invalid characters after ':' found */
            return APR_EGENERAL;
        }
        goto deal_with_path;
    }

    /* first colon delimits username:password */
    s1 = memchr(hostinfo, ':', s - hostinfo);
    if (s1) {
        uptr->user = savepvn((char *)hostinfo, s1 - hostinfo);
        ++s1;
        uptr->password = savepvn((char *)s1, s - s1);
    }
    else {
        uptr->user = savepvn((char *)hostinfo, s - hostinfo);
    }
    hostinfo = s + 1;
    goto deal_with_host;
}


/////////////////////////////////////////////////////////////////////
// XS interface functions

MODULE = URI::XS             PACKAGE = URI::XS

TYPEMAP: <<EOT
URI *           T_URI

INPUT

T_URI
        if (!(SvROK ($arg) && SvOBJECT (SvRV ($arg))
            && SvSTASH (SvRV ($arg)) == URI_STASH))
          croak (\"object is not of type URI::XS\");
        $var = (URI *)SvPVX (SvRV ($arg));

EOT

BOOT:
{
        /* put code that runs once at load time here */

        uri_stash         = gv_stashpv ("URI::XS", 1);
}

PROTOTYPES: DISABLE

void
new (klass, uri_sv = NULL)
        char *klass
        SV *uri_sv
        PPCODE:
{
        SV *pv = NEWSV (0, sizeof (URI));
        if (pv == NULL) {
            croak("Error: NEWSV() failed in Craw::URI::new()");
        }
        SvPOK_only (pv);
        Zero (SvPVX (pv), 1, URI);
        ((URI *)SvPVX (pv))->uptr = (apr_uri_t *)safemalloc(sizeof(apr_uri_t));
        if (((URI *)SvPVX (pv))->uptr == NULL) {
            croak("Error: safemalloc() failed in Craw::URI::new()");
        }
        memset (((URI *)SvPVX (pv))->uptr,0,sizeof(apr_uri_t));
        if (uri_sv != NULL) {
            uri_parse(uri_sv,((URI *)SvPVX (pv)));
        }
        XPUSHs (sv_2mortal (sv_bless ( newRV_noinc (pv),
                strEQ (klass, "URI::XS") ? URI_STASH : gv_stashpv (klass, 1)
                )));
}

void
clone (self)
        URI *self;
        PPCODE:
{
        int i;
        char **fakearray = (char **)self->uptr;
        char **newfakearray;
        SV *pv = NEWSV (0, sizeof (URI));
        SvPOK_only (pv);
        Zero (SvPVX (pv), 1, URI);
        ((URI *)SvPVX (pv))->uptr = (apr_uri_t *)safemalloc(sizeof(apr_uri_t));
        memset (((URI *)SvPVX (pv))->uptr,0,sizeof(apr_uri_t));

        if (self->uptr->is_initialized) {
            ((URI *)SvPVX (pv))->uptr->is_initialized = 1;
            newfakearray = (char **)((URI *)SvPVX (pv))->uptr;
            for (i=0; i < 10 ;i++) {
                if (fakearray[i]) {
                    newfakearray[i] = savepv(fakearray[i]);
                }
            }
        }

        XPUSHs (sv_2mortal (sv_bless ( newRV_noinc (pv), URI_STASH )));
}


void
parse (self,scalar)
        URI *self
        SV *scalar
        PPCODE:
{
        uri_parse(scalar,self);
        XPUSHs (ST (0));
}


int
trivial_abs (self, base)
        URI *self
        URI *base
    CODE:
{
        char **fakearray = (char **)self->uptr;
        char **basefakearray = (char **) base->uptr;
        int i;
        RETVAL = 1;
        if ((base != NULL) && (base->uptr->is_initialized) && (self->uptr->scheme == NULL)) {
            if (self->uptr->raw != NULL) {
                /* kill the raw string, if we change something */
                safefree(self->uptr->raw);
                self->uptr->raw = NULL;
            }
            if (NULL != base->uptr->scheme)
                self->uptr->scheme = savepv(base->uptr->scheme);
            if (self->uptr->hostname == NULL) {
                if (NULL != base->uptr->hostname)
                    self->uptr->hostname = savepv(base->uptr->hostname);
                self->uptr->port = base->uptr->port;

                for (i = 2; i <= 5 ; i++) {
                    /* user, password, port_str */
                    if (i == 2 || i == 3 || i == 5) {
                        if (fakearray[i]) {
                            safefree(fakearray[i]);
                            fakearray[i] = NULL;
                        }
                        if (basefakearray[i]) {
                            fakearray[i] = savepv(basefakearray[i]);
                        }
                    }
                }
                if (!(self->uptr->path && *(self->uptr->path) == '/')) {
                    if ((self->uptr->path == NULL) || (*(self->uptr->path) == '\0')) {
                        for (i = 6; i <= 8 ;) {
                            /* path, query, fragment */
                            if (fakearray[i]) {
                                safefree(fakearray[i]);
                                fakearray[i] = NULL;
                            }
                            if (basefakearray[i]) {
                                fakearray[i] = savepv(basefakearray[i]);
                            }
                            if (fakearray[++i] != NULL) {
                                /* skip to end if we find that query, or fragment is not NULL */
                                i = 9;
                            }
                        }
                    }
                    else {
                        RETVAL = 0;     /* More to do in perl */
                    }
                }
            }
            self->uptr->is_initialized = 1;
        }
}
    OUTPUT:
        RETVAL

int
trivial_rel (self, base)
        URI *self
        URI *base
    CODE:
{
        char **fakearray = (char **)self->uptr;
        int i;
        int selfport;
        int baseport;
        RETVAL = 0;
        if ((self->uptr->scheme == NULL) &&
            (self->uptr->hostname == NULL) &&
            (self->uptr->user == NULL) &&
            (self->uptr->password == NULL)) {

            /* it is already relative */
            RETVAL = 1;

        }
        else {
            RETVAL = 1;

            if ((base != NULL) && (base->uptr->is_initialized)) {

                selfport = self->uptr->port;
                if (!selfport) {
                    selfport = apr_uri_port_of_scheme(self->uptr->scheme);
                }
                baseport = base->uptr->port;
                if (!baseport) {
                    baseport = apr_uri_port_of_scheme(base->uptr->scheme);
                }
                if (
                    ((self->uptr->scheme == base->uptr->scheme) ||
                     (base->uptr->scheme && self->uptr->scheme &&
                      strcasecmp(self->uptr->scheme, base->uptr->scheme) == 0)) &&
                    ((self->uptr->hostname == base->uptr->hostname) ||
                     (base->uptr->hostname && self->uptr->hostname &&
                      strcasecmp(self->uptr->hostname, base->uptr->hostname) == 0)) &&
                    ((self->uptr->user == base->uptr->user) ||
                     (base->uptr->user && self->uptr->user &&
                      strcasecmp(self->uptr->user, base->uptr->user) == 0)) &&
                    ((self->uptr->password == base->uptr->password) ||
                     (base->uptr->password && self->uptr->password &&
                      strcasecmp(self->uptr->password, base->uptr->password) == 0)) &&
                    (selfport == baseport)
                    ) {
                    /* scheme, authority, and port match. */

                    /* printf("selfport = %d  baseport= %d\n",selfport,baseport); */

                    for (i = 0; i <= 5 ; i++) {
                        /* scheme, hostinfo, user, passowrd, hostname, port_str */
                        if (fakearray[i]) {
                            safefree(fakearray[i]);
                            fakearray[i] = NULL;
                        }
                        self->uptr->port = 0;

                        if (self->uptr->raw != NULL) {
                            /* kill the raw string, if we change something */
                            safefree(self->uptr->raw);
                            self->uptr->raw = NULL;
                        }
                    }
                    RETVAL = 0; /* More to do in perl */
                }

            }
            else {
                RETVAL = 0;     /* More to do in perl */
            }
        }
}
    OUTPUT:
        RETVAL

int
abs_is_local (self, base)
        URI *self
        URI *base
    PREINIT:
        int selfport = 0;
        int baseport = 0;
    CODE:
{
        RETVAL = 0;
        /* quick check used when parsing robots.txt to see if the URL is local to the base. */
        if ((self->uptr->scheme == NULL || (strcasecmp(self->uptr->scheme,base->uptr->scheme) == 0)) &&
            (self->uptr->hostname == NULL || (strcasecmp(self->uptr->hostname,base->uptr->hostname) == 0)) &&
            (self->uptr->port == base->uptr->port)) {
            selfport = self->uptr->port;
            if (!selfport) {
                selfport = apr_uri_port_of_scheme(self->uptr->scheme);
            }
            baseport = base->uptr->port;
            if (!baseport) {
                baseport = apr_uri_port_of_scheme(base->uptr->scheme);
            }
            if (selfport == baseport) {
                RETVAL = 1;
            }
        }
}
    OUTPUT:
        RETVAL


void
set_bad_url_chars(str)
            unsigned char *str
    CODE:
{
        if (bad_url_chars == NULL) {
            bad_url_chars = (unsigned char *)safemalloc(255);
            memset ((void *)bad_url_chars,0,255);
        }

        while (*str) {
            bad_url_chars[*str++] = 1;
        }
}

void
reset_bad_url_chars()
    CODE:
{
        if (bad_url_chars != NULL) {
            safefree(bad_url_chars);
            bad_url_chars = NULL;
        }
}


int
bad_url (self)
        URI *self
    CODE:
{
        char *ptr;
        char *last;
        int depth;

        RETVAL = 0;
        /* quick check for un-crawlable URLS. Checks for hostname that will pass DNS checks*/
        if ((self->uptr->scheme == NULL) ||
            (self->uptr->hostname == NULL) ||
            (self->uptr->fragment != NULL) ||    /* bad_url all fragments */
            !( ((strcasecmp(self->uptr->scheme,"http") == 0) && ( self->uptr->port == 0 || self->uptr->port == 80 )) ||
               ((strcasecmp(self->uptr->scheme,"https") == 0) && (self->uptr->port == 0 || self->uptr->port == 443 )) ) ||
            (strstr(self->uptr->hostname,"..") > 0) ||
            (self->uptr->path && strstr(self->uptr->path,"../") > 0) ||
            (self->uptr->user != NULL) ||
            (strlen(self->uptr->hostname) >= 255)) {
            RETVAL = 1;
        }
        else {
            /* make sure all labels are less than 63 octets long (RFC1035 2.3.1) */
            last = self->uptr->hostname;
            ptr = index(last,'.');
            while(ptr && ((int)(ptr - last) <= 63)) {
                ptr++;
                last = ptr;
                ptr = index(last,'.');
            }
            if (ptr) {
                RETVAL = 1;
                /* printf("label too long %s\n",last); */
            }
            else {
                /* check path depth */
                depth = 0;
                if (self->uptr->path) {
                    for(ptr = self->uptr->path ; *ptr ; ptr++) {
                        if (*ptr == '/') {
                            depth++;
                        }

                        if (bad_url_chars && bad_url_chars[(unsigned int)*ptr]) {
                            RETVAL = 1;
                            break;
                        }
                    }
                }
                for(ptr = self->uptr->hostname ; *ptr ; ptr++) {
                    if (!valid_hostname_char[(unsigned int)*ptr]) {
                        RETVAL = 1;
                        break;
                    }
                }
            }
        }
}
    OUTPUT:
        RETVAL

int
bool( URI *self, ... )
    CODE:
    {
      char **fakearray = (char **)self->uptr;
      int i;
      RETVAL = 0;
      /* 9 comse from the different values in fakearray */
      for ( i = 0; i <= 9; i++ )
        {
          if ( fakearray[i] != NULL && fakearray[i][0] != '\0' )
            {
              RETVAL = 1;
              break;
            }
        }
    }
    OUTPUT:
      RETVAL

void
scheme (self, sv = NULL)
        URI *self
        SV *sv
    ALIAS:
        scheme = 0
        hostinfo = 1
        user = 2
        password = 3
        hostname = 4
        host = 4
        port_str = 5
        _path = 6
        query = 7
        fragment = 8
        raw = 9

    PREINIT:
        char *p;
        char *str = NULL;
        char **fakearray;

    INIT:
        fakearray = (char **)self->uptr;

    PPCODE:
        if (sv) {
            if (self->uptr->raw != NULL) {
                /* kill the raw string, if we change something */
                safefree(self->uptr->raw);
                self->uptr->raw = NULL;
            }
            if (fakearray[ix] != NULL) {
                safefree(fakearray[ix]);
                fakearray[ix] = NULL;
            }
            if (SvTYPE(sv)) {
                /* not undef */
                /* printf("setting %d to [%s] flags=%d\n",ix,SvPV_nolen(sv),(int)SvTYPE(sv)); */
                fakearray[ix] = savepv(SvPV_nolen(sv));

                if (ix == 5) {
                    self->uptr->port = strtol(self->uptr->port_str, NULL, 10);
                }
            }
        }
        str = fakearray[ix];
        if (str == NULL) {
            XPUSHs (sv_2mortal(newSVsv(&PL_sv_undef)));
        }
        else {
            if (ix == 4 || ix == 0) {
                for (p = str; *p ; p++) {
                    *p = toLOWER(*p);
                }
            }
            XPUSHs (sv_2mortal(newSVpv(str, 0)));
        }


void
uri_parts (self)
        URI *self
    PREINIT:
        int i;
        char *p;
        char *str = NULL;
        char **fakearray;

    INIT:
        fakearray = (char **)self->uptr;

    PPCODE:
        for (i = 0; i < 9; i++) {
            if (i != 5) {
                str = fakearray[i];
                if (str == NULL) {
                    XPUSHs (sv_2mortal(newSVsv(&PL_sv_undef)));
                }
                else {
                    if (i == 0 || i == 4) {
                        for (p = str; *p ; p++) {
                            *p = toLOWER(*p);
                        }
                    }
                    XPUSHs (sv_2mortal(newSVpv(str, 0)));
                }
            }
            else {
                XPUSHs (sv_2mortal(newSViv(self->uptr->port)));
            }
        }

int
port (self,...)
         URI *self
    PREINIT:
         SV *sv = NULL;
    CODE:
         /* printf("port called with %d items\n",items); */
         if (items > 1) {
             sv = ST(1);
             if (self->uptr->port_str) {
                 safefree(self->uptr->port_str);
                 self->uptr->port_str = NULL;
                 self->uptr->port = 0;
             }
             if (sv != NULL && SvTYPE(sv)) {
                 if (SvIOK(sv)) {
                     /* printf("port() iv string [%s] iv=[%d]\n",ix,SvPV_nolen(sv),SvIVX(sv)); */
                     self->uptr->port_str = savepv(SvPV_nolen(sv));
                     self->uptr->port = SvIVX(sv);
                 }
                 else {
                     self->uptr->port_str = savepv(SvPV_nolen(sv));
                     self->uptr->port     = strtol(self->uptr->port_str, NULL, 10);
                 }
             }
         }
         /* printf("port() returning port pv=[%s] iv=%d\n",self->uptr->port_str,self->uptr->port); */
         RETVAL = self->uptr->port;
    OUTPUT:
         RETVAL

int
scheme_port (self)
         URI *self
    CODE:
         if ((self->uptr == NULL) || (self->uptr->scheme == NULL)) {
           RETVAL  = 0;
         }
         else {
           RETVAL  = apr_uri_port_of_scheme(self->uptr->scheme);
         }
    OUTPUT:
         RETVAL


SV *
quote_process (str)
    SV *str

    INIT:
    unsigned char *s;
    unsigned char *end;
    unsigned char *last_quote;
    STRLEN len;
    int    q_mode;
    int    utf8_mode;

    CODE:
{

    utf8_mode = 0;
    q_mode = 0;
    last_quote = NULL;

    if (SvUTF8(str)) {
        utf8_mode = 1;
    }

    if (!(!SvOK(str) || (SvPOK(str) && SvCUR(str)==0) || SvREADONLY(str) )) {

        if ((!SvOOK(str) || !SvPOK(str)) && !SvMAGICAL(str)) {
            SvUPGRADE(str,SVt_PVIV);
        }

        s = (unsigned char *) SvPV(str,len);
        end = s + len;

        while (s < end) {
            if (*s == '\"') {
                if (q_mode)
                    q_mode = 0;
                else {
                    last_quote = s;
                    q_mode = 1;
                }
            }
            else if (q_mode && ((*s == '.') || (*s == '!') ||  (*s == '?') ||  (*s == ':') ||  (*s == ';'))) {
                *s = (unsigned char) 17;
            }
            else if (*s & 0x80) {
                // clean up high bit chars that do NOT conform to UTF-8 format
                if (((*s & 0xE0) == 0xC0) && ((*(s+1) & 0xC0) == 0x80)) {
                    utf8_mode = 1;
                    s++;
                }
                else if (((*s & 0xF0) == 0xE0) && ((*(s+1) & 0xC0) == 0x80) && ((*(s+2) & 0xC0) == 0x80)) {
                    utf8_mode = 1;
                    s += 2;
                }
                else if (((*s & 0xF8) == 0xF0) && ((*(s+1) & 0xC0) == 0x80) && ((*(s+2) & 0xC0) == 0x80) && ((*(s+3) & 0xC0) == 0x80)) {
                    utf8_mode = 1;
                    s += 3;
                }
                else {
                    *s = ' ';
                }
            }

            s++;
        }

        if (q_mode && last_quote) {
            /* remove unbalanced quote character */
            while (last_quote < end - 1) {
                *last_quote = *(last_quote+1);
                last_quote++;
            }
            SvCUR_set(str,len - 1);
        }
    }
    if (utf8_mode) {
        SvUTF8_on(str);
    }
    (void)RETVAL; // -Wall -Werror
}
OUTPUT:
        str


void
DESTROY (URI *self)
    CODE:
         free_uptr(self);
         if (self->uptr) {
             safefree(self->uptr);
         }


int
nonspace_count (str)
        unsigned char *str
    CODE:
{
  RETVAL = 0;
    /* count number of space characters.  Note non-unicodeness */

  while (*str) {
    if ( ! is_space[(unsigned char)*str++]) { RETVAL++; }
  }
}
 OUTPUT:
    RETVAL


int
fix_escaped_chars (sv)
    SV *sv

    INIT:
    STRLEN  i;
    STRLEN  len;
    char    *str;
    unsigned char c;

    CODE:
{
/*
 * fix_escaped_chars ()
 *
 * This is an strange funtion that scans an URI or part of a URI and checks
 * for URI escaped ( %4A of example ) characters that do not need to be
 * escaped because they are not reserved or highbyte characters.
 *
 * SIDE AFFECT: URI escaped strings are converted to upper case as part of
 * the canonicalization process. ( %2f -> %2F )
 */

  RETVAL = 0;
  SvPOK_only (sv);
  str = SvPV (sv, len);

  /*  printf("CHECK: %s len=%d\n",str,len); */

  i = 0;
  while((i + 2) < len) {
      if ((str[i] == '%') && isxdigit(str[i+1]) && isxdigit(str[i+2]))
      {
          c = ((((str[i+1] > '9') ? 0x9 : 0x0 ) + ( str[i+1] & 0xF )) << 4) +
            ((str[i+2] > '9') ? 0x9 : 0x0 ) + ( str[i+2] & 0xF );

          str[i+1] = toupper(str[i+1]);
          str[i+2] = toupper(str[i+2]);
          i += 2;
          /*      printf("checking %d  code=%%%c%c  c=%d\n",i,str[i+1],str[i+2],c); */
          if (uri_unreserved_char[c])
          {
            i = len;
            RETVAL = 1;
          }

      }
      i++;
  }
}
OUTPUT:
    RETVAL



PROTOTYPES: ENABLE

