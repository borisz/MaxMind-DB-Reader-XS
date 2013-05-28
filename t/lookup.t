#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

our $VERSION = '0.01';

use MaxMind::DB::Reader::XS;
use Data::Dumper;
use Storable 'dclone';

my $ip_24_24_24_24 = {
    'country' => {
        'iso_code' => 'US',
        'names'    => {
            'zh-CN' => "\x{7f8e}\x{56fd}",
            'en'    => 'United States',
            'ja' =>
                "\x{30a2}\x{30e1}\x{30ea}\x{30ab}\x{5408}\x{8846}\x{56fd}",
            'ru' => "\x{421}\x{428}\x{410}"
        },
        'geoname_id' => 6252001
    },
    'subdivisions' => [
        {
            'iso_code' => 'NY',
            'names'    => {
                'zh-CN' => "\x{7ebd}\x{7ea6}\x{5dde}",
                'en'    => 'New York',
                'ja' =>
                    "\x{30cb}\x{30e5}\x{30fc}\x{30e8}\x{30fc}\x{30af}\x{5dde}",
                'ru' => "\x{41d}\x{44c}\x{44e}-\x{419}\x{43e}\x{440}\x{43a}"
            },
            'geoname_id' => 5128638
        }
    ],
    'location' => {
        'longitude'  => '-73.7752',
        'latitude'   => '40.6763',
        'time_zone'  => 'America/New_York',
        'metro_code' => '501'
    },
    'postal' => { 'code' => '11434' },
    'city'   => {
        'names'      => { 'en' => 'Jamaica' },
        'geoname_id' => 5122520
    },
    'continent' => {
        'names' => {
            'zh-CN' => "\x{5317}\x{7f8e}\x{6d32}",
            'en'    => 'North America',
            'ja'    => "\x{5317}\x{30a2}\x{30e1}\x{30ea}\x{30ab}",
            'ru' =>
                "\x{421}\x{435}\x{432}\x{435}\x{440}\x{43d}\x{430}\x{44f} \x{410}\x{43c}\x{435}\x{440}\x{438}\x{43a}\x{430}"
        },
        'continent_code' => 'NA',
        'geoname_id'     => 6255149
    },
    'registered_country' => {
        'iso_code' => 'US',
        'names'    => {
            'zh-CN' => "\x{7f8e}\x{56fd}",
            'en'    => 'United States',
            'ja' =>
                "\x{30a2}\x{30e1}\x{30ea}\x{30ab}\x{5408}\x{8846}\x{56fd}",
            'ru' => "\x{421}\x{428}\x{410}"
        },
        'geoname_id' => 6252001
    },
    'traits' => {
        'cellular'    => 1,
        'is_military' => 0
    },

    test_data => {
        min => {
            utf8_string_t => '',
            bytes_t       => '',
            uint16_t      => 0,
            uint32_t      => 0,
            int32_t       => -2147483648,
            uint64_t      => "\0\0\0\0\0\0\0\0",
            uint128_t     => "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
            boolean_t     => 0,
        },
        max => {
            utf8_string_t => "Stra\x{c3}\x{9f}e",
            bytes_t       => 'test',
            uint16_t      => 65535,
            uint32_t      => 4294967295,
            int32_t       => 2147483647,
            uint64_t      => "\xff\xff\xff\xff\xff\xff\xff\xff",
            uint128_t =>
                "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
            boolean_t => 1,
        }
    },
};

my $meta_hash = {
    'ip_version'                  => 4,
    'binary_format_minor_version' => 0,
    'description'                 => { 'en' => 'Test Database' },
    'build_epoch'                 => "\x00\x00\x00\x00\x51\x83\xef\x76",
    'node_count'                  => 24,
    'database_type'               => 'Test',
    'languages'                   => [
        'en',
        'ja',
        'ru',
        'zh-CN'
    ],
    'record_size'                 => 28,
    'binary_format_major_version' => 2
};

use FindBin qw/$Bin/;

for my $ip_version (qw/ 4 6 /) {
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

        push @ips, ( '::24.24.24.24', '::ffff:24.24.24.24' )
            if $ip_version == 6;

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

        my @ips = qw/ 88.88.88.88 127.0.0.1 24.24.23.255 24.24.25.0 /;
        push @ips,
            ( '2001:4860:b002::67', '2001:4860:b002::69', '::88.88.88.88',
            '::127.0.0.1',        '::24.24.23.255',   '::24.24.25.0',
            '::ffff:88.88.88.88', '::ffff:127.0.0.1', '::ffff:24.24.23.255',
            '::ffff:24.24.25.0' )
            if $ip_version == 6;

        for my $ip (@ips) {
            my $result = $mmdb->lookup_by_ip($ip);
            ok( !defined($result), "$ip is not found" );
        }
    }
}
done_testing();

__END__
