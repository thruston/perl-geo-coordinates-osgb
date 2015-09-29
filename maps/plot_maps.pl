use strict;
use warnings;
use Geo::Coordinates::British_Maps qw(@maps);

sub plot_poly {
    my ($p, $s) = @_;
    my $color  = $s =~ m{\AOL}osxi ? 'red' : 'blue';
    my $adjust = $s =~ m{\AOL}osxi ? '+2' : '-2'; 
    my $path = join '--', map { sprintf "(%.1f,%.1f)", $_->[0]/1000, $_->[1]/1000 } @{$p}; 
    my $out = $s =~ m{Inset}xios ?
        sprintf "p:=%s; draw p;", $path : 
        sprintf "p:=%s; label(\"%s\" infont \"phvr8r\" scaled 0.5, center p shifted (0,%s)) withcolor .6[%s,white]; draw p;  ", 
                    $path, $s, $adjust, $color;
    return $out;
}

my $series_wanted = (@ARGV > 0) ? $ARGV[0] : 'A';


open(my $plotter, '>', 'plot.mp');
print $plotter 'prologues := 3; outputtemplate := "%j%c.eps"; beginfig(1); defaultfont := "phvr8r"; drawoptions(withpen pencircle scaled 0.2);path p;', "\n";

print $plotter 'for i=0 upto 12: draw (0,100i) -- (700,100i) withcolor .7 white; label.rt(decimal 100i, (700,100i)); label.lft(decimal 100i, (0,100i)); endfor' ,"\n";
print $plotter 'for i=0 upto  7: draw (100i,0) -- (100i,1200) withcolor .7 white; endfor' ,"\n";

for my $m (@maps) {
    my $p = index($series_wanted, $m->{series});
    next if $p < 0;
    print $plotter plot_poly($m->{polygon}, $m->{label}), "\n"; 
}

print $plotter "endfig;end.\n";
close $plotter;
system('mpost', 'plot.mp');
