#!perl -w

print "1..10\n";

use URI;
use URI::XS;

my $u = URI::XS->new("http://www.perl.com/path?q=fôo");

print "not " unless $u->canonical() eq "http://www.perl.com/path?q=f%F4o";
print "ok 1\n";

print "not " unless $u->port == 80;
print "ok 2\n";

# play with port
$u->port(8080);
$u->port(80);
$u->port(undef);

print "not " unless $u->canonical() eq "http://www.perl.com/path?q=f%F4o";
print "ok 3\n";

print "not " unless $u->host eq "www.perl.com";
print "ok 4\n";

print "not " unless $u->path eq "/path";
print "ok 5\n";

$u = URI::XS->new("http://%77%77%77%2e%70%65%72%6c%2e%63%6f%6d/%70%75%62/%61/%32%30%30%31/%30%38/%32%37/%62%6a%6f%72%6e%73%74%61%64%2e%68%74%6d%6c");
print "not " unless $u->canonical eq "http://www.perl.com/pub/a/2001/08/27/bjornstad.html";
print "ok 6\n";

$u = URI::XS->new("http://\nen.wikipedia.org/wiki/Elephant_in_the_room");

print "not " unless $u->host eq "en.wikipedia.org";
print "ok 7\n";


$u = URI::XS->new("http://\n\ren.wikipedia.org/wiki/Elephant_in_the_room");

print "not " unless $u->host eq "en.wikipedia.org";
print "ok 8\n";

$u = URI::XS->new("http://             en.wikipedia.org/wiki/Elephant_in_the_room");

print "not " unless $u->host eq "en.wikipedia.org";
print "ok 9\n";

$u = URI::XS->new("http://\ten.wikipedia.org/wiki/Elephant_in_the_room");

print "not " unless $u->host eq "en.wikipedia.org";
print "ok 10\n";
