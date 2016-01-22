#! /usr/bin/perl -w

# Toby Thurston ---  6 May 2009
# Parse LL and show as National Grid ref

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/ll_to_grid/;
use Geo::Coordinates::OSGB::Grid qw/format_grid_landranger/;

if ( @ARGV == 0 ) {
    die "Usage: $0 lat lon\n"
}

my ($lat, $lon);
if ( $ARGV[0] eq 'test' ) {
    $lat = 52 + ( 39 + 27.2531/60 )/60;
    $lon =  1 + ( 43 +  4.5177/60 )/60;
} 
else {
    ($lat, $lon) = @ARGV;
}

my ($e,  $n)  = ll_to_grid($lat, $lon);

printf "Your input: %g %g from WGS84 is %s %s on the grid\n", $lat, $lon, $e, $n;
printf "which is %s\n", scalar format_grid_landranger($e, $n);

