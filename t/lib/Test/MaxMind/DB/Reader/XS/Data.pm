package Test::MaxMind::DB::Reader::XS::Data;

our ( $ip_24_24_24_24, $meta_hash );

my @values = (
    0,  0.0, 1,      .1,  0.123, 10, 7.99, 999999999.9999999,
    -1, -.1, -0.123, -10, -7.99, -999999999.9999999
);

$ip_24_24_24_24 = {
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
        },
        tst => {
            array_ieee754_float_t  => \@values,
            array_ieee754_double_t => \@values,
        },
    },
};

$meta_hash = {
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
1;

