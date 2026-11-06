// Sets the integer variable, for each point, to whether the copy of the domain it
// took the point from is flipped over: 1 when it is only turned, -1 when flipped.
PYRO_FUNCTION wallpaper_tile_flip_to_int(
    __global WallpaperTile* tile,
    __global PyroInt* var_int)
{
    int i = get_global_id(0);

    var_int[i] = tile[i].flip;
}
