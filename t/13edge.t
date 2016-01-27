# Toby Thurston -- 20 Jan 2016 

# test boundary conditions

use Geo::Coordinates::OSGB qw/ll_to_grid grid_to_ll set_default_shape/;
use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid format_grid_GPS/;

use Test::More tests => 14;

# The point of this test is to check running off the edge of the OSTN02 polygon
# (79020, 20) is just 20 N and E of the SW corner of the first sq in OSTN02
# and the first transformation of +100 -90 m will take us to (79120, -70)
# which should cause us fall back to using the Helmert approximation

my ($helmert_lat, $helmert_lon) = (49.8143931975509, -6.4635705395896);
is( sprintf( "%s %s", grid_to_ll(79020,20)), "$helmert_lat $helmert_lon" , "Edge one");
is( ll_to_grid($helmert_lat, $helmert_lon), "79020 20", "Edge one");


is( ll_to_grid(grid_to_ll(77360, 895710)), "77360 895710", "near Uist");
is( ll_to_grid(grid_to_ll(109865,764128)), "109865 764128", "near Coll");
is( ll_to_grid(grid_to_ll(458020,1217306)), "458020.000 1217320.559", "near Yell");
is( ll_to_grid(grid_to_ll(449611,1215083)), "449611.000 1215095.427", "near Yell");
is( ll_to_grid(grid_to_ll(456720,1210574)), "456720.000 1210582.123", "near Yell");
is( ll_to_grid(grid_to_ll(452979,1203121)), "452979.000 1203122.069", "near Yell");
is( ll_to_grid(grid_to_ll(447086,1203452)), "447086.000 1203453.381", "near Yell");
is( ll_to_grid(grid_to_ll(382514, 682908)), "382514 682908", "off Scarborough");
is( ll_to_grid(grid_to_ll(377516, 684564)), "377516 684564", "off Scarborough");
is( ll_to_grid(grid_to_ll(363754, 724465)), "363754 724465", "off Scarborough");
is( ll_to_grid(grid_to_ll(parse_grid('SW 540 170'))), "154000 17000", "in SW");
is( ll_to_grid(grid_to_ll(parse_grid('SW 910 150'))), "191000 15000", "in SW");

#  1217306.000  1217320.559  14.559  9.512 
#  1215083.000  1215095.427  12.427  9.499 
#  1210574.000  1210582.123   8.123  9.474 
#  1203121.000  1203122.069   1.069  9.536 
