use Test::More;
use URI::XS;
use URI;
use strict;

my $expected_URI_version = 1.58;

if ( $URI::VERSION ne $expected_URI_version ) {
    BAIL_OUT("Wrong version of URI installed: is $URI::VERSION, should be $expected_URI_version");
}

#
# test correct escaping of path component and not breaking/segfaulting
# with high byte chars in the URI.
#
# URI::XS differs from URI in that the sub-components are not
# escaped when returned. The path_query(), path(), and canonical() are
# escaped. (URI follows RFC3492 and "Punycode" encodes the host.)
#
# So our test needs to have, for each URI (and component thereof):
# - What URI does
# - What URI::XS should do
#
# This requires us to build a table of URIs and responses and then walk it.
# Note that this means that we do NOT directly compare the URI::XS and
# URI output anymore! We instead check the returned value vs. what we expect
# to get; this is a little more work for anyone adding test cases, but it
# decreases the dependence of URI::XS on exactly matching URI's output.
#
# See the tinyarro.ws short URL example below for an example: the encoded
# URLS http://%E2%9E%A1.ws/lyta (our version) and http://xn--4ag7q.ws/lyta
# (the URI version) both *mean* http://➡.ws/lyta; to us, our encoding and
# the Punycode encoding are the same, but to browsers, they both point to
# the same place: http://➡.ws/lyta.
#
# Note: The IDN encoding in URI seems to be wrong! The Thawte encoder (at
# http://www.thawte.com/ssl/idn-converter/index.html), which is the only one
# I've found so far that actually works - as in, gives results that act
# identically when pasted into the browser, gives xn-hgi.ws as the correct
# encoding of ➡.ws, and this can be verified by pasting it into the browser.

my %uris = (
'http://www.parismatch.com/parismatch/recherche/recherche?motcle= santé' => {
    'URI::http' => {
      path => '/parismatch/recherche/recherche',
      path_query => '/parismatch/recherche/recherche?motcle=%20sant%C3%A9',
      scheme => 'http',
      fragment => undef,
      query => 'motcle=%20sant%C3%A9',
      port => 80,
      host => 'www.parismatch.com',
      host_port => 'www.parismatch.com:80',
      authority => 'www.parismatch.com',
      canonical => 'http://www.parismatch.com/parismatch/recherche/recherche?motcle=%20sant%C3%A9',
    },
    'URI::XS' => {
      path => '/parismatch/recherche/recherche',
      path_query => '/parismatch/recherche/recherche?motcle=%20sant%C3%A9',
      scheme => 'http',
      fragment => undef,
      query => 'motcle= santé',
      port => 80,
      host => 'www.parismatch.com',
      host_port => 'www.parismatch.com:80',
      authority => 'www.parismatch.com',
      canonical => 'http://www.parismatch.com/parismatch/recherche/recherche?motcle=%20sant%C3%A9',
    },
  },
'http://www.Santé.com/foo bar/Santé#santé' => {
    'URI::XS' => {
      path => '/foo%20bar/Sant%C3%A9',
      path_query => '/foo%20bar/Sant%C3%A9',
      scheme => 'http',
      fragment => 'santé',
      query => undef,
      port => 80,
      host => 'www.santé.com',
      host_port => 'www.santé.com:80',
      authority => 'www.santé.com',
      canonical => 'http://www.sant%C3%A9.com/foo%20bar/Sant%C3%A9#sant%C3%A9',
    },
    'URI::http' => {
      path => '/foo%20bar/Sant%C3%A9',
      path_query => '/foo%20bar/Sant%C3%A9',
      scheme => 'http',
      fragment => 'sant%C3%A9',
      query => undef,
      port => 80,
      host => 'www.xn--sant-8fa9m.com',
      host_port => 'www.xn--sant-8fa9m.com:80',
      authority => 'www.xn--sant-8fa9m.com',
      canonical => 'http://www.xn--sant-8fa9m.com/foo%20bar/Sant%C3%A9#sant%C3%A9',
    },
},

'http://➡.ws/lyta' => {
    'URI::XS' => {
      path => '/lyta',
      path_query => '/lyta',
      scheme => 'http',
      fragment => undef,
      query => undef,
      port => 80,
      host => '➡.ws',
      host_port => '➡.ws:80',
      authority => '➡.ws',
      canonical => 'http://%E2%9E%A1.ws/lyta',
    },
    'URI::http' => {
      path => '/lyta',
      path_query => '/lyta',
      scheme => 'http',
      fragment => undef,
      query => undef,
      port => 80,
      host => 'xn--4ag7q.ws',
      host_port => 'xn--4ag7q.ws:80',
      authority => 'xn--4ag7q.ws',
      canonical => 'http://xn--4ag7q.ws/lyta',
    }
},
);

foreach my $uri (keys %uris) {
    my $new = URI::XS->new($uri);
    my $old = URI->new($uri);

    for my $method (qw(path path_query scheme fragment query port)) {
        is $new->$method, $uris{$uri}->{ref $new}->{$method}, "new $method";
        is $old->$method, $uris{$uri}->{ref $old}->{$method}, "old $method";
    }

    if (defined($new->scheme)) {
        for my $method (qw(host host_port authority)) {
          is $new->$method, $uris{$uri}->{ref $new}->{$method}, "new $method";
          is $old->$method, $uris{$uri}->{ref $old}->{$method}, "old $method";
        }
    }

    # canonical must be last, for URI it changes its parts
    for my $method (qw(canonical)) {
        is $new->$method, $uris{$uri}->{ref $new}->{$method}, "new $method";
        is $old->$method, $uris{$uri}->{ref $old}->{$method}, "old $method";
    }
}
done_testing();

