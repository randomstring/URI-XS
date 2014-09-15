package URI::XS;

use strict;
use Carp;

our $VERSION = '1.0';

use parent qw( Exporter );
our @EXPORT_OK = qw( parse quote_process host_from_url base_domain_from_url );

use Net::Domain::PublicSuffix qw( base_domain );

use XSLoader;

XSLoader::load "URI::XS", $VERSION;

use overload ('""'     => \&as_string,
              '=='     => sub { overload::StrVal($_[0]) eq
                                overload::StrVal($_[1])
                              },
              'bool' => \&bool,
              fallback => 1,
              );

use vars qw($reserved $mark $unreserved %escapes);
$reserved   = q(;/?:@&=+$,[]);
$mark       = q(-_.!~*'());                                    #'; #emacs
$unreserved = "A-Za-z0-9\Q$mark\E";

for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

sub uri_escape_string
{
    my($str) = @_;

    return '' if (! defined $str);

    $str =~ s/\s+$//;
    $str =~ s/([\s\|\^\{\}\x80-\xFF])/$escapes{$1}/oge;
    if (fix_escaped_chars($str)) {
        $str =~ s{%([0-9a-fA-F]{2})}
               { my $a = chr(hex($1));
                 $a =~ /^[$unreserved]\z/o ? $a : "%\U$1"
               }ge;
    }

    return $str;
}

sub host_from_url
{
    my $uri = URI::XS->new(@_);
    return $uri && $uri->host;
}

sub base_domain_from_url { base_domain(host_from_url(@_)) }


sub new_abs
{
    my ($self, $uri, $base) = @_;

    if (ref $self ne 'URI::XS') {
        $self = URI::XS->new($uri);
    }
    else {
        $self->parse($uri);
    }
    $self->abs($base) if (defined($base));

    return $self;
}


sub as_string
{
    my $self = shift;

    my $s = $self->raw;
    if (!defined($s)) {
        $self->canonical;
        $s = $self->raw;
    }

    return $s;
}

sub canonical
{
    # Make sure scheme is lowercased, that we don't escape unreserved chars,
    # and that we use upcase escape sequences.

    my $self = shift;

    my $portstr = '';
    my $auth = '';
    my $relpath = undef;
    my ($scheme,$hostinfo,$user,$password,$hostname,$port,$path,$query,$fragment) =
        $self->uri_parts;

    # return undef if ($hostname eq '');

    if ( ! defined($path) && ! defined($hostname) && ! defined($query) ) {
        return $self;      # This is a non-hierarchical URI,
                           # could do escapes below.  Not sure.
    }

    $hostname = '' if (!defined $hostname);
    $hostname =~ s/\.$//;
    $scheme = ($scheme ? "$scheme://" : '');
    $auth = $user if (defined $user);
    $auth .= ':' . $password if (defined $user && defined $password);
    $auth .= '@' if ($auth);
#    $path = '/' if ((!defined($path) || ($path eq '')) && !defined($query));
    $path = '/' if ((!defined($path) || ($path eq '')));

    # http://foo.com/a///b.html  -> http://foo.com/a/b.html  (breaks RFC compatibility, but its better this way)
    $path =~ s,//+,/,g if (defined $path);

    if (defined($path) && defined($scheme) && defined($hostname) && $path =~ m,^/\./,)  {
        $path =~ s,^/(\.\.?/)+,/,;
    }

    if (defined($path) && defined($scheme) && defined($hostname) && $path =~ m,^(.*?)/(\.\./.*),) {
        # fix urls with relative paths in them:
        #   http://blog.com/foo/dec/01/../../jan/02/index.html  => http://blog.com/foo/jan/02/index.html
        $path = "$1/";
        $relpath  = $2;
        $relpath .= "?$query" if (defined($query));
        $relpath .= "#$fragment" if (defined($fragment));

        if ($path !~ /\.\./ && ($path ne '/')) {
            # print "DEBUG RELPATH: $path   $relpath\n"
        }
        else {
            $path .= $relpath;
            $relpath = undef;
        }
    }
    else {
        $path .= "?$query" if (defined($query));
        $path .= "#$fragment" if (defined($fragment));
    }
    $path = ''  if (!defined($path));

    if ($port > 0 && $port != $self->scheme_port) {
        $portstr = ":$port";
    }

    my $canon = "$scheme$auth$hostname$portstr$path";

    $canon =~ s/\s+$//;
    $canon =~ s/([\s\|\^\{\}\x80-\xFF])/$escapes{$1}/oge;
    if (fix_escaped_chars($canon)) {
        $canon =~ s{%([0-9a-fA-F]{2})}
               { my $a = chr(hex($1));
                 $a =~ /^[$unreserved]\z/o ? $a : "%\U$1"
               }ge;
    }


    my $raw = $self->raw;
    if (defined($raw) && ($canon eq $raw)) {
        return $self;
    }
    else {
        my $c;
        if (defined $relpath) {
            $c = URI::XS->new($relpath);
            $c->abs($canon);
        }
        else {
            $c = URI::XS->new($canon);
        }
        if (!defined $raw) {
            $self->raw($canon);   # as_string() counts on this to fix raw if NULL
        }

        return $c;
    }
}

sub authority
{
    my $self = shift;
    my $auth = '';

    if (@_) {
        $auth = shift;

        if (defined $auth && $auth =~ /\@/) {
            my($a,$host) = split ('@',$auth,2);
            if ($host =~ /^(.+):(\d+)$/) {
                $self->host($1);
                $self->port($2);
            }
            else {
                $self->host($host);
            }
            if ($a =~ /:/) {
                my($user,$password) = split (':',$auth,2);
                $self->user($user);
                $self->password($password);
            }
            else {
                $self->user($a);
            }
        }
        else {
            $self->host($auth || undef);
            $self->port(undef);
            $self->user(undef);
            $self->password(undef);
        }
    }

    my $user = $self->user;
    my $password = $self->password;
    my $host = $self->host;
    my $port = $self->port;
    my $default_port = $self->scheme_port;
    return undef if (!defined($host) && !defined($user) && !defined($password) && ## no critic qw( ProhibitExplicitReturnUndef )
                     (($port == 0) || ($port == $default_port)));
    $host .= ":$port" if (defined $port && $port != 0 && $port != $default_port);

    $auth = '';
    $auth = $user if ($user);
    $auth .= ':' . $password if ($user && $password);
    $auth .= '@' if ($auth);
    $auth .= $host if (defined $host);

    return $auth;
}

sub host_port
{
    my $self = shift;
    my $hostport = '';

    if (@_) {
        $hostport = shift;
        if (defined($hostport) && $hostport =~ /^(.+):(\d+)$/) {
            $self->host($1);
            $self->port($2);
        }
        else {
            $self->host($hostport);
            $self->port(undef);
        }
    }

    my $host = $self->host;
    return undef if (!defined $host); ## no critic qw( ProhibitExplicitReturnUndef )
    my $port = $self->port || $self->scheme_port || '';

    $hostport = "$host:$port";

    return $hostport;
}

sub path_query
{
    my $self = shift;
    my $pathquery = shift;

    if (defined $pathquery) {
        my($path,$query) = split(/\?/,$pathquery,2);
        $self->path($path);
        $self->query($query);
    }
    else {
        $pathquery = $self->path || '';
        my $query =  $self->query;
        $pathquery .= "?$query" if (defined($query));
    }

    $pathquery =~ s/\s+$//;
    $pathquery =~ s/([\s\|\^\{\}\x80-\xFF])/$escapes{$1}/oge;
    if (fix_escaped_chars($pathquery)) {
        $pathquery =~ s{%([0-9a-fA-F]{2})}
               { my $a = chr(hex($1));
                 $a =~ /^[$unreserved]\z/o ? $a : "%\U$1"
               }ge;
    }
    return $pathquery;
}

sub path
{
    my $self = shift;

    my $path = $self->_path(@_);

    if (defined $path) {
        $path =~ s/([\s\|\^\{\}\x80-\xFF])/$escapes{$1}/oge;
        if (fix_escaped_chars($path)) {
            $path =~ s{%([0-9a-fA-F]{2})}
               { my $a = chr(hex($1));
                 $a =~ /^[$unreserved]\z/o ? $a : "%\U$1"
               }ge;
        }
    }
    else {
        $path = '';
    }

    return $path;
}

sub opaque
{
    my ($self) = shift @_;

    # place holder until real opaque is implemented
    return $self->path(@_);
}

sub abs
{
    my($self,$b) = @_;

    if (!defined($b)) {
        warn("Missing base argument");
        return $self;
    }

    my $base = (ref $b ? $b : URI::XS->new($b));

    return $self if ($self->trivial_abs($base));

    my $path = $self->path;

    my $p = $base->path || '';
    $p =~ s,[^/]+$,,;
    $p .= $path;
    my @p = split('/', $p, -1);
    shift(@p) if @p && !length($p[0]);
    my $i = 1;
    while ($i < @p) {
        #print "$i ", join("/", @p), " ($p[$i])\n";
        if ($p[$i-1] eq ".") {
            splice(@p, $i-1, 1);
            $i-- if $i > 1;
        }
        elsif ($p[$i] eq ".." && $p[$i-1] ne "..") {
            splice(@p, $i-1, 2);
            if ($i > 1) {
                $i--;
                push(@p, "") if $i == @p;
            }
        }
        else {
            $i++;
        }
    }
    $p[-1] = "" if @p && $p[-1] eq ".";  # trailing "/."
    # standard URI class allows for this option to strip leading ..'s from the URL
    #
    if ($URI::XS::ABS_REMOVE_LEADING_DOTS) {
        shift @p while @p && $p[0] =~ /^\.\.?$/;
    }
    $self->path("/" . join("/", @p));

    return $self;
}

sub rel
{
    my($self,$base) = @_;

    if (!$base) {
        warn("Missing base argument");
        return $self;
    }

    my $rel = $self->clone;
    $base = URI::XS->new($base) unless ref $base;

    if ($rel->trivial_rel($base)) {
        return $rel;
    }

    my $path   = $rel->path;
    my $bpath  = $base->path;
    for ($path, $bpath) {  $_ = "/$_" unless m,^/,; }

    # This loop is based on code from Nicolai Langfeldt <janl@ifi.uio.no>.
    # First we calculate common initial path components length ($li).
    my $li = 1;
    while (1) {
        my $i = index($path, '/', $li);
        last if $i < 0 ||
                $i != index($bpath, '/', $li) ||
                substr($path,$li,$i-$li) ne substr($bpath,$li,$i-$li);
        $li=$i+1;
    }
    # then we nuke it from both paths
    substr($path, 0,$li) = '';
    substr($bpath,0,$li) = '';

    if ($path eq $bpath &&
        defined($rel->fragment) &&
        !defined($rel->query)) {
        $rel->path("");
    }
    else {
        # Add one "../" for each path component left in the base path
        $path = ('../' x $bpath =~ tr|/|/|) . $path;
        $path = "./" if $path eq "";
        $rel->path($path);
    }

    return $rel;
}

sub rel_pureperl
{
    my($self,$base) = @_;

    if (!$base) {
        warn("Missing base argument");
        return $self;
    }

    my $rel = $self->clone;
    $base = URI::XS->new($base) unless ref $base;

    my $scheme = $rel->scheme;
    my $auth   = $rel->authority;
    my $path   = $rel->path;

    if (!defined($scheme) && !defined($auth)) {
        # it is already relative
        return $rel;
    }

    my $bscheme = $base->scheme;
    my $bauth   = $base->authority;
    my $bpath   = $base->path;

    for ($bscheme, $bauth, $auth) {
        $_ = '' unless defined
    }

    unless ($scheme eq $bscheme && $auth eq $bauth) {
        # different location, can't make it relative
        return $rel;
    }

    for ($path, $bpath) {  $_ = "/$_" unless m,^/,; }

    # Make it relative by eliminating scheme and authority
    $rel->scheme(undef);
    $rel->authority(undef);

    # This loop is based on code from Nicolai Langfeldt <janl@ifi.uio.no>.
    # First we calculate common initial path components length ($li).
    my $li = 1;
    while (1) {
        my $i = index($path, '/', $li);
        last if $i < 0 ||
                $i != index($bpath, '/', $li) ||
                substr($path,$li,$i-$li) ne substr($bpath,$li,$i-$li);
        $li=$i+1;
    }
    # then we nuke it from both paths
    substr($path, 0,$li) = '';
    substr($bpath,0,$li) = '';

    if ($path eq $bpath &&
        defined($rel->fragment) &&
        !defined($rel->query)) {
        $rel->path("");
    }
    else {
        # Add one "../" for each path component left in the base path
        $path = ('../' x $bpath =~ tr|/|/|) . $path;
        $path = "./" if $path eq "";
        $rel->path($path);
    }

    return $rel;
}

sub is_toplevel
{
    my($self,$base) = @_;

    my $path_query = $self->path_query;
    return 0 if ($path_query ne '/' && $path_query ne '');
    return 0 if (defined $self->fragment);
    return 1;
}


1;

=head1 NAME

URI::XS - Fast Uniform Resource Identifiers (absolute and relative)

=head1 SYNOPSIS

 $u1 = URI::XS->new("http://www.perl.com");
 $u2 = URI::XS->new("foo", "http");
 $u3 = $u2->abs($u1);
 $u4 = $u3->clone;
 $u5 = URI::XS->new("HTTP://WWW.perl.com:80")->canonical;

 $str = $u->as_string;
 $str = "$u";

 $scheme = $u->scheme;
 # $opaque = $u->opaque; # not yet implemented
 $path   = $u->path;
 $frag   = $u->fragment;

 $u->scheme("https");
 $u->host("ftp.perl.com");
 $u->path("cpan/");

=head1 DESCRIPTION

This module implements the C<URI::XS> class.  Objects of this class
represent "Uniform Resource Identifier references" as specified in RFC
2396 (and updated by RFC 2732).

=head1 CONSTRUCTORS

The following methods construct new C<URI::XS> objects:

=over 4

=item $uri = URI::XS->new( $str )

=item $uri = URI::XS->new( $str, $scheme )

Constructs a new URI::XS object.  The string
representation of a URI::XS is given as argument, together with an optional
scheme specification. Leading and trailing white space are
automatically removed from the $str argument before it is processed further.

The constructor determines the scheme, maps this to an appropriate
URI subclass, constructs a new object of that class and returns it.

The $scheme argument is only used when $str is a
relative URI.  It can be either a simple string that
denotes the scheme, a string containing an absolute URI reference, or
an absolute C<URI> object.  If no $scheme is specified for a relative
URI $str, then $str is simply treated as a generic URI (no scheme-specific
methods available).

The set of characters available for building URI references is
restricted (see L<URI::Escape>).  Characters outside this set are
automatically escaped by the URI constructor.

=item $uri = URI::XS->new_abs( $str, $base_uri )

Constructs a new absolute URI::XS object.  The $str argument can
denote a relative or absolute URI.  If relative, then it is
absolutized using $base_uri as base. The $base_uri must be an absolute
URI.

=item $uri->clone

Returns a copy of the $uri.


=item $uri->scheme

=item $uri->scheme( $new_scheme )

Sets and returns the scheme part of the $uri.  If the $uri is
relative, then $uri->scheme returns C<undef>.  If called with an
argument, it updates the scheme of $uri

=item $uri->opaque

=item $uri->opaque( $new_opaque )

Sets and returns the scheme-specific part of the $uri
(everything between the scheme and the fragment)
as an escaped string.

=item $uri->path

=item $uri->path( $new_path )

Sets and returns the escaped path part of the $uri.

This differes from how C<URI> implements this. C<URI> just
aliases path() to call opaque().

=item $uri->hostname

=item $uri->hostname( $new_host )

Alias of the host command.

=item $uri->host

=item $uri->host( $new_host )

Sets and returns the lowercased host part of the $uri.
The string is not escaped (unlike C<URI>).

=item $uri->password

=item $uri->password( $new_password )

Sets and returns the password part of the $uri.
The string is not escaped (unlike C<URI>).

=item $uri->user

=item $uri->user( $new_user )

Sets and returns the user part of the $uri.
The string is not escaped (unlike C<URI>).

=item $uri->fragment

=item $uri->fragment( $new_frag )

Returns the fragment identifier of a URI reference.
The string is not escaped (unlike C<URI>).

=item $uri->as_string

Returns a URI object to a plain string.  URI objects are
also converted to plain strings automatically by overloading.  This
means that $uri objects can be used as plain strings in most Perl
constructs.

=item $uri->canonical

Returns a normalized version of the URI.  The rules
for normalization are scheme-dependent.  They usually involve
lowercasing the scheme and Internet host name components,
removing the explicit port specification if it matches the default port,
uppercasing all escape sequences, and unescaping octets that can be
better represented as plain characters.

For efficiency reasons, if the $uri is already in normalized form,
then a reference to it is returned instead of a copy.

=item $uri->abs( $base_uri )

Returns an absolute URI reference.  If $uri is already
absolute, then a reference to it is simply returned.  If the $uri
is relative, then a new absolute URI is constructed by combining the
$uri and the $base_uri, and returned.

=item $uri->rel( $base_uri )

Returns a relative URI reference if it is possible to make one that
denotes the same resource relative to $base_uri. If not, then $uri is
simply returned.

=item $uri->authority

=item $uri->authority( $new_authority )

Sets and returns theauthority component of the uri.
The string is not escaped (unlike C<URI>).

=item $uri->path

=item $uri->path( $new_path )

Sets and returns the escaped path component of
the $uri (the part between the host name and the query or fragment).
The path can never be undefined, but it can be the empty string.

=item $uri->path_query

=item $uri->path_query( $new_path_query )

Sets and returns the escaped path and query
components as a single entity.  The path and the query are
separated by a "?" character, but the query can itself contain "?".

=item $uri->is_toplevel

Returns 1 if the URI is a toplevel URL, ie with no path, no query, and
no fragment parts to the URI.

=item $uri->port

=item $uri->port( $port )

Sets and returns the port number of the protocol.

=item $uri->port_str

=item $uri->port_str( $port )

Sets and returns the port number of the protocol, takes a string or (char *) as input.

=back

=head1 SEE ALSO

L<URI>

RFC 2396: "Uniform Resource Identifiers (URI): Generic Syntax",
Berners-Lee, Fielding, Masinter, August 1998.

http://www.iana.org/assignments/uri-schemes

http://www.iana.org/assignments/urn-namespaces

http://www.w3.org/Addressing/

=head1 COPYRIGHT

Copyright 2008 Blekko

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS / ACKNOWLEDGMENTS

This module is an XS re-write of Perl's C<URI> module, using
the fast C URI parser from the Apache project. Elimination of the
"Charlie Foxtrot" of a OO perl and on the fly scheme inclusion.
Some functions from C<URI> simply reused almost verbatim.
C<URI> was used as a reference standard, and compatibilty is maintained
whenever possible.

C<URI> is based on the C<URI::URL> module, which in turn was
(distantly) based on the C<wwwurl.pl> code in the libwww-perl for
perl4 developed by Roy Fielding, as part of the Arcadia project at the
University of California, Irvine, with contributions from Brooks
Cutter.

C<URI::URL> was developed by Gisle Aas, Tim Bunce, Roy Fielding and
Martijn Koster with input from other people on the libwww-perl mailing
list.


=cut

