// The fundamental domain of wallpaper group pg (orbifold xx): fold a point
// into one copy of it and scatter a point to a random copy.
//
// One cell of the lattice holds two copies of it. The domain is the Dirichlet
// domain of a seed point: everything nearer the seed than any other image of
// it under the group. The table below lists the copies in one cell by where
// each holds the seed's image and how the group turns the domain onto it; the
// seed and the copies come from `fold_helpers.copies("pg")`, and the two have
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
// domain itself through `folded`.
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
    PyroXY* folded)
{
    int found = 0;
    PyroReal best = INFINITY;
    PyroReal wx = 0.0;
    PyroReal wy = 0.0;

    for (int k = 0; k < count; ++k) {
        __constant PyroReal* row = copies + WP_COPY_STRIDE * k;
        PyroReal dx = z.x - (cell0.x * row[0] + cell1.x * row[1]);
        PyroReal dy = z.y - (cell0.y * row[0] + cell1.y * row[1]);

        PyroReal u = floor(inv0.x * dx + inv0.y * dy);
        PyroReal v = floor(inv1.x * dx + inv1.y * dy);

        for (int corner = 0; corner < 4; ++corner) {
            PyroReal cu = u + (PyroReal)(corner & 1);
            PyroReal cv = v + (PyroReal)(corner >> 1);
            PyroReal ex = dx - (near0.x * cu + near1.x * cv);
            PyroReal ey = dy - (near0.y * cu + near1.y * cv);
            PyroReal far = ex * ex + ey * ey;

            if (far < best) {
                best = far;
                found = k;
                wx = ex;
                wy = ey;
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

    return found;
}

// z carried by the isometry of the group that takes the domain onto copy k,
// and then by the lattice translation to the cell that holds the point
// (tx, ty).
//
// The isometry is the copy's turn applied about the seed: the step from the
// seed is flipped by f, turned by c + i*s, and set down at the copy's image of
// the seed. The cell is found by rounding (tx, ty) in the coordinates of the
// reduced basis, which gives every cell an equal share of the plane, so a
// (tx, ty) spread evenly over a region picks the cells in it evenly.
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
    __constant PyroReal* row = copies + WP_COPY_STRIDE * k;
    PyroReal c = row[2];
    PyroReal s = row[3];

    PyroReal wx = z.x - (cell0.x * copies[0] + cell1.x * copies[1]);
    PyroReal wy = row[4] * (z.y - (cell0.y * copies[0] + cell1.y * copies[1]));

    PyroReal m = round(inv0.x * tx + inv0.y * ty);
    PyroReal n = round(inv1.x * tx + inv1.y * ty);

    PyroXY out;
    out.x = c * wx - s * wy + cell0.x * row[0] + cell1.x * row[1]
          + near0.x * m + near1.x * n;
    out.y = s * wx + c * wy + cell0.y * row[0] + cell1.y * row[1]
          + near0.y * m + near1.y * n;

    return out;
}

#endif

#define WP_PG_COPIES 2

//     u,   v,    c,   s,    f
__constant PyroReal wp_pg_copies[] = {
    0.25, 0.0,  1.0, 0.0,  1.0,   // the domain itself
    0.75, 0.5, -1.0, 0.0, -1.0,   // flipped over a line at 90 degrees
};

PYRO_FUNCTION wallpaper_pg_fold(
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

    wp_copy_find(zin[i], wp_pg_copies, WP_PG_COPIES,
                 cell0, cell1, near0, near1, inv0, inv1, &folded);

    zin[i] = folded;
}

// Three uniform draws: which copy, then a point spread evenly over the disc
// of radius `reach` about the origin, whose cell the point is moved to.
PYRO_FUNCTION wallpaper_pg_scatter(
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
    int k = min((int)(rng_float(random_state[i]) * WP_PG_COPIES),
                WP_PG_COPIES - 1);
    PyroReal r = reach * sqrt(rng_float(random_state[i]));
    PyroReal t = 2.0 * M_PI_F * rng_float(random_state[i]);

    zin[i] = wp_copy_scatter(zin[i], wp_pg_copies, k,
                             cell0, cell1, near0, near1, inv0, inv1,
                             r * cos(t), r * sin(t));
}
