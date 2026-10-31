# Fold into the fundamental domain of p1

| Group | `p1` |
| --- | --- |
| Orbifold | ○ |
| Lattice | oblique, set by `a`, `b`, `gamma` |
| Point group | $C_{1}$ |
| Copies of the fundamental domain in a cell | 1 |
| Classes of rotation centre | none |
| Directions of mirror line | none |
| Directions of glide axis | none |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = b\,e^{i\gamma}
```

## The fold

A cell holds 1 copy of the fundamental domain. The domain is the Dirichlet domain of a seed point $z_0$ chosen inside the cell: the points nearer the seed than any other image of it under the group,

```math
D = \{\, z : |z - z_0| \le |z - g z_0| \ \text{for every } g \in G \,\}
```

and the copy of $D$ that holds a point $z$ is the one whose image of the seed lies nearest to $z$:

```math
k = \operatorname{argmin}_{j} \, \min_{t \in \Lambda} \, |z - g_j z_0 - t|
```

where $g_1, \dots, g_N$ carry $D$ onto the $N$ copies in one cell and $\Lambda$ is the lattice of translations.

The fold carries $z$ back by the inverse of that copy's isometry, $z \mapsto g_k^{-1}(z - t)$, so it lands in $D$ itself. It is a function of $z$ alone: the same point always folds to the same place.

## Works with

- `p1` steps the point into a neighbouring tile at random, so iterating walks it over the tiling.
- `p1_scatter` carries a folded point to a random copy within `reach`, even across the whole of it in one step.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
