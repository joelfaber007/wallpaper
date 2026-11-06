# Exit a tile of the Cairo pentagonal tiling

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

## The exit

The enter keeps, for each point, which of the four turns of the pentagon in a cell it took the point from, $k$, and the cell, as whole steps $(m, n)$ of the lattice. The exit reads them from the buffer `tile_id` names, turns the point by $k$ quarter turns about the origin and moves it to that cell:

```math
z \mapsto i^{k} z + t, \qquad t = a(m + i n)
```

This is the inverse of the enter, so a point nothing has moved since the enter lands exactly where it was. The turn carries the seed onto the image the enter found, which is why the exit needs no `seed` of its own. A turn outside the four, which another group's enter may have kept, is read as the nearest one there is.

## Works with

- `p4g_cairo_enter` folds the point into one pentagon and keeps the tile it took it from. Give it the same `tile_id` and `a`.
- `p4g_cairo_fold` and `p4g_scatter` fold into the pentagon and spread it over the tiling without keeping where anything came from.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
