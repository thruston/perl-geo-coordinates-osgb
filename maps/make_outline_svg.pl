use strict;
use warnings;
use Geo::Coordinates::British_Maps qw(%maps);

sub overlap_or_touch {
    my ($a,$b) = @_;
    return !($b->[0][0] > $a->[1][0]
          || $b->[1][0] < $a->[0][0]
          || $b->[1][1] < $a->[0][1]
          || $b->[0][1] > $a->[1][1]);
}
my $series_wanted = (@ARGV > 0) ? $ARGV[0] : 'A';

my $mp_file = 'outlines.mp';

open(my $plotter, '>', $mp_file);
print $plotter "prologues := 3; outputtemplate := \"outlines$series_wanted.svg\"; outputformat:=\"svg\";\n";  
print $plotter "beginfig(1); path p[]; color orange, pink, red;\n"; 
print $plotter "orange = ( 221/255, 61/255, 31/255 ); pink = (224/255,36/255,114/255); red = (228/255, 0, 28/255);\n";

my @draws;
my @inset_connectors;
my $i = 0;
my %path_number_for = ();
for my $k (sort keys %maps) {
    my ($series, $label) = split ':', $k;
    my $p = index($series_wanted, $series);
    next if $p < 0;
    $path_number_for{$k} = $i++;
    my $m = $maps{$k};
    my $path = join '--', map { sprintf "(%.2f,%.2f)", $_->[0]/1000, $_->[1]/1000 } @{$m->{polygon}}; 
    my $color = $series eq 'A' ? 'pink' : $series eq 'B' ? 'orange' : $series eq 'C' ? 'red' : 'black';
    my $out = sprintf 'p%d:=%s; draw p%d withcolor %s;', $path_number_for{$k}, $path, $path_number_for{$k}, $color; 
    # adjustments for OL maps
    my $textcolor = $label =~ m{\AOL}osxi ? 'blue' : $color;
    my $adjust    = $label =~ m{\AOL}osxi ? '+2' : '-2'; 
    if ( $k eq $m->{parent} ) {
        $out .= "label(\"$label\" infont \"phvb8r\" scaled 0.5, center p$path_number_for{$k} shifted (0,$adjust)) withcolor .5[$textcolor,white];"; 
    }
    elsif ( overlap_or_touch($m->{bbox}, $maps{$m->{parent}}->{bbox} )) {
        #warn "No connector for $k\n";
    }
    else {
        push @inset_connectors, sprintf "draw center p%d -- center p%d cutbefore p%d cutafter p%d dashed withdots scaled 0.2  withcolor %s;\n",
                                $path_number_for{$k}, $path_number_for{$m->{parent}},
                                $path_number_for{$k}, $path_number_for{$m->{parent}},
                                $color;
    }
    push @draws, "$out\n";
}

print $plotter "drawoptions(withpen pencircle scaled 0.2 withcolor .7 white);\n";
print $plotter 'for i=1 upto 12: draw (0,100i) --  (700,100i); endfor',"\n";
print $plotter 'for i=1 upto  6: draw (100i,0) -- (100i,1300); endfor',"\n";

print $plotter "drawoptions(withpen pencircle scaled 0.2);\n";
print $plotter @draws;
print $plotter @inset_connectors;

print $plotter "endfig;end.\n";
close $plotter;
system('mpost', $mp_file);
