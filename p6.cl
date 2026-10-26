// Step the point into an adjacent tile of wallpaper group p6 (orbifold 632).
//
// p6 is a hexagonal lattice together with a rotation through 60 degrees. Its
// powers give the 3-fold and 2-fold centres as well, and they sit at three
// inequivalent places - 6-fold at the lattice points, 3-fold at the triangle
// centres, 2-fold at the midpoints of the cell edges - which is what the
// orbifold name 632 counts.
//
//   a       the length of a lattice vector; the second vector is the first
//           turned through 60 degrees, at (a/2, a*sqrt(3)/2)
//
// The six neighbours of a hexagonal lattice point are +-a1, +-a2 and
// +-(a1 - a2), and stepping to them with equal probability spreads the walk
// equally in every direction. Leaving the third pair out spreads it sqrt(3)
// times further along one axis than the other, which renders as a band.
//
// The rotation has order 6, so iterating it reaches its inverse; the
// translations are offered in both directions so the walk does not march off
// to infinity.

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

#define WP_P6_STRIDE 5

//    c,                   s,   f,   ca,                   cb
__constant PyroReal wp_p6_moves[] = {
    1.0,                 0.0, 1.0,  1.0,                  0.0,   // translation by +a1, along x
    1.0,                 0.0, 1.0, -1.0,                  0.0,   // translation by -a1
    1.0,                 0.0, 1.0,  0.5,  0.86602540378443865,   // translation by +a2, at 60 degrees
    1.0,                 0.0, 1.0, -0.5, -0.86602540378443865,   // translation by -a2
    1.0,                 0.0, 1.0,  0.5, -0.86602540378443865,   // translation by +(a1 - a2), at -60 degrees
    1.0,                 0.0, 1.0, -0.5,  0.86602540378443865,   // translation by -(a1 - a2)
    0.5, 0.86602540378443865, 1.0,  0.0,                  0.0,   // rotation through 60 degrees about the origin
};

PYRO_FUNCTION wallpaper_p6(
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
    int m = WP_P6_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p6_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p6_moves[m] * px - wp_p6_moves[m + 1] * py
             + wp_p6_moves[m + 3] * a;
    zin[i].y = wp_p6_moves[m + 1] * px + wp_p6_moves[m] * py
             + wp_p6_moves[m + 4] * a;
}
