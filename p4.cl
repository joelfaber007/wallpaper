// Step the point into an adjacent tile of wallpaper group p4 (orbifold 442).
//
// p4 is a square lattice together with a quarter turn. There are two
// inequivalent 4-fold centres - the lattice points and the cell centres - and
// the 2-fold centres at the midpoints of the cell sides, which is what the
// orbifold name 442 counts.
//
//   a       the side of the square cell
//
// A quarter turn has order 4, so iterating it reaches its inverse and no
// backwards variant is needed; the translations are offered in both
// directions so the walk does not march off to infinity.

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
// accumulated, in cw0..cw4, and one uniform value picks a move by counting
// how many of them it reaches -- still one path for every work item.

#define WP_P4_STRIDE 5

//    c,   s,   f,   ca,   cb
__constant PyroReal wp_p4_moves[] = {
    1.0, 0.0, 1.0,  1.0,  0.0,   // translation by +a, along x
    1.0, 0.0, 1.0, -1.0,  0.0,   // translation by -a
    1.0, 0.0, 1.0,  0.0,  1.0,   // translation by +a, along y
    1.0, 0.0, 1.0,  0.0, -1.0,   // translation by -a
    0.0, 1.0, 1.0,  0.0,  0.0,   // quarter turn about the origin
    0.0, 1.0, 1.0,  1.0,  0.0,   // quarter turn about the cell centre
};

PYRO_FUNCTION wallpaper_p4(
    __global PyroXY* zin,
    PyroReal a,
    PyroReal cw0,
    PyroReal cw1,
    PyroReal cw2,
    PyroReal cw3,
    PyroReal cw4,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_P4_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p4_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p4_moves[m] * px - wp_p4_moves[m + 1] * py
             + wp_p4_moves[m + 3] * a;
    zin[i].y = wp_p4_moves[m + 1] * px + wp_p4_moves[m] * py
             + wp_p4_moves[m + 4] * a;
}
