// Step the point into an adjacent tile of wallpaper group cmm (orbifold 2*22).
//
// cmm has the two perpendicular mirror families of pmm on a centred lattice.
// The half turn at the crossing of two mirrors lies on a mirror line, but the
// centring produces a second class of 2-fold centre a quarter of a cell away
// that lies on no mirror at all - the 2 that stands before the star in the
// orbifold name.
//
//   a       the cell width, along the x axis
//   b       the cell height, along the y axis
//
// Mirrors and half turns are their own inverses; the translations are offered
// in both directions so the walk does not drift.

// Every move is a rotation or a reflection followed by a translation, so five
// numbers describe any of them:
//
//   x' = c*px - s*(f*py) + ca*a
//   y' = s*px + c*(f*py) + cb*b
//
// where c + i*s is the unit complex number the move turns the plane by, and f
// is +1 for a direct move and -1 for an opposite one, which flips the plane
// over before turning it. The whole move set is therefore a table, and the
// kernel reads a row of it instead of branching: work items that pick
// different moves still run the same six instructions.
//
// The moves are not drawn with equal probability. A cell that is longer than
// it is tall would otherwise spread the walk further along one axis than the
// other and render as a band, so each move's share is set on the host to make
// the spread equal in every direction. The shares reach the kernel already
// accumulated, in cw0..cw8, and one uniform value picks a move by counting
// how many of them it reaches -- still one path for every work item.

#define WP_CMM_STRIDE 5

//     c,   s,    f,   ca,   cb
__constant PyroReal wp_cmm_moves[] = {
     1.0, 0.0,  1.0,  1.0,  0.0,   // translation by +a, along x
     1.0, 0.0,  1.0, -1.0,  0.0,   // translation by -a
     1.0, 0.0,  1.0,  0.0,  1.0,   // translation by +b, along y
     1.0, 0.0,  1.0,  0.0, -1.0,   // translation by -b
     1.0, 0.0,  1.0,  0.5,  0.5,   // centring translation, to the middle of the cell
     1.0, 0.0,  1.0, -0.5, -0.5,   // the same, backwards
    -1.0, 0.0, -1.0,  0.0,  0.0,   // mirror in the line x = 0
     1.0, 0.0, -1.0,  0.0,  0.0,   // mirror in the line y = 0
    -1.0, 0.0,  1.0,  0.0,  0.0,   // half turn about the origin
    -1.0, 0.0,  1.0,  0.5,  0.5,   // half turn about (a/4, b/4)
};

PYRO_FUNCTION wallpaper_cmm(
    __global PyroXY* zin,
    PyroReal a,
    PyroReal b,
    PyroReal cw0,
    PyroReal cw1,
    PyroReal cw2,
    PyroReal cw3,
    PyroReal cw4,
    PyroReal cw5,
    PyroReal cw6,
    PyroReal cw7,
    PyroReal cw8,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_CMM_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5) + (u >= cw6) + (u >= cw7) + (u >= cw8));

    PyroReal px = zin[i].x;
    PyroReal py = wp_cmm_moves[m + 2] * zin[i].y;

    zin[i].x = wp_cmm_moves[m] * px - wp_cmm_moves[m + 1] * py
             + wp_cmm_moves[m + 3] * a;
    zin[i].y = wp_cmm_moves[m + 1] * px + wp_cmm_moves[m] * py
             + wp_cmm_moves[m + 4] * b;
}
