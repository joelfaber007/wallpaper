# Scatter over the tiling of p4g

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

## The scatter

A cell holds 8 copies of the fundamental domain. Three uniform numbers $u_0, u_1, u_2 \in [0, 1)$ are drawn. The first picks one of the $N$ copies, each with probability $1/N$, and the other two a point spread evenly over the disc of radius $\rho$ = `reach`:

```math
r = \rho\sqrt{u_1}, \quad \theta = 2\pi u_2
```

The point is carried by the isometry $g_k$ that takes the domain onto the chosen copy, then by the lattice translation to the cell that holds $r e^{i\theta}$:

```math
z \mapsto g_k(z) + t, \qquad t \in \Lambda \text{ nearest } r e^{i\theta}
```

After one call every copy within `reach` is as likely as every other, which is what makes a folded motif tile evenly up to the edge of `reach` and stop there.

## Works with

- `p4g` steps the point into a neighbouring tile at random, so iterating walks it over the tiling.
- `p4g_fold` folds every point into one copy of the fundamental domain.
- `p4g_region` routes the point by which of the group's special positions it lies on.
- `p4g_cairo_fold` folds every point into one tile of a Cairo pentagonal tiling, which the scatter then repeats.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
