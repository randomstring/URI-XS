#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);

BEGIN {
    use_ok('URI::XS');
}

my ($uri, $base);

for my $basestr ('http://www.skrenta.com/', 'http://www.skrenta.com') {
    $base = new URI::XS($basestr);

    for my $rel ('monster/', '/monster/') {

        $uri = new URI::XS;
        $uri->new_abs( $rel, $base );

        is $uri->as_string, "http://www.skrenta.com/monster/",
        " from $basestr and $rel";
    }
}

my $test_empty = new URI::XS();
isa_ok $test_empty, q{URI::XS};

$uri = new URI::XS( "/monster" );
is( $uri, '/monster' );

$uri = $uri->new_abs( "/monster", $test_empty );
is( $uri, '/monster' );

#  Bad base url found in the wild
$uri = new URI::XS("http:/jjsbar.com");
#print "string: ", $uri->as_string, "  canonical: ", $uri->canonical(), "\n";
is( $uri, 'http:/jjsbar.com' );

$uri = $uri->new_abs( "offsale.html", "http:/jjsbar.com");
is( $uri, 'http:///offsale.html' );

$uri = new URI::XS("");
is( $uri, '', "empty URI returns empty string");

$uri = $uri->new_abs( "//bar", "http://jjsbar.com/");
is( $uri, 'http://bar/' );

#use URI;
#my $test = new URI->new_abs( "//bar", "http://jjsbar.com/");
#is( "$test", 'http://bar' );

$uri = new URI::XS('http://www.microsoft.com/foo\bar\baz.html');
is( $uri->canonical->as_string, 'http://www.microsoft.com/foo/bar/baz.html', "convert back slash to forward slash");

$uri = new URI::XS(          'http://www.microsoft.com/foo/baz?q=test\bar\baz#n\a');
is( $uri->canonical->as_string, 'http://www.microsoft.com/foo/baz?q=test\bar\baz#n\a', "ignore back slash in args or fragment");

$uri = new URI::XS("http://www.microsoft.com/foo%5Cbar%5cbaz.html");
is( $uri->canonical->as_string, 'http://www.microsoft.com/foo%5Cbar%5Cbaz.html', "do not change escaped back slash %5C");

$uri = new URI::XS("http://www.microsoft.com/foo/../bar/index.html");
is( $uri->canonical->as_string, 'http://www.microsoft.com/bar/index.html', "short circuit relative url paths");

$uri = new URI::XS("http://www.microsoft.com/foo/dec/01/../../jan/02/index.html");
is( $uri->canonical->as_string, 'http://www.microsoft.com/foo/jan/02/index.html', "short circuit relative url paths");

$uri = new URI::XS("http://foo.com//a//b/c.html");
is( $uri->canonical, 'http://foo.com/a/b/c.html', "clean up multiple forward slashes");

$uri = new URI::XS("http://foo.com/a///////b/c.html");
is( $uri->canonical, 'http://foo.com/a/b/c.html', "clean up multiple forward slashes");

$uri = new URI::XS("http://foo.com/./c.html");
is( $uri->canonical, 'http://foo.com/c.html', "clean up leading ./");

$uri = new URI::XS("http://foo.com/./c.html");
is( $uri->canonical, 'http://foo.com/c.html', "clean up leading ./");

$uri = new URI::XS("http://foo.com/././././c.html");
is( $uri->canonical, 'http://foo.com/c.html', "clean up multiple leading ./");

$uri = new URI::XS("http://foo.com/./../../../c.html");
is( $uri->canonical, 'http://foo.com/c.html', "clean up multiple leading ./ and ../");

$uri = new URI::XS("http://foo.com/./.././.././c.html");
is( $uri->canonical, 'http://foo.com/c.html', "clean up multiple leading ./ and ../");
