# Design ideas and notes

## Map data

All the source data for map series is in the maps/ directory.

Everything here is experimental.

For each series there are (currently) two files

- catalogue which defines 
  -- an index number for each map (unique to this project)
  -- the sheet number for the map - not necessarily an integer
  -- the sheet title
  -- the current ISBN number for maps that have them

- sheet-polygons which has
  -- index numbers which match the catalogue)
  -- sheet number (matching the catalogue)
  -- flag - an integer to show the status of the entry
  -- MULTIPOLYGON in WKT format

There are two files for each series, and one line in each of the files for each
map in the series.  The data format for the sheet polygons is Well Known Text
(as defined in Wikipedia).  The set of polygons for each map is defined as a
MULTIPOLYGON; ie a list of POLYGONS.  There are no holes in any of the
polygons.  A missing polygon list is recorded as "EMPTY" (this is part of WKT).

The units are metres from the false point of origin (which is some 5 miles west
of the Scillies).  So the south west corner of Landranger sheet 204, which has
traditional grid reference SW 720 140 is defined in this data as "172000
14000".  This is essentially what "parse_grid" returns. No leading zeros
needed.

The polygon should start at the south west corner of the sheet and be recorded
clockwise.  WKT insists that the first pair is repeated at the end to close the
polygon. So a simple 40km square Landranger sheet with no insets or extensions,
such as Sheet 152, whose SW corner is at SP 530 300 is recorded as

    (((453000 230000, 493000 230000, 493000 270000, 453000 270000, 453000 230000)))

If the sheet boundary is more complicated that a square record a coordinate
pair at each corner.  Include extensions - where the coloured printing spills
over the neat edge - as part of the main polygon in the appropriate place,
always moving anticlockwise.  Extensions don’t have to be rectilinear but they
are made up of straight lines.  Ignore extensions for administrative boundaries
and labels.  If in doubt use common sense.  

If an inset is drawn on the map sheet with its own grid margin then record it
as a separate polygon following the WKT format.

The first (and last) pair should always be the SW corner, if an extension
affects the SW corner, start and end with the regular corner pair even if they
are technically redundant.  This allows me to find the SW corners currently
defined for the Landranger maps easily.  In the Landranger series this only affect sheet 162.





## Transformations

desired transformations are 

- from GPS LL data to and from OSGB grid
- from OSGB36 grid to from UK LL references (Airy36) (for checking on maps, testing)


For OSGB36 grid to Airy1830 LL we just need to do xy_to_ll with
right parms

and vice versa

For OSGB36 grid to WGS84 (ETRS89) we have to transform grid
(backwards) with OSTN02 to WGS84 pseudo grid then use xy_to_ll to
get to ll

From WGS84 to OSGB36 grid, we use ll_to_xy (with WGS84 shape) to get
to ps-grid then OSTN02 to get to OSGB36 grid


    grid_to_ll   (e,n, reference)
    grid_to_ll  (e, n, [OSGB36])        # default to OSGB36
    grid_to_ll  (e, n, [ETRS89])

    ll_to_grid (lat, lon, [OSGB36])
    ll_to_grid (lat, lon, [ETRS89])

    OSGB36_to_ETRS89 (e,n)
    ETRS89_to_OSGB36 (e,n)

    (lat,lon) = OSGB_to_GPX(e,n)
              = grid_to_ll(OSGB36_to_ETRS89($e,$n),{shape => ETRS89});

    (e,n)     = GPX_to_OSGB(lat,lon)
              = ETRS89_to_OSGB36(ll_to_grid(lat,lon,{shape => ETRS89}));

    (lat,lon) = grid_to_ll (e,n,{shape => "OSGB36"});
    (lat,lon) = grid_to_ll (e,n);

    (e,n)     = ll_to_grid (lat,lon,{shape=>"OSGB36"});
    (e,n)     = ll_to_grid (lat,lon)


We can also do the (approximate) Molodensky transformation used in
Garmin GPS.  To show BNG the Garmin takes WGS84 coordinates, does a
Molo to transform (approx) to Airy 1830, and does the equivalent of
ll_to_grid using OSGB36 shape.

         WGS84                OSGB36

    LL     A-------Molo---------->a
           |                      |
           |                      |
          ll2grid               ll2grid
           |                      |
           |                      |
           V                      V
    Grid   *------OSTN02 -----> B~b

B and b are approx equal.
B is definitive.  b is what you'll see on your eTrex.

Note that of the intermediate results ("WGS84 grid" is meaningless,
but OSGB36 LL is what is shown around the edges of OS maps).
