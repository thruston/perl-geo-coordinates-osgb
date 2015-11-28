use strict;
use warnings;
use Carp;
use Geo::Coordinates::DecimalDegrees;
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

open my $tt, '<', 'OSTN02/OSTN02_OSGM02Tests_Out.txt' or die "Failed to open test data file\n";

my $maxerr = 0;
while (<$tt>) {
    my ($station, $x, $y, $z, @rest) = split ',';
    next if $station eq 'StationName';
    my ($lat, $lon, $H) = _cartesian_to_llh($x,$y,$z), 
    
    my $os_lat = ($rest[0] eq 'N' ? +1 : -1) * $rest[1]+$rest[2]/60+$rest[3]/3600;
    my $error = abs($os_lat-$lat);
    if ($error > $maxerr) {
        $maxerr = $error
    }

    #printf "%-16s %.12f %.12f %20.12f\n", $station, $lat, $os_lat, $error*1E9;

    my ($dd,$mm,$ss, $sign) = decimal2dms($lat);
    croak "Errk\n" unless $dd == $rest[1];
    croak "Oops\n" unless $mm == $rest[2];

}
printf "%f --> %g mm\n", $maxerr, $maxerr*110_000_000;

