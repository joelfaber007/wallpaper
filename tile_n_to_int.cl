// Sets the integer variable, for each point, to the second coordinate of the cell it
// took the point from, in whole steps of the second lattice basis vector.
PYRO_FUNCTION wallpaper_tile_n_to_int(
    __global WallpaperTile* tile,
    __global PyroInt* var_int)
{
    int i = get_global_id(0);

    var_int[i] = tile[i].n;
}
