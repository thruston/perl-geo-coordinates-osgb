#! /usr/bin/perl -w

# Toby Thurston ---  6 May 2009
# Parse a National Grid ref and show it as LL coordinates

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/
        parse_grid
        grid_to_ll
        shift_ll_into_WGS84
        format_ll_trad
        format_ll_ISO
        format_grid_map
        format_grid_landranger/;

use Geo::Coordinates::OSTN02 qw/
        OSGB36_to_ETRS89
        /;

my $gr = "@ARGV";

my ($e, $n) = $gr eq 'test' ? (651409.903, 313177.270) : parse_grid($gr);
my ($x, $y, $z) = OSGB36_to_ETRS89($e,$n,0);
my ($lat, $lon) = grid_to_ll($e, $n);
my ($wla, $wlo) = grid_to_ll($x,$y,'WGS84');

print "Your input: $gr == $e $n ";
printf "is %s\n", scalar format_grid_map($e, $n);

printf "and %s on that sheet\n",  join ':', format_ll_trad($lat, $lon);
printf "but %s in WGS84 terms\n", join ':', format_ll_trad($wla, $wlo);
printf "or as decimals %.8g %.8g\n", $wla, $wlo;

