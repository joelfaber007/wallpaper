// Whether the cell of the tile an enter function took the point from lies
// within `radius` cells of the cell at the origin.
//
// How far a cell (m, n) lies is counted in one of three ways, chosen by
// `metric`: 0 takes max(|m|, |n|), the steps of a king on a chessboard, which
// makes a square of cells on a square lattice; 1 takes |m| + |n|, the steps of
// a rook, which makes a diamond; 2 takes max(|m|, |n|, |m + n|), the steps
// between neighbouring cells of a hexagonal lattice, which makes a hexagon on
// one.
PYRO_FUNCTION wallpaper_tile_ring(
    __global WallpaperTile* tile,
    int radius,
    int metric,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);
    int m = tile[i].m;
    int n = tile[i].n;
    int far;

    if (metric == 1) {
        far = abs(m) + abs(n);
    }
    else if (metric == 2) {
        far = max(max(abs(m), abs(n)), abs(m + n));
    }
    else {
        far = max(abs(m), abs(n));
    }

    if (far <= radius) {
        active_output_ids[i] = PYRO_OUTPUT_inside;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_outside;
    }
}
