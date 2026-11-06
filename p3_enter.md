# Enter the fundamental domain of p3

| Group | `p3` |
| --- | --- |
| Orbifold | 333 |
| Lattice | hexagonal, set by `a` |
| Point group | $C_{3}$ |
| Copies of the fundamental domain in a cell | 3 |
| Classes of rotation centre | 3 × 3-fold |
| Directions of mirror line | none |
| Directions of glide axis | none |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = a\,e^{i\pi/3}
```

## The enter

The point is folded exactly as `p3_fold` folds it. The copy of the fundamental domain that holds $z$ is the one whose image of the seed lies nearest,

```math
(k, t) = \operatorname{argmin}_{j,\ t \in \Lambda} \, |z - g_j z_0 - t|
```

and the point is carried back into the domain itself by the inverse of that copy's isometry:

```math
z \mapsto g_k^{-1}(z - t)
```

What sets the enter apart from the fold is that it keeps $k$ and $t$. They go into the buffer `tile_id` names: the copy $k$, as its row among the copies of the domain in a cell, and the cell $t$, as whole steps $(m, n)$ of the lattice basis the copies are placed with, $t = m\,\mathbf{e}_1 + n\,\mathbf{e}_2$.

## Between the enter and the exit

Functions placed between the two see the point inside the one copy of the domain. Call what they do together $F$. The exit carries the result back to the tile the point came from, so the whole run is

```math
z \mapsto g_k\big(F\big(g_k^{-1}(z - t)\big)\big) + t
```

Each tile has $F$ applied in its own frame, turned and flipped with the tile, so the whole run commutes with every isometry of the group: whatever $F$ does to one tile it does to every other, even where it carries points out of the domain and into the neighbouring tiles. The run puts every point back in or near the tile it came from, so it gives the pattern the group's symmetry only where what came in already had it, such as over a region the fold and scatter have filled.

## Works with

- `p3_exit` carries the point back to the tile the enter took it from. Give it the same `tile_id` and lattice parameters.
- `p3_fold` folds the same way without keeping the tile.
- `p3_scatter` carries a folded point to a random copy instead of the one it came from.
- `p3_tile_copy`, `tile_side`, `tile_cell_class`, `tile_ring`, `tile_pick`, `tile_is` and `tile_copy_is` read the tile the enter keeps, and branch on it.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
