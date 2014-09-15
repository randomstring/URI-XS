#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use URI::XS;

ok( !!URI::XS->new( "http://www.skrenta.com/foo" ) );
ok( URI::XS->new( "/bar/baz" ) );
ok( !URI::XS->new( "" ) );
ok( URI::XS->new( "0" ) );

done_testing();
