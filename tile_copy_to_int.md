# Load a tile's copy into an integer variable

Every enter function keeps, for each point, the tile it took the point from. This sets the integer variable `var_int_id` to the copy of the fundamental domain that tile is, as its row in the group's copy table: 0 for the domain itself, and up to one less than the number of copies in a cell.

The rows are listed, in order, as the outputs of the group's `<group>_tile_copy`.

The variable can then be read by any plugin that takes an integer variable, such as `pyro/variables_integer`'s `test_var`, `test_mod` and `translate_x`, or changed with its `add` and `mod`.

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `<group>_tile_copy` branches on the same number, one output per copy.
- `tile_copy_to_int`, `tile_flip_to_int`, `tile_m_to_int` and `tile_n_to_int` together load the whole tile.
