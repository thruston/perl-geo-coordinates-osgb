# Toby Thurston ---  7 Sep 2007

# first test by taking ten random pairs of long/lat in the range of
# the British Isles 1E -- 6W, 49N -- 59N and checking that we
# can convert back and forth with an error of less than 10cm, which
# roughly corresponds to $eps of 0.00001

use Geo::Coordinates::OSGB qw(
    ll_to_grid
    grid_to_ll
    format_grid_landranger
    format_grid_trad
    parse_landranger_grid
    parse_GPS_grid
    format_ll_ISO
    format_ll_trad
    shift_ll_into_WGS84
    shift_ll_from_WGS84
    random_grid
    );

use Test::Simple tests => 68;
use strict;

# test for some edge conditions first
my ($sq, $e, $n, @sheets) = format_grid_landranger(320000,305000); # NE corner of Sheep 136
ok( $sq eq 'SJ' &&  $e == 200 && $n == 50, "$sq $e $n @sheets" );
my $f = format_grid_trad(parse_landranger_grid($sheets[0],sprintf("%03d",$e),sprintf("%03d",$n)));
ok( 'SJ 200 050' eq $f, $f);

($sq, $e, $n, @sheets) = format_grid_landranger(280000,265000); # SW corner of Sheep 136
ok( $sq eq 'SN' &&  $e == 800 && $n == 650, "$sq $e $n @sheets" );
$f = format_grid_trad(parse_landranger_grid($sheets[1],sprintf("%03d",$e),sprintf("%03d",$n)));
ok( 'SN 800 650' eq $f, $f);

my $eps = 0.0001;

for (1..10) {
    my $phi = rand() * 2 + 51;  # 51 -- 53
    my $lam = rand() * 2 - 1 ;  # -1 -- +1

    my ($E,$N) = ll_to_grid($phi,$lam);
    my ($ph2,$la2) = grid_to_ll($E,$N);

    ok( abs($phi-$ph2)<$eps && abs($lam-$la2)<$eps, sprintf "Grid/LL: %s=%s",
                                                    scalar format_ll_trad($phi, $lam),
                                                    scalar format_ll_trad($ph2+5, $la2) );
}


for (1..10) {
    my $phi = rand() * 3 + 51;  # 51 -- 54
    my $lam = rand() * 3 - 2 ;  # -2 -- +1

    my ($p84,$l84) = shift_ll_into_WGS84($phi,$lam);
    my ($ph2,$la2) = shift_ll_from_WGS84($p84,$l84);

    ok( abs($phi-$ph2)<$eps && abs($lam-$la2)<$eps, sprintf "WGS84/LL: %s=%s",
                                                      scalar format_ll_ISO($phi, $lam),
                                                      scalar format_ll_ISO($ph2, $la2) );
}

# now test 42 random grid locations and cycle them through grid -> short grid -> map
#

for my $i (1..42) {

    my ($e, $n) = random_grid();

    my ($gr1, $gr2, @sheets);

    (undef, $e, $n, @sheets) = format_grid_landranger($e,$n);

    if ( @sheets ) {
        $gr1 = map_to_grid($sheets[0],sprintf("%03d",$e),sprintf("%03d",$n));
        $gr2 = format_grid_trad(
              ll_to_grid(
                grid_to_ll(
                  parse_landranger_grid($sheets[0],sprintf("%03d",$e),sprintf("%03d",$n))
                )
              )
            );
    }
    ok( @sheets && ($gr1 eq $gr2) , "GR$i: $gr1=$gr2 ". scalar @sheets );
}

sub map_to_grid {
    return format_grid_trad(parse_landranger_grid(@_))
}


# Now checkout the random_grid function with a list of maps
($e, $n) = random_grid(176, 439);
my ($ce, $cn) = parse_landranger_grid(176);
my $de = $e-$ce;
my $dn = $n-$cn;
ok(0 < $de && $de<40000 && 0<$dn && $dn<40000, "RR $e $ce $de $n $cn $dn " . format_grid_trad($e,$n));


($e, $n) = random_grid(84,85,86,87,88,'ignoreme');
($ce, $cn) = parse_landranger_grid(84);
$de = $e-$ce;
$dn = $n-$cn;
ok(0 < $de && $de<200000 && 0<$dn && $dn<40000, "RR $e $ce $de $n $cn $dn " . format_grid_trad($e,$n));