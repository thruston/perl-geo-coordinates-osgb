use strict;
use warnings;
use Carp;
use Text::Balanced 'extract_bracketed';

sub wkt_to_list {
    my $w = shift;
    $w =~ s/^\(+//;
    $w =~ s/\)+$//;
    my @p;
    for my $pair (split /,/, $w) {
        my ($x,$y) = $pair =~ m{\A\s*(\d+)\s+(\d+)\s*\Z}osxm;
        croak "Invalid pair" unless $x && $y;
        push @p, [$x, $y];
    }
    croak "Unclosed polygon" unless $p[0][0] == $p[-1][0] && $p[0][1] == $p[-1][1];
    return [@p]
}

sub polygon_area_in_km {
    my $p = shift;
    my $a = 0;
    for (my $i=1; $i < scalar @{$p}; $i++) {
        $a = $a + $p->[$i-1][0] * $p->[$i][1]
                - $p->[$i-1][1] * $p->[$i][0];
    }
    return $a/2_000_000;
}



my %label_for;
my %polygons_for;
while (<>) {
    my ($nn, $label, $flag, @mp) = split;
    my $mpg = "@mp";
    next if $mpg eq 'EMPTY';
    my ($extracted, $remainder) = extract_bracketed($mpg);
    print "Broken: $_" if $mpg ne $extracted;

    $label_for{$nn} = $label;
    my $polygon_list = substr($extracted, 1, -1);
    my $polygon;
    while ($polygon_list) {
        ($polygon, $polygon_list) = extract_bracketed($polygon_list);
        push @{$polygons_for{$nn}}, wkt_to_list($polygon);
        $polygon_list =~ s/^,\s*//;
    }
}


for my $k (sort keys %polygons_for ) {
    print "$k - Sheet $label_for{$k} -"; 
    my $n = 0;
    for my $p (@{$polygons_for{$k}}) {
        $n++;
        print " ";
        print polygon_area_in_km($p);
    }
    print "\n";
}

