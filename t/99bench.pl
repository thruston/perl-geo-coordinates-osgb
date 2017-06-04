# Toby Thurston -- 04 Jun 2017 

# Bench mark the conversion routines

use strict;
use Geo::Coordinates::OSGB   qw/grid_to_ll grid_to_ll_helmert ll_to_grid ll_to_grid_helmert/;
use Benchmark qw/cmpthese/;

print "Comparing conversion from lat/lon to grid\n";
cmpthese( -1, {
    normal => "ll_to_grid(52 + rand 3, 0 - rand 3)", 
    approx => "ll_to_grid_helmert(52 + rand 3, 0 - rand 3)", 
} );
print "\n";
print "Comparing conversion from grid to lat/lon\n";
cmpthese( -1, {
    normal  => "grid_to_ll(400000 + rand 100000, 300000 + rand 100000)",
    approx => "grid_to_ll_helmert(400000 + rand 100000, 300000 + rand 100000)",
} );
