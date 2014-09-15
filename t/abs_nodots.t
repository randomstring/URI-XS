use Test;
use URI::XS;

BEGIN { plan tests => 4 }

$URI::XS::ABS_REMOVE_LEADING_DOTS = 1;

while($line = <DATA>) {
    chomp($line);
    my($base,$rel,$ans) = split(/\s+/,$line,3);

    my $a = URI::XS->new_abs($rel,$base);

    if ($a ne $ans) {
        #print "new_abs($base,$rel) = $a\n";
        ok(0);
    }
    else {
        ok(1);
    }
}


__DATA__
http://www.bottlecount.com/foo/bar/ ../../../baz.html http://www.bottlecount.com/baz.html
http://www.westcoastwine.net/test/index.html ../../../contact.html http://www.westcoastwine.net/contact.html
http://www.wineontheweb.com/ ../foo/bar/../baz/ http://www.wineontheweb.com/foo/baz/
http://www.example.com/ ../../baz/ http://www.example.com/baz/
