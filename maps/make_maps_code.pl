# Toby Thurston -- 21 Sep 2015 
# compile the map tables into perl source code

sub polygon_area_in_km {
    my $p = shift;
    my $a = 0;
    for (my $i=1; $i < scalar @{$p}; $i++) {
        $a = $a + $p->[$i-1][0] * $p->[$i][1]
                - $p->[$i-1][1] * $p->[$i][0];
    }
    return $a/2_000_000;
}


while (<>) {
    my ($nn, $label, $flag, $mpg) = split ' ', $_, 4;
    $mpg =~ s/\s*$//;

    next if $mpg eq 'EMPTY';

    my $nest = 0;
    my $x; my $y;

    my @polylist;
    my $p=0;
    my $s = reverse $mpg;
    while (length $s) {
        $c = chop $s;
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
    for my $p (@polylist) {
        $p = [ map { [ split ' ' ] } split ',', $p ];
    }
    for my $p (@polylist) {
        my $a = polygon_area_in_km($p);
        print "$nn >> $a >>";
        for my $pt ( @{$p} ) {
            print "($pt->[0],$pt->[1]) "
        }
        print "\n";
    }
    for my $i (0 .. $#polylist) {
        my $s = join ',', map { "[$_->[0],$_->[1]]" } @{$polylist[$i]};
        print "\$polylist[$nn][$i] = [ $s ];\n";
    }
}
