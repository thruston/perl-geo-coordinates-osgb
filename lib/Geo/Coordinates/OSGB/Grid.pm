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

sub _get_grid_ref {
    my $s = "@_";
    my $S = uc $s;
    return if 0 > index GRID_SQ_LETTERS, substr $S, 0, 1;
    return if 0 > index GRID_SQ_LETTERS, substr $S, 1, 1;
    my $sq = substr $S, 0, 2;
    my $numbers = $S =~ tr/0-9//cdr;
    my $len = length $numbers;
    return if $len % 2;
    return unless 0 < $len && $len <= 10;
    my $e = reverse sprintf "%05d", scalar reverse substr $numbers, 0, $len/2;
    my $n = reverse sprintf "%05d", scalar reverse substr $numbers,    $len/2;
    return ($sq, $e, $n);
}

sub parse_grid {
    my $s = "@_";
    
    my ($sq, $e, $n) = _get_grid_ref($s);
    
    if ( defined $sq ) {
        my ($E, $N) = _sq_to_grid($sq);
        return ($E+$e, $N+$n);
    }

    if ( $s =~ m{\A ((?:A:)\d{1,3}) \D+ (\d{3}) \D? (\d{3}) \Z}xsm ) { # sheet/eee/nnn etc
        return parse_landranger_grid($1, $2, $3)
    }
    if ( $s =~ m{\A \d{1,3} \Z}xsm && $s < 205 ) {  # just a landranger sheet
        return parse_landranger_grid($s)
    }
    if ( $s =~ m{\A (\d+(?:\.\d+)?) \s+ (\d+(?:\.\d+)?) \Z}xsmio ) { # eee nnn
        return ($1, $2)
    }

    _bail_out(wanted => "a grid reference", supplied => $s);
}

*parse_trad_grid = \&parse_grid;
*parse_GPS_grid  = \&parse_grid;

sub parse_landranger_grid {
    my ($sheet, $e, $n) = @_;

    if ( !defined $sheet ) {
        return 
    }

    if ( defined $maps{$sheet} ) {
        return parse_map_grid($sheet, $e, $n)
    }
    
    if ( defined $maps{"A:$sheet"} ) {
        return parse_map_grid("A:$sheet", $e, $n)
    }

    _bail_out(wanted => "a Landranger sheet number", supplied => $sheet);
}

# Produce a random GR 
# A simple approach would pick 0 < E < 700000 and 0 < N < 1250000
# but that way many GRs produced would be in the sea, so pick a random
# map, and then find a random GR within its bbox
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
    my $map = $sheets[int rand @sheets];
    my ($lle, $lln) = @{$maps{$map}->{bbox}->[0]};
    my ($ure, $urn) = @{$maps{$map}->{bbox}->[1]};
    my $easting  = $lle + int(rand ($ure-$lle));
    my $northing = $lln + int(rand ($urn-$lln));
    
    return ($easting, $northing);
}

sub format_grid {
    my ($e, $n, $options) = ( @_, { form => 'SS EEE NNN' } );
    my $form = uc $options->{form} || 'TRAD';
    if ( $form eq 'TRAD' ) {
        return format_grid_trad($e, $n)
    }
    elsif ( $form eq 'GPS' ) {
        return format_grid_GPS($e, $n)
    }
    elsif ( $form eq 'MAP' ) {
        return format_grid_map($e, $n, $options)
    }
    elsif ( $form eq 'LANDRANGER' ) {
        return format_grid_landranger($e, $n)
    }
    elsif ( $form =~ m{ \A (S{1,2})(\s*)(E{1,5})(\s*)(N{1,5}) \Z }iosxm ) {
        my $sq;
        ($sq, $e, $n) = format_grid_GPS($e, $n);
        $e /= 10**(5 - length $3);
        $n /= 10**(5 - length $5);
        my $gr = sprintf "%s%s%0d%s%0d", $sq, $2, $e, $4, $n;
        $gr =~ s/\s+/ /g;
        return $gr;
    }
    else {
        return ($e, $n)
    }
}

sub format_grid_trad {
    my $e = shift;
    my $n = shift;
    my $sq;

    ($sq, $e, $n) = format_grid_GPS($e, $n);
    ($e,$n) = map { int $_/100 } ($e,$n);

    return ($sq, $e, $n) if wantarray;
    return sprintf '%s %03d %03d', $sq, $e, $n;
}

sub format_grid_GPS {
    my ($e, $n) = @_;
    my $sq = _grid_to_sq($e,$n);
    ($e,$n) = map { int } map { $_ % MINOR_GRID_SQ_SIZE } ($e, $n);
    return ($sq, $e, $n) if wantarray;
    return sprintf '%s %05d %05d', $sq, $e, $n;
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

sub format_grid_landranger {
    my ($easting,$northing) = @_;

    my ($sq, $e, $n, @sheets) = format_grid_map($easting, $northing, { series_keys => 'A' });

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

sub format_grid_map { 
    my ($e, $n, $options) = @_;
    my $wanted_keys = defined $options->{series_keys} 
                    ? $options->{series_keys}
                    : join '', sort keys %name_for_map_series;
    my @sheets = ();
    while (my ($k,$m) = each %maps) {
        next unless index($wanted_keys, substr($k,0,1)) > -1;
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

    if (!@sheets )    { return sprintf '%s %03d %03d is not on any maps in series %s', $sq, $e, $n, $options->{series_keys}; }
    else              { return sprintf '%s %03d %03d on %s', $sq, $e, $n, join ', ', @sheets; }
    
}

sub parse_map_grid {
    my ($sheet, $e, $n) = @_;

    return if !defined wantarray;

    return if !defined $sheet;

    if ( !defined $maps{$sheet} ) { 
        _bail_out(wanted => "a defined sheet identifier", supplied => $sheet) 
    }

    my @ll = @{$maps{$sheet}->{polygon}[0]};

    if ( !defined $e )          { return wantarray ? @ll : format_grid_trad(@ll) }
    if ( !defined $n )          { $n = -1 }

    SWITCH: {
        if ( $e =~ m{\A (\d{3}) (\d{3}) \Z}x && $n == -1 ) { ($e, $n) = ($1*100, $2*100) ; last SWITCH }
        if ( $e =~ m{\A\d{3}\Z}x && $n =~ m{\A\d{3}\Z}x )  { ($e, $n) = ($e*100, $n*100) ; last SWITCH }
        if ( $e =~ m{\A\d{5}\Z}x && $n =~ m{\A\d{5}\Z}x )  { ($e, $n) = ($e*1,   $n*1  ) ; last SWITCH }
        _bail_out(wanted => "a grid reference", supplied => "@_");
    }

    $e = $ll[0] + ($e-$ll[0]) % MINOR_GRID_SQ_SIZE;
    $n = $ll[1] + ($n-$ll[1]) % MINOR_GRID_SQ_SIZE;

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

sub _bail_out {
    my %a = ( wanted => 'something', supplied => 'nothing', @_ );
    croak "Failed, trying to parse $a{wanted} from: $a{supplied}";
}


1;

=pod

=head1 Functions for parsing and formatting grid references

This module provides useful functions for parsing and formatting OSGB grid 
references.  Some detailed background is given in "background.pod" and on 
the OS web site.  

=head2 Routines to generate grid references

=over 4

=item random_grid([sheet1, sheet2, ...])

Takes an optional list of map sheet identifiers, and returns a random easting
and northing for some place covered by one of the maps.  There's no guarantee
that the point will not be in the sea, but it will be within the bounding box
of one of the maps. 

If you omit the list of sheets, then one of map sheets defined in
Geo::Coordinates::OSGB::Maps will be picked at random.  

As a convenience whole numbers in the range 1..204 will be interpreted
as Landranger sheets, as if you had written 'A:1', 'A:2', etc. 

Any sheet identifiers in the list that are not defined in
Geo::Coordinates::OSGB::Maps will be (silently) ignored.  

The easting and northing are returned as meters from the grid origin, so that
they are suitable for input to any of the c<format_grid> routines.

=back

=head2 Routines to format (easting, northing) pairs

=over 4

=item format_grid_trad(e,n)

Formats an (easting, northing) pair into traditional `full national grid
reference' with two letters and two sets of three numbers, like this
`SU 387 147'.  If you want to remove the spaces, just apply C<s/\s//g> to it.

    $gridref = format_grid_trad(438710.908, 114792.248); # SU 387 147
    $gridref =~ s/\s//g;                                 # SU387147

If you want the individual components call it in a list context.

    ($sq, $e, $n) = format_grid_trad(438710.908, 114792.248); # ('SU', 387, 147)

This provide a second way to get the reference without spaces:

    $gridref = sprintf "%s%03d%03d", format_grid_trad(438710.908, 114792.248); 

Note that rather than being rounded, the easting and northing are truncated to
hectometers (as the OS system demands), so the grid reference refers to the
lower left corner of the relevant 100m square.

=over 4

=item format_grid_GPS(e,n)

Users who have bought a GPS receiver may initially have been puzzled by the
unfamiliar format used to present coordinates in the British national grid format.
My first Garmin Legend C used to show this sort of thing in the display.

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

Note that rather than being rounded, the easting and northing are truncated to
meters for consistency with traditional grid references. Grid references in
GPS form therefore refer to the lower left corner of the relevant 1m square.

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

If you only want maps from a subset of the defined series, then you can pass 
an optional argument to control which series are included, like this:

   my $gr = format_grid_map(e,n, {series_wanted => 'AB' });

When called like this the list of maps returned with only include sheets from 
series A and B (which are defined to the OS Landrangers and Explorers).

=item format_grid_landranger(e,n)

An alternative to "format_grid_,map(e,n,{series_wanted => 'A'})" except 
that the leading "A:" will be stripped from any sheet names returned.

=back

=head2 Routines to extract (easting, northing) pairs from grid references

=over 4



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

=cut
