# Wallpaper group p4m

| Group | `p4m` |
| --- | --- |
| Orbifold | *442 |
| Lattice | square, set by `a` |
| Point group | $D_{4}$ |
| Copies of the fundamental domain in a cell | 8 |
| Classes of rotation centre | 2 × 4-fold, 1 × 2-fold |
| Directions of mirror line | 4 |
| Directions of glide axis | 2 |

The lattice is spanned by

```math
\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,a
```

## The moves

Every move is an isometry of the plane: a turn, perhaps after a flip, then a shift. With the point as the complex number $z = x + iy$ it is

```math
z \mapsto e^{i\theta} z + t \quad\text{or}\quad z \mapsto e^{i\theta}\bar{z} + t
```

the second for a move that turns the plane over: a mirror or a glide.

One call applies one of these, drawn at random. Here $a$ and the basis are as above.

| Move | Map |
| --- | --- |
| translation by +a, along x | $z \mapsto z + a$ |
| translation by -a | $z \mapsto z - a$ |
| translation by +a, along y | $z \mapsto z + i\,a$ |
| translation by -a | $z \mapsto z - i\,a$ |
| quarter turn about the origin | $z \mapsto iz$ |
| mirror in the line y = 0 | $z \mapsto \bar{z}$ |
| mirror in the diagonal y = x | $z \mapsto i\bar{z}$ |
| mirror in the line x = a/2 | $z \mapsto -\bar{z} + a$ |

Each translation is offered in both directions so the walk does not drift off to infinity; the turns, mirrors and glides need no reverse, since repeating them cycles back.

## How often each move is drawn

Drawing every move equally often would let the walk spread faster along one direction of the lattice than another, and the tiling would render as a band. Instead the draws start from a split between the translations and the other moves that `symmetry` sets,

```math
p_k = \begin{cases} \dfrac{1 - s}{n_t} & \text{for each of the } n_t \text{ translations} \\ \dfrac{s}{n_r} & \text{for each of the other } n_r \text{ moves} \end{cases}
```

and tilt it, as little as possible, until the walk's spread grows at the same rate in every direction:

```math
w_k \propto p_k\, e^{-\lambda d_k}
```

where $d_k$ is how much move $k$ leans the spread one way and $\lambda$ is the one value that makes the lean vanish. Every weight stays positive, so no move is ever dropped, and a split that is already balanced is left as it is.

## Works with

- `p4m_fold` folds every point into one copy of the fundamental domain.
- `p4m_scatter` carries a folded point to a random copy within `reach`, even across the whole of it in one step.
- `p4m_region` routes the point by which of the group's special positions it lies on.

Give every plugin of the group the same lattice parameters, or their tiles, domains and special positions will not line up.
