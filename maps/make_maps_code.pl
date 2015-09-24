# Toby Thurston -- 21 Sep 2015 
# compile the map tables into perl source code
#
use strict;
use warnings;
use Carp;

sub polygon_area_in_km {
    my $p = shift;
    my $a = 0;
    for (my $i=1; $i < scalar @{$p}; $i++) {
        $a = $a + $p->[$i-1][0] * $p->[$i][1]
                - $p->[$i-1][1] * $p->[$i][0];
    }
    return $a/2_000_000;
}

# return the ll and ur corners as a list of points
# note that in the OSGB grid the values of the coordinates for valid grid references are not negative
sub polygon_bbox {
    my $p = shift;
    my $llx = my $lly = 1e12;
    my $urx = my $ury = 0;
    for my $point ( @{$p} ) {
        $llx = $point->[0] if $point->[0] < $llx;
        $urx = $point->[0] if $point->[0] > $urx;
        $lly = $point->[1] if $point->[1] < $lly;
        $ury = $point->[1] if $point->[1] > $ury;
    }
    return [ [$llx, $lly], [$urx, $ury] ] ;
}

sub plot_poly {
    my ($p, $s) = @_;
    my $color = $s =~ m{\AOL}osxi ? 'red' : 'blue';
    my $path = join '--', map { sprintf "(%.1f,%.1f)", $_->[0]/1000, $_->[1]/1000 } @{$p}; 
    return sprintf "p:=%s; label(\"%s\" infont \"phvr8r\" scaled 0.7, center p) withcolor .8[%s,white]; draw p;  ", 
                    $path, $s, $color;
}

my @maps;
my $Minimum_sheet_size = 300; # Anything smaller than 300km^2 is an inset

LINE:
while (<>) {
    my ($nn, $label, $flag, $mpg) = split ' ', $_, 4;
    $mpg =~ s/\s*$//;

    next LINE if $mpg eq 'EMPTY';

    my $series = substr($nn,0,1);

    # split the MULTIPOLYGON string up 1 char at a time using the reverse and chop trick
    my $nest = 0;
    my @polylist;
    my $p=0;
    my $s = reverse $mpg;
    while (length $s) {
        my $c = chop $s;
        if ($nest==1 && $c eq ',') {
           $p++;
           next;
        }
        if    ($c eq '(') { $nest++ }
        elsif ($c eq ')') { $nest-- }
        else {
            $polylist[$p] .= $c;
        }
    }
    # split each POLYGON string into an array of coordinate pairs
    for my $p (@polylist) {
        $p = [ map { [ split ' ' ] } split ',', $p ];
    }

    # split the polygons up into insets and sides 
    # Often there will be only 1 side and 0 insets, so special case that first
    if (1==@polylist) {
        my $b = polygon_bbox($polylist[0]);
        push @maps, { series => $series, label => $label, bbox => $b, polygon => $polylist[0] };
        next LINE;
    }

    my @insets;
    my @sides;
    for my $p (@polylist) {
        my $a = polygon_area_in_km($p);
        if ($a < $Minimum_sheet_size) {
            print "$label --> Inset area: $a\n";
            push @insets, $p;
        }
        else {
            push @sides, $p;
        }
    }

    # sort out the sides
    if (1==@sides) {
        my $b = polygon_bbox($sides[0]);
        push @maps, { series => $series, label => $label, bbox => $b, polygon => $sides[0] };
    }
    elsif (2==@sides) {
        my $b1 = polygon_bbox($sides[0]);
        my $b2 = polygon_bbox($sides[1]);
        my $center_E1 = $b1->[0][0] + ($b1->[1][0]-$b1->[0][0])/2;
        my $center_E2 = $b2->[0][0] + ($b2->[1][0]-$b2->[0][0])/2;
        my $center_N1 = $b1->[0][1] + ($b1->[1][1]-$b1->[0][1])/2;
        my $center_N2 = $b2->[0][1] + ($b2->[1][1]-$b2->[0][1])/2;
        my $E_diff = $center_E1 - $center_E2;
        my $N_diff = $center_N1 - $center_N2;
        my $label1 = my $label2 = $label;
        if ( abs($E_diff) > abs($N_diff) ) {
            $label1 .= $E_diff > 0 ? 'E' : 'W';
            $label2 .= $E_diff > 0 ? 'W' : 'E';
        }
        else {
            $label1 .= $N_diff > 0 ? 'N' : 'S';
            $label2 .= $N_diff > 0 ? 'S' : 'N';
        }
        push @maps, { series => $series, label => $label1, bbox => $b1, polygon => $sides[0] };
        push @maps, { series => $series, label => $label2, bbox => $b2, polygon => $sides[1] };
    }
    else {
        croak "More than two sides to sheet $label\n";
    }

    # do the insets
    if (1==@insets) {
        my $b = polygon_bbox($insets[0]);
        push @maps, { series => $series, label => "$label Inset", bbox => $b, polygon => $insets[0] };
    }
    elsif (1 < @insets ) {
        my $inset_ordinal = 'A';
        for my $p (@insets) {
            my $b = polygon_bbox($p);
            my $s = sprintf "%s Inset %s", $label, $inset_ordinal++;
            push @maps, { series => $series, label => $s, bbox => $b, polygon => $p };
        }
    }
}

#use Geo::Coordinates::OSGB 'parse_grid';
#
#my ($e, $n) = parse_grid('NR 640 440');
#
#for my $m (@maps) {
#    if ($m->{bbox}->[0][0] <= $e && $e <= $m->{bbox}->[1][0]
#     && $m->{bbox}->[0][1] <= $n && $n <= $m->{bbox}->[1][1] ) {
#
#        print $m->{series}, ":", $m->{label}, "\n";
#    }
#}

open(my $plotter, '>', 'plot.mp');
print $plotter ' prologues := 3; outputtemplate := "%j%c.eps"; beginfig(1); path p;', "\n";

for my $m (@maps) {
        print $m->{series}, ":", $m->{label}, "\n";
        print $plotter plot_poly($m->{polygon}, $m->{label}), "\n"; 
    }
#}
print $plotter "endfig;end.\n";
close $plotter;
