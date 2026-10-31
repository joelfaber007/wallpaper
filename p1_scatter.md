# Scatter over the tiling of p1

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

## The scatter

A cell holds 1 copy of the fundamental domain. Two uniform numbers $u_1, u_2 \in [0, 1)$ pick a point spread evenly over the disc of radius $\rho$ = `reach`:

```math
r = \rho\sqrt{u_1}, \quad \theta = 2\pi u_2
```

The point is carried by the lattice translation to the cell that holds $r e^{i\theta}$:

```math
z \mapsto z + t, \qquad t \in \Lambda \text{ nearest } r e^{i\theta}
```

After one call every copy within `reach` is as likely as every other, which is what makes a folded motif tile evenly up to the edge of `reach` and stop there.

## Works with

- `p1` steps the point into a neighbouring tile at random, so iterating walks it over the tiling.
- `p1_fold` folds every point into one copy of the fundamental domain.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
