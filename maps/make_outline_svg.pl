use strict;
use warnings;
use Geo::Coordinates::British_Maps qw(%maps);

sub plot_poly {
    my ($path, $s) = @_;
    my $out = "p:=$path; draw p withcolor orange;";
    my $color  = $s =~ m{\AOL}osxi ? 'red' : 'blue';
    my $adjust = $s =~ m{\AOL}osxi ? '+2' : '-2'; 
    if ($s !~ m{Inset}xios ) {
        $out .= "label(\"$s\" infont \"phvb8r\" scaled 0.5, center p shifted (0,$adjust)) withcolor .6[$color,white];"; 
    }
    $out .= "\n";
    return $out;
}

my $series_wanted = (@ARGV > 0) ? $ARGV[0] : 'A';

my $mp_file = 'outlines.mp';

open(my $plotter, '>', $mp_file);
print $plotter "prologues := 3; outputtemplate := \"outlines$series_wanted.svg\"; outputformat:=\"svg\";\n";  
print $plotter 'beginfig(1); path p; color orange; orange = ( 221/255, 61/255, 31/255 );', "\n";

my @draws;
while (my ($k, $m) = each %maps) {
    my ($series, $label) = split ':', $k;
    my $p = index($series_wanted, $series);
    next if $p < 0;
    my $path = join '--', map { sprintf "(%.2f,%.2f)", $_->[0]/1000, $_->[1]/1000 } @{$m->{polygon}}; 
    push @draws, plot_poly($path, $label); 
}

print $plotter "drawoptions(withpen pencircle scaled 0.2 withcolor .7 white);\n";
print $plotter 'for i=1 upto 12: draw (0,100i) --  (700,100i); endfor',"\n";
print $plotter 'for i=1 upto  6: draw (100i,0) -- (100i,1300); endfor',"\n";

print $plotter "drawoptions(withpen pencircle scaled 0.2);\n";
print $plotter @draws;

print $plotter "endfig;end.\n";
close $plotter;
system('mpost', $mp_file);
