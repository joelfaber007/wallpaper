// Decide which of wallpaper group p6's special positions holds the point.
//
// p6 (orbifold 632) has three classes of rotation centre (one 6-fold, one
// 3-fold, one 2-fold). Those are the only places the group itself singles out:
// everywhere else the point is held by nothing but the translations, which is
// what the last output means.
//
// The positions are worked out on the host from the same move table the
// p6 transform draws its steps from, so what this decides about cannot come
// apart from what that tiles with. The kernel is handed them already placed.
//
// A class of centre is a set the group carries one into another: a motif
// placed on one appears on every one of them whether it was asked for or not.
// Centres in different classes are independent, and are what the orbifold name
// counts -- so the classes are given an output each.

#ifndef WP_REGION_HELPERS
#define WP_REGION_HELPERS

// This block is repeated verbatim in every <group>_region.cl, and the copies
// have to stay identical. A package is compiled as one translation unit, so
// the guard keeps whichever copy comes first and drops the rest; the copies
// are there because a package cannot declare a library of its own the way the
// core does, and keeping the block in a single file would break the day a
// plugin sorting ahead of that one wanted it.

// How far the point lies from the nearest copy of one of the group's special
// points, squared -- squared so that comparing it with a radius costs no point
// a square root.
//
// The step from the special point to the point is taken into lattice
// coordinates and folded into one cell. That much puts the two in the same
// cell but does not yet say which copy of the special point is nearest: a
// point just inside one edge is nearer the copy across that edge than the one
// it was folded against. The basis the package hands over is reduced, which
// makes the cell a Delaunay cell, and for those the nearest copy is always one
// of the four corners the point now sits between.
PyroReal wp_region_corner(PyroXY e1, PyroXY e2, PyroReal u, PyroReal v)
{
    PyroReal x = e1.x * u + e2.x * v;
    PyroReal y = e1.y * u + e2.y * v;

    return x * x + y * y;
}

PyroReal wp_region_centre(
    PyroXY z,
    PyroXY at,
    PyroXY fold0,
    PyroXY fold1,
    PyroXY e1,
    PyroXY e2)
{
    PyroReal dx = z.x - at.x;
    PyroReal dy = z.y - at.y;

    PyroReal u = fold0.x * dx + fold0.y * dy;
    PyroReal v = fold1.x * dx + fold1.y * dy;

    u -= floor(u);
    v -= floor(v);

    return fmin(
        fmin(wp_region_corner(e1, e2, u, v),
             wp_region_corner(e1, e2, u - 1.0, v)),
        fmin(wp_region_corner(e1, e2, u, v - 1.0),
             wp_region_corner(e1, e2, u - 1.0, v - 1.0)));
}

// How far the point lies across the nearest line of a family of parallel ones.
// `along` is a unit vector down the lines, so turning it a quarter turn
// measures across them; the lines lie `gap` apart with the first `at` from the
// origin, and the remainder of that spacing lands on the nearest of them.
PyroReal wp_region_line(PyroXY z, PyroXY along, PyroReal at, PyroReal gap)
{
    PyroReal across = along.x * z.y - along.y * z.x - at;
    PyroReal step = across - gap * floor(across / gap);

    return fmin(step, gap - step);
}

#endif

PYRO_FUNCTION wallpaper_p6_region(
    __global PyroXY* zin,
    PyroXY fold0,
    PyroXY fold1,
    PyroXY cell0,
    PyroXY cell1,
    PyroReal r_squared,
    PyroXY centre_0_0,
    PyroXY centre_1_0,
    PyroXY centre_1_1,
    PyroXY centre_2_0,
    PyroXY centre_2_1,
    PyroXY centre_2_2,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);
    PyroXY z = zin[i];

    PyroReal to_centre_0 =
        wp_region_centre(z, centre_0_0, fold0, fold1, cell0, cell1);
    PyroReal to_centre_1 =
        wp_region_centre(z, centre_1_0, fold0, fold1, cell0, cell1);
    to_centre_1 = fmin(to_centre_1,
        wp_region_centre(z, centre_1_1, fold0, fold1, cell0, cell1));
    PyroReal to_centre_2 =
        wp_region_centre(z, centre_2_0, fold0, fold1, cell0, cell1);
    to_centre_2 = fmin(to_centre_2,
        wp_region_centre(z, centre_2_1, fold0, fold1, cell0, cell1));
    to_centre_2 = fmin(to_centre_2,
        wp_region_centre(z, centre_2_2, fold0, fold1, cell0, cell1));

    if (to_centre_0 <= r_squared) {
        active_output_ids[i] = PYRO_OUTPUT_centre_0;
    }
    else if (to_centre_1 <= r_squared) {
        active_output_ids[i] = PYRO_OUTPUT_centre_1;
    }
    else if (to_centre_2 <= r_squared) {
        active_output_ids[i] = PYRO_OUTPUT_centre_2;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_general;
    }
}
