// Step the point into an adjacent tile of wallpaper group p4g (orbifold 4*2).
//
// p4g has the quarter turns of p4, but its mirrors run along the diagonals of
// the cell and pass through none of the 4-fold centres - the 4 stands before
// the star for that reason, and only the 2-fold centres, which do lie on a
// mirror, come after it. The result reads as a pinwheel rather than as a grid
// of reflections.
//
//   a       the side of the square cell
//
// The quarter turn has order 4 and the mirror is its own inverse; the glide
// inverts to itself composed with a lattice translation already among the
// moves.

// Every move is a rotation or a reflection followed by a translation, so five
// numbers describe any of them:
//
//   x' = c*px - s*(f*py) + ca*a
//   y' = s*px + c*(f*py) + cb*a
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

#define WP_P4G_STRIDE 5

//     c,   s,    f,   ca,   cb
__constant PyroReal wp_p4g_moves[] = {
     1.0, 0.0,  1.0,  1.0,  0.0,   // translation by +a, along x
     1.0, 0.0,  1.0, -1.0,  0.0,   // translation by -a
     1.0, 0.0,  1.0,  0.0,  1.0,   // translation by +a, along y
     1.0, 0.0,  1.0,  0.0, -1.0,   // translation by -a
     0.0, 1.0,  1.0,  0.0,  0.0,   // quarter turn about the origin
     0.0, 1.0, -1.0,  0.5, -0.5,   // diagonal mirror through (a/2, 0)
    -1.0, 0.0, -1.0,  0.5,  0.5,   // glide along the axis x = a/4
};

PYRO_FUNCTION wallpaper_p4g(
    __global PyroXY* zin,
    PyroReal a,
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
    int m = WP_P4G_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p4g_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p4g_moves[m] * px - wp_p4g_moves[m + 1] * py
             + wp_p4g_moves[m + 3] * a;
    zin[i].y = wp_p4g_moves[m + 1] * px + wp_p4g_moves[m] * py
             + wp_p4g_moves[m + 4] * a;
}
