# Load a tile's second cell coordinate into an integer variable

Every enter function keeps, for each point, the tile it took the point from, and with it the cell, as whole steps $(m, n)$ of the lattice basis the group's copies are placed with. This sets the integer variable `var_int_id` to $n$, the steps along the second basis vector. The cell at the origin has $n = 0$.

The variable can then be read by any plugin that takes an integer variable, such as `pyro/variables_integer`'s `test_var`, `test_mod` and `translate_x`, or changed with its `add` and `mod`.

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `tile_m_to_int` loads the other coordinate.
- `tile_copy_to_int`, `tile_flip_to_int`, `tile_m_to_int` and `tile_n_to_int` together load the whole tile.
