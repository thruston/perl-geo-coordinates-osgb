package Geo::Coordinates::OSGB::Grid;
use base qw(Exporter);
use strict;
use warnings;

our $VERSION = '2.10';
our %EXPORT_TAGS = (
    all => [ qw( 
                 parse_grid 
                 parse_trad_grid 
                 parse_GPS_grid 
                 parse_landranger_grid
                 parse_map_grid
                 format_grid
                 format_grid_trad 
                 format_grid_GPS 
                 format_grid_landranger
                 format_grid_map
                 random_grid 
           )]
    );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

my $SHORT_GRID_REF = qr{ \A ([GHJMNORST][A-Z]) \s? (\d{1,3}) \D? (\d{1,3}) \Z }smiox;
my $LONG_GRID_REF  = qr{ \A ([GHJMNORST][A-Z]) \s? (\d{4,5}) \D? (\d{4,5}) \Z }smiox;
# size of LR sheets
use constant LR_SHEET_SIZE => 40_000;


sub parse_grid {
    my $s = "@_";
    if ( $s =~ $SHORT_GRID_REF ) {
        return _parse_grid($1, $2*100, $3*100)
    }
    if ( $s =~ $LONG_GRID_REF ) {
        return _parse_grid($1, $2, $3)
    }
    if ( $s =~ m{\A (\d{1,3}) \D+ (\d{3}) \D? (\d{3}) \Z}xsm ) { # sheet/eee/nnn etc
        return parse_landranger_grid($1, $2, $3)
    }
    if ( $s =~ m{\A \d{1,3} \Z}xsm && $s < 205 ) {  # just a landranger sheet
        return parse_landranger_grid($s)
    }
    if ( $s =~ m{\A (\d+(?:\.\d+)?) \s+ (\d+(?:\.\d+)?) \Z}xsmio ) { # eee nnn
        return ($1, $2)
    }

    croak "$s <-- this does not match my grid ref patterns";
}

sub parse_trad_grid {
    my $gr = "@_";
    if ( $gr =~ $SHORT_GRID_REF  ) { return _parse_grid($1, $2*100, $3*100) }

    croak "Cannot parse @_ as a traditional grid reference";
}

sub parse_GPS_grid {
    my $gr = "@_";
    if ( $gr =~ $LONG_GRID_REF  ) { return _parse_grid($1, $2, $3) }

    croak "Cannot parse @_ as a GPS grid reference";
}

sub _parse_grid {
    my ($letters, $e, $n) = @_;

    return if !defined wantarray;

    $letters = uc $letters;

    my $c = substr $letters,0,1;
    $e += $BIG_OFF{$c}->{E}*BIG_SQUARE;
    $n += $BIG_OFF{$c}->{N}*BIG_SQUARE;

    my $d = substr $letters,1,1;
    $e += $SMALL_OFF{$d}->{E}*SQUARE;
    $n += $SMALL_OFF{$d}->{N}*SQUARE;

    return ($e,$n);
}


sub parse_landranger_grid {
    my ($sheet, $e, $n) = @_;

    return if !defined wantarray;

    if ( !defined $sheet )      { croak 'Missing OS Sheet number'  }
    if ( !defined $LR{$sheet} ) { croak "Unknown OS Sheet number ($sheet)" }
    if ( !defined $e )          { return wantarray ? @{$LR{$sheet}} : format_grid_trad(@{$LR{$sheet}}) }
    if ( !defined $n )          { $n = -1 }

    use integer;

    SWITCH: {
        if ( $e =~ m{\A (\d{3}) (\d{3}) \Z}x && $n == -1 ) { ($e, $n) = ($1*100, $2*100) ; last SWITCH }
        if ( $e =~ m{\A\d{3}\Z}x && $n =~ m{\A\d{3}\Z}x )  { ($e, $n) = ($e*100, $n*100) ; last SWITCH }
        if ( $e =~ m{\A\d{5}\Z}x && $n =~ m{\A\d{5}\Z}x )  { ($e, $n) = ($e*1,   $n*1  ) ; last SWITCH }
        croak "I was expecting a grid reference, not this: @_";
    }

    my $full_easting  = _lr_to_full_grid($LR{$sheet}->[0], $e);
    my $full_northing = _lr_to_full_grid($LR{$sheet}->[1], $n);

    return ($full_easting, $full_northing)
}

sub _lr_to_full_grid {
    my ($lower_left_offset, $in_square_offset) = @_;

    my $lower_left_in_square = $lower_left_offset % 100_000;

    my $distance_from_lower_left = $in_square_offset - $lower_left_in_square;
    if ( $distance_from_lower_left < 0 ) {
        $distance_from_lower_left += 100_000;
    }

    if ( $distance_from_lower_left < 0 || $distance_from_lower_left >= LR_SHEET_SIZE ) {
        croak 'Grid reference not on sheet';
    }

    return $lower_left_offset + $distance_from_lower_left;
}

my %BIG_OFF = (
              G => { E => -1, N => 2 },
              H => { E =>  0, N => 2 },
              J => { E =>  1, N => 2 },
              M => { E => -1, N => 1 },
              N => { E =>  0, N => 1 },
              O => { E =>  1, N => 1 },
              R => { E => -1, N => 0 },
              S => { E =>  0, N => 0 },
              T => { E =>  1, N => 0 },
           );

my %SMALL_OFF = (
                 A => { E =>  0, N => 4 },
                 B => { E =>  1, N => 4 },
                 C => { E =>  2, N => 4 },
                 D => { E =>  3, N => 4 },
                 E => { E =>  4, N => 4 },

                 F => { E =>  0, N => 3 },
                 G => { E =>  1, N => 3 },
                 H => { E =>  2, N => 3 },
                 J => { E =>  3, N => 3 },
                 K => { E =>  4, N => 3 },

                 L => { E =>  0, N => 2 },
                 M => { E =>  1, N => 2 },
                 N => { E =>  2, N => 2 },
                 O => { E =>  3, N => 2 },
                 P => { E =>  4, N => 2 },

                 Q => { E =>  0, N => 1 },
                 R => { E =>  1, N => 1 },
                 S => { E =>  2, N => 1 },
                 T => { E =>  3, N => 1 },
                 U => { E =>  4, N => 1 },

                 V => { E =>  0, N => 0 },
                 W => { E =>  1, N => 0 },
                 X => { E =>  2, N => 0 },
                 Y => { E =>  3, N => 0 },
                 Z => { E =>  4, N => 0 },
           );

use constant BIG_SQUARE => 500_000;
use constant SQUARE     => 100_000;

# Landranger sheet data
# These are the full GRs (as metres from Newlyn) of the SW corner of each sheet.
my %LR = (
      1 => [ 429_000, 1_179_000 ] ,
      2 => [ 433_000, 1_156_000 ] ,
      3 => [ 414_000, 1_147_000 ] ,
      4 => [ 420_000, 1_107_000 ] ,
      5 => [ 340_000, 1_020_000 ] ,
      6 => [ 321_000,   996_000 ] ,
      7 => [ 315_000,   970_000 ] ,
      8 => [ 117_000,   926_000 ] ,
      9 => [ 212_000,   940_000 ] ,
     10 => [ 252_000,   940_000 ] ,
     11 => [ 292_000,   929_000 ] ,
     12 => [ 300_000,   939_000 ] ,
     13 => [  95_000,   903_000 ] ,
     14 => [ 105_000,   886_000 ] ,
     15 => [ 196_000,   900_000 ] ,
     16 => [ 236_000,   900_000 ] ,
     17 => [ 276_000,   900_000 ] ,
     18 => [  69_000,   863_000 ] ,
     19 => [ 174_000,   860_000 ] ,
     20 => [ 214_000,   860_000 ] ,
     21 => [ 254_000,   860_000 ] ,
     22 => [  57_000,   823_000 ] ,
     23 => [ 113_000,   836_000 ] ,
     24 => [ 150_000,   830_000 ] ,
     25 => [ 190_000,   820_000 ] ,
     26 => [ 230_000,   820_000 ] ,
     27 => [ 270_000,   830_000 ] ,
     28 => [ 310_000,   833_000 ] ,
     29 => [ 345_000,   830_000 ] ,
     30 => [ 377_000,   830_000 ] ,
     31 => [  50_000,   783_000 ] ,
     32 => [ 130_000,   800_000 ] ,
     33 => [ 170_000,   790_000 ] ,
     34 => [ 210_000,   780_000 ] ,
     35 => [ 250_000,   790_000 ] ,
     36 => [ 285_000,   793_000 ] ,
     37 => [ 325_000,   793_000 ] ,
     38 => [ 365_000,   790_000 ] ,
     39 => [ 120_000,   770_000 ] ,
     40 => [ 160_000,   760_000 ] ,
     41 => [ 200_000,   750_000 ] ,
     42 => [ 240_000,   750_000 ] ,
     43 => [ 280_000,   760_000 ] ,
     44 => [ 320_000,   760_000 ] ,
     45 => [ 360_000,   760_000 ] ,
     46 => [  92_000,   733_000 ] ,
     47 => [ 120_000,   733_000 ] ,
     48 => [ 120_000,   710_000 ] ,
     49 => [ 160_000,   720_000 ] ,
     50 => [ 200_000,   710_000 ] ,
     51 => [ 240_000,   720_000 ] ,
     52 => [ 270_000,   720_000 ] ,
     53 => [ 294_000,   720_000 ] ,
     54 => [ 334_000,   720_000 ] ,
     55 => [ 164_000,   680_000 ] ,
     56 => [ 204_000,   682_000 ] ,
     57 => [ 244_000,   682_000 ] ,
     58 => [ 284_000,   690_000 ] ,
     59 => [ 324_000,   690_000 ] ,
     60 => [ 110_000,   640_000 ] ,
     61 => [ 131_000,   662_000 ] ,
     62 => [ 160_000,   640_000 ] ,
     63 => [ 200_000,   642_000 ] ,
     64 => [ 240_000,   645_000 ] ,
     65 => [ 280_000,   650_000 ] ,
     66 => [ 316_000,   650_000 ] ,
     67 => [ 356_000,   650_000 ] ,
     68 => [ 157_000,   600_000 ] ,
     69 => [ 175_000,   613_000 ] ,
     70 => [ 215_000,   605_000 ] ,
     71 => [ 255_000,   605_000 ] ,
     72 => [ 280_000,   620_000 ] ,
     73 => [ 320_000,   620_000 ] ,
     74 => [ 357_000,   620_000 ] ,
     75 => [ 390_000,   620_000 ] ,
     76 => [ 195_000,   570_000 ] ,
     77 => [ 235_000,   570_000 ] ,
     78 => [ 275_000,   580_000 ] ,
     79 => [ 315_000,   580_000 ] ,
     80 => [ 355_000,   580_000 ] ,
     81 => [ 395_000,   580_000 ] ,
     82 => [ 195_000,   530_000 ] ,
     83 => [ 235_000,   530_000 ] ,
     84 => [ 265_000,   540_000 ] ,
     85 => [ 305_000,   540_000 ] ,
     86 => [ 345_000,   540_000 ] ,
     87 => [ 367_000,   540_000 ] ,
     88 => [ 407_000,   540_000 ] ,
     89 => [ 290_000,   500_000 ] ,
     90 => [ 317_000,   500_000 ] ,
     91 => [ 357_000,   500_000 ] ,
     92 => [ 380_000,   500_000 ] ,
     93 => [ 420_000,   500_000 ] ,
     94 => [ 460_000,   485_000 ] ,
     95 => [ 213_000,   465_000 ] ,
     96 => [ 303_000,   460_000 ] ,
     97 => [ 326_000,   460_000 ] ,
     98 => [ 366_000,   460_000 ] ,
     99 => [ 406_000,   460_000 ] ,
    100 => [ 446_000,   460_000 ] ,
    101 => [ 486_000,   460_000 ] ,
    102 => [ 326_000,   420_000 ] ,
    103 => [ 360_000,   420_000 ] ,
    104 => [ 400_000,   420_000 ] ,
    105 => [ 440_000,   420_000 ] ,
    106 => [ 463_000,   420_000 ] ,
    107 => [ 500_000,   420_000 ] ,
    108 => [ 320_000,   380_000 ] ,
    109 => [ 360_000,   380_000 ] ,
    110 => [ 400_000,   380_000 ] ,
    111 => [ 430_000,   380_000 ] ,
    112 => [ 470_000,   385_000 ] ,
    113 => [ 510_000,   386_000 ] ,
    114 => [ 220_000,   360_000 ] ,
    115 => [ 240_000,   345_000 ] ,
    116 => [ 280_000,   345_000 ] ,
    117 => [ 320_000,   340_000 ] ,
    118 => [ 360_000,   340_000 ] ,
    119 => [ 400_000,   340_000 ] ,
    120 => [ 440_000,   350_000 ] ,
    121 => [ 478_000,   350_000 ] ,
    122 => [ 518_000,   350_000 ] ,
    123 => [ 210_000,   320_000 ] ,
    124 => [ 250_000,   305_000 ] ,
    125 => [ 280_000,   305_000 ] ,
    126 => [ 320_000,   300_000 ] ,
    127 => [ 360_000,   300_000 ] ,
    128 => [ 400_000,   308_000 ] ,
    129 => [ 440_000,   310_000 ] ,
    130 => [ 480_000,   310_000 ] ,
    131 => [ 520_000,   310_000 ] ,
    132 => [ 560_000,   310_000 ] ,
    133 => [ 600_000,   310_000 ] ,
    134 => [ 617_000,   290_000 ] ,
    135 => [ 250_000,   265_000 ] ,
    136 => [ 280_000,   265_000 ] ,
    137 => [ 320_000,   260_000 ] ,
    138 => [ 345_000,   260_000 ] ,
    139 => [ 385_000,   268_000 ] ,
    140 => [ 425_000,   270_000 ] ,
    141 => [ 465_000,   270_000 ] ,
    142 => [ 504_000,   274_000 ] ,
    143 => [ 537_000,   274_000 ] ,
    144 => [ 577_000,   270_000 ] ,
    145 => [ 200_000,   220_000 ] ,
    146 => [ 240_000,   225_000 ] ,
    147 => [ 270_000,   240_000 ] ,
    148 => [ 310_000,   240_000 ] ,
    149 => [ 333_000,   228_000 ] ,
    150 => [ 373_000,   228_000 ] ,
    151 => [ 413_000,   230_000 ] ,
    152 => [ 453_000,   230_000 ] ,
    153 => [ 493_000,   234_000 ] ,
    154 => [ 533_000,   234_000 ] ,
    155 => [ 573_000,   234_000 ] ,
    156 => [ 613_000,   250_000 ] ,
    157 => [ 165_000,   201_000 ] ,
    158 => [ 189_000,   190_000 ] ,
    159 => [ 229_000,   185_000 ] ,
    160 => [ 269_000,   205_000 ] ,
    161 => [ 309_000,   205_000 ] ,
    162 => [ 349_000,   188_000 ] ,
    163 => [ 389_000,   190_000 ] ,
    164 => [ 429_000,   190_000 ] ,
    165 => [ 460_000,   195_000 ] ,
    166 => [ 500_000,   194_000 ] ,
    167 => [ 540_000,   194_000 ] ,
    168 => [ 580_000,   194_000 ] ,
    169 => [ 607_000,   210_000 ] ,
    170 => [ 269_000,   165_000 ] ,
    171 => [ 309_000,   165_000 ] ,
    172 => [ 340_000,   155_000 ] ,
    173 => [ 380_000,   155_000 ] ,
    174 => [ 420_000,   155_000 ] ,
    175 => [ 460_000,   155_000 ] ,
    176 => [ 495_000,   160_000 ] ,
    177 => [ 530_000,   160_000 ] ,
    178 => [ 565_000,   155_000 ] ,
    179 => [ 603_000,   133_000 ] ,
    180 => [ 240_000,   112_000 ] ,
    181 => [ 280_000,   112_000 ] ,
    182 => [ 320_000,   130_000 ] ,
    183 => [ 349_000,   115_000 ] ,
    184 => [ 389_000,   115_000 ] ,
    185 => [ 429_000,   116_000 ] ,
    186 => [ 465_000,   125_000 ] ,
    187 => [ 505_000,   125_000 ] ,
    188 => [ 545_000,   125_000 ] ,
    189 => [ 585_000,   115_000 ] ,
    190 => [ 207_000,    87_000 ] ,
    191 => [ 247_000,    72_000 ] ,
    192 => [ 287_000,    72_000 ] ,
    193 => [ 310_000,    90_000 ] ,
    194 => [ 349_000,    75_000 ] ,
    195 => [ 389_000,    75_000 ] ,
    196 => [ 429_000,    76_000 ] ,
    197 => [ 469_000,    90_000 ] ,
    198 => [ 509_000,    97_000 ] ,
    199 => [ 549_000,    94_000 ] ,
    200 => [ 175_000,    50_000 ] ,
    201 => [ 215_000,    47_000 ] ,
    202 => [ 255_000,    32_000 ] ,
    203 => [ 132_000,    11_000 ] ,
    204 => [ 172_000,    14_000 ] ,
);

sub random_grid {
    my @preferred_sheets = @_;
    my @sheets;
    if (@preferred_sheets > 0) {
        @sheets = map { $_ if exists $LR{$_} } @preferred_sheets;
    }
    else {
        @sheets = keys %LR;
    }
    my $map = $sheets[ int rand $#sheets ];
    my $easting = $LR{$map}[0] + int(rand LR_SHEET_SIZE);
    my $northing = $LR{$map}[1] + int(rand LR_SHEET_SIZE);
    return ($easting, $northing);
}

sub format_grid_trad {
    my $e = shift;
    my $n = shift;
    my $sq;

    ($sq, $e, $n) = format_grid_GPS($e, $n);

    use integer;
    ($e,$n) = ($e/100,$n/100);
    return ($sq, $e, $n) if wantarray;
    return sprintf '%s %03d %03d', $sq, $e, $n;
}

sub format_grid_GPS {
    my $e = shift;
    my $n = shift;

    croak 'Easting must not be negative' if $e<0;
    croak 'Northing must not be negative' if $n<0;

    # round to nearest metre
    ($e,$n) = map { $_+0.5 } ($e, $n);
    my $sq;

    my $great_square_index_east  = 2 + int $e/BIG_SQUARE;
    my $great_square_index_north = 1 + int $n/BIG_SQUARE;
    my $small_square_index_east  = int ($e%BIG_SQUARE)/SQUARE;
    my $small_square_index_north = int ($n%BIG_SQUARE)/SQUARE;

    my @grid = ( [ qw( V W X Y Z ) ],
                 [ qw( Q R S T U ) ],
                 [ qw( L M N O P ) ],
                 [ qw( F G H J K ) ],
                 [ qw( A B C D E ) ],
               );

    $sq = $grid[$great_square_index_north][$great_square_index_east]
        . $grid[$small_square_index_north][$small_square_index_east];

    ($e,$n) = map { $_ % SQUARE } ($e, $n);

    return ($sq, $e, $n) if wantarray;
    return sprintf '%s %05d %05d', $sq, $e, $n;
}

sub format_grid_landranger {
    my ($e,$n) = @_;
    my @sheets = ();
    for my $sheet (1..204) {
        my $e_difference = $e - $LR{$sheet}->[0];
        my $n_difference = $n - $LR{$sheet}->[1];
        if ( 0 <= $e_difference && $e_difference < LR_SHEET_SIZE
          && 0 <= $n_difference && $n_difference < LR_SHEET_SIZE ) {
            push @sheets, $sheet
        }
    }
    my $sq;
    ($sq, $e, $n) = format_grid_trad($e,$n);

    return ($sq, $e, $n, @sheets) if wantarray;

    if (!@sheets )    { return sprintf '%s %03d %03d is not on any OS Sheet', $sq, $e, $n }
    if ( @sheets==1 ) { return sprintf '%s %03d %03d on OS Sheet %d'        , $sq, $e, $n, $sheets[0] }
    if ( @sheets==2 ) { return sprintf '%s %03d %03d on OS Sheets %d and %d', $sq, $e, $n, @sheets }

    my $phrase = join ', ', @sheets[0..($#sheets-1)], "and $sheets[-1]";
    return sprintf '%s %03d %03d on OS Sheets %s', $sq, $e, $n, $phrase;

}

use Geo::Coordinates::OSGB::Maps qw{%maps};

sub format_grid_map { 
    my ($e, $n) = @_;
    my @sheets = ();
    while (my ($k,$m) = each %maps) {
        if ($m->{bbox}->[0][0] <= $e && $e < $m->{bbox}->[1][0]
         && $m->{bbox}->[0][1] <= $n && $n < $m->{bbox}->[1][1]) {
            my $w = _winding_number($e, $n, $m->{polygon});
            if ($w != 0) { 
                push @sheets, $k;
            }
        }
    }
    my $sq;
    ($sq, $e, $n) = format_grid_trad($e,$n);
    @sheets = sort @sheets;

    return ($sq, $e, $n, @sheets) if wantarray;

    if (!@sheets )    { return sprintf '%s %03d %03d is not on any of our maps', $sq, $e, $n; }
    else              { return sprintf '%s %03d %03d on %s', $sq, $e, $n, join ', ', @sheets; }
    
}

sub parse_map_grid {
    my ($sheet, $e, $n) = @_;

    return if !defined wantarray;

    if ( !defined $sheet )        { croak 'Missing sheet identifier'  }
    if ( !defined $maps{$sheet} ) { croak "Unknown sheet identifier ($sheet)" }

    my @ll = @{$maps{$sheet}->{bbox}[0]};

    if ( !defined $e )          { return wantarray ? @ll : format_grid_trad(@ll) }
    if ( !defined $n )          { $n = -1 }

    SWITCH: {
        if ( $e =~ m{\A (\d{3}) (\d{3}) \Z}x && $n == -1 ) { ($e, $n) = ($1*100, $2*100) ; last SWITCH }
        if ( $e =~ m{\A\d{3}\Z}x && $n =~ m{\A\d{3}\Z}x )  { ($e, $n) = ($e*100, $n*100) ; last SWITCH }
        if ( $e =~ m{\A\d{5}\Z}x && $n =~ m{\A\d{5}\Z}x )  { ($e, $n) = ($e*1,   $n*1  ) ; last SWITCH }
        croak "I can't parse a grid reference from this: @_";
    }

    $e = $ll[0] + ($e-$ll[0]) % SQUARE;
    $n = $ll[1] + ($n-$ll[1]) % SQUARE;

    my $w = _winding_number($e, $n, $maps{$sheet}->{polygon});

    if ($w == 0) {
        croak "Grid reference ($e,$n) is not on sheet $sheet";
    }

    return ($e, $n);
}

# is $pt left of $a--$b?
sub _is_left {
    my ($x, $y, $a, $b) = @_;
    return ( ($b->[0] - $a->[0]) * ($y - $a->[1]) - ($x - $a->[0]) * ($b->[1] - $a->[1]) );
}

# adapted from http://geomalgorithms.com/a03-_inclusion.html
sub _winding_number {
    my ($x, $y, $poly) = @_;
    my $w = 0;
    for (my $i=0; $i < $#$poly; $i++ ) {
        if ( $poly->[$i][1] <= $y ) {
            if ($poly->[$i+1][1]  > $y && _is_left($x, $y, $poly->[$i], $poly->[$i+1]) > 0 ) {
                $w++;
            }
        }
        else {
            if ($poly->[$i+1][1] <= $y && _is_left($x, $y, $poly->[$i], $poly->[$i+1]) < 0 ) {
                $w--;
            }
        }
    }
    return $w;
}

1;

=pod

=over

=item random_grid([sheet1, sheet2, ...])

Takes an optional list of Landranger map numbers (1..204), and returns a random
easting and northing for some place covered by one of the maps.  There's no
guarantee that the point will not be in the sea, but it will be on one of the
maps. If you omit the list of sheets, then one of the 204 will be picked at
random.  If the list includes sheet numbers that are not in the range 1..204
they will be (silently) ignored.  The easting and northing are returns as
meters from Newlyn, so that they are suitable for input to any of the
c<format_grid> routines.

=item format_grid_trad(e,n)

Formats an (easting, northing) pair into traditional `full national grid
reference' with two letters and two sets of three numbers, like this
`TQ 102 606'.  If you want to remove the spaces, just apply C<s/\s//g> to it.

    $gridref = format_grid_trad(533000, 180000); # TQ 330 800
    $gridref =~ s/\s//g;                         # TQ330800

If you want the individual components call it in a list context.

    ($sq, $e, $n) = format_grid_trad(533000, 180000); # (TQ,330,800)

Note the easting and northing are truncated to hectometers (as the OS system
demands), so the grid reference refers to the lower left corner of the
relevant 100m square.

=item format_grid_GPS(e,n)

Users who have bought a GPS receiver may initially have been puzzled by the
unfamiliar format used to present coordinates in the British national grid format.
On my Garmin Legend C it shows this sort of thing in the display.

    TQ 23918
   bng 00972

and in the track logs the references look like this C<TQ 23918 00972>.

These are just the same as the references described on the OS sheets, except
that the units are metres rather than hectometres, so you get five digits in
each of the easting and northings instead of three.  So in a scalar context
C<format_grid_GPS()> returns a string like this:

    $gridref = format_grid_GPS(533000, 180000); # TQ 33000 80000

If you call it in a list context, you will get a list of square, easting, and
northing, with the easting and northing as metres within the grid square.

    ($sq, $e, $n) = format_grid_GPS(533000, 180000); # (TQ,33000,80000)

Note that, at least until WAAS is working in Europe, the results from your
GPS are unlikely to be more accurate than plus or minus 5m even with perfect
reception.  Most GPS devices can display the accuracy of the current fix you
are getting, but you should be aware that all normal consumer-level GPS
devices can only ever produce an approximation of an OS grid reference, no
matter what level of accuracy they may display.  The reasons for this are
discussed below in the section on L<Theory>.

=item format_grid_map(e,n)

This routine returns the grid reference formatted in the same way as
C<format_grid_trad>, but it also appends a list of maps on which the point
appears.  Note that the list will be empty if the grid point does not appear on
any of the defined maps.  This can happen with points in the sea, or in other
areas not covered by the any of the British OS maps (such as Northern Ireland
or the Channel Islands).  In most cases the list will contain more than one map
-- this is because (a) there are several series of maps defined and (b) many of
the sheets in each series overlap at the edges.

In a list context you will get back a list like this:  (square, easting,
northing, sheet) or (square, easting, northing, sheet1, sheet2) etc.  There are
a few places where three sheets overlap, and one corner of Herefordshire which
appears on four Landranger maps (sheets 137, 138, 148, and 149).  If the GR is
not on any sheet, then the list of sheets will be empty.

In a scalar context you will get back the same information in a helpful string
form like this "NN 241 738 on A:41, B:392, C:47".  Note that the easting and
northing will have been truncated to the normal hectometre three digit form.
The idea is that you'll use this form for people who might actually want to
look up the grid reference on the given map sheet, and the traditional GR form
is quite enough accuracy for that purpose.

See the section below on L<Maps> for more details, including the series of maps
that are included.

=item parse_trad_grid(grid_ref)

Turns a traditional grid reference into a full easting and northing pair in
metres from the point of origin.  The I<grid_ref> can be a string like
C<'TQ203604'> or C<'SW 452 004'>, or a list like this C<('TV', '435904')> or a list
like this C<('NN', '345', '208')>.


=item parse_GPS_grid(grid_ref)

Does the same as C<parse_trad_grid> but is looking for five digit numbers
like C<'SW 45202 00421'>, or a list like this C<('NN', '34592', '20804')>.

=item parse_landranger_grid(sheet, e, n)

This converts an OS Landranger sheet number and a local grid reference
into a full easting and northing pair in metres from the point of origin.

The OS Landranger sheet number should be between 1 and 204 inclusive (but
I may extend this when I support insets).  You can supply C<(e,n)> as 3-digit
hectometre numbers or 5-digit metre numbers.  In either case if you supply
any leading zeros you should 'quote' the numbers to stop Perl thinking that
they are octal constants.

This module will croak at you if you give it an undefined sheet number, or
if the grid reference that you supply does not exist on the sheet.

In order to get just the coordinates of the SW corner of the sheet, just call
it with the sheet number.  It is easy to work out the coordinates of the
other corners, because all OS Landranger maps cover a 40km square (if you
don't count insets or the occasional sheet that includes extra details
outside the formal margin).

=item parse_grid(grid_ref)

Attempts to match a grid reference some form or other in the input string
and will then call the appropriate grid parsing routine from those defined
above.  In particular it will parse strings in the form C<'176/345210'>
meaning grid ref 345 210 on sheet 176, as well as C<'TQ345210'> and C<'TQ
34500 21000'> etc.  You can in fact always use "parse_grid" instead of the more
specific routines unless you need to be picky about the input.

