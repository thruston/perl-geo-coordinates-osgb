use Geo::Coordinates::OSGB qw(grid_to_ll);
use Geo::Coordinates::OSGB::Grid qw(random_grid);
use Browser::Open qw(open_browser);

sub format_grid_streetmap {
    my $e = shift;
    my $n = shift;
    return sprintf 'http://www.streetmap.co.uk/map.srf?x=%06d&y=%06d&z=3', $e, $n;
}

sub format_ll_googlemaps {
    my ($lat, $lon) = @_;
    return sprintf 'http://www.google.com/maps/place/@%f,%f,14z/data=!4m2!3m1!1s0x0:0x0', $lat, $lon;
}

my ($e, $n) = @ARGV ? @ARGV : random_grid();

my ($lat, $lon) = grid_to_ll($e, $n);

open_browser(format_grid_streetmap($e, $n));
open_browser(format_ll_googlemaps($lat,$lon));

# This script picks a random spot in the British Isles and shows you it on Streetmap.co.uk and 
# on Google maps;  this lets you compare the OS and the Google maps side by side for the same
# area - sometimes you'll end up in the sea, but you'll always be on one of the Landranger sheets
# It's surprisingly additictive...
# Toby Thurston -- 24 Jun 2015 
#
# PS the Google maps parameters are the result of experimentation rather than any API documentation
# so I've no idea what the data parameter does, but it seems to be necessary.  The "14z" controls the 
# level of zoom, and makes it roughly 1:50,000 corresponding to the Streetmap display with "&z=3".
