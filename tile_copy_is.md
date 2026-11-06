# Branch on one particular tile

Every enter function keeps, for each point, the tile it took the point from: the copy of the fundamental domain, as its row in the group's copy table, and the cell, as whole steps $(m, n)$ of the lattice basis the group's copies are placed with. This sends the point one way if its tile is the one the parameters name and the other way if not.

Copy 0 in cell $(0, 0)$ is the fundamental domain itself, where the fold puts every point. The rows of the copy table are listed, in order, as the outputs of the group's `<group>_tile_copy`.

## The outputs

| Output | Taken when |
| --- | --- |
| `match` | The tile is copy `copy` in cell (`m`, `n`). |
| `other` | The tile is any other. |

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `<group>_tile_copy` lists the copies, in the order `copy` counts them.
- `tile_is` picks out every copy in a cell, whichever copy it is.
