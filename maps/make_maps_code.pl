# Toby Thurston -- 13 Jan 2016 
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

my @series_to_build = ();
open my $control, '<', 'map_series.txt' or die "Cannot open control file\n";
while ( <$control> ) {
    chomp;
    next unless my ($id, $file, $sides, $max_inset_area, $max_sheet_area, $short_name, $long_name) =
          $_ =~ /([A-Z])\s+(\S+)\s+(\d)\D+(\d+)\D+(\d+)\s+(\S+)\s+(\S.*)$/osmx;

    $long_name =~ s/\A\"(.*)\"\Z/$1/s or
    $long_name =~ s/\A\'(.*)\'\Z/$1/s;

    push @series_to_build, {
        id         => $id,                                
        cat_file   => sprintf('catalogue-%s.txt', $file), 
        poly_file  => sprintf('polygons-%s.txt', $file),  
        max_inset_area => $max_inset_area,                    
        max_sheet_area => $max_sheet_area,                    
        short_name => $short_name,                        
        long_name  => $long_name,                        
    }
}

#for my $s (@series_to_build) {
#    for my $k (sort keys %$s) {
#        print "$k --> $s->{$k}\n";
#    }
#}


my @sheets;
my %label_for;
my %title_for;
my %seen;

use Business::ISBN qw( valid_isbn_checksum );

for my $s (@series_to_build) {
    my $series = $s->{id};
    open my $cat, '<', $s->{cat_file} or die "Cannot open catalogue file for $series\n";
    warn "Reading catalogue for $s->{long_name}\n";
    while ( <$cat> ) {
        chomp;
        my ($nn, $isbn, $label, $title) = split ' ', $_, 4;
        croak "Invalid index number: $nn $series" unless $nn =~ m{\A $series (\d+) \Z}x;
        
        if ( $isbn ) {
            croak "Invalid ISBN for $nn : $isbn\n" unless valid_isbn_checksum($isbn);
            croak "Duplicate ISBN for $nn\n" if $seen{$isbn}++;
        }

        croak "Duplicate id for $nn\n" if exists $title_for{$nn};
        $title =~ s/\s*\Z//iosxm;
        $title_for{$nn} = $title;
        $label_for{$nn} = $label;

    }

    close $cat;
    open my $fh, '<', $s->{poly_file} or die "Cannot open polygon file for $series\n";
    warn "Reading polygons for $s->{long_name}\n";
    LINE:
    while (<$fh>) {

        my ($nn, $junk, $flag, $mpg) = split ' ', $_, 4;
        $mpg =~ s/\s*$//;

        next LINE if $mpg eq 'EMPTY';
        
        next LINE if $flag eq '8';

        croak "Missing flag" if $flag =~ m{\A\(}iosx;

        croak "Invalid index number: $nn $series" unless $nn =~ m{\A $series (\d+) \Z}x;

        croak "Missing title for $nn\n" unless my $title = $title_for{$nn};
        croak "Missing label for $nn\n" unless my $label = $label_for{$nn};

        # split the MULTIPOLYGON string up 1 char at a time using the reverse and chop trick
        my $nest = 0;
        my @polylist;
        my $p=0;
        my $gpm = reverse $mpg;
        while (length $gpm) {
            my $c = chop $gpm;
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
            if ($a < 0 ) {
                for my $pt (reverse @$p) {
                    print join(' ', @$pt), ', ';
                }
                print "\n";
                croak "Not a positive area for $label $a";
            }

            my $b = polygon_bbox($p);

            # push the polys into lists here (list for side 1, list for side 2)
            # main side is first poly in each list

            if ( $a <= $s->{max_inset_area} ) {
                # do nothing here
            }
            elsif ( $a <= $s->{max_sheet_area} ) {
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
            my @suffixes = pair_label_suffixes($sides[0][0]{bbox}, $sides[1][0]{bbox});
            for my $side (0..1) {
                $parent_key = sprintf "%s:%s%s", $series, $label, $suffixes[$side];
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
                                    title => $title,
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
                                title => $title,
                            };
            }
        }
        
    }
    close $fh;
}


open my $perl, '>', '../lib/Geo/Coordinates/OSGB/Maps.pm';
print $perl <<'END_PREAMBLE';
package Geo::Coordinates::OSGB::Maps;
use base qw(Exporter);
use strict;
use warnings;
our $VERSION = '2.11';
our @EXPORT_OK = qw(%maps %name_for_map_series);
our %maps;
our %name_for_map_series = ( 
  A => 'OS Landranger', 
  B => 'OS Explorer',
  C => 'OS One-Inch 7th series',
  H => 'Harvey British Mountain maps',
  J => 'Harvey Superwalker',
);
END_PREAMBLE

for my $m (@sheets) {
    print $perl '$maps{"', $m->{key}, '"} = { ';
    printf $perl 'bbox => [[%d, %d], [%d, %d]], ', $m->{bbox}->[0][0], $m->{bbox}->[0][1], $m->{bbox}->[1][0], $m->{bbox}->[1][1];
    for my $f ( qw{area series number parent title} ) {
        die "No f\n" unless defined $f;
        die "No $f in $m->{key}\n" unless defined $m->{$f};
        printf $perl "%s => '%s', ", $f, $m->{$f};
    }
    print $perl 'polygon => [', join(',', map { sprintf '[%d,%d]', $_->[0], $_->[1] } @{$m->{poly}}), ']'; # no comma because last
    print $perl " };\n";
}

print $perl "1;\n\n";
print $perl <<'POD';
=pod

=head1 Data for OSGB Maps

This module exports no functions, but just two hashes of data.

=head2 Hash C<%name_for_map_series>

The keys are the single letter codes used for each map series.  
The values are the descriptive names of each series.

Currently (V2.11) we have

  A => 'OS Landranger', 
  B => 'OS Explorer',
  C => 'OS One-Inch 7th series',
  H => 'Harvey British Mountain maps',
  J => 'Harvey Superwalker',

=head2 Hash C<%maps>

The keys are short identifiers for each sheet or inset.  Where a map has more than one side, or includes
insets then, there will be a separate entry for each side and inset.

The value for each key is another hash containing the following items

=over 4

=item bbox

The bounding box of the sheet as a list of two pairs of coordinates (in metres
from the grid origin)

=item polygon
  
A list of pairs of coordinates (in metres from grid origin) that define the
corners of the sheet.  The list starts at the SW corner (approximately, on some
sheets it's not entirely obvious where to start), and works round
anticlockwise.  In all cases the last pair is the same as the first pair.

=item area 

The calculated area of the sheet in square kilometres

=item series

A single letter series identifier -- this will be one of the keys from the
"name_for_map_series" hash

=item number

The identifier for this map within the series, not including any suffix for a
sheet or an inset.  The two sides of a single map have the same number.  The
number is not always an integer - Outdoor Leisure maps are designated "OL14"
etc.  Those maps known by two numbers have a "number" consisting of both
numbers divided by a "/"; such as "418/OL60" in the Explorer series.

=item parent

The key of the parent map for an inset.  Main sheets of a map, will have
"parent" equal to their own key.

=item title

The title of the map.  Different sheets and insets from the same map will have
the same title.

=back

=cut

POD
close $perl;
warn sprintf "Wrote %d sheet definitions to maps module\n", scalar @sheets;
