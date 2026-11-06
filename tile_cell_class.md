# Branch on the class of a tile's cell

Every enter function keeps, for each point, the cell it took the point from, as whole steps $(m, n)$ of the lattice basis the group's copies are placed with. This sorts the cells into `k` classes by

```math
c = (p\,m + q\,n) \bmod k, \qquad 0 \le c < k
```

and sends the point to output `class_`$c$. The remainder is taken non-negative, so the classes carry on across the origin rather than reflecting there.

## Choosing p, q and k

| `p` | `q` | `k` | Pattern of cells |
| --- | --- | --- | --- |
| 1 | 1 | 2 | On a square or rectangular lattice, a checkerboard: no two cells that share an edge alike. |
| 1 | 0 | 2 | Stripes running along the second basis vector. |
| 0 | 1 | 2 | Stripes running along the first basis vector. |
| 1 | 1 | 3 | Diagonal bands, three cells wide before they repeat. |
| 1 | -1 | 3 | On a hexagonal lattice, every cell unlike all six of its neighbours. |
| 1 | 2 | 4 | Bands that step along two cells on each row. |

Every copy of the fundamental domain in a cell is in the same class. Branch on `tile_side` or `<group>_tile_copy` as well to tell the copies within a cell apart.

## The outputs

| Output | Taken when |
| --- | --- |
| `class_0` | $c = 0$. |
| `class_1` | $c = 1$. |
| `class_2` | $c = 2$, which needs `k` of 3 or more. |
| `class_3` | $c = 3$, which needs `k` = 4. |

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
