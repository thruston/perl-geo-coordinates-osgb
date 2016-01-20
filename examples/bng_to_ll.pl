#! /usr/bin/perl -w

# Toby Thurston -- 20 Jan 2016 
# Parse a National Grid ref and show it as LL coordinates

use strict;
use warnings;

sub dms {
    my ($degrees,$n,$s) = @_;
    my $sign = $degrees < 0 ? $s : $n;
    my $dd = abs($degrees);
    my $d = int($dd);
    my $mm = 60*($dd-$d);
    my $m = int($mm);
    my $ss = 60*($mm-$m);
    return ($sign, $d, $m, $ss);
}

use Geo::Coordinates::OSGB qw/grid_to_ll/;
use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid_landranger/;

my $gr = "@ARGV";

my ($e, $n) = $gr eq 'test' ? (651409.903, 313177.270) : parse_grid($gr);
my ($lat, $lon) = grid_to_ll($e, $n);

print "Your input: $gr == $e $n ";
printf "is %s\n", scalar format_grid_landranger($e, $n);

printf "Which is %s %d° %d' %g'', ", dms($lat, 'N', 'S');
printf "%s %d° %d' %g'' in WGS84 terms\n", dms($lon, 'E', 'W');
printf "And as decimal lat/lon: %.8g %.8g\n", $lat, $lon;

