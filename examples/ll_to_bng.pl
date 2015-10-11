#! /usr/bin/perl -w

# Toby Thurston ---  6 May 2009
# Parse LL and show as National Grid ref

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/
        parse_ISO_ll
        ll_to_grid
        shift_ll_from_WGS84
        format_ll_trad
        format_grid_trad
        format_grid_map/;

use Geo::Coordinates::OSTN02 qw/ETRS89_to_OSGB36/;

if ( @ARGV == 0 ) {
    die "Usage: $0 lat lon\n"
}

my ($lat, $lon);
if ( $ARGV[0] eq 'test' ) {
    $lat = 52 + ( 39 + 27.2531/60 )/60;
    $lon =  1 + ( 43 +  4.5177/60 )/60;
}
elsif ( @ARGV == 1 ) {
    ($lat, $lon) = parse_ISO_ll($ARGV[0]);
} else {
    ($lat, $lon) = @ARGV;
}

my ($gla, $glo, undef) = shift_ll_from_WGS84($lat, $lon);
my ($ge, $gn) = ll_to_grid($gla, $glo);
my ($e,  $n)  = ll_to_grid($lat, $lon);

print "Your input: @ARGV\n";
printf "is %s\n", scalar format_ll_trad($lat, $lon);

printf "$e $n == %d %d from OSGB  (%s)\n", $e, $n, scalar format_grid_map($e, $n);
printf "or %d %d from WGS84 (%s)\n", $ge, $gn, scalar format_grid_map($ge, $gn);

printf join '|', ETRS89_to_OSGB36(ll_to_grid($lat,$lon,'WGS84'),108.05);
