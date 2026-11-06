// One tile of a Cairo pentagonal tiling, with the symmetry of wallpaper group
// p4g (orbifold 4*2): fold a point into it, and carry a point into it and back
// out to where it came from.
//
// The tile is the Dirichlet domain of a seed on one of the group's mirrors:
// everything nearer the seed than any other image of it under the group. The
// mirror holds the seed still, so the seed has four images in a cell rather
// than eight, and its domain is two copies of the fundamental domain joined
// across that mirror. For any seed between the 2-fold centre (0, a/2) and the
// point (a/4, a/4) of the mirror x + y = a/2, that domain is a pentagon, and
// the domains of all the seed's images are the tiles of a Cairo tiling.
//
// The quarter turns about the origin carry the seed onto its four images in a
// cell. They reach every image, since the mirror that holds the seed still is
// one of the flips: so the fold turns the point but never flips it, and the
// table holds nothing but the four turns.

#define WP_P4G_CAIRO_TURNS 4

//     c,    s
__constant PyroReal wp_p4g_cairo_turns[] = {
     1.0,  0.0,   // the tile itself
     0.0,  1.0,   // turned through 90 degrees
    -1.0,  0.0,   // turned through 180 degrees
     0.0, -1.0,   // turned through 270 degrees
};

// Which tile holds z, with z carried back into the first tile through
// `folded`, and the lattice translation from that tile's place in the cell
// at the origin to where it holds z through (m, n), in whole steps of a.
//
// The tile holding z is the one whose image of the seed lies nearest. The
// lattice is square, so the nearest repeat of an image is found by rounding
// each coordinate of the step to it. The point is carried back by turning
// the step from that image back by c - i*s and setting it down at the seed.
int wp_cairo_find(
    PyroXY z,
    PyroReal a,
    PyroReal seed,
    PyroXY* folded,
    int* m,
    int* n)
{
    PyroReal sx = a * seed;
    PyroReal sy = a * (0.5 - seed);

    int found = 0;
    PyroReal best = INFINITY;
    PyroReal wx = 0.0;
    PyroReal wy = 0.0;
    PyroReal tu = 0.0;
    PyroReal tv = 0.0;

    for (int k = 0; k < WP_P4G_CAIRO_TURNS; ++k) {
        PyroReal c = wp_p4g_cairo_turns[2 * k];
        PyroReal s = wp_p4g_cairo_turns[2 * k + 1];

        PyroReal dx = z.x - (c * sx - s * sy);
        PyroReal dy = z.y - (s * sx + c * sy);

        PyroReal u = round(dx / a);
        PyroReal v = round(dy / a);

        dx -= a * u;
        dy -= a * v;

        PyroReal far = dx * dx + dy * dy;

        if (far < best) {
            best = far;
            found = k;
            wx = dx;
            wy = dy;
            tu = u;
            tv = v;
        }
    }

    PyroReal c = wp_p4g_cairo_turns[2 * found];
    PyroReal s = wp_p4g_cairo_turns[2 * found + 1];

    folded->x = sx + c * wx + s * wy;
    folded->y = sy + c * wy - s * wx;
    *m = (int)tu;
    *n = (int)tv;

    return found;
}

PYRO_FUNCTION wallpaper_p4g_cairo_fold(
    __global PyroXY* zin,
    PyroReal a,
    PyroReal seed)
{
    int i = get_global_id(0);
    PyroXY folded;
    int m;
    int n;

    wp_cairo_find(zin[i], a, seed, &folded, &m, &n);

    zin[i] = folded;
}

// Fold the point into the first tile exactly as the fold does, and keep in
// `tile` which turn of it, in which cell, the point was taken from.
PYRO_FUNCTION wallpaper_p4g_cairo_enter(
    __global PyroXY* zin,
    __global WallpaperTile* tile,
    PyroReal a,
    PyroReal seed)
{
    int i = get_global_id(0);
    PyroXY folded;
    int m;
    int n;

    int k = wp_cairo_find(zin[i], a, seed, &folded, &m, &n);

    zin[i] = folded;
    tile[i].copy = k;
    tile[i].flip = 1;
    tile[i].m = m;
    tile[i].n = n;
}

// Carry the point out of the first tile to the turn and cell `tile` holds,
// which undoes the enter function that stored them.
//
// The turn is about the origin and takes the seed onto its image, so the
// seed drops out: the point is turned by c + i*s and moved by (m, n) steps of
// a. The turn is kept within the four this tiling has, since the tile may
// have been stored by another group's enter function.
PYRO_FUNCTION wallpaper_p4g_cairo_exit(
    __global PyroXY* zin,
    __global WallpaperTile* tile,
    PyroReal a)
{
    int i = get_global_id(0);
    int k = clamp(tile[i].copy, 0, WP_P4G_CAIRO_TURNS - 1);
    PyroReal c = wp_p4g_cairo_turns[2 * k];
    PyroReal s = wp_p4g_cairo_turns[2 * k + 1];
    PyroXY z = zin[i];

    zin[i].x = c * z.x - s * z.y + a * tile[i].m;
    zin[i].y = s * z.x + c * z.y + a * tile[i].n;
}

// Branch on which of the four turns of the pentagon the tile an enter
// function took the point from is. The outputs list the turns in order, so
// the number of quarter turns is the output taken.
PYRO_FUNCTION wallpaper_p4g_cairo_tile_copy(
    __global WallpaperTile* tile,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    active_output_ids[i] = clamp(tile[i].copy, 0, WP_P4G_CAIRO_TURNS - 1);
}
