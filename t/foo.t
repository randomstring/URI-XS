use Test;
use URI::XS;

print "1..10\n";

my $q2 = URI::XS->new('http://loosername:secretpassword@www.example2.com/bar/baz.cgi?q=wtf&session=1231245abcdef#inbox');

%ans = (
    scheme   => 'http',
    user     => 'loosername',
    password => 'secretpassword',
    hostinfo => 'loosername:secretpassword@www.example2.com',
    hostname => 'www.example2.com',
    port_str => undef,
    path     => '/bar/baz.cgi',
    query    => 'q=wtf&session=1231245abcdef',
    fragment => 'inbox',
    port     => 80,
   );

my $i = 1;
foreach my $f (sort keys %ans) {
    if ((!defined($ans{$f}) && !defined($q2->$f())) ||
	($ans{$f} eq $q2->$f())) {
	print "ok " . $i++ . "\n";
    }
    else {
	print "not ok " . $i++ . "\n";
    }
}
