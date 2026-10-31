# Special positions of pmg

| Group | `pmg` |
| --- | --- |
| Orbifold | 22* |
| Lattice | rectangular, set by `a`, `b` |
| Point group | $D_{2}$ |
| Copies of the fundamental domain in a cell | 4 |
| Classes of rotation centre | 2 × 2-fold |
| Directions of mirror line | 1 |
| Directions of glide axis | 1 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,b
```

## The tests

A rotation centre $c$ counts as holding the point when the nearest copy of it is within `radius`,

```math
\min_{t \in \Lambda} |z - c - t|^2 \le r^2
```

and a family of parallel lines when the nearest of them is within `width`. A family is a unit vector $\mathbf{u}$ along the lines, the offset $o$ of one of them and the gap $g$ between them, and the distance to the nearest is

```math
d = \min(\delta,\ g - \delta), \qquad \delta = (\mathbf{u} \times z - o) \ \mathrm{mod}\ g
```

where $\mathbf{u} \times z$ is the distance of $z$ across a line through the origin along $\mathbf{u}$. The outputs are tested in the order they are listed below and the first that holds is taken, so a point near a rotation centre is reported there even when it is also on a mirror through it.

## Outputs

| Output | Taken when |
| --- | --- |
| `centre_0` | The point is within the radius of a 2-fold rotation centre of the first class, of which every cell holds two. |
| `centre_1` | The point is within the radius of a 2-fold rotation centre of the second class, of which every cell holds two. |
| `mirror` | The point is within the width of a mirror line, which the group turns the plane over about while holding every point of the line still. |
| `glide` | The point is within the width of a glide axis, which the group turns the plane over about and then slides along, holding no point at all still. |
| `general` | The point is on none of the group's special positions, and is held by nothing but the translations. |

## Works with

- `pmg` steps the point into a neighbouring tile at random, so iterating walks it over the tiling.
- `pmg_fold` folds every point into one copy of the fundamental domain.
- `pmg_scatter` carries a folded point to a random copy within `reach`, even across the whole of it in one step.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
