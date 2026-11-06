// Whether the tile an enter function took the point from lies in the one cell
// named, whichever copy of the domain it is.
PYRO_FUNCTION wallpaper_tile_is(
    __global WallpaperTile* tile,
    int m,
    int n,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    if (tile[i].m == m && tile[i].n == n) {
        active_output_ids[i] = PYRO_OUTPUT_match;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_other;
    }
}
