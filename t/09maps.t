# Toby Thurston -- 24 Sep 2015 
# test map finding

use Geo::Coordinates::OSGB qw/parse_grid format_grid_trad format_grid_map format_ll_ISO parse_map_grid grid_to_ll/;

use Test::Simple tests => 15;

my ($pt, $s, $t);

$pt = format_grid_trad(parse_map_grid('C:158',653,950));
ok("$pt" eq 'SU 653 950', "Point $pt");

$pt = format_grid_trad(parse_map_grid('B:OL1E','299009'));
ok("$pt" eq 'SE 299 009', "Point $pt");

@pt = parse_map_grid('A:47',54940,59910);
$s = format_ll_ISO(grid_to_ll(@pt));
ok($s eq '+5640-00600/', $s);

$s = join ' ', format_grid_map(parse_grid("TQ 102 606"));
$t = 'TQ 102 606 A:176 A:187 B:161 C:170';
ok($s eq $t, "$s  ??  $t");

$s = format_grid_map(parse_grid("SP 516 066"));
ok($s eq 'SP 516 066 on A:164, B:180E, C:158', $s);


$s = format_grid_map(parse_grid("NN 241 738"));
ok($s eq "NN 241 738 on A:41, B:392, C:47", $s);

$s = format_grid_map(parse_grid("SU 029 269"));
ok($s eq 'SU 029 269 on A:184, B:118N, B:130S, C:167', $s);

# Tetbury Museum
$s = format_grid_map(parse_grid("ST 889 933"));
ok($s eq 'ST 889 933 on A:162, A:163, A:173, B:168, C:156, C:157', $s);

# points on upper right edges are *not* on map
$s = format_grid_map(406000, 130000);
ok($s eq 'SU 060 300 on A:184, B:130S, C:167', $s);
#
# but points on lower left  edges are included (this is the convention)
$s = format_grid_map(383000, 110000);
ok($s eq 'ST 830 100 on A:194, B:118N, C:178', $s);


# now test some extensions
# Junction 37 on the M1 (for old times' sake) shown on OL1E in an extension
$s = format_grid_map(432100, 405900);
ok($s eq 'SE 321 059 on A:110, A:111, B:278N, B:OL1E, C:102', $s);
# 3km S of the above (which is not on the extension area around J37)
$s = format_grid_map(432100, 403900);
ok($s eq 'SE 321 039 on A:110, A:111, B:278N, C:102', $s);

use Geo::Coordinates::British_Maps qw/%name_for_map_series/;
ok($name_for_map_series{'A'} eq 'OS Landranger', "Series A == OS Landranger");
ok($name_for_map_series{'B'} eq 'OS Explorer',   "Series B == OS Explorer");
ok($name_for_map_series{'C'} eq 'OS One-Inch 7th series',   "Series C == OS One-Inch");
