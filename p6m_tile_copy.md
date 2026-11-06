# Branch on the copy of the fundamental domain of p6m

| Group | `p6m` |
| --- | --- |
| Orbifold | *632 |
| Lattice | hexagonal, set by `a` |
| Point group | $D_{6}$ |
| Copies of the fundamental domain in a cell | 12 |
| Classes of rotation centre | 1 × 6-fold, 1 × 3-fold, 1 × 2-fold |
| Directions of mirror line | 6 |
| Directions of glide axis | 6 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = a\,e^{i\pi/3}
```

## The outputs

The enter keeps, for each point, which copy $k$ of the fundamental domain it took the point from. This sends the point to output $k$: one output for each copy in a cell, in the order of the group's copy table, named by the isometry's linear part, the turn or flip that carries the domain onto the copy.

| Output | Taken when |
| --- | --- |
| `turn_0` | The tile is the fundamental domain itself, in the copy table's first row. |
| `turn_60` | The tile is the fundamental domain turned through 60 degrees. |
| `turn_120` | The tile is the fundamental domain turned through 120 degrees. |
| `turn_180` | The tile is the fundamental domain turned through 180 degrees. |
| `turn_240` | The tile is the fundamental domain turned through 240 degrees. |
| `turn_300` | The tile is the fundamental domain turned through 300 degrees. |
| `flip_0` | The tile is the fundamental domain flipped over a line at 0 degrees, by a mirror or a glide along it. |
| `flip_30` | The tile is the fundamental domain flipped over a line at 30 degrees, by a mirror or a glide along it. |
| `flip_60` | The tile is the fundamental domain flipped over a line at 60 degrees, by a mirror or a glide along it. |
| `flip_90` | The tile is the fundamental domain flipped over a line at 90 degrees, by a mirror or a glide along it. |
| `flip_120` | The tile is the fundamental domain flipped over a line at 120 degrees, by a mirror or a glide along it. |
| `flip_150` | The tile is the fundamental domain flipped over a line at 150 degrees, by a mirror or a glide along it. |

Every cell holds one copy of each, so whatever the outputs do is repeated in every cell. A copy outside those this group has, which another group's enter may have kept, is read as the nearest one it has.

## Works with

- `p6m_enter` keeps the tile this reads. Give it the same `tile_id`.
- `p6m_exit` carries the point back to that tile; this can come before it or after it.
- `tile_side` tells only the turned copies from the flipped ones, `tile_cell_class` and `tile_ring` sort by cell, `tile_pick` picks tiles at random, `tile_is` picks out one cell, and `tile_copy_is` picks out one tile.
