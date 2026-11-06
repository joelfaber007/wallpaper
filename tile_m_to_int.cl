// Sets the integer variable, for each point, to the first coordinate of the cell it
// took the point from, in whole steps of the first lattice basis vector.
PYRO_FUNCTION wallpaper_tile_m_to_int(
    __global WallpaperTile* tile,
    __global PyroInt* var_int)
{
    int i = get_global_id(0);

    var_int[i] = tile[i].m;
}
