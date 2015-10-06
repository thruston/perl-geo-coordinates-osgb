# Toby Thurston -- 04 Oct 2015 
#
use strict;
use warnings;

use Geo::Coordinates::OSTN02 qw/ETRS89_to_OSGB36 OSGB36_to_ETRS89/;
use Geo::Coordinates::OSGB   qw/grid_to_ll ll_to_grid format_grid_GPS/;

use Test::Simple tests => 13*3;

# some test data obtained by feeding random GRs to the online batch converter provided by the OS.
my @test_data = ();

push @test_data, { grid => [452788,520697], gps => [54.578747, -1.184859, 48.329], xyz => [3704143.232593,  -76611.478515, 5174384.798039], sq => "NZ5220"}; 
push @test_data, { grid => [481267,257208], gps => [52.207128, -0.812142, 47.431], xyz => [3916409.21937,   -55517.041028, 5016997.080619], sq => "SP8157"}; 
push @test_data, { grid => [421176,317227], gps => [52.752264, -1.687695, 49.691], xyz => [3867013.25437,  -113939.043255, 5053944.064276], sq => "SK2117"}; 
push @test_data, { grid => [ 88724,901972], gps => [57.89812,  -7.255943, 57.185], xyz => [3370501.932141, -429137.262071, 5379764.59814], sq => "NA8801"}; 
push @test_data, { grid => [ 75537,860152], gps => [57.514799, -7.421059, 57.352], xyz => [3405037.296092, -443509.816804, 5356956.390959], sq => "NF7560"}; 
push @test_data, { grid => [379729,556107], gps => [54.899281, -2.317626, 51.532], xyz => [3672795.235173, -148646.379371, 5194986.532721], sq => "NY7956"}; 
push @test_data, { grid => [450194,324208], gps => [52.813107, -1.256732, 48.719], xyz => [3862369.694384,  -84731.245309, 5058038.525777], sq => "SK5024"}; 
push @test_data, { grid => [150568,710527], gps => [56.221674, -6.025127, 55.203], xyz => [3534749.594129, -373084.536562, 5278250.538957], sq => "NM5010"}; 
push @test_data, { grid => [255012,226125], gps => [51.914736, -4.109446, 53.672], xyz => [3932328.987003, -282524.503244, 4996999.207321], sq => "SN5526"}; 
push @test_data, { grid => [245034,781030], gps => [56.894632, -4.545662, 54.500], xyz => [3480870.620076, -276741.919278, 5319546.098732], sq => "NN4581"}; 
push @test_data, { grid => [229282,676823], gps => [55.954001, -4.735895, 54.597], xyz => [3566898.284692, -295502.227418, 5261621.804203], sq => "NS2976"}; 
push @test_data, { grid => [272130,244454], gps => [52.083637, -3.867554, 53.861], xyz => [3918711.351871, -264921.586214, 5008569.90597], sq => "SN7244"}; 
push @test_data, { grid => [271900,369407], gps => [53.206266, -3.919454, 54.758], xyz => [3819401.025246,  -261683.53264, 5084368.958787], sq => "SH7169"}; 

my $eps = 0.00000126; # about 10 cm

for my $t (@test_data) {
    my ($sq, $e, $n) = format_grid_GPS(@{$t->{grid}});
    ok($t->{sq} eq sprintf "%s%02d%02d", $sq, int($e/1000), int($n/1000));

    my ($x,$y,$z) = OSGB36_to_ETRS89(@{$t->{grid}}, 0);
    my ($lat, $lon) = grid_to_ll($x,$y,'ETRS89');
   
    my $dphi = abs($lat - $t->{gps}[0]);
    my $dlam = abs($lon - $t->{gps}[1]);

    ok($dphi < $eps && $dlam < $eps, "$lat ($dphi) $lon ($dlam)");

    ok($z == $t->{gps}[2]);

    }



