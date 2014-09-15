#!/usr/bin/perl

use URI::XS;

BEGIN { print "1..11\n"; }

my $u = URI::XS->new();

$u->host("foo");
print ($u->host eq "foo" ? "ok\n" : "not ok\n");

my $a = "foo";
$a =~ /^(.+)/;
$u->host($1);
print ($u->host eq "foo" ? "ok\n" : "not ok\n");

my $b = "foo";
$b =~ /^(.+)/;
$u->host("$1");
print ($u->host eq "foo" ? "ok\n" : "not ok\n");

$u->host(1234);
print ($u->host eq "1234" ? "ok\n" : "not ok\n");

$u->host(undef);
print (!defined($u->host)  ? "ok\n" : "not ok\n");

$u->host("");
print ($u->host eq ""  ? "ok\n" : "not ok\n");

$u->host(1234.5);
print ($u->host eq "1234.5" ? "ok\n" : "not ok\n");

$u->port(1234);
print ($u->port == 1234 ? "ok\n" : "not ok\n");
print ($u->port_str eq "1234" ? "ok\n" : "not ok\n");


$u->port_str("567");
print ($u->port == 567 ? "ok\n" : "not ok\n");
print ($u->port_str eq "567" ? "ok\n" : "not ok\n");
