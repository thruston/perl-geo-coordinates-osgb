use strict;
use warnings;

use Geo::Coordinates::OSGB       qw(ll_to_grid);
use Geo::Coordinates::OSGB::Grid qw(format_grid);
use Geo::Coordinates::OSGB::Maps qw(%maps);

sub plot_poly {
    my ($path, $s) = @_;
    my $color  = $s =~ m{\AOL}osxi ? 'red' : 'blue';
    my $adjust = $s =~ m{\AOL}osxi ? '+2' : '-2';
    $s =~ s/–/"&char149&"/;
    $s =~ s/’/'/;
    return sprintf "p:=%s; draw p; label((\"%s\") infont \"phvb8r\" scaled 0.5, center p shifted (0,%s)) withcolor .4[%s,white];\n", 
                    $path, $s, $adjust, $color;
}

my $series_wanted = (@ARGV > 0) ? $ARGV[0] : 'A';


open(my $plotter, '>', 'plot.mp');
print $plotter 'prologues := 3; outputtemplate := "%j%c.eps"; beginfig(1); defaultfont := "phvr8r"; path p;', "\n";

my @fills;
my @draws;
while (my ($k, $m) = each %maps) {
    my ($series, $label) = split ':', $k;
    # patch
    #$label = $m->{number};

    my $p = index($series_wanted, $series);
    next if $p < 0;
    my $path = join '--', map { sprintf "(%.1f,%.1f)", $_->[0]/1000, $_->[1]/1000 } @{$m->{polygon}}; 
    push @fills, sprintf "fill %s..cycle withcolor ( 0.98, 0.906, 0.71 );\n", $path;
    push @draws, plot_poly($path, $label); 
}

print $plotter @fills;

print $plotter "drawoptions(withpen pencircle scaled 0.4);\n";
for my $lon (-11..2) {
    my @points = ();
    for my $lat (496..612) {
        push @points, sprintf '(%.1f,%.1f)', map { $_/1000 } ll_to_grid($lat/10,$lon);
    }
    print $plotter 'draw ', join('--', @points), ' withcolor .7[.5 green,white];';
    print $plotter sprintf 'label.bot("%s" & char 176, %s) withcolor .4 green;', $lon, $points[0];
}
for my $lat (50..61) {
    my @points = ();
    for my $lon (-112..22) {
        push @points, sprintf '(%.1f,%.1f)', map { $_/1000 } ll_to_grid($lat,$lon/10);
    }
    print $plotter 'draw ', join('..', @points), ' withcolor .7[.5 green,white];';
    print $plotter sprintf 'label.lft("%s" & char 176, %s) withcolor .4 green;', $lat, $points[0];
}
   


print $plotter 'for i=0 upto 12: draw (0,100i) --  (700,100i) withcolor .7 white; endfor',"\n";
print $plotter 'for i=0 upto  7: draw (100i,0) -- (100i,1200) withcolor .7 white; endfor',"\n";
print $plotter 'for i=1 upto 12: label.lft(decimal 100i, (0,100i)); endfor',"\n";
print $plotter 'for i=1 upto  7: label.bot(decimal 100i, (100i,0)); endfor',"\n";
print $plotter 'label.llft("0",origin);',"\n";

for my $x (0..6) {
    for my $y (0..11) {
        my $sq = format_grid($x*100000,$y*100000, { form => 'SS' });
        print $plotter sprintf 'label("%s" infont "phvr8r" scaled 3, (%d,%d)) withcolor .8 white;', 
                                      $sq, 50+$x*100, 50+$y*100;
    }
}

print $plotter "drawoptions(withpen pencircle scaled 0.2 withcolor (0, 172/255, 226/255));\n";
print $plotter "input british-isles.mp;\n";

print $plotter "drawoptions(withpen pencircle scaled 0.2);\n";
print $plotter @draws;

print $plotter "endfig;end.\n";
close $plotter;
system('mpost', 'plot.mp');
