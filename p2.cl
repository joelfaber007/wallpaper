// Step the point into an adjacent tile of wallpaper group p2 (orbifold 2222).
//
// p2 is an oblique lattice together with a half turn. The rotation centres
// sit at the lattice points, at the midpoints of the lattice vectors and at
// the centres of the tiles - four classes in all, which is what the orbifold
// name 2222 counts.
//
//   a1      the first lattice vector, along the x axis
//   a2      the second, at angle gamma to the first
//
// A half turn is its own inverse, so the two rotations need no backwards
// variant; the translations are offered in both directions so the walk does
// not march off to infinity.

// Every move is a rotation or a reflection followed by a translation, so five
// numbers describe any of them:
//
//   x' = c*px - s*(f*py) + ca*a1.x + cb*a2.x
//   y' = s*px + c*(f*py) + ca*a1.y + cb*a2.y
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

#define WP_P2_STRIDE 5

//     c,   s,   f,   ca,   cb
__constant PyroReal wp_p2_moves[] = {
     1.0, 0.0, 1.0,  1.0,  0.0,   // translation by +a1
     1.0, 0.0, 1.0, -1.0,  0.0,   // translation by -a1
     1.0, 0.0, 1.0,  0.0,  1.0,   // translation by +a2
     1.0, 0.0, 1.0,  0.0, -1.0,   // translation by -a2
    -1.0, 0.0, 1.0,  0.0,  0.0,   // half turn about the origin
    -1.0, 0.0, 1.0,  1.0,  0.0,   // half turn about the midpoint of a1
};

PYRO_FUNCTION wallpaper_p2(
    __global PyroXY* zin,
    PyroXY a1,
    PyroXY a2,
    PyroReal cw0,
    PyroReal cw1,
    PyroReal cw2,
    PyroReal cw3,
    PyroReal cw4,
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_P2_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p2_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p2_moves[m] * px - wp_p2_moves[m + 1] * py
             + wp_p2_moves[m + 3] * a1.x + wp_p2_moves[m + 4] * a2.x;
    zin[i].y = wp_p2_moves[m + 1] * px + wp_p2_moves[m] * py
             + wp_p2_moves[m + 3] * a1.y + wp_p2_moves[m + 4] * a2.y;
}
