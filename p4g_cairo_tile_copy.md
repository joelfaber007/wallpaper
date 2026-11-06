# Branch on the turn of a Cairo pentagon

| Group | `p4g` |
| --- | --- |
| Orbifold | 4*2 |
| Lattice | square, set by `a` |
| Point group | $D_{4}$ |
| Copies of the fundamental domain in a tile | 2 |
| Tiles in a cell | 4 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,a
```

## The outputs

The enter keeps, for each point, which of the four turns $k$ of the pentagon in a cell it took the point from. This sends the point to output $k$, named by the quarter turn about the origin that carries the first pentagon onto that one.

| Output | Taken when |
| --- | --- |
| `turn_0` | The tile is the first pentagon, the one the fold carries every point into. |
| `turn_90` | The tile is the first pentagon turned through 90 degrees about the origin. |
| `turn_180` | The tile is the first pentagon turned through 180 degrees about the origin. |
| `turn_270` | The tile is the first pentagon turned through 270 degrees about the origin. |

The four pentagons around each 4-fold centre are one of each, so giving each output its own colour colours the Cairo tiling with no two pentagons that share an edge alike: across a long edge the neighbour is a quarter turn away, and across the short edge a half turn. A turn outside the four, which another group's enter may have kept, is read as the nearest one there is.

## Works with

- `p4g_cairo_enter` keeps the tile this reads. Give it the same `tile_id`.
- `p4g_cairo_exit` carries the point back to that tile; this can come before it or after it.
- `tile_side` tells only the turned copies from the flipped ones, `tile_cell_class` and `tile_ring` sort by cell, `tile_pick` picks tiles at random, `tile_is` picks out one cell, and `tile_copy_is` picks out one tile.
