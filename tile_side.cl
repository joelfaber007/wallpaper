// Which side up the tile an enter function took the point from lies: the
// domain only turned, or the domain flipped over. Every wallpaper group with
// a mirror or a glide has both, and they are the left- and right-handed tiles
// of its pattern.
PYRO_FUNCTION wallpaper_tile_side(
    __global WallpaperTile* tile,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    if (tile[i].flip < 0) {
        active_output_ids[i] = PYRO_OUTPUT_flipped;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_turned;
    }
}
