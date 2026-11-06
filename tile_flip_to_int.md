# Load which side up a tile lies into an integer variable

Every enter function keeps, for each point, the tile it took the point from, and with it whether that copy of the fundamental domain is the domain only turned, or flipped over. This sets the integer variable `var_int_id` to

| Value | When |
| --- | --- |
| 1 | The copy has the same side up as the domain: the domain itself, or the domain turned. |
| -1 | The copy is the domain flipped over by a mirror or a glide. |

The groups with neither mirrors nor glides -- `p1`, `p2`, `p3`, `p4` and `p6` -- have no flipped copies, and the Cairo enter never flips, so with them it is always 1.

The variable can then be read by any plugin that takes an integer variable, such as `pyro/variables_integer`'s `test_var`, `test_mod` and `translate_x`, or changed with its `add` and `mod`.

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `tile_side` branches on the same thing, with an output for each side.
- `tile_copy_to_int`, `tile_flip_to_int`, `tile_m_to_int` and `tile_n_to_int` together load the whole tile.
