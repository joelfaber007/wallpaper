// Step the point into an adjacent tile of wallpaper group p3m1 (orbifold *333).
//
// p3m1 is p3 with mirrors added, placed so that all three classes of 3-fold
// centre lie on a mirror line - the orbifold name puts all three behind the
// star. It is the pair of p31m, which has the same rotations but places its
// mirrors so that two of the three classes miss them.
//
//   a       the length of a lattice vector; the second vector is the first
//           turned through 60 degrees, at (a/2, a*sqrt(3)/2)
//
// The six neighbours of a hexagonal lattice point are +-a1, +-a2 and
// +-(a1 - a2), and stepping to them with equal probability spreads the walk
// equally in every direction. Leaving the third pair out spreads it sqrt(3)
// times further along one axis than the other, which renders as a band.
//
// The rotation has order 3 and the mirror is its own inverse, so neither
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

#define WP_P3M1_STRIDE 5

//     c,                   s,    f,   ca,                   cb
__constant PyroReal wp_p3m1_moves[] = {
     1.0,                 0.0,  1.0,  1.0,                  0.0,   // translation by +a1, along x
     1.0,                 0.0,  1.0, -1.0,                  0.0,   // translation by -a1
     1.0,                 0.0,  1.0,  0.5,  0.86602540378443865,   // translation by +a2, at 60 degrees
     1.0,                 0.0,  1.0, -0.5, -0.86602540378443865,   // translation by -a2
     1.0,                 0.0,  1.0,  0.5, -0.86602540378443865,   // translation by +(a1 - a2), at -60 degrees
     1.0,                 0.0,  1.0, -0.5,  0.86602540378443865,   // translation by -(a1 - a2)
    -0.5, 0.86602540378443865,  1.0,  0.0,                  0.0,   // rotation through 120 degrees about the origin
    -1.0,                 0.0, -1.0,  0.0,                  0.0,   // mirror in the line x = 0
};

PYRO_FUNCTION wallpaper_p3m1(
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
    int m = WP_P3M1_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5) + (u >= cw6));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p3m1_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p3m1_moves[m] * px - wp_p3m1_moves[m + 1] * py
             + wp_p3m1_moves[m + 3] * a;
    zin[i].y = wp_p3m1_moves[m + 1] * px + wp_p3m1_moves[m] * py
             + wp_p3m1_moves[m + 4] * a;
}
