# Toby Thurston --- 22 Sep 2008

# out of range conditions

use strict;
use Geo::Coordinates::OSGB   qw/grid_to_ll ll_to_grid/;

use Test::More tests => 3; 

is(ll_to_grid(49,-2, {shape => 'OSGB36'} ), '400000.000 -100000.000', "True origin of OSGB36");
is(ll_to_grid(55.2597198486328,-6.1883339881897), '133985 604172', "Outside OSTN02");
is(ll_to_grid(66,40), '2184572 2427658', "In the White Sea, NW Russia");


