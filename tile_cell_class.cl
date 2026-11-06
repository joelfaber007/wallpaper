// Which class of cell the tile an enter function took the point from lies
// in, counting the cell (m, n) as p*m + q*n and taking that modulo k.
//
// The remainder is made non-negative, so the cells either side of the origin
// fall into the classes the pattern continues with rather than mirror images
// of them. The outputs are listed in order, so the remainder is the step from
// the first.
PYRO_FUNCTION wallpaper_tile_cell_class(
    __global WallpaperTile* tile,
    int p,
    int q,
    int k,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);
    int c = (p * tile[i].m + q * tile[i].n) % k;

    if (c < 0) {
        c += k;
    }

    active_output_ids[i] = PYRO_OUTPUT_class_0 + c;
}
