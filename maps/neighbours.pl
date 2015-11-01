use strict;
use warnings;

use Geo::Coordinates::OSGB qw{parse_grid format_grid_map};
use Geo::Coordinates::British_Maps qw{%maps};
use POSIX qw/floor ceil/;

sub bounding_circle {
    my $box = shift;
    my $scale = shift;
    my $center = [ ($box->[0][0]+$box->[1][0])/2,
                   ($box->[0][1]+$box->[1][1])/2 ];
    my $radius = int($scale * 0.5 * sqrt( ($box->[1][0] - $box->[0][0])**2
                                         +($box->[1][1] - $box->[0][1])**2 ) + 0.5);

    my @circle = ();
    for my $t (0..36) {
        push @circle, [ int($center->[0] + $radius * cos( 3.14159265359 * $t/18 ) + 0.5), 
                        int($center->[1] + 0.9*$radius * sin( 3.14159265359 * $t/18 ) + 0.5)] 
    }
    return \@circle;
}

sub plot_neighbours {
    my $mp = shift;
    my $n  = shift;
    my $key = shift;
    my $mark = shift;
    my $map = $maps{$key};
    my ($series, $label) = split ':', $key;
    print $mp "beginfig($n);\npath cc, pp, ss, N[];\n";

    my $scale = 0.004725; # so that 120 km fits across A4 page

    my $circle = bounding_circle($map->{bbox}, 1.2);

    print $mp sprintf "cc = %s;\n", join '..', map { sprintf "(%g,%g)", $_->[0]*$scale, $_->[1]*$scale } @$circle;
    print $mp sprintf "pp = %s;\n", join '--', map { sprintf "(%g,%g)", $_->[0]*$scale, $_->[1]*$scale } @{$map->{polygon}};
    print $mp "fill pp..cycle withcolor ( 0.98, 0.906, 0.71 );\n"; 

    my $llx =  700000;
    my $lly = 1250000;
    my $urx = 0;
    my $ury = 0;

    my %sheet_names = ();
    for my $pair (@$circle) {
        next if $pair->[0] < 0 || $pair->[1] < 0;
        $llx = $pair->[0] if $pair->[0] < $llx;
        $lly = $pair->[1] if $pair->[1] < $lly;
        $urx = $pair->[0] if $pair->[0] > $urx;
        $ury = $pair->[1] if $pair->[1] > $ury;
        my ($sq, $e, $n, @sheets) = format_grid_map(@$pair);
        for my $s (@sheets) {
            my ($ss, $junk) = split ':', $s;
            next unless $ss eq $series;
            next if $s eq $key;
            $sheet_names{$s}++
        }
    }

    # find any other sheets wholly inside this bbox
    while ( my ($k,$v) = each %maps ) {
        my ($ss, $junk) = split ':', $k;
        next unless $ss eq $series;
        next if $k eq $key;
        $sheet_names{$k}++ if $llx <= $v->{bbox}[0][0] && $v->{bbox}[1][0] <= $urx
                           && $lly <= $v->{bbox}[0][1] && $v->{bbox}[1][1] <= $ury;
    }

    my $i=0;
    my @sheets_drawing = ();
    for my $s (sort keys %sheet_names) {
        my @poly = (); 
        for my $pair (@{$maps{$s}->{polygon}}) {
            push @poly, sprintf '(%g,%g)', map { $_ * $scale } @$pair;
            $llx = $pair->[0] if $pair->[0] < $llx;
            $lly = $pair->[1] if $pair->[1] < $lly;
            $urx = $pair->[0] if $pair->[0] > $urx;
            $ury = $pair->[1] if $pair->[1] > $ury;
        }
        push @sheets_drawing, sprintf "N%d = %s;\n", $i, join '--', @poly;
        if ( $s !~ m{Inset} ) {
            my $adjust = $s =~ m{\A B:OL}xios ? +5 : -3;
            push @sheets_drawing, sprintf "label(\"$s\", center N%d shifted %g up) withcolor .5[blue,white];\n", $i, $adjust;
        }
        push @sheets_drawing, sprintf "draw N%d withpen pencircle scaled 1 withcolor .5[blue,white];\n", $i++;
    }

    $llx = floor($llx/1000); $lly = floor($lly/1000);
    $urx = ceil($urx/1000); $ury = ceil($ury/1000);

    # add grid in the background
    for my $x ( ceil($llx/10) .. floor($urx/10) ) {
        printf $mp "draw ((%g,%g) -- (%g,%g)) shifted (%g,0) withcolor .8white;\n", map {$_*1000*$scale} $llx,$lly,$llx,$ury,10*$x-$llx;
    }
    for my $y ( ceil($lly/10) .. floor($ury/10) ) {
        printf $mp "draw ((%g,%g) -- (%g,%g)) shifted (0,%g) withcolor .8white;\n", map {$_*1000*$scale} $llx,$lly,$urx,$lly,10*$y-$lly;
    }

    print $mp @sheets_drawing;

    print $mp "draw pp withpen pencircle scaled .4;\n";
    print $mp "label.top(\"$key\", center pp);\n";
    print $mp "label.bot(\"$map->{area}\" infont \"phvr8r\" scaled 0.6, center pp) withcolor .67 red;\n";
    print $mp sprintf "label.urt(\"%d %d\" infont defaultfont scaled 0.6, (%g,%g));\n",
                       $map->{polygon}[0][0]/1000,
                       $map->{polygon}[0][1]/1000,
                       $map->{polygon}[0][0]*$scale,
                       $map->{polygon}[0][1]*$scale;
    print $mp "drawoptions(withpen pencircle scaled 0.2 withcolor (0, 172/255, 226/255));\n";
    print $mp "input gb-coast-large.mp;\n";
    print $mp "drawoptions();\n";
    print $mp sprintf "ss = unitsquare xscaled %g yscaled %g shifted (%g,%g);\n", map {$_*1000*$scale} ($urx-$llx, $ury-$lly, $llx, $lly);
    print $mp "clip currentpicture to ss;\n";
    #
    # add grid scale
    for (my $x=10*ceil($llx/10); $x<=10*floor($urx/10); $x += 10) {
        printf $mp "label(\"%02d\" infont \"phvr8r\" scaled 0.8, (%g,%g) shifted 5 up);\n",   $x % 100, $x*1000*$scale, $ury*1000*$scale;
        printf $mp "label(\"%02d\" infont \"phvr8r\" scaled 0.8, (%g,%g) shifted 5 down);\n", $x % 100, $x*1000*$scale, $lly*1000*$scale;
    }
    for (my $y=10*ceil($lly/10); $y<=10*floor($ury/10); $y+=10) {
        printf $mp "label(\"%02d\" infont \"phvr8r\" scaled 0.8, (%g,%g) shifted 7 left);\n",  $y % 100, $llx*1000*$scale, $y*1000*$scale;
        printf $mp "label(\"%02d\" infont \"phvr8r\" scaled 0.8, (%g,%g) shifted 7 right);\n", $y % 100, $urx*1000*$scale, $y*1000*$scale;
    }
    #print $mp "draw cc withcolor .67 red;\n";
    
    if (defined $mark) {
        my ($x,$y) = map { $_*$scale } parse_grid($mark);
        print $mp "fill fullcircle scaled 3 shifted ($x,$y) withcolor .67 green;\n";
    }
    print $mp "draw ss; endfig;\n"

}

my $mp_filename = "nearby.mp";
open my $mp, ">", $mp_filename;
print $mp <<'HEADER';
prologues:=3;outputtemplate:="%j%c.eps";
defaultfont := "phvr8r";
HEADER

my $i = 0;
for my $arg (@ARGV) {
    my ($sheet, $mark) = split '/', $arg, 2;
    if (! defined $maps{$sheet}) {
        warn "No sheet $sheet\n";
        next;
    }
    $i++;
    plot_neighbours($mp, $i, $sheet, $mark); 
}
print $mp <<'FOOTER';
end
FOOTER
close $mp;
system('mpost', '-numbersystem=double', $mp_filename);

