use strict;
use warnings;
use Geo::Coordinates::OSGB qw/_llh_to_cartesian _cartesian_to_llh 
                             shift_ll_from_WGS84 _shift_ll_from_wgs84_to_osgb36
                             shift_ll_into_WGS84 _shift_ll_from_osgb36_to_wgs84
                             /;


my $lat = 52 + 39/60 + 27.2531/3600;
my $lon =  1 + 43/60 +  4.5177/3600;
my $elh = 24.7;

warn "$lat $lon\n";
my ($x,$y,$z) = _llh_to_cartesian($lat, $lon, $elh, { shape => 'OSGB36' });
warn "$x $y $z\n";


my ($rlat, $rlon, $rh) = _cartesian_to_llh($x,$y,$z, {shape => 'OSGB36' });
warn "$lat $lon $elh\n";
warn "$rlat $rlon $rh\n";


my ($latN, $lonN) = _shift_ll_from_wgs84_to_osgb36($lat, $lon);
warn "New: $latN $lonN\n";
my ($latNN, $lonNN) = _shift_ll_from_osgb36_to_wgs84($latN, $lonN);
warn "New: $latNN $lonNN\n";
warn "Arg: $lat $lon\n";


warn "Arg: $lat $lon\n";
my ($latO, $lonO) = shift_ll_from_WGS84($lat, $lon);
warn "Old: $latO $lonO\n";
my ($latOO, $lonOO) = shift_ll_into_WGS84($latO, $lonO);
warn "Old: $latOO $lonOO\n";
warn "Arg: $lat $lon\n";

