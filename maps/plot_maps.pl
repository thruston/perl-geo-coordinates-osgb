use strict;
use warnings;
use Geo::Coordinates::British_Maps qw(@maps);

sub plot_poly {
    my ($p, $s) = @_;
    my $color = $s =~ m{\AOL}osxi ? 'red' : 'blue';
    my $path = join '--', map { sprintf "(%.1f,%.1f)", $_->[0]/1000, $_->[1]/1000 } @{$p}; 
    return sprintf "p:=%s; label(\"%s\" infont \"phvr8r\" scaled 0.7, center p) withcolor .8[%s,white]; draw p;  ", 
                    $path, $s, $color;
}

my $series_wanted = (@ARGV > 0) ? $ARGV[0] : 'A';


open(my $plotter, '>', 'plot.mp');
print $plotter ' prologues := 3; outputtemplate := "%j%c.eps"; beginfig(1); path p;', "\n";

for my $m (@maps) {
    my $p = index($series_wanted, $m->{series});
    next if $p < 0;
    print $plotter plot_poly($m->{polygon}, $m->{label}), "\n"; 
}

print $plotter "endfig;end.\n";
close $plotter;
system('mpost', 'plot.mp');
