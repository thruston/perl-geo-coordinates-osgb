use strict;
use warnings;

use Test::More tests => 12;

use Geo::Coordinates::OSGB qw /ll_to_grid/;
use Geo::Coordinates::OSGB::Grid qw/
  format_grid_trad
  format_grid_GPS
  format_grid_map
  format_grid_landranger
  format_grid
  /;


is(format_grid_trad(0,0),   "SV 000 000",     "False origin trad");
is(format_grid_trad(-1,-1), "WE 999 999",     "SW of False origin trad");

is(format_grid_GPS(0,0),    "SV 00000 00000", "False origin GPS");
is(format_grid_GPS(-1,-1),  "WE 99999 99999", "SW of False origin GPS");

# Rockall
my ($e, $n) = ll_to_grid(57.596304, -13.687308);
is(format_grid_trad($e, $n), 'MC 035 165', 'Rockall');

# OSHQ
$e = 438710.908;
$n = 114792.248;
is(format_grid($e, $n, {form => 'SSEN'}),       'SU31',       "format_grid with SSEN");                  
is(format_grid($e, $n, {form => 'ss eee nnn'}), 'SU 387 147', "format_grid with SS EEE NNN");                  
is(format_grid($e, $n, {form => 'trad'}),  'SU 387 147',      "format_grid with trad"); 
is(format_grid($e, $n, {form => 'gps' }),  'SU 38710 14792',  "format_grid with gps");  
is(format_grid($e, $n, {form => 'map' }),  'SU 387 147 on A:196, B:OL22E, C:180',  "format_grid with map");  
is(format_grid($e, $n, {form => 'map', series_keys => 'B'}),  'SU 387 147 on B:OL22E',               "format_grid with map + options");
is(format_grid($e, $n, {form => 'landranger'}),               'SU 387 147 on Landranger sheet 196',  "format_grid with landranger");                  
