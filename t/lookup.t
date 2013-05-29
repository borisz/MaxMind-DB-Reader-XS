#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

our $VERSION = '0.01';

use MaxMind::DB::Reader::XS;
use Data::Dumper;
use Storable 'dclone';
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::MaxMind::DB::Reader::XS::Data;

my $ip_24_24_24_24 = $Test::MaxMind::DB::Reader::XS::Data::ip_24_24_24_24;
my $meta_hash      = $Test::MaxMind::DB::Reader::XS::Data::meta_hash;

for my $ip_version (qw/ 4 /) {
    for my $record_size (qw/ 24 28 32 /) {

        my $file = "v${ip_version}-$record_size.mmdb";

        my $mmdb = MaxMind::DB::Reader::XS->open( "$Bin/data/$file", 2 );

        is(
            MaxMind::DB::Reader::XS->lib_version, '0.2',
            "CAPI Version is 0.2"
        );
        is(
            MaxMind::DB::Reader::XS->lib_version, '0.2',
            "lib_version works as static member function"
        );
        is(
            $mmdb->lib_version, '0.2',
            "lib_version works as member function"
        );

        my $meta = $mmdb->metadata;

        my $meta_clone      = dclone($meta);
        my $meta_hash_clone = dclone($meta_hash);

<<<<<<< HEAD
is( $meta->{description}{en}, 'Test Database Tue Jun 18 15:02:01 2013', 'description match' );
is( "@{$meta->{languages}}", 'en ja ru zh-CN', 'DB contains en ja ru zh-CN' );
=======
        $meta_hash_clone->{ip_version}  = $ip_version;
        $meta_hash_clone->{record_size} = $record_size;
>>>>>>> Add more lookup tests

        for (qw/ node_count database_type description build_epoch /) {
            delete $meta_clone->{$_};
            delete $meta_hash_clone->{$_};
        }

        is_deeply( $meta_clone, $meta_hash_clone, "Metadata match" );

        for (
            [ 'ip_version'                  => $ip_version, ],
            [ 'binary_format_minor_version' => 0, ],
            [ 'database_type'               => 'Test', ],
            [ 'record_size'                 => $record_size, ],
            [ 'binary_format_major_version' => 2 ],
            ) {
            is( $meta->{ $_->[0] }, $_->[1], "\$meta->{$_->[0]} is $_->[1]" );
        }

        my ( $upper32, $lower32 ) = unpack NN => $meta->{build_epoch};
        ok( $upper32 == 0, "Upper 32 epoch bits are zero" );
        ok(
            ( $lower32 >= 0x51a3e21c and $lower32 <= 0x51a3e220 ),
            "Lower 32 epoch bits match"
        );

        like(
            $meta->{description}{en}, qr/^Test Database/,
            'description match'
        );
        is(
            "@{$meta->{languages}}", 'en ja ru zh-CN',
            'DB contains en ja ru zh-CN'
        );

        my @ips = ('24.24.24.24');

        for my $ip (@ips) {
            my $result = $mmdb->lookup_by_ip($ip);
            is_deeply( $result, $ip_24_24_24_24, "Data for $ip match" );

            is(
                utf8::is_utf8( $result->{registered_country}{names}{ja} ), 1,
                "utf8 flag is set for names/ja"
            );
            ok(
                !utf8::is_utf8( $result->{registered_country}{names}{us} ),
                "utf8 flag is NOT set for names/us"
            );

            ok( $result->{traits}{is_military} == 0, "Boolean zero works" );
            ok( $result->{traits}{cellular} == 1,    "Boolean one works" );

        }

        @ips = qw/ 88.88.88.88 127.0.0.1 24.24.23.255 24.24.25.0 /;

        for my $ip (@ips) {
            my $result = $mmdb->lookup_by_ip($ip);
            ok( !defined($result), "$ip is not found" );
        }
    }
}
done_testing();

__END__
