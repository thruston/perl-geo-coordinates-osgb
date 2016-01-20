package Geo::Coordinates::OSGB::Grid;

use Geo::Coordinates::OSGB::Maps qw{%maps %name_for_map_series};

use base qw(Exporter);
use strict;
use warnings;
use Carp;
use POSIX qw/floor/;

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

use constant GRID_SQ_LETTERS => 'VWXYZQRSTULMNOPFGHJKABCDE';
use constant GRID_SIZE => sqrt length GRID_SQ_LETTERS;
use constant MINOR_GRID_SQ_SIZE => 100_000;
use constant MAJOR_GRID_SQ_SIZE => GRID_SIZE * MINOR_GRID_SQ_SIZE;
use constant MAJOR_GRID_SQ_EASTING_OFFSET  => 2 * MAJOR_GRID_SQ_SIZE;
use constant MAJOR_GRID_SQ_NORTHING_OFFSET => 1 * MAJOR_GRID_SQ_SIZE;
use constant MAX_GRID_SIZE => MINOR_GRID_SQ_SIZE * length GRID_SQ_LETTERS;

# Produce a random GR 
# A simple approach would pick 0 < E < 700000 and 0 < N < 1250000 but that way
# many GRs produced would be in the sea, so pick a random map, and then find a
# random GR within its bbox and finally check that the resulting pair is
# actually on some map.

sub random_grid {
    my @preferred_sheets = @_;
    # assume plain sheet numbers are Landranger
    for my $s (@preferred_sheets) {
        if ($s =~ m{\A\d+\Z}) {
            $s =~ s/\A/A:/
        }
    }
    my @sheets;
    if (@preferred_sheets > 0) {
        @sheets = grep { exists $maps{$_} } @preferred_sheets;
    }
    else {
        @sheets = keys %maps;
    }
    my ($map, $lle, $lln, $ure, $urn, $easting, $northing);
    while (1) {
        $map = $maps{$sheets[int rand @sheets]};
        ($lle, $lln) = @{$map->{bbox}->[0]};
        ($ure, $urn) = @{$map->{bbox}->[1]};
        $easting  = $lle + int(rand ($ure-$lle));
        $northing = $lln + int(rand ($urn-$lln));
        last if 0 != _winding_number($easting, $northing, $map->{polygon});
    }
    return ($easting, $northing);
}

sub format_grid {
    my ($easting, $northing, $options) = @_;

    my $form      = exists $options->{form}   ? uc $options->{form}   : 'SS EEE NNN';
    my $with_maps = exists $options->{maps}   ?    $options->{maps}   : 0;
    my $map_keys  = exists $options->{series} ? uc $options->{series} : join '', sort keys %name_for_map_series;

    my $sq = _grid_to_sq($easting,$northing);
    my ($e,$n) = map { int } map { $_ % MINOR_GRID_SQ_SIZE } ($easting, $northing);

    my @sheets = ();
    if ( $with_maps ) {
        while (my ($k,$m) = each %maps) {
            next unless index($map_keys, substr($k,0,1)) > -1;
            if ($m->{bbox}->[0][0] <= $easting  && $easting  < $m->{bbox}->[1][0]
                && $m->{bbox}->[0][1] <= $northing && $northing < $m->{bbox}->[1][1]) {
                my $w = _winding_number($easting, $northing, $m->{polygon});
                if ($w != 0) { 
                    push @sheets, $k;
                }
            }
        }
        @sheets = sort @sheets;
    } 

    if ( $form eq 'TRAD' ) {
        $form = 'SS EEE NNN';
    }
    elsif ( $form eq 'GPS' ) {
        $form = 'SS EEEEE NNNNN';
    }

    if ( my ($space_a, $e_spec, $space_b, $n_spec) = $form =~ m{ \A S{1,2}(\s*)(E{1,5})(\s*)(N{1,5}) \Z }iosxm ) {
        my $e_len = length $e_spec;
        my $n_len = length $n_spec;
        $e = int($e / 10**(5 - $e_len));
        $n = int($n / 10**(5 - $n_len));

        if ( wantarray ) {
            return ($sq, $e, $n, @sheets)
        }

        my $gr = sprintf "%s%s%0.*d%s%0.*d", $sq, $space_a, $e_len, $e, $space_b, $n_len, $n;
        $gr =~ s/\s+/ /g;

        if ( $with_maps ) {
            if ( @sheets ) {
                return sprintf '%s on %s', $gr, join ', ', @sheets; 
            }
            else {
                return sprintf '%s is not on any maps in series %s', $gr, $map_keys;
            }
        }
        else {
            return $gr;
        }
    }

    croak "Format $form was not recognized";
}

sub format_grid_trad {
    my ($easting, $northing) = @_;
    return format_grid($easting, $northing, { form => 'SS EEE NNN' })
}

sub format_grid_GPS {
    my ($easting, $northing) = @_;
    return format_grid($easting, $northing, { form => 'SS EEEEE NNNNN' })
}

sub format_grid_map {
    my ($easting, $northing, $options) = @_;
    if ( defined $options ) {
        $options->{maps} = 1
    }
    else {
        $options = { maps => 1 }
    }
    return format_grid($easting, $northing, $options)
}

sub format_grid_landranger {
    my ($easting,$northing) = @_;

    my ($sq, $e, $n, @sheets) = format_grid($easting, $northing, { form => 'SS EEE NNN', maps => 1, series => 'A' });

    for my $s (@sheets) {
        $s =~ s/\AA://;
    }
    
    return ($sq, $e, $n, @sheets) if wantarray;

    if (!@sheets )    { return sprintf '%s %03d %03d is not on any Landranger sheet', $sq, $e, $n }
    if ( @sheets==1 ) { return sprintf '%s %03d %03d on Landranger sheet %s'        , $sq, $e, $n, $sheets[0] }
    if ( @sheets==2 ) { return sprintf '%s %03d %03d on Landranger sheets %s and %s', $sq, $e, $n, @sheets }

    my $phrase = join ', ', @sheets[0..($#sheets-1)], "and $sheets[-1]";
    return sprintf '%s %03d %03d on Landranger sheets %s', $sq, $e, $n, $phrase;

}

sub _get_grid_letter_offsets {
    my $a = shift;
    my $i = index(GRID_SQ_LETTERS, $a);
    if ($i < 0) {
        croak "I can't use $a as a grid square letter";
    }
    return ($i % GRID_SIZE, int $i / GRID_SIZE )
}

sub _sq_to_grid {
    my $aa = shift;
    my ($E,$N) = _get_grid_letter_offsets(substr($aa,0,1));
    my ($e,$n) = _get_grid_letter_offsets(substr($aa,1,1));
    return (
        MAJOR_GRID_SQ_SIZE * $E - MAJOR_GRID_SQ_EASTING_OFFSET  + MINOR_GRID_SQ_SIZE * $e, 
        MAJOR_GRID_SQ_SIZE * $N - MAJOR_GRID_SQ_NORTHING_OFFSET + MINOR_GRID_SQ_SIZE * $n
    );
}

sub _grid_to_sq {
    my ($e, $n) = @_;
    $e += MAJOR_GRID_SQ_EASTING_OFFSET;
    $n += MAJOR_GRID_SQ_NORTHING_OFFSET;
    if (!(0 <= $e && $e < MAX_GRID_SIZE && 0 <= $n && $n < MAX_GRID_SIZE )) {
        croak "Too far off the grid: @_";
    }
    my $major_index = int $e / MAJOR_GRID_SQ_SIZE + GRID_SIZE * int $n / MAJOR_GRID_SQ_SIZE;
    $e = $e % MAJOR_GRID_SQ_SIZE;
    $n = $n % MAJOR_GRID_SQ_SIZE;
    my $minor_index = int $e / MINOR_GRID_SQ_SIZE + GRID_SIZE * int $n / MINOR_GRID_SQ_SIZE;
    return 
       substr(GRID_SQ_LETTERS, $major_index, 1) .
       substr(GRID_SQ_LETTERS, $minor_index, 1);
}

sub _get_grid_square {
    my $s = shift;
    my $S = uc $s;
    return if 0 > index GRID_SQ_LETTERS, substr $S, 0, 1;
    return if 0 > index GRID_SQ_LETTERS, substr $S, 1, 1;
    return substr $S, 0, 2;
}

sub _get_eastnorthings {
    my $S = shift;
    my $numbers = $S =~ tr/0-9//cdr;
    my $len = length $numbers;
    croak "No easting or northing found" unless $len;
    croak "Easting and northing have different lengths in $S" if $len % 2;
    croak "Too many digits in $S" if $len > 10;
    my $e = reverse sprintf "%05d", scalar reverse substr $numbers, 0, $len/2;
    my $n = reverse sprintf "%05d", scalar reverse substr $numbers,    $len/2;
    return ($e, $n)
}

sub parse_grid {

    my $options = 'HASH' eq ref $_[-1] ? pop @_ : { };

    my $figs = exists $options->{figs} ? $options->{figs} : 3;

    my @out;

    my $s = @_ < 3 ? "@_" : sprintf "%s %0.*d %0.*d", $_[0], $figs, $_[1], $figs, $_[2];

    my $sq      = _get_grid_square($s);

    if ( defined $sq ) {
        my ($E, $N) = _sq_to_grid($sq);
        my ($e, $n) = _get_eastnorthings(substr $s, 2);
        @out = ($E+$e, $N+$n);
        return wantarray ? @out : "@out";
    }

    if (my ($sheet, $numbers) = $s =~ m{\A ([A-Z0-9:.]+)\D+(\d+\D*\d+) \Z }xsmio ) {

        # allow Landranger sheets with no prefix
        $sheet = "A:$sheet" if exists $maps{"A:$sheet"};

        if ( exists $maps{$sheet} ) { 
            my @ll_corner = @{$maps{$sheet}->{bbox}[0]};  # NB we need the bbox corner so that it is left and below all points on the map

            my ($e, $n) = _get_eastnorthings($numbers);

            $e = $ll_corner[0] + ($e-$ll_corner[0]) % MINOR_GRID_SQ_SIZE;
            $n = $ll_corner[1] + ($n-$ll_corner[1]) % MINOR_GRID_SQ_SIZE;

            my $w = _winding_number($e, $n, $maps{$sheet}->{polygon});
            if ($w == 0) {
                croak sprintf "Grid reference %s = (%d, %d) is not on sheet %s", scalar format_grid($e,$n), $e, $n, $sheet;
            }
            return wantarray ? ($e, $n) : "$e $n";
        }
    }

    if ( @out = $s =~ m{\A (\d+(?:\.\d+)?) \s+ (\d+(?:\.\d+)?) \Z}xsmio ) { # eee nnn
        return wantarray ? @out : "@out";
    }

    croak "Failed to parse a grid reference from $s";
}

*parse_trad_grid       = \&parse_grid;
*parse_GPS_grid        = \&parse_grid;
*parse_landranger_grid = \&parse_grid;
*parse_map_grid        = \&parse_grid;

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

__END__

=pod

=head1 Functions for parsing and formatting grid references

This module provides useful functions for parsing and formatting OSGB grid 
references.  Some detailed background is given in C<background.pod> and on 
the OS web site.  

=head2 Routines to generate grid references

=over 4

=item C<random_grid([sheet1, sheet2, ...])>

Takes an optional list of map sheet identifiers, and returns a random easting
and northing for some place covered by one of the maps.  There's no guarantee
that the point will not be in the sea, but it will be within the bounding box
of one of the maps. 

If you omit the list of sheets, then one of map sheets defined in
L<Geo::Coordinates::OSGB::Maps> will be picked at random.  

As a convenience whole numbers in the range 1..204 will be interpreted
as Landranger sheets, as if you had written C<A:1>, C<A:2>, etc. 

Any sheet identifiers in the list that are not defined in
L<Geo::Coordinates::OSGB::Maps> will be (silently) ignored.  

The easting and northing are returned as meters from the grid origin, so that
they are suitable for input to the C<format_grid> routines.

=back

=head2 Routines to format (easting, northing) pairs

=over 4

=item C<format_grid(e, n)>

Formats an (easting, northing) pair into traditional `full national grid
reference' with two letters and two sets of three numbers, like this
`SU 387 147'.  

    $gridref = format_grid(438710.908, 114792.248); # SU 387 147

If you want the individual components call it in a list context.

    ($sq, $e, $n) = format_grid(438710.908, 114792.248); # ('SU', 387, 147)

Note that rather than being rounded, the easting and northing are *truncated* to
hectometers (as the OS system demands), so the grid reference refers to the
lower left corner of the relevant 100m square.  The system is described below the
legend on all OS Landranger maps.

=item C<format_grid(e, n, {form =E<gt> 'SS EEE NNN', maps =E<gt> 0, series =E<gt> 'ABCHJ'})>

The format grid routine takes an optional third argument to control 
the form of grid reference returned.  This should be a hash reference with 
one or more of the keys shown above, with the default values.

=over 8

=item form  

Controls the format of the grid reference.  With C<$e, $n> set as above:

    Format          produces        Format            produces       
    ----------------------------------------------------------------
    'SSEN'          SU31            'SS E N'          SU 3 1         
    'SSEENN'        SU3814          'SS EE NN'        SU 38 14       
    'SSEEENNN'      SU387147        'SS EEE NNN'      SU 387 147     
    'SSEEEENNNN'    SU38711479      'SS EEEE NNNN'    SU 3871 1479 
    'SSEEEEENNNNN'  SU3871014792    'SS EEEEE NNNNN'  SU 38710 14792 

There are two other special formats:

     form => 'TRAD' is equivalent to form => 'SS EEE NNN'
     form => 'GPS'  is equivalent to form => 'SS EEEEE NNNNN'

In a list context, this option means that the individual components are returned
appropriately truncated as shown.  So with C<SS EEE NNN> you get back C<('SU', 387, 147)>
and B<not> C<('SU', 387.10908, 147.92248)>.  The format can be given as upper case or lower
case or a mixture.

=item maps

Controls whether to include a list of map sheets after the grid reference.
Set it to 1 (or any true value) to include the list, and to 0 (or any false value) 
to leave it out.  The default is C<maps =E<gt> 0>.

In a scalar context you get back a string like this:

    SU 387 147 on A:196, B:OL22E, C:180

In a list context you get back a list like this:
    
    ('SU', 387, 147, A:196, B:OL22E, C:180)

=item series

This option is only used when C<maps> is true.  It controls which series of maps to include in the list of 
sheets.  Currently the series included are:

C<A> : OS Landranger 1:50000 maps

C<B> : OS Explorer 1:25000 maps (some of these are designated as `Outdoor Leisure' maps)

C<C> : OS Seventh Series One-Inch 1:63360 maps

C<H> : Harvey British Mountain maps — mainly at 1:40000

C<J> : Harvey Super Walker maps — mainly at 1:25000

so if you only want Explorer maps use: C<series =E<gt> 'B'>, and if you want only Explorers and Landrangers
use: C<series =E<gt> 'AB'>, and so on. 

Note that the numbers returned for the Harvey maps have been invented for the purposes
of this module.  They do not appear on the maps themselves; instead the maps have titles.
You can use the numbers returned as an index to the data in C<Geo::Coordinates::OSGB::Maps>
to find the appropriate title.

=back 4

=item format_grid_trad(e,n)

Equivalent to C<format_grid(e,n, { form =E<gt> 'trad' })>.

=item format_grid_GPS(e,n)

Equivalent to C<format_grid(e,n, { form =E<gt> 'gps' })>.

=item format_grid_map(e,n)

Equivalent to C<format_grid(e,n, { maps =E<gt> 1 })>.

=item format_grid_landranger(e,n)

Equivalent to

   format_grid(e,n,{ form => 'ss eee nnn', maps => 1, series => 'A' }) 

except that the leading "A:" will be stripped from any sheet names returned, and you 
get a slightly fancier set of phrases in a scalar context depending on how many 
map numbers are in the list of sheets.

=back

For more examples of formatting look at the test files.

=head2 Routines to extract (easting, northing) pairs from grid references

=over 4

=item parse_grid

The C<parse_grid> routine extracts a (easting, northing) pair from a string, 
or a list of arguments, representing a grid reference.  The pair returned
are in units of metres from the false origin of the grid, so that you can pass them to 
C<format_grid> or C<grid_to_ll>.

The arguments should be in one of the following forms

=over 8

=item A single string representing a grid reference

  String                        ->  interpreted as   
  --------------------------------------------------
  parse_grid("TA 123 678")      ->  (512300, 467800) 
  parse_grid("TA 12345 67890")  ->  (512345, 467890) 

The spaces are optional in all cases.  You can also refer to a 10km square 
as "TA16" which will return C<(510000, 460000)>, or to a kilometre
square as "TA1267" which gives C<(512000, 467000)>. For completeness you can 
also use "TA 1234 6789" to refer to a decametre square C<(512340, 467890)> but 
you might struggle to find a use for that one.

=item A list representing a grid reference

  List                             ->  interpreted as   
  -----------------------------------------------------
  parse_grid('TA', '123 678')      ->  (512300, 467800) 
  parse_grid('TA', 123, 678)       ->  (512300, 467800) 
  parse_grid('TA', '12345 67890')  ->  (512345, 467890) 
  parse_grid('TA', 12345, 67890)   ->  (512345, 467890) 

If you are processing grid references from some external data source beware 
that if you use a list with bare numbers you may lose any leading zeros for 
grid references close to the SW corner of a grid square.  This can lead to 
some ambiguity.  Either make the numbers into strings to preserve the leading 
digits or supply a hash of options as a fourth argument with the `figs' option to define
how many figures are supposed to be in each easting and northing.  Like this:

  List                                     ->  interpreted as   
  -------------------------------------------------------------
  parse_grid('TA', 123, 8)                 ->  (512300, 400800) 
  parse_grid('TA', 123, 8, { figs => 5 })  ->  (500123, 400008) 

The default setting of figs is 3, which assumes you are using hectometres as in a traditional 
grid reference.

=item A string or list representing a map sheet and a grid reference on that sheet

     Map input                      ->  interpreted as    
     ----------------------------------------------------
     parse_grid('A:164/352194')     ->  (435200, 219400) 
     parse_grid('B:OL43E/914701')   ->  (391400, 570100) 
     parse_grid('B:OL43E 914 701')  ->  (391400, 570100) 
     parse_grid('B:OL43E','914701') ->  (391400, 570100) 
     parse_grid('B:OL43E',914,701)  ->  (391400, 570100)

Again spaces are optional, but you need some non-digit between the map
identifier and the grid reference.  There are also some constraints:
the map identifier must be one defined in L<Geo::Coordinates::OSGB::Maps>;
and the following grid reference must actually be on the given sheet.  Note
also that you need to supply a specific sheet for a map that has more than one.
The given example would fail if the map was given as `B:OL43', since that map has two sheets: 
`B:OL43E' and `B:OL43W'.

If you give the identifier as just a number, it's assumed that you wanted
a Landranger map;

     parse_grid('176/224711')  ->  (522400, 171100) 
     parse_grid(164,513,62)    ->  (451300, 206200) 

The routine will croak of you pass it a sheet identifier that is not defined in 
L<Geo::Coordinates::OSGB::Maps>.  It will also croak if the supplied easting and northing 
are not actually on the sheet.

In earlier versions, the easting and northing arguments were optional, and you could 
leave them out to get just the SW corner of the sheet.  This functionality has been 
removed in this version, because it's not always obvious where the SW corner of a 
sheet is (for an example look at the inset on Landranger sheet 107).

If you need access to the postion of the sheets in this version, you should work directly with
the data in C<Geo::Coordinates::OSGB::Maps>.

=back 4 

=item parse_trad_grid(grid_ref)

This is included only for backward compatibility.  It is now just a synonym
for C<parse_grid>.

=item parse_GPS_grid(grid_ref)

This is included only for backward compatibility.  It is now just a synonym
for C<parse_grid>.

=item parse_landranger_grid(sheet, e, n)

This is included only for backward compatibility.  It is now just a synonym
for C<parse_grid>.

=item parse_map_grid(sheet, e, n)

This is included only for backward compatibility.  It is now just a synonym
for C<parse_grid>.

=back 

For more examples of parsing look at the test files.

=cut
