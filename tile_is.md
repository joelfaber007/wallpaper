# Branch on one particular cell

Every enter function keeps, for each point, the tile it took the point from: the copy of the fundamental domain, as its row in the group's copy table, and the cell, as whole steps $(m, n)$ of the lattice basis the group's copies are placed with. This sends the point one way if its tile lies in the cell the parameters name, whichever copy it is, and the other way if not.

Cell $(0, 0)$ holds the fundamental domain itself, where the fold puts every point, together with the other copies placed around it.

## The outputs

| Output | Taken when |
| --- | --- |
| `match` | The tile is any copy in cell (`m`, `n`). |
| `other` | The tile is in any other cell. |

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `tile_copy_is` picks out one copy within the cell.
- `tile_ring` with a `radius` of 0 picks out the cell at the origin as well.
