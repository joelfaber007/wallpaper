// The fundamental domain of wallpaper group pmm (orbifold *2222): fold a point
// into one copy of it, scatter a point to a random copy, and carry a point
// into it and back out to where it came from.
//
// One cell of the lattice holds four copies of it. The domain is the Dirichlet
// domain of a seed point: everything nearer the seed than any other image of
// it under the group. The table below lists the copies in one cell by where
// each holds the seed's image and how the group turns the domain onto it; the
// seed and the copies come from `fold_helpers.copies("pmm")`, and the two have
// to match row for row.
//
// The table does not depend on the lattice parameters. Every turn here is a
// rotation or a reflection in the plane, whatever the cell's shape, and (u, v)
// are lattice coordinates, which the kernel places with the cell it is handed.

#ifndef WP_COPY_HELPERS
#define WP_COPY_HELPERS

// This block is repeated verbatim in every <group>_fold.cl, and the copies
// have to stay identical. A package is compiled as one translation unit, so
// the guard keeps whichever copy comes first and drops the rest; the copies
// are there because a package cannot declare a library of its own the way the
// core does, and keeping the block in a single file would break the day a
// plugin sorting ahead of that one wanted it.

// Each copy of the fundamental domain is a row of five numbers in its group's
// table: (u, v), the image of the seed that the copy holds, in the lattice
// coordinates of cell0 and cell1; then (c, s, f), the turn that carries the
// domain onto the copy -- flipped over when f is -1, then turned by c + i*s.
#define WP_COPY_STRIDE 5

// Which copy of the fundamental domain holds z, with z carried back into the
// domain itself through `folded`, and the lattice translation from that
// copy's place in the table to where it holds z through `shift`.
//
// The domain is everything nearer the seed than any other image of it, so the
// copy holding z is the one whose image of the seed lies nearest. Every image
// repeats in every cell, and the nearest repeat is found by taking the step to
// it into the coordinates of a reduced basis -- near0 and near1, whose inverse
// has the rows inv0 and inv1 -- and trying the four corners of the cell it
// falls in. That is exact because a reduced cell is split by its shorter
// diagonal into two triangles with no obtuse angle.
//
// The point is carried back by undoing the copy's turn: the step from the
// image is turned back by c - i*s, unflipped by f, and set down at the seed,
// which is the image the first row holds.
int wp_copy_find(
    PyroXY z,
    __constant PyroReal* copies,
    int count,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY near0,
    PyroXY near1,
    PyroXY inv0,
    PyroXY inv1,
    PyroXY* folded,
    PyroXY* shift)
{
    int found = 0;
    PyroReal best = INFINITY;
    PyroReal wx = 0.0;
    PyroReal wy = 0.0;
    PyroReal tx = 0.0;
    PyroReal ty = 0.0;

    for (int k = 0; k < count; ++k) {
        __constant PyroReal* row = copies + WP_COPY_STRIDE * k;
        PyroReal dx = z.x - (cell0.x * row[0] + cell1.x * row[1]);
        PyroReal dy = z.y - (cell0.y * row[0] + cell1.y * row[1]);

        PyroReal u = floor(inv0.x * dx + inv0.y * dy);
        PyroReal v = floor(inv1.x * dx + inv1.y * dy);

        for (int corner = 0; corner < 4; ++corner) {
            PyroReal cu = u + (PyroReal)(corner & 1);
            PyroReal cv = v + (PyroReal)(corner >> 1);
            PyroReal sx = near0.x * cu + near1.x * cv;
            PyroReal sy = near0.y * cu + near1.y * cv;
            PyroReal ex = dx - sx;
            PyroReal ey = dy - sy;
            PyroReal far = ex * ex + ey * ey;

            if (far < best) {
                best = far;
                found = k;
                wx = ex;
                wy = ey;
                tx = sx;
                ty = sy;
            }
        }
    }

    __constant PyroReal* row = copies + WP_COPY_STRIDE * found;
    PyroReal c = row[2];
    PyroReal s = row[3];
    PyroReal f = row[4];

    folded->x = cell0.x * copies[0] + cell1.x * copies[1]
              + c * wx + s * wy;
    folded->y = cell0.y * copies[0] + cell1.y * copies[1]
              + f * (c * wy - s * wx);

    shift->x = tx;
    shift->y = ty;

    return found;
}

// z carried by the isometry of the group that takes the domain onto copy k,
// and then by the lattice translation `shift`.
//
// The isometry is the copy's turn applied about the seed: the step from the
// seed is flipped by f, turned by c + i*s, and set down at the copy's image of
// the seed. It undoes wp_copy_find: a point that folded to `folded` with copy
// k and `shift` is carried by them back to where it was.
PyroXY wp_copy_carry(
    PyroXY z,
    __constant PyroReal* copies,
    int k,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY shift)
{
    __constant PyroReal* row = copies + WP_COPY_STRIDE * k;
    PyroReal c = row[2];
    PyroReal s = row[3];

    PyroReal wx = z.x - (cell0.x * copies[0] + cell1.x * copies[1]);
    PyroReal wy = row[4] * (z.y - (cell0.y * copies[0] + cell1.y * copies[1]));

    PyroXY out;
    out.x = c * wx - s * wy + cell0.x * row[0] + cell1.x * row[1] + shift.x;
    out.y = s * wx + c * wy + cell0.y * row[0] + cell1.y * row[1] + shift.y;

    return out;
}

// z carried by the isometry of the group that takes the domain onto copy k,
// and then by the lattice translation to the cell that holds the point
// (tx, ty).
//
// The cell is found by rounding (tx, ty) in the coordinates of the reduced
// basis, which gives every cell an equal share of the plane, so a (tx, ty)
// spread evenly over a region picks the cells in it evenly.
PyroXY wp_copy_scatter(
    PyroXY z,
    __constant PyroReal* copies,
    int k,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY near0,
    PyroXY near1,
    PyroXY inv0,
    PyroXY inv1,
    PyroReal tx,
    PyroReal ty)
{
    PyroReal m = round(inv0.x * tx + inv0.y * ty);
    PyroReal n = round(inv1.x * tx + inv1.y * ty);

    PyroXY shift;
    shift.x = near0.x * m + near1.x * n;
    shift.y = near0.y * m + near1.y * n;

    return wp_copy_carry(z, copies, k, cell0, cell1, shift);
}

// The tile wp_copy_find took a point from, kept in `tile` for the exit
// function to carry the point back to: the copy, whether that copy is the
// domain flipped over, and the lattice translation as whole steps (m, n) of
// cell0 and cell1. The rows cinv0 and cinv1 are the inverse of that basis.
void wp_tile_store(
    __global WallpaperTile* tile,
    __constant PyroReal* copies,
    int k,
    PyroXY shift,
    PyroXY cinv0,
    PyroXY cinv1)
{
    tile->copy = k;
    tile->flip = (int)copies[WP_COPY_STRIDE * k + 4];
    tile->m = (int)round(cinv0.x * shift.x + cinv0.y * shift.y);
    tile->n = (int)round(cinv1.x * shift.x + cinv1.y * shift.y);
}

// The copy `tile` holds, kept within the `count` copies of the group reading
// it, since the tile may have been stored by another group's enter function.
int wp_tile_copy(__global WallpaperTile* tile, int count)
{
    return clamp(tile->copy, 0, count - 1);
}

// The lattice translation `tile` holds, in the plane.
PyroXY wp_tile_shift(__global WallpaperTile* tile, PyroXY cell0, PyroXY cell1)
{
    PyroXY shift;
    shift.x = cell0.x * tile->m + cell1.x * tile->n;
    shift.y = cell0.y * tile->m + cell1.y * tile->n;

    return shift;
}

#endif

#define WP_PMM_COPIES 4

//     u,    v,    c,   s,    f
__constant PyroReal wp_pmm_copies[] = {
    0.25, 0.25,  1.0, 0.0,  1.0,   // the domain itself
    0.75, 0.75, -1.0, 0.0,  1.0,   // turned through 180 degrees
    0.25, 0.75,  1.0, 0.0, -1.0,   // flipped over a line at 0 degrees
    0.75, 0.25, -1.0, 0.0, -1.0,   // flipped over a line at 90 degrees
};

PYRO_FUNCTION wallpaper_pmm_fold(
    __global PyroXY* zin,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY near0,
    PyroXY near1,
    PyroXY inv0,
    PyroXY inv1)
{
    int i = get_global_id(0);
    PyroXY folded;
    PyroXY shift;

    wp_copy_find(zin[i], wp_pmm_copies, WP_PMM_COPIES,
                 cell0, cell1, near0, near1, inv0, inv1, &folded, &shift);

    zin[i] = folded;
}

// Three uniform draws: which copy, then a point spread evenly over the disc
// of radius `reach` about the origin, whose cell the point is moved to.
PYRO_FUNCTION wallpaper_pmm_scatter(
    __global PyroXY* zin,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY near0,
    PyroXY near1,
    PyroXY inv0,
    PyroXY inv1,
    PyroReal reach,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    int k = min((int)(rng_float(random_state[i]) * WP_PMM_COPIES),
                WP_PMM_COPIES - 1);
    PyroReal r = reach * sqrt(rng_float(random_state[i]));
    PyroReal t = 2.0 * M_PI_F * rng_float(random_state[i]);

    zin[i] = wp_copy_scatter(zin[i], wp_pmm_copies, k,
                             cell0, cell1, near0, near1, inv0, inv1,
                             r * cos(t), r * sin(t));
}

// Fold the point into the fundamental domain exactly as the fold does, and
// keep in `tile` which copy of the domain, in which cell, it was taken from.
PYRO_FUNCTION wallpaper_pmm_enter(
    __global PyroXY* zin,
    __global WallpaperTile* tile,
    PyroXY cell0,
    PyroXY cell1,
    PyroXY near0,
    PyroXY near1,
    PyroXY inv0,
    PyroXY inv1,
    PyroXY cinv0,
    PyroXY cinv1)
{
    int i = get_global_id(0);
    PyroXY folded;
    PyroXY shift;

    int k = wp_copy_find(zin[i], wp_pmm_copies, WP_PMM_COPIES,
                         cell0, cell1, near0, near1, inv0, inv1,
                         &folded, &shift);

    zin[i] = folded;
    wp_tile_store(&tile[i], wp_pmm_copies, k, shift, cinv0, cinv1);
}

// Carry the point out of the fundamental domain to the copy and cell `tile`
// holds, which undoes the enter function that stored them.
PYRO_FUNCTION wallpaper_pmm_exit(
    __global PyroXY* zin,
    __global WallpaperTile* tile,
    PyroXY cell0,
    PyroXY cell1)
{
    int i = get_global_id(0);
    int k = wp_tile_copy(&tile[i], WP_PMM_COPIES);

    zin[i] = wp_copy_carry(zin[i], wp_pmm_copies, k, cell0, cell1,
                           wp_tile_shift(&tile[i], cell0, cell1));
}

// Branch on which copy of the fundamental domain the tile an enter function
// took the point from is. The outputs list the copies in the order of the
// table, so the copy's row is the output taken.
PYRO_FUNCTION wallpaper_pmm_tile_copy(
    __global WallpaperTile* tile,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    active_output_ids[i] = wp_tile_copy(&tile[i], WP_PMM_COPIES);
}
