# Toby Thurston --- 16 Apr 2009
use strict;
use warnings;

# This test data is taken directly from the OS etst files OSTN02
#

my %test_input = (
    BLAC                 => {lat => 53.77911025694444,  lon => -3.040454906944444,  e =>  331534.552,  n =>  431920.792 },
    BRIS                 => {lat => 51.42754743361111,  lon => -2.544076186111111,  e =>  362269.979,  n =>  169978.688 },
    BUT1                 => {lat => 58.51560361805556,  lon => -6.260914556388889,  e =>  151968.641,  n =>  966483.777 },
    CARL                 => {lat => 54.89542340527777,  lon => -2.938277414722223,  e =>  339921.133,  n =>  556034.759 },
    CARM                 => {lat => 51.8589089675,  lon => -4.308524766111111,  e =>  241124.573,  n =>  220332.638 },
    COLC                 => {lat => 51.89436637527778,  lon => 0.897243275,  e =>  599445.578,  n =>  225722.824 },
    DARE                 => {lat => 53.34480280666667,  lon => -2.640493207222222,  e =>  357455.831,  n =>  383290.434 },
    DROI                 => {lat => 52.25529381638889,  lon => -2.154586149444444,  e =>  389544.178,  n =>  261912.151 },
    EDIN                 => {lat => 55.9247826525,  lon => -3.294792187777777,  e =>  319188.423,  n =>  670947.532 },
    FLA1                 => {lat => 54.11685144333333,  lon => -0.07773132666666667,  e =>  525745.658,  n =>  470703.211 },
    GIR1                 => {lat => 57.13902519305555,  lon => -2.048560316111111,  e =>  397160.479,  n =>  805349.734 },
    GLAS                 => {lat => 55.85399952972222,  lon => -4.296490155555555,  e =>  256340.914,  n =>  664697.266 },
    INVE                 => {lat => 57.48625000333333,  lon => -4.219263989444444,  e =>  267056.756,  n =>  846176.969 },
    IOMN                 => {lat => 54.32919541055556,  lon => -4.388491180000001,  e =>  244780.625,  n =>  495254.884 },
    IOMS                 => {lat => 54.08666318083333,  lon => -4.634521684999999,  e =>  227778.318,  n =>  468847.386 },
    KING                 => {lat => 52.75136687444444,  lon => 0.4015354769444445,  e =>  562180.535,  n =>  319784.993 },
    LEED                 => {lat => 53.80021519916667,  lon => -1.663791675833333,  e =>  422242.174,  n =>  433818.699 },
    LIZ1                 => {lat => 49.96006138305556,  lon => -5.203046100277778,  e =>  170370.706,  n =>   11572.404 },
    LOND                 => {lat => 51.48936564611111,  lon => -0.1199255641666667,  e =>  530624.963,  n =>  178388.461 },
    LYN1                 => {lat => 53.41628515777778,  lon => -4.289180693055555,  e =>  247958.959,  n =>  393492.906 },
    LYN2                 => {lat => 53.41630925166667,  lon => -4.289177926388889,  e =>  247959.229,  n =>  393495.580 },
    MALA                 => {lat => 57.00606696527777,  lon => -5.828366926388889,  e =>  167634.190,  n =>  797067.142 },
    NAS1                 => {lat => 51.40078220388889,  lon => -3.551283487222222,  e =>  292184.858,  n =>  168003.462 },
    NEWC                 => {lat => 54.97912274,  lon => -1.616576845555556,  e =>  424639.343,  n =>  565012.700 },
    NFO1                 => {lat => 51.37447025916666,  lon => 1.444547306944445,  e =>  639821.823,  n =>  169565.856 },
    NORT                 => {lat => 52.25160950916667,  lon => -0.91248957,  e =>  474335.957,  n =>  262047.752 },
    NOTT                 => {lat => 52.962191095,  lon => -1.197476561666667,  e =>  454002.822,  n =>  340834.941 },
    OSHQ                 => {lat => 50.9312793775,  lon => -1.450514340555556,  e =>  438710.908,  n =>  114792.248 },
    PLYM                 => {lat => 50.43885825472222,  lon => -4.108645639722222,  e =>  250359.798,  n =>   62016.567 },
    SCP1                 => {lat => 50.57563665166667,  lon => -1.297822771388889,  e =>  449816.359,  n =>   75335.859 },
    SUM1                 => {lat => 59.8540991425,  lon => -1.274869112222222,  e =>  440725.061,  n => 1107878.445 },
    THUR                 => {lat => 58.58120461444445,  lon => -3.726310213055556,  e =>  299721.879,  n =>  967202.990 },
    SCILLY               => {lat => 49.92226394333333,  lon => -6.299777527222222,  e =>   91492.135,  n =>   11318.801 },
    STKILDA              => {lat => 57.81351842166666,  lon => -8.578544610277778,  e =>    9587.897,  n =>  899448.993 },
    FLANNAN              => {lat => 58.21262248138889,  lon => -7.592555631111111,  e =>   71713.120,  n =>  938516.401 },
    NORTHRONA            => {lat => 59.09671617777778,  lon => -5.827993408888888,  e =>  180862.449,  n => 1029604.111 },
    SULESKERRY           => {lat => 59.09335035083333,  lon => -4.417576741666667,  e =>  261596.767,  n => 1025447.599 },
    FOULA                => {lat => 60.13308092083334,  lon => -2.073828223611111,  e =>  395999.656,  n => 1138728.948 },
    FAIRISLE             => {lat => 59.53470794333333,  lon => -1.625169658333333,  e =>  421300.513,  n => 1072147.236 },
    ORKNEY               => {lat => 59.03743871,  lon => -3.214540010555556,  e =>  330398.311,  n => 1017347.013 },
    ORK_MAIN_ORK         => {lat => 58.71893718305556,  lon => -3.073926035277778,  e =>  337898.195,  n =>  981746.359 },
    ORK_MAIN_MAIN        => {lat => 58.72108286444445,  lon => -3.137882873055556,  e =>  334198.101,  n =>  982046.419 },
);

use Geo::Coordinates::OSGB   qw/grid_to_ll ll_to_grid/;

sub dms {
    my $dd = shift;
    my $add = abs($dd);
    my $sign = $dd/$add;
    my $d = int($add);
    my $mm = 60*($add-$d);
    my $m = int($mm);
    my $s = sprintf "%.4f", 60*($mm-$m);
    return ($d, $m, $s);
}

use Test::More; 
plan tests => 27 + 3 * keys %test_input;

# Example from the OS guide
my $lat_given = 52 + 39/60 + 27.2531/3600;
my $lon_given =  1 + 43/60 +  4.5177/3600;
my ($lat, $lon) = grid_to_ll(651409.903, 313177.270, { shape => 'OSGB36' });
my $gotten = sprintf "%.7f %.7f", $lat, $lon;
my $given  = sprintf "%.7f %.7f", $lat_given, $lon_given;
is($gotten, $given, "Fixed pos from OS example");

my $maxlate = my $maxlone = 0;
my $minlate = my $minlone = 1e6;

for my $k ( sort keys %test_input ) {
    my ($lat,$lon, $e, $n) = @{$test_input{$k}}{qw/lat lon e n/};
    
    my $given_grid = sprintf "%.3f %.3f", $e, $n;
    my $got_grid   = sprintf "%.3f %.3f", ll_to_grid($lat, $lon);

    my ($got_lat, $got_lon) = grid_to_ll($e,$n);
    my $lat_error = 11e7*abs($lat-$got_lat);
    my $lon_error =  7e7*abs($lon-$got_lon);
    $maxlate = $lat_error if $lat_error > $maxlate;
    $minlate = $lat_error if $lat_error < $minlate;
    $maxlone = $lon_error if $lon_error > $maxlone;
    $minlone = $lon_error if $lon_error < $minlone;

    is($got_grid, $given_grid, "ll_to_grid for Station $k" );
    ok($lat_error < ($lat < 55 ? 10 : 113), sprintf "Lat for %s %.9g %.3g mm", $k, $lat, $lat_error); # about 113 mm
    ok($lon_error < 10,  sprintf "Lon for %s %.9g %.3g mm", $k, $lon, $lon_error); # about  10 mm
}
#print "$minlate $maxlate -- $minlone $maxlone\n";


use Geo::Coordinates::OSGB::Grid qw/format_grid/;
# some test data obtained by feeding random GRs to the online batch converter provided by the OS.
my @test_data = ();

push @test_data, { grid => [452788,520697], gps => [54.578747, -1.184859, 48.329], xyz => [3704143.232593,  -76611.478515, 5174384.798039], sq => "NZ5220"}; 
push @test_data, { grid => [481267,257208], gps => [52.207128, -0.812142, 47.431], xyz => [3916409.21937,   -55517.041028, 5016997.080619], sq => "SP8157"}; 
push @test_data, { grid => [421176,317227], gps => [52.752264, -1.687695, 49.691], xyz => [3867013.25437,  -113939.043255, 5053944.064276], sq => "SK2117"}; 
push @test_data, { grid => [ 88725,901972], gps => [57.898121, -7.255926, 57.185], xyz => [3370501.932141, -429137.262071, 5379764.59814], sq => "NA8801"}; 
push @test_data, { grid => [ 75537,860152], gps => [57.514799, -7.421059, 57.352], xyz => [3405037.296092, -443509.816804, 5356956.390959], sq => "NF7560"}; 
push @test_data, { grid => [379729,556107], gps => [54.899281, -2.317626, 51.532], xyz => [3672795.235173, -148646.379371, 5194986.532721], sq => "NY7956"}; 
push @test_data, { grid => [450194,324208], gps => [52.813107, -1.256732, 48.719], xyz => [3862369.694384,  -84731.245309, 5058038.525777], sq => "SK5024"}; 
push @test_data, { grid => [150568,710527], gps => [56.221674, -6.025127, 55.203], xyz => [3534749.594129, -373084.536562, 5278250.538957], sq => "NM5010"}; 
push @test_data, { grid => [255012,226125], gps => [51.914736, -4.109446, 53.672], xyz => [3932328.987003, -282524.503244, 4996999.207321], sq => "SN5526"}; 
push @test_data, { grid => [245034,781030], gps => [56.894632, -4.545662, 54.500], xyz => [3480870.620076, -276741.919278, 5319546.098732], sq => "NN4581"}; 
push @test_data, { grid => [229282,676823], gps => [55.954001, -4.735895, 54.597], xyz => [3566898.284692, -295502.227418, 5261621.804203], sq => "NS2976"}; 
push @test_data, { grid => [272130,244454], gps => [52.083637, -3.867554, 53.861], xyz => [3918711.351871, -264921.586214, 5008569.90597], sq => "SN7244"}; 
push @test_data, { grid => [271900,369407], gps => [53.206266, -3.919454, 54.758], xyz => [3819401.025246,  -261683.53264, 5084368.958787], sq => "SH7169"}; 

my $eps = 0.0000025; # about 20 cm
my $maxep = 0;
my $maxel = 0;

for my $t (@test_data) {
    is(format_grid(@{$t->{grid}}, { form=>'SSEENN' }), $t->{sq}, "Random square");

    my ($lat, $lon) = map { sprintf "%.6f", $_ } grid_to_ll(@{$t->{grid}});
   
    my $dphi = abs($lat - $t->{gps}[0]);
    my $dlam = abs($lon - $t->{gps}[1]);

    $maxep = $dphi if $dphi > $maxep;
    $maxel = $dlam if $dlam > $maxel;

    ok($dphi < $eps && $dlam < $eps, sprintf "%s %s (%g %g)", $lat, $lon, $dphi, $dlam);

}

