// Step the point into an adjacent tile of wallpaper group p4m (orbifold *442).
//
// p4m is the square lattice with every symmetry the square has: the quarter
// turn of p4 together with mirrors along the cell sides, along the diagonals
// and halfway between. Every rotation centre lies on a mirror, so the
// orbifold name puts all three of them behind the star.
//
//   a       the side of the square cell
//
// Each mirror is its own inverse and the quarter turn has order 4, so no move
// needs a backwards variant; the translations are offered in both directions
// so the walk does not march off to infinity.

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
// accumulated, in cw0..cw6, and one uniform value picks a move by counting
// how many of them it reaches -- still one path for every work item.

#define WP_P4M_STRIDE 5

//     c,   s,    f,   ca,   cb
__constant PyroReal wp_p4m_moves[] = {
     1.0, 0.0,  1.0,  1.0,  0.0,   // translation by +a, along x
     1.0, 0.0,  1.0, -1.0,  0.0,   // translation by -a
     1.0, 0.0,  1.0,  0.0,  1.0,   // translation by +a, along y
     1.0, 0.0,  1.0,  0.0, -1.0,   // translation by -a
     0.0, 1.0,  1.0,  0.0,  0.0,   // quarter turn about the origin
     1.0, 0.0, -1.0,  0.0,  0.0,   // mirror in the line y = 0
     0.0, 1.0, -1.0,  0.0,  0.0,   // mirror in the diagonal y = x
    -1.0, 0.0, -1.0,  1.0,  0.0,   // mirror in the line x = a/2
};

PYRO_FUNCTION wallpaper_p4m(
    __global PyroXY* zin,
    PyroReal a,
    PyroReal cw0,
    PyroReal cw1,
    PyroReal cw2,
    PyroReal cw3,
    PyroReal cw4,
    PyroReal cw5,
    PyroReal cw6,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_P4M_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5) + (u >= cw6));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p4m_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p4m_moves[m] * px - wp_p4m_moves[m + 1] * py
             + wp_p4m_moves[m + 3] * a;
    zin[i].y = wp_p4m_moves[m + 1] * px + wp_p4m_moves[m] * py
             + wp_p4m_moves[m + 4] * a;
}
