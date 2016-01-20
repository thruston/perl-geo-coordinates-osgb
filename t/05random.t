# Toby Thurston -- 20 Jan 2016 
#
use strict;
use warnings;
use Test::More tests => 64;

use Geo::Coordinates::OSGB qw(ll_to_grid grid_to_ll);
use Geo::Coordinates::OSGB::Grid qw(format_grid parse_grid parse_landranger_grid random_grid);

# Random round trip - random_grid ensures they are all in OSTN02 coverage, so accuracy is always less that 10cm and 
# usually only 1 or 2 mm.  Here it's rounded to 1m by "%d %d" but then we start with whole metres anyway

for my $r (1..20) {
    my ($E, $N) = random_grid();

    my ($e,$n) = ll_to_grid(grid_to_ll($E, $N));

    is (sprintf("%d %d", $e, $n), sprintf("%d %d", $E, $N), sprintf "Round trip %s %s", $r, scalar format_grid($E, $N));

}


# now test 42 random grid locations and cycle them through grid -> short grid -> map
#
my $i = 0;
LIFE:
while (1) {

    my ($E, $N) = random_grid();

    my ($sq, $e, $n, @sheets) = format_grid($E,$N, { form => 'gps', maps => 1});

    if ( @sheets ) {
        $i++;
        my ($ee, $nn) = parse_grid($sheets[0], $e, $n, {figs => 5});
        my $gr1 = format_grid($ee, $nn);
        my $gr2 = format_grid(ll_to_grid(grid_to_ll($ee, $nn)));
        is($gr1, $gr2, "GR$i: $gr1=$gr2 " . join ' ', @sheets );
    }

    last LIFE if $i == 42;
}


# Now checkout the random_grid function with a list of maps
# The point here is that 118 is a Landranger sheet but 439 is not
# Also sheet 118 is not overlapped by a sheet with a lower number
# so A:118 must be first in the list returned (because it's sorted)
my ($e, $n) = random_grid(118, 439);
my (undef, undef, undef, @sheets) = format_grid($e, $n, { maps => 1 });
ok(@sheets > 0 && $sheets[0] eq 'A:118', "@sheets");

# test that we can also ignore a random string
# sheets 84-88 all share the same lower northing
# so we are checking that the deltas fit in a 200 km x 40 km box (plus a little margin)
use Geo::Coordinates::OSGB::Maps qw/%maps/;
($e, $n) = random_grid(84,85,86,87,88,'ignoreme');
my ($lle, $lln) = @{$maps{'A:84'}->{bbox}[0]};
my $de = $e-$lle;
my $dn = $n-$lln;
ok(0 < $de && $de<202000 && 0<$dn && $dn<42000, "RR $de < 202000 $dn < 42000 " . format_grid($e,$n));
