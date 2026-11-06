# Branch on the copy of the fundamental domain of pgg

| Group | `pgg` |
| --- | --- |
| Orbifold | 22× |
| Lattice | rectangular, set by `a`, `b` |
| Point group | $D_{2}$ |
| Copies of the fundamental domain in a cell | 4 |
| Classes of rotation centre | 2 × 2-fold |
| Directions of mirror line | none |
| Directions of glide axis | 2 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,b
```

## The outputs

The enter keeps, for each point, which copy $k$ of the fundamental domain it took the point from. This sends the point to output $k$: one output for each copy in a cell, in the order of the group's copy table, named by the isometry's linear part, the turn or flip that carries the domain onto the copy.

| Output | Taken when |
| --- | --- |
| `turn_0` | The tile is the fundamental domain itself, in the copy table's first row. |
| `turn_180` | The tile is the fundamental domain turned through 180 degrees. |
| `flip_0` | The tile is the fundamental domain flipped over a line at 0 degrees, by a mirror or a glide along it. |
| `flip_90` | The tile is the fundamental domain flipped over a line at 90 degrees, by a mirror or a glide along it. |

Every cell holds one copy of each, so whatever the outputs do is repeated in every cell. A copy outside those this group has, which another group's enter may have kept, is read as the nearest one it has.

## Works with

- `pgg_enter` keeps the tile this reads. Give it the same `tile_id`.
- `pgg_exit` carries the point back to that tile; this can come before it or after it.
- `tile_side` tells only the turned copies from the flipped ones, `tile_cell_class` and `tile_ring` sort by cell, `tile_pick` picks tiles at random, `tile_is` picks out one cell, and `tile_copy_is` picks out one tile.
