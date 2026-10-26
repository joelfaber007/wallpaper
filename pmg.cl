// Step the point into an adjacent tile of wallpaper group pmg (orbifold 22*).
//
// pmg is a rectangular lattice with mirrors in one direction only and a glide
// at right angles to them. The half turns sit off the mirror lines, midway
// between them, which is why the orbifold name puts its two rotation centres
// before the star rather than on it.
//
//   a       the cell width, along the x axis
//   b       the cell height, along the y axis
//
// The mirror and the half turn are their own inverses. The glide is not, but
// its inverse is the glide composed with the -a translation, which is already
// among the moves.

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
// accumulated, in cw0..cw5, and one uniform value picks a move by counting
// how many of them it reaches -- still one path for every work item.

#define WP_PMG_STRIDE 5

//     c,   s,    f,   ca,   cb
__constant PyroReal wp_pmg_moves[] = {
     1.0, 0.0,  1.0,  1.0,  0.0,   // translation by +a, along x
     1.0, 0.0,  1.0, -1.0,  0.0,   // translation by -a
     1.0, 0.0,  1.0,  0.0,  1.0,   // translation by +b, along y
     1.0, 0.0,  1.0,  0.0, -1.0,   // translation by -b
    -1.0, 0.0, -1.0,  0.0,  0.0,   // mirror in the line x = 0
     1.0, 0.0, -1.0,  0.5,  0.0,   // glide along the axis y = 0
    -1.0, 0.0,  1.0,  0.5,  0.0,   // half turn about (a/4, 0)
};

PYRO_FUNCTION wallpaper_pmg(
    __global PyroXY* zin,
    PyroReal a,
    PyroReal b,
    PyroReal cw0,
    PyroReal cw1,
    PyroReal cw2,
    PyroReal cw3,
    PyroReal cw4,
    PyroReal cw5,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_PMG_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5));

    PyroReal px = zin[i].x;
    PyroReal py = wp_pmg_moves[m + 2] * zin[i].y;

    zin[i].x = wp_pmg_moves[m] * px - wp_pmg_moves[m + 1] * py
             + wp_pmg_moves[m + 3] * a;
    zin[i].y = wp_pmg_moves[m + 1] * px + wp_pmg_moves[m] * py
             + wp_pmg_moves[m + 4] * b;
}
