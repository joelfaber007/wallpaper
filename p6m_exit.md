# Exit the fundamental domain of p6m

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

## The exit

The enter keeps, for each point, the copy $k$ of the fundamental domain it took the point from and the cell, as whole steps $(m, n)$ of the lattice basis the copies are placed with. The exit reads them from the buffer `tile_id` names and applies the isometry that carries the domain onto copy $k$, then the translation to that cell:

```math
z \mapsto g_k(z) + t, \qquad t = m\,\mathbf{e}_1 + n\,\mathbf{e}_2
```

This is the inverse of the enter, so a point nothing has moved since the enter lands exactly where it was. A copy outside the copies this group has in a cell, which another group's enter may have kept, is read as the nearest one it has.

## Works with

- `p6m_enter` folds the point into the domain and keeps the tile it took it from. Give it the same `tile_id` and lattice parameters.
- `p6m_fold` and `p6m_scatter` fold into the domain and spread it over the tiling without keeping where anything came from.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
