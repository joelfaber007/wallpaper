// Whether the tile an enter function took the point from is among a share of
// the tiles picked at random, the same ones on every iteration.
//
// The tile -- its copy and its cell -- and the salt are mixed into one number
// by a hash, so every point of a tile gets the same number and tiles next to
// one another get unrelated ones. The top 24 bits of it make a number evenly
// spread over [0, 1), and the tile is picked when that is below `share`.

// Mixes the bits of x so that every bit of the result depends on every bit of
// x: the integer hash of Chris Wellons's "lowbias32".
uint wp_tile_mix(uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;

    return x;
}

PYRO_FUNCTION wallpaper_tile_pick(
    __global WallpaperTile* tile,
    PyroReal share,
    int salt,
    __global ActiveOutputIDs* active_output_ids)
{
    int i = get_global_id(0);

    uint h = wp_tile_mix((uint)salt);
    h = wp_tile_mix(h ^ (uint)tile[i].copy);
    h = wp_tile_mix(h ^ (uint)tile[i].m);
    h = wp_tile_mix(h ^ (uint)tile[i].n);

    PyroReal u = (PyroReal)(h >> 8) * (1.0 / 16777216.0);

    if (u < share) {
        active_output_ids[i] = PYRO_OUTPUT_picked;
    }
    else {
        active_output_ids[i] = PYRO_OUTPUT_rest;
    }
}
