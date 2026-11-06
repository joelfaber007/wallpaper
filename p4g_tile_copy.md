# Branch on the copy of the fundamental domain of p4g

| Group | `p4g` |
| --- | --- |
| Orbifold | 4*2 |
| Lattice | square, set by `a` |
| Point group | $D_{4}$ |
| Copies of the fundamental domain in a cell | 8 |
| Classes of rotation centre | 1 × 4-fold, 1 × 2-fold |
| Directions of mirror line | 2 |
| Directions of glide axis | 4 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,a
```

## The outputs

The enter keeps, for each point, which copy $k$ of the fundamental domain it took the point from. This sends the point to output $k$: one output for each copy in a cell, in the order of the group's copy table, named by the isometry's linear part, the turn or flip that carries the domain onto the copy.

| Output | Taken when |
| --- | --- |
| `turn_0` | The tile is the fundamental domain itself, in the copy table's first row. |
| `turn_90` | The tile is the fundamental domain turned through 90 degrees. |
| `turn_180` | The tile is the fundamental domain turned through 180 degrees. |
| `turn_270` | The tile is the fundamental domain turned through 270 degrees. |
| `flip_0` | The tile is the fundamental domain flipped over a line at 0 degrees, by a mirror or a glide along it. |
| `flip_45` | The tile is the fundamental domain flipped over a line at 45 degrees, by a mirror or a glide along it. |
| `flip_90` | The tile is the fundamental domain flipped over a line at 90 degrees, by a mirror or a glide along it. |
| `flip_135` | The tile is the fundamental domain flipped over a line at 135 degrees, by a mirror or a glide along it. |

Every cell holds one copy of each, so whatever the outputs do is repeated in every cell. A copy outside those this group has, which another group's enter may have kept, is read as the nearest one it has.

## Works with

- `p4g_enter` keeps the tile this reads. Give it the same `tile_id`.
- `p4g_exit` carries the point back to that tile; this can come before it or after it.
- `tile_side` tells only the turned copies from the flipped ones, `tile_cell_class` and `tile_ring` sort by cell, `tile_pick` picks tiles at random, `tile_is` picks out one cell, and `tile_copy_is` picks out one tile.
