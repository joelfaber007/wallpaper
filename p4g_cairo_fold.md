# Fold into a tile of the Cairo pentagonal tiling

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

## The tile

The tile is the Dirichlet domain of a seed $z_0$ on the mirror $x + y = a/2$: the points nearer the seed than any other image of it under the group,

```math
D = \{\, z : |z - z_0| \le |z - g z_0| \ \text{for every } g \in G \,\}, \qquad z_0 = a\left(\sigma + i\left(\tfrac{1}{2} - \sigma\right)\right)
```

where $\sigma$ = `seed`. The mirror holds $z_0$ still, so it has four images in a cell instead of eight, and $D$ is two copies of the fundamental domain joined across the mirror. For $0 < \sigma \le \tfrac{1}{4}$ it is the pentagon with corners

```math
0, \quad a\left(\tfrac{1}{2} - q + iq\right), \quad a\,\tfrac{1 + i}{2}, \quad a\left(q + i\left(\tfrac{1}{2} + q\right)\right), \quad a\left(-q + i\left(\tfrac{1}{2} - q\right)\right), \qquad q = \frac{1 - 4\sigma}{4(1 - 2\sigma)}
```

Its corners at the two 4-fold centres $0$ and $a(1 + i)/2$ are right angles. Its short edge, of length $2\sqrt{2}\,q\,a$, lies on a mirror and is centred on a 2-fold centre, and its other four edges are all as long as each other. The mirror through $z_0$ cuts the tile into its two copies of the fundamental domain.

| `seed` | Tile |
| --- | --- |
| $\tfrac{\sqrt{3} - 1}{4} \approx 0.1830$ | The dual of the snub square tiling: angles of 120° and 90°. |
| $\tfrac{7 - \sqrt{7}}{28} \approx 0.1555$ | Equilateral: all five edges equally long. |
| towards 0 | The short edge grows and the angle opposite it opens towards a straight line. |
| $\tfrac{1}{4}$ | The short edge shrinks to nothing and the tile is a square. |

## The fold

The quarter turns about the origin carry $z_0$ onto its four images in a cell, and they reach every one: each flip of the group is one of its direct isometries applied after the mirror through $z_0$, which holds $z_0$ still. The tile that holds a point $z$ is the one whose image of the seed lies nearest to $z$:

```math
k = \operatorname{argmin}_{j \in \{0, 1, 2, 3\}} \, \min_{t \in \Lambda} \, |z - i^{j} z_0 - t|
```

and the fold carries $z$ back by turning the step from that image the other way, $z \mapsto z_0 + i^{-k}(z - i^{k} z_0 - t)$, so it lands in $D$ itself. It never flips the point, so a motif folded here is not made mirror-symmetric within its tile.

## Works with

- `p4g_scatter` carries a folded point to a random copy within `reach`. Its copies include the flips, so every tile then shows the motif together with its mirror image.
- `p4g` steps the point into a neighbouring tile at random, so iterating walks it over the tiling.
- `p4g_fold` folds into one copy of the fundamental domain, half the size of this tile and shaped by a seed off every mirror.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
