# Branch on how far a tile's cell is from the origin

Every enter function keeps, for each point, the cell it took the point from, as whole steps $(m, n)$ of the lattice basis the group's copies are placed with. This counts how many steps that cell lies from the cell at the origin and compares it with `radius`.

## How the steps are counted

| `metric` | Steps | The patch it makes |
| --- | --- | --- |
| 0 | $\max(\lvert m\rvert, \lvert n\rvert)$ | A square of cells on a square lattice, and a parallelogram on any other. |
| 1 | $\lvert m\rvert + \lvert n\rvert$ | A diamond of cells on a square lattice. |
| 2 | $\max(\lvert m\rvert, \lvert n\rvert, \lvert m + n\rvert)$ | A hexagon of cells on a hexagonal lattice, whose basis vectors are 60 degrees apart. |

A `radius` of 0 is the cell at the origin alone.

## The outputs

| Output | Taken when |
| --- | --- |
| `inside` | The cell lies `radius` steps or fewer from the cell at the origin. |
| `outside` | The cell lies further. |

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
