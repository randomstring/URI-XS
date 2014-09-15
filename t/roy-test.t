#!/usr/bin/env perl

use warnings;

use FindBin;

print "1..72\n";

if (-d "t") {
   chdir("t") || die "Can't chdir 't': $!";
   # fix all relative library locations
   foreach (@INC) {
      $_ = "../$_" unless m,^/,;
   }
}

use URI::XS;
use URI;
$no = 1;


# skip roytest4.html and roytest5.html because they test archaic "//" in path.

for $i (1..3) {
   my $file = "$FindBin::Bin/roytest$i.html";

   open(FILE, $file) || die "Can't open $file: $!";
   print "# $file\n";
   $base = undef;
   while (<FILE>) {
       if (/^<BASE href="([^"]+)">/) {
           $basestr = "$1";
           $base = URI::XS->new("$basestr");
           # print "Setting base = $1 [" . $base->canonical . "]\n";
       } elsif (/^<a href="([^"]*)">.*<\/a>\s*=\s*(\S+)/) {
           die "Missing base at line $." unless $base;
           $link = $1;
           $exp  = $2;
           $exp = $base->canonical if $exp =~ /current/;  # special case test 22

           # rfc2396bis restores the rfc1808 behaviour
           if ($no == 7) {
               $exp = "http://a/b/c/d;p?y";
           }
           elsif ($no == 48) {
               $exp = "http://a/b/c/d;p?y";
           }

           $base = URI::XS->new("$basestr");
           my $abs  = URI::XS->new($link);
           $abs->abs($base->canonical);
           unless ($abs->canonical eq $exp) {
               $abs_old = URI->new_abs($link,$basestr)->canonical;
               print "$file:$.:  Expected: $exp [$abs_old]\n";
               print "abs($link," . $base->canonical .") ==> " . $abs->canonical . "\n";
               print "not ";
           }
           print "ok $no\n";
           $no++;
       }
   }
   close(FILE);
}
