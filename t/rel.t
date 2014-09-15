#!/usr/bin/perl

print "1..23\n";

use strict;
use URI::XS;

my $url = "http://www.example.com/foo/bar/";
my $uri = URI::XS->new($url);

my $url2 = 'http://user:password@www.example.com/foo/bar/';
my $uri2 = URI::XS->new($url2);

my $url3 = '/foo/bar/baz/';
my $uri3 = URI::XS->new($url3);

my $url4 = 'https://www.example.com/foo/bar/';
my $uri4 = URI::XS->new($url4);

my $url5 = 'http://www.example.com/';
my $uri5 = URI::XS->new($url5);

my $url6 = 'http://www.example.com';
my $uri6 = URI::XS->new($url6);

#print "DEBUG 1: " . $uri->rel("http://www.example.com/foo/bar/") ."\n";
#print "DEBUG 2: " . $uri->rel("http://WWW.EXAMPLE.COM/foo/bar/") ."\n";
#print "DEBUG 3: " . $uri->rel("http://WWW.EXAMPLE.COM/FOO/BAR/") ."\n";
#print "DEBUG 4: " . $uri->rel("http://WWW.EXAMPLE.COM:80/foo/bar/") ."\n";
#print "DEBUG 5: " . $uri->rel('HTTP://user:password@WWW.EXAMPLE.COM:80/foo/bar/') ."\n";
#print "DEBUG 6: " . $uri2->rel('HTTP://user:password@WWW.EXAMPLE.COM:80/foo/bar/') . "\n";

print "not " unless $uri->rel("http://www.example.com/foo/bar/") eq "./";
print "ok 1\n";

print "not " unless $uri->rel("HTTP://WWW.EXAMPLE.COM/foo/bar/") eq "./";
print "ok 2\n";

print "not " unless $uri->rel("HTTP://WWW.EXAMPLE.COM/FOO/BAR/") eq "../../foo/bar/";
print "ok 3\n";

print "not " unless $uri->rel("HTTP://WWW.EXAMPLE.COM:80/foo/bar/") eq "./";
print "ok 4\n";

print "not " unless $uri->rel('HTTP://user:password@WWW.EXAMPLE.COM:80/foo/bar/') eq "$url";
print "ok 5\n";

print "not " unless $uri2->rel('HTTP://user:password@WWW.EXAMPLE.COM:80/foo/bar/') eq "./";
print "ok 6\n";

print "not " unless $uri2->rel($url) eq "$url2";
print "ok 7\n";

print "not " unless $uri2->rel('http://user:password@www.example.com:888/foo/bar/') eq "$url2";
print "ok 8\n";

#
# test for urls that are already relative
#
print "not " unless $uri3->rel('http://user:password@www.example.com:888/foo/bar/') eq "$url3";
print "ok 9\n";

print "not " unless $uri3->rel($uri) eq "$url3";
print "ok 10\n";

print "not " unless $uri3->rel($uri2) eq "$url3";
print "ok 11\n";

#
# Test with different scheme
#
print "not " unless $uri4->rel($url) eq "$url4";
print "ok 12\n";

print "not " unless $uri4->rel($url2) eq "$url4";
print "ok 13\n";

print "not " unless $uri4->rel($url3) eq "$url4";
print "ok 14\n";

print "not " unless $uri2->rel($url4) eq "$url2";
print "ok 15\n";

#
# Test with base url
#

#print "DEBUG 16: " . $uri->rel($uri5)."\n";
#print "DEBUG 17: " . $uri2->rel($uri5)."\n";
#print "DEBUG 18: " . $uri3->rel($uri5)."\n";
#print "DEBUG 19: " . $uri4->rel($uri5)."\n";

print "not " unless $uri->rel($uri5) eq "foo/bar/";
print "ok 16\n";

print "not " unless $uri2->rel($uri5) eq "$url2";
print "ok 17\n";

print "not " unless $uri3->rel($uri5) eq "$url3";
print "ok 18\n";

print "not " unless $uri4->rel($uri5) eq "$url4";
print "ok 19\n";

print "not " unless $uri->rel($uri6) eq "foo/bar/";
print "ok 20\n";

print "not " unless $uri2->rel($uri6) eq "$url2";
print "ok 21\n";

print "not " unless $uri3->rel($uri6) eq "$url3";
print "ok 22\n";

print "not " unless $uri4->rel($uri6) eq "$url4";
print "ok 23\n";
