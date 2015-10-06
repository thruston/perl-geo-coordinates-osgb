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


my @maps;
my $Minimum_sheet_size = 300; # Anything smaller than 300km^2 is an inset

my @polygon_files = (
    'polygons-os-landranger.txt',
    'polygons-os-explorer.txt',
    'polygons-os-one-inch.txt',
);

for my $f (@polygon_files) {
    open my $fh, '<', $f;
    LINE:
    while (<$fh>) {
        my ($nn, $label, $flag, $mpg) = split ' ', $_, 4;
        $mpg =~ s/\s*$//;

        next LINE if $mpg eq 'EMPTY';
        
        next LINE if $flag eq '8';

        croak "Missing flag" if $flag =~ m{\A\(}iosx;

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
            # check each pair has two and only two coordinates and that the polygon is closed
            for my $pt (@$p) {
                if (2!=@$pt) {
                   my $err = "@$pt"; 
                   croak "Broken pair $err at line $. in $ARGV";;
               } 
            }
            croak "Unclosed polygon" unless $p->[0][0] == $p->[-1][0]
                                         && $p->[0][1] == $p->[-1][1];
        }
        
        # split the polygons up into insets and sides 
        # Often there will be only 1 side and 0 insets, so special case that first
        if (1==@polylist) {
            my $b = polygon_bbox($polylist[0]);
            push @maps, { series => $series, label => $label, bbox => $b, polygon => $polylist[0] };
            next LINE;
        }

        my @insets;
        my @inset_areas;
        my @sides;
        for my $p (@polylist) {
            my $a = polygon_area_in_km($p);
            if ($a < $Minimum_sheet_size) {
                #print "$label --> Inset area: $a\n";
                @insets = sort by_area @insets, { poly => $p, area => $a };
            }
            else {
                push @sides, $p;
            }
        }

        sub by_area {
            $b->{area} <=> $a->{area}
        }
        

        # sort out the sides
        # first check the sides array
        # if there are insets but no sides, then promote the biggest inset to a side
        if (0 < @insets && 0 == @sides) {
            push @sides, map {$_->{poly}} shift @insets;
        }

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
            croak "More than two sides to sheet $label";
        }

        # do the insets
        if (1==@insets) {
            my $p = $insets[0]->{poly};
            my $b = polygon_bbox($p);
            push @maps, { series => $series, label => "$label Inset", bbox => $b, polygon => $p };
        }
        elsif (1 < @insets ) {
            my $inset_ordinal = 'A';
            for my $i (@insets) {
                my $p = $i->{poly};
                my $b = polygon_bbox($p);
                my $s = sprintf "%s Inset %s", $label, $inset_ordinal++;
                push @maps, { series => $series, label => $s, bbox => $b, polygon => $p };
            }
        }
    }
    close $fh;
}

use Geo::Coordinates::OSGB 'format_grid_GPS';
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

open(my $perl, '>', '../lib/Geo/Coordinates/British_Maps.pm');
print $perl <<'END_PREAMBLE';
package Geo::Coordinates::British_Maps;
use base qw(Exporter);
use strict;
use warnings;
our $VERSION = '2.09';
our @EXPORT_OK = qw(%maps %name_for_map_series);
our %maps;
our %name_for_map_series = ( 
  A => 'OS Landranger', 
  B => 'OS Explorer',
  C => 'OS One-Inch 7th series',
  H => 'Harvey British Mountain Map',
  J => 'Harvey Super Walker',
);
END_PREAMBLE

for my $m (@maps) {
    my $k = sprintf "%s:%s", $m->{series}, $m->{label};
    print $perl '$maps{"', $k, '"} = { ';
    printf $perl 'bbox => [[%d, %d], [%d, %d]], ', $m->{bbox}->[0][0], $m->{bbox}->[0][1], $m->{bbox}->[1][0], $m->{bbox}->[1][1];
    print $perl 'polygon => [', join(',', map { sprintf '[%d,%d]', $_->[0], $_->[1] } @{$m->{polygon}}), ']';
    print $perl " };\n";
}

print $perl "1;\n";
close $perl;
warn sprintf "Wrote %d map sheet definitions to maps module\n", scalar @maps;
