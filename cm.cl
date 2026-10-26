// Step the point into an adjacent tile of wallpaper group cm (orbifold *x).
//
// cm has the same mirrors as pm, but on a centred lattice: as well as the
// corners of the rectangle, the centre of every cell is a lattice point. That
// extra half-cell translation carries each mirror onto a glide halfway
// between the mirror lines, so the group has both a mirror and a glide that
// is not a mirror composed with a lattice translation - the star and the x of
// the orbifold name.
//
//   a       the cell width, along the x axis
//   b       the cell height, along the y axis
//
// Both directions of the centring translation and of the glide are offered,
// for the same reason the cell translations are: so the walk does not drift.
// A walk that could only glide forward would climb b/2 with every glide.

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
// accumulated, in cw0..cw7, and one uniform value picks a move by counting
// how many of them it reaches -- still one path for every work item.

#define WP_CM_STRIDE 5

//     c,   s,    f,   ca,   cb
__constant PyroReal wp_cm_moves[] = {
     1.0, 0.0,  1.0,  1.0,  0.0,   // translation by +a, along x
     1.0, 0.0,  1.0, -1.0,  0.0,   // translation by -a
     1.0, 0.0,  1.0,  0.0,  1.0,   // translation by +b, along y
     1.0, 0.0,  1.0,  0.0, -1.0,   // translation by -b
     1.0, 0.0,  1.0,  0.5,  0.5,   // centring translation, to the middle of the cell
     1.0, 0.0,  1.0, -0.5, -0.5,   // the same, backwards
    -1.0, 0.0, -1.0,  0.0,  0.0,   // mirror in the line x = 0
    -1.0, 0.0, -1.0,  0.5,  0.5,   // glide along the axis x = a/4
    -1.0, 0.0, -1.0,  0.5, -0.5,   // the same, backwards
};

PYRO_FUNCTION wallpaper_cm(
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
    __global PyroRNG* random_state)
{
    int i = get_global_id(0);
    PyroReal u = rng_float(random_state[i]);
    int m = WP_CM_STRIDE * (
        (u >= cw0) + (u >= cw1) + (u >= cw2) + (u >= cw3) + (u >= cw4) +
        (u >= cw5) + (u >= cw6) + (u >= cw7));

    PyroReal px = zin[i].x;
    PyroReal py = wp_cm_moves[m + 2] * zin[i].y;

    zin[i].x = wp_cm_moves[m] * px - wp_cm_moves[m + 1] * py
             + wp_cm_moves[m + 3] * a;
    zin[i].y = wp_cm_moves[m + 1] * px + wp_cm_moves[m] * py
             + wp_cm_moves[m + 4] * b;
}
