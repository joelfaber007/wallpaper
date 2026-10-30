// Step the point into an adjacent tile of wallpaper group p1 (orbifold o).
//
// p1 is the group of an oblique lattice and nothing else: no rotation, no
// mirror, no glide. Its only steps are the translations to the six
// neighbouring tiles.
//
//   a1      the shortest lattice vector
//   a2      the shortest vector independent of it, at 90 degrees or more
//           to a1, so that a1 + a2 is the shorter diagonal of the cell
//
// a1 and a2 alone generate the group; a1 + a2 is there so the walk can
// spread evenly. Two directions can only be balanced against each other,
// and on a lattice whose vectors are not perpendicular that leaves the
// spread an ellipse. With the third the shares can be set to make it round
// on every lattice: the six steps are the hexagonal neighbours of a
// hexagonal lattice, and on a rectangular one the diagonal gets no share.
//
// Both directions of each translation are offered so the walk is
// reversible. A single direction generates the group just as well, but a
// point that only ever stepped +a1 and +a2 would march off to infinity
// instead of exploring the tiling.

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

#define WP_P1_STRIDE 5

//    c,   s,   f,   ca,   cb
__constant PyroReal wp_p1_moves[] = {
    1.0, 0.0, 1.0,  1.0,  0.0,   // translation by +a1
    1.0, 0.0, 1.0, -1.0,  0.0,   // translation by -a1
    1.0, 0.0, 1.0,  0.0,  1.0,   // translation by +a2
    1.0, 0.0, 1.0,  0.0, -1.0,   // translation by -a2
    1.0, 0.0, 1.0,  1.0,  1.0,   // translation by +(a1 + a2)
    1.0, 0.0, 1.0, -1.0, -1.0,   // translation by -(a1 + a2)
};

PYRO_FUNCTION wallpaper_p1(
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
    int m = WP_P1_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4));

    PyroReal px = zin[i].x;
    PyroReal py = wp_p1_moves[m + 2] * zin[i].y;

    zin[i].x = wp_p1_moves[m] * px - wp_p1_moves[m + 1] * py
             + wp_p1_moves[m + 3] * a1.x + wp_p1_moves[m + 4] * a2.x;
    zin[i].y = wp_p1_moves[m + 1] * px + wp_p1_moves[m] * py
             + wp_p1_moves[m + 3] * a1.y + wp_p1_moves[m + 4] * a2.y;
}
