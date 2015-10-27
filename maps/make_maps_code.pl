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

# work out labels for two boxes : NS or EW?
sub pair_label_suffixes {
    my $b1 = shift;
    my $b2 = shift;
    my $center_E1 = $b1->[0][0] + ($b1->[1][0]-$b1->[0][0])/2;
    my $center_E2 = $b2->[0][0] + ($b2->[1][0]-$b2->[0][0])/2;
    my $center_N1 = $b1->[0][1] + ($b1->[1][1]-$b1->[0][1])/2;
    my $center_N2 = $b2->[0][1] + ($b2->[1][1]-$b2->[0][1])/2;
    my $E_diff = $center_E1 - $center_E2;
    my $N_diff = $center_N1 - $center_N2;
    my $label1;
    my $label2;
    if ( abs($E_diff) > abs($N_diff) ) {
        $label1 = $E_diff > 0 ? 'E' : 'W';
        $label2 = $E_diff > 0 ? 'W' : 'E';
    }
    else {
        $label1 = $N_diff > 0 ? 'N' : 'S';
        $label2 = $N_diff > 0 ? 'S' : 'N';
    }
    return ($label1, $label2);
}



my @sheets;
my $Minimum_sheet_size = 300; # Anything smaller than 300km^2 is an inset

my @polygon_files = (
    'polygons-os-landranger.txt',
    'polygons-os-explorer.txt',
    'polygons-os-one-inch.txt',
);

my %sizes = ();

my $min_inset_area = 1;
my $max_inset_area = 300;
my $min_sheet_area = 300;
my $max_sheet_area = 10000;

for my $f (@polygon_files) {
    open my $fh, '<', $f;
    warn "Reading from $f\n";
    LINE:
    while (<$fh>) {

        if ( $_ =~ m{\A (inset|sheet)_area_range \s+ (\d+) \D+ (\d+) \s* \Z}iosx ) {
            if ( $1 eq 'inset') {
                ($min_inset_area, $max_inset_area) = ($2, $3);
            }
            else {
                ($min_sheet_area, $max_sheet_area) = ($2, $3);
            }
            next LINE;
        }

        my ($nn, $label, $flag, $mpg) = split ' ', $_, 4;
        $mpg =~ s/\s*$//;

        next LINE if $mpg eq 'EMPTY';
        
        next LINE if $flag eq '8';

        croak "Missing flag" if $flag =~ m{\A\(}iosx;

        croak "Invalid index number" unless $nn =~ m{\A ([A-Z]) (\d+) \Z}iosx;
        my $series = $1;

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
        # and work out the areas, and push then into the right sides array
        my @sides = ( [], [] );
        my $side_index = -1;

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
            
            my $a = polygon_area_in_km($p);
            croak "Not a positive area" unless $a > 0;

            my $b = polygon_bbox($p);

            # push the polys into lists here (list for side 1, list for side 2)
            # main side is first poly in each list

            if ( $min_inset_area <= $a && $a <= $max_inset_area ) {
                # do nothing here
            }
            elsif ( $min_sheet_area <= $a && $a <= $max_sheet_area ) {
                croak "$series $label too many sides" if $side_index > 0;
                $side_index++;
            }
            else {
                croak "$label Area $a out of expected range";
            }
            push @{$sides[$side_index]}, { poly => $p, area => $a, bbox => $b };

        }

        # do we have two sides?  if so, find labels
        my ($i, $key, $parent_key);
        if ( @{$sides[1]} > 0 ) {
            my @s = pair_label_suffixes($sides[0][0]{bbox}, $sides[1][0]{bbox});
            for my $side (0..1) {
                $parent_key = sprintf "%s:%s%s", $series, $label, $s[$side];
                $i = 0;
                for my $region ( @{$sides[$side]} ) {
                    $key = sprintf "%s%s", $parent_key, $i==0 ? '' : '.'.chr(96+$i);
                    $i++;
                    push @sheets, { key => $key, 
                                    bbox => $region->{bbox},
                                    area => $region->{area},
                                    poly => $region->{poly},
                                    series => $series,
                                    number => $label,
                                    parent => $parent_key,
                                };
                }
            }
        }
        else {
            $parent_key = sprintf "%s:%s", $series, $label;
            $i = 0;
            for my $region ( @{$sides[0]} ) {
                $key = sprintf "%s%s", $parent_key, $i==0 ? '' : '.'.chr(96+$i);
                $i++;
                push @sheets, { key => $key, 
                                bbox => $region->{bbox},
                                area => $region->{area},
                                poly => $region->{poly},
                                series => $series,
                                number => $label,
                                parent => $parent_key,
                            };
            }
        }
        
    }
    close $fh;
}


open(my $perl, '>', '../lib/Geo/Coordinates/British_Maps.pm');
print $perl <<'END_PREAMBLE';
package Geo::Coordinates::British_Maps;
use base qw(Exporter);
use strict;
use warnings;
our $VERSION = '2.10';
our @EXPORT_OK = qw(%maps %name_for_map_series);
our %maps;
our %name_for_map_series = ( 
  A => 'OS Landranger', 
  B => 'OS Explorer',
  C => 'OS One-Inch 7th series',
);
END_PREAMBLE

for my $m (@sheets) {
    print $perl '$maps{"', $m->{key}, '"} = { ';
    printf $perl 'bbox => [[%d, %d], [%d, %d]], ', $m->{bbox}->[0][0], $m->{bbox}->[0][1], $m->{bbox}->[1][0], $m->{bbox}->[1][1];
    for my $f ( qw{ area series number parent } ) {
        printf $perl "%s => '%s', ", $f, $m->{$f};
    }
    print $perl 'polygon => [', join(',', map { sprintf '[%d,%d]', $_->[0], $_->[1] } @{$m->{poly}}), ']'; # no comma because last
    print $perl " };\n";
}

print $perl "1;\n";
close $perl;
warn sprintf "Wrote %d sheet definitions to maps module\n", scalar @sheets;
