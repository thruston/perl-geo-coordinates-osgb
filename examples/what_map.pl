use strict;
use warnings;

use Geo::Coordinates::OSGB qw{parse_grid format_grid_map};

my $bng = $ARGV[0];

my ($e, $n) = parse_grid($bng);
printf "%s -> %s\n", $bng, scalar format_grid_map($e,$n);
