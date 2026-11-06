// Whether the tile an enter function took the point from is the one tile
// named by its copy and its cell.
PYRO_FUNCTION wallpaper_tile_copy_is(
    __global WallpaperTile* tile,
    int copy,
    int m,
    int n,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    if (tile[i].copy == copy && tile[i].m == m && tile[i].n == n) {
        active_output_ids[i] = PYRO_OUTPUT_match;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_other;
    }
}
