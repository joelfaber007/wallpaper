# Enter a tile of the Cairo pentagonal tiling

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

## The enter

The point is folded exactly as `p4g_cairo_fold` folds it. The tile that holds $z$ is the one whose image of the seed $z_0$ lies nearest,

```math
(k, t) = \operatorname{argmin}_{j \in \{0, 1, 2, 3\},\ t \in \Lambda} \, |z - i^{j} z_0 - t|
```

and the point is turned back into the first tile:

```math
z \mapsto i^{-k}(z - t)
```

What sets the enter apart from the fold is that it keeps $k$ and $t$. They go into the buffer `tile_id` names: the turn $k$, and the cell $t$ as whole steps $(m, n)$ of the lattice, $t = a(m + i n)$.

## Between the enter and the exit

Functions placed between the two see the point inside the one pentagon. Call what they do together $F$. The exit carries the result back to the pentagon the point came from, so the whole run is

```math
z \mapsto i^{k} F\big(i^{-k}(z - t)\big) + t
```

Each pentagon has $F$ applied in its own frame, turned with the pentagon, so the whole run commutes with the quarter turns and translations of p4g. Neither the enter nor the exit flips the point, so it does not commute with p4g's flips: a pentagon and its mirror image both have $F$ applied unmirrored, and where $F$ has no mirror symmetry of its own, the two differ by more than a reflection.

## Works with

- `p4g_cairo_exit` carries the point back to the pentagon the enter took it from. Give it the same `tile_id` and `a`.
- `p4g_cairo_fold` folds the same way without keeping the tile.
- `p4g_scatter` carries a folded point to a random copy instead of the one it came from.
- `p4g_cairo_tile_copy`, `tile_side`, `tile_cell_class`, `tile_ring`, `tile_pick`, `tile_is` and `tile_copy_is` read the tile the enter keeps, and branch on it.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
