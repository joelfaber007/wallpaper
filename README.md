# Wallpaper symmetry

This package repeats a flame across the plane with the symmetry of any of the
17 wallpaper groups. Each group comes as a small set of plugins that work
together: a transform that walks the point from tile to tile, a fold and a
scatter that build an exact kaleidoscope, and a decision function that routes
points by the group's special positions.

Symmetry along a line and round a point are in the `frieze` and `rosette`
packages.

## How a group acts

A symmetry group is a set of isometries: maps of the plane that keep every
distance. Writing the point as the complex number $z = x + iy$, every isometry
is a turn, perhaps after a flip, and then a shift:

```math
z \mapsto e^{i\theta} z + t \qquad\text{or}\qquad z \mapsto e^{i\theta}\bar{z} + t
```

The first kind, the direct isometries, are translations ($\theta = 0$) and
rotations. The second kind turn the plane over: a mirror holds a line still and
a glide reflects in a line and slides along it.

A wallpaper group's translations form a lattice

```math
\Lambda = \{\, m\,\mathbf{a}_1 + n\,\mathbf{a}_2 : m, n \in \mathbb{Z} \,\}
```

and its other elements carry the lattice onto itself, which is what limits a
wallpaper's rotations to orders 2, 3, 4 and 6. The parameters of every
wallpaper plugin set the lattice:

| Lattice | Parameters | Basis | Groups |
| --- | --- | --- | --- |
| oblique | `a`, `b`, `gamma` | $\mathbf{a}_1 = a, \quad \mathbf{a}_2 = b\,e^{i\gamma}$ | `p1`, `p2` |
| rectangular | `a`, `b` | $\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,b$ | `pm`, `pg`, `pmm`, `pmg`, `pgg` |
| centred rectangular | `a`, `b` | $\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,b, \quad \text{centring } \tfrac{1}{2}(\mathbf{a}_1 + \mathbf{a}_2)$ | `cm`, `cmm` |
| square | `a` | $\mathbf{a}_1 = a, \quad \mathbf{a}_2 = i\,a$ | `p4`, `p4m`, `p4g` |
| hexagonal | `a` | $\mathbf{a}_1 = a, \quad \mathbf{a}_2 = a\,e^{i\pi/3}$ | `p3`, `p3m1`, `p31m`, `p6`, `p6m` |

On an oblique lattice the pair you give is reduced to the shortest pair that
spans the same lattice, so any $a$, $b$ and $\gamma$ describe a lattice the
walk can tile evenly.

## The groups

| Group | Orbifold | Lattice | Point group | Domains per cell | Rotation centres | Mirror directions | Glide directions | Plugins |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `p1` | ○ | oblique | $C_{1}$ | 1 | none | none | none | transform, fold, scatter |
| `p2` | 2222 | oblique | $C_{2}$ | 2 | 4 × 2-fold | none | none | transform, fold, scatter, region |
| `pm` | ** | rectangular | $D_{1}$ | 2 | none | 1 | none | transform, fold, scatter, region |
| `pg` | ×× | rectangular | $D_{1}$ | 2 | none | none | 1 | transform, fold, scatter, region |
| `cm` | *× | centred rectangular | $D_{1}$ | 2 | none | 1 | 1 | transform, fold, scatter, region |
| `pmm` | *2222 | rectangular | $D_{2}$ | 4 | 4 × 2-fold | 2 | none | transform, fold, scatter, region |
| `pmg` | 22* | rectangular | $D_{2}$ | 4 | 2 × 2-fold | 1 | 1 | transform, fold, scatter, region |
| `pgg` | 22× | rectangular | $D_{2}$ | 4 | 2 × 2-fold | none | 2 | transform, fold, scatter, region |
| `cmm` | 2*22 | centred rectangular | $D_{2}$ | 4 | 3 × 2-fold | 2 | 2 | transform, fold, scatter, region |
| `p4` | 442 | square | $C_{4}$ | 4 | 2 × 4-fold, 1 × 2-fold | none | none | transform, fold, scatter, region |
| `p4m` | *442 | square | $D_{4}$ | 8 | 2 × 4-fold, 1 × 2-fold | 4 | 2 | transform, fold, scatter, region |
| `p4g` | 4*2 | square | $D_{4}$ | 8 | 1 × 4-fold, 1 × 2-fold | 2 | 4 | transform, fold, scatter, region |
| `p3` | 333 | hexagonal | $C_{3}$ | 3 | 3 × 3-fold | none | none | transform, fold, scatter, region |
| `p3m1` | *333 | hexagonal | $D_{3}$ | 6 | 3 × 3-fold | 3 | 3 | transform, fold, scatter, region |
| `p31m` | 3*3 | hexagonal | $D_{3}$ | 6 | 2 × 3-fold | 3 | 3 | transform, fold, scatter, region |
| `p6` | 632 | hexagonal | $C_{6}$ | 6 | 1 × 6-fold, 1 × 3-fold, 1 × 2-fold | none | none | transform, fold, scatter, region |
| `p6m` | *632 | hexagonal | $D_{6}$ | 12 | 1 × 6-fold, 1 × 3-fold, 1 × 2-fold | 6 | 6 | transform, fold, scatter, region |

The orbifold name is Conway's: each digit is a class of rotation centre of that
order, $*$ a mirror (digits after it are centres on mirrors), $\times$ a glide
with no mirror, and ○ a pattern with translations alone. The point group is
what is left when the translations are forgotten: $C_n$ is $n$ rotations, and
$D_n$ is $n$ rotations with $n$ mirrors.

## The plugins for a group

Each group's plugins share its name. Taking p4m as the example:

| Plugin | Kind | What it does |
| --- | --- | --- |
| `p4m` | transform | Applies one of the group's moves at random: a translation to a neighbouring tile, a turn, a mirror or a glide. Iterated, it walks the point over the whole tiling. |
| `p4m_fold` | transform | Folds every point into one copy of the fundamental domain, the smallest piece the group repeats. Deterministic: the same point always lands in the same place. |
| `p4m_scatter` | transform | Carries a point to a random copy of the domain within `reach` of the origin, every copy equally likely. |
| `p4m_region` | decision | Sends the point to one output for each class of rotation centre, one for the mirrors, one for the glides and one for the rest. |

Give every plugin of a group the same lattice parameters; otherwise their tiles,
domains and special positions will not line up.

## Recipes

These are flame graphs, written from the start node to the last function.
Each function named is one node.

**Tile a motif by walking.** Give the group's transform a branch of its own
from the start, beside the branches that draw the motif:

```
start ─┬─ your motif functions
       └─ p4m
```

Each iteration's point is the next one's input, so a point that has been
through the motif keeps being carried from tile to tile by `p4m`, and the
motif spreads over the tiling. Raise `symmetry` to have each tile's turns and
mirrors filled in sooner, lower it to have the pattern spread out faster.

**An exact kaleidoscope.** Fold the motif into the fundamental domain, then
scatter it over the tiling:

```
start ── your motif functions ── p4m_fold ── p4m_scatter
```

The fold gathers everything into one copy, and the scatter repeats that copy
evenly over every cell within `reach`. Nothing depends on how long it has run,
so the tiling is even from the first iteration and stops cleanly at `reach`.

**Paint the special positions.** Spread points over a disc and route them by
where they lie:

```
start ── affine (sx = sy = 0) ── circle ── p4m_region ─┬─ centre_0 ── blend_rgb
                                                       ├─ mirror ── blend_rgb
                                                       └─ general ── blend_rgb
```

`affine` (from `pyro/functions`) with zero scale sends every point to the
origin, `circle` (from `pyro/blur`) spreads it over a disc, `blend_rgb` (from
`pyro/colour`) paints it, and each output of `p4m_region` takes the points on one kind of
special position. `radius` and `width` set how near a centre or a line counts.

## Even tiling

The transforms do not draw their moves equally often. On a lattice longer one
way than the other, equal draws would let the walk spread faster along that
direction, and the tiling would render as a band. Each transform starts from a
split between translations and the other moves that `symmetry` sets,

```math
p_k = \begin{cases} \dfrac{1 - s}{n_t} & \text{for each of the } n_t \text{ translations} \\ \dfrac{s}{n_r} & \text{for each of the other } n_r \text{ moves} \end{cases}
```

and tilts it as little as possible, in the sense of relative entropy, until
the walk's spread grows at the same rate in every direction:

```math
w_k \propto p_k\, e^{-\lambda d_k}
```

Here $d_k$ is how far move $k$ leans the spread one way, and $\lambda$ the one
value that makes the lean vanish. Every weight stays positive, so no move is
dropped and the whole group is still reached.

## Each plugin's own page

Every plugin has a page of its own in the package manager, with the group's
facts, the maths of what it computes and the plugins it works with. A
transform's page lists each of its moves as a map of $z$.
