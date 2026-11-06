// Sets the integer variable, for each point, to the copy of the fundamental domain
// it took the point from, as its row in the group's copy table.
PYRO_FUNCTION wallpaper_tile_copy_to_int(
    __global WallpaperTile* tile,
    __global PyroInt* var_int)
{
    int i = get_global_id(0);

    var_int[i] = tile[i].copy;
}
