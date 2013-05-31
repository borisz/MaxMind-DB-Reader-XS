#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

our $VERSION = '0.01';

use MaxMind::DB::Reader::XS;
use FindBin qw/$Bin/;

my $mmdb = MaxMind::DB::Reader::XS->open( "$Bin/data/v4-28.mmdb", 2 );

is( MaxMind::DB::Reader::XS->lib_version, '0.3', "CAPI Version is 0.3" );
is(
    MaxMind::DB::Reader::XS->lib_version, '0.3',
    "lib_version works as static member function"
);
is( $mmdb->lib_version, '0.3', "lib_version works as member function" );

done_testing();

__END__
