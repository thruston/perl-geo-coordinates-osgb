# Toby Thurston -- 14 Jan 2016 

# test grid ref parsing and ll parsing

use Test::More tests=>16;

use Geo::Coordinates::OSGB::Grid qw(
    parse_trad_grid
    parse_GPS_grid
    parse_grid
    parse_landranger_grid
    format_grid_trad
);

is( parse_grid('176/238714') ,  parse_landranger_grid(176,238,714),     'Parse sheets');
is( parse_grid('TA123567')   ,  parse_trad_grid('TA123567'),            'Parse trad1');
is( parse_grid('TA123567')   ,  parse_trad_grid('TA 123 567'),          'Parse trad1a');
is( parse_grid('TA123567')   ,  parse_trad_grid('TA','123567'),         'Parse trad2');
is( parse_grid('TA123567')   ,  parse_trad_grid('TA',123,567),          'Parse trad3');
is( parse_grid(1)            ,  parse_landranger_grid(1),                    'Parse sheet1');
is( parse_grid(1)            ,  format_grid_trad(429000,1180000) ,      'Parse formatting');
is( parse_grid(204)          ,  format_grid_trad(172000,14000) ,        'Parse formatting');


ok( (($e,$n) = parse_grid('TQ 234 098')) && $e == 523_400 && $n == 109_800 , "Help example 1 $e $n");
ok( (($e,$n) = parse_grid('TQ234098')  ) && $e == 523_400 && $n == 109_800 , "Help example 2 $e $n");
ok( (($e,$n) = parse_grid('TQ',234,98) ) && $e == 523_400 && $n == 109_800 , "Help example 3 $e $n");

ok( (($e,$n) = parse_grid('TQ 23451 09893')) && $e == 523_451 && $n == 109_893 , "Help example 4 $e $n");
ok( (($e,$n) = parse_grid('TQ2345109893')  ) && $e == 523_451 && $n == 109_893 , "Help example 5 $e $n");
ok( (($e,$n) = parse_grid('TQ',23451,9893) ) && $e == 523_451 && $n == 109_893 , "Help example 6 $e $n");

# You can also get grid refs from individual maps.
# Sheet between 1..204; gre & grn must be 3 or 5 digits long

ok( (($e,$n) = parse_grid(176,123,994)     ) && $e == 512_300 && $n == 199_400 , "Help example 7 $e $n");
#
# With just the sheet number you get GR for SW corner
ok( (($e,$n) = parse_grid(184)) && $e == 389000 && $n == 115000 , "Help example 8 $e $n");

