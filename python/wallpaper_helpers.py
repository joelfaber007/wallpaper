import functools
from collections.abc import Callable

import numpy
import scipy.optimize

import lattice_helpers
import _wallpaper_moves


#
# Helper functions for the wallpaper package's move weights
#

# Each wallpaper plugin spells its move set out in a
# `__constant PyroReal wp_<name>_moves[]` table, which `_wallpaper_moves`
# holds the same rows of. The weights are worked out from those rows rather than
# restated here, so the moves the kernel executes and the weights it draws
# them with cannot drift apart.


@functools.lru_cache(maxsize=32)
def _moves(group: str) -> numpy.ndarray:
    """The (c, s, f, ca, cb) rows of a group's move table, in table order."""

    rows = _wallpaper_moves.MOVES.get(group)
    if rows is None:
        raise ValueError(f"no wallpaper group '{group}'")

    return numpy.array(rows)


def _linear(rows: numpy.ndarray) -> numpy.ndarray:
    """Each move's linear part, as a 2x2 matrix.

    The table stores it as (c, s, f): the plane is flipped when f is -1 and
    then turned by the unit complex number c + i*s, which is the matrix
    ((c, -s*f), (s, c*f)). A direct move has determinant +1 and an opposite
    one -1, so the sign of the determinant is what says whether a move turns
    the plane over."""

    c, s, f = rows[:, 0], rows[:, 1], rows[:, 2]

    return numpy.stack(
        [numpy.stack([c, -s * f], axis=1), numpy.stack([s, c * f], axis=1)],
        axis=1,
    )


def _offsets(
    rows: numpy.ndarray, ax: float, by: float, vectors: bool
) -> numpy.ndarray:
    """Each move's translation, in Cartesian coordinates.

    The table stores it as the pair (ca, cb), which the kernel scales by the
    parameters the group takes. Most groups scale the two by an axis length
    each; p1 and p2 read them as coefficients of the two lattice vectors,
    which the caller packs into (ax, by) as complex numbers."""

    ca, cb = rows[:, 3], rows[:, 4]

    if vectors:
        a1, a2 = complex(ax), complex(by)

        return numpy.stack(
            [ca * a1.real + cb * a2.real, ca * a1.imag + cb * a2.imag], axis=1
        )

    return numpy.stack([ca * ax, cb * by], axis=1)


def _identity(rows: numpy.ndarray) -> numpy.ndarray:
    """Which moves are plain translations."""

    return (rows[:, 0] == 1.0) & (rows[:, 1] == 0.0) & (rows[:, 2] == 1.0)


def _solve(
    d: numpy.ndarray,
    imbalance: Callable[[numpy.ndarray], float],
    prior: numpy.ndarray,
) -> numpy.ndarray:
    """Weights that balance the walk's spread.

    `imbalance(w)` is how far the walk drawn with weights `w` leans one way,
    as a share of its spread, and `d` is each move's part in that lean when
    the move is counted by its translation alone. Were the lean that linear
    sum, the balanced weighting closest to `prior` -- the minimum relative
    entropy solution -- would be `w ∝ prior*exp(-lam*d)` for one `lam`. The
    weights are taken from that family, with the `lam` at which the walk's
    actual lean is zero. `prior` says how the draws would be split if the
    walk were already balanced and nothing had to be corrected.

    Two properties matter. Every weight stays positive, so no move is ever
    dropped and the group is still generated in full. And when the prior is
    already balanced `lam` is zero, so the split is left exactly as asked.

    When no weighting in the family balances the walk, the prior comes back
    unchanged: the walk is then as even as it can be made without dropping a
    move, and the render still shows the group.
    """

    # The lean is a share of the spread, so it is compared with zero on a
    # scale that does not depend on the size of the cell.
    if abs(imbalance(prior)) <= 1e-12:
        return prior.copy()

    # Without a move on each side of the lean, tilting the draws towards one
    # side has nothing to tilt them towards.
    if not d.min() < 0.0 < d.max():
        return prior.copy()

    # Scaled so lam is of order one whatever the size of the cell.
    d = d / numpy.abs(d).max()

    def tilted(lam: float) -> numpy.ndarray:
        # Shifted before exponentiating so a large lam cannot overflow.
        x = -lam * d
        e = prior * numpy.exp(x - x.max())
        return e / e.sum()

    def lean(lam: float) -> float:
        return imbalance(tilted(lam))

    # As lam grows the draws pile onto the moves that lean the other way, so
    # the lean falls; the root is searched for on the side that reduces it.
    # Past a few thousand every weight but the extremes has underflowed.
    side = 1.0 if lean(0.0) > 0.0 else -1.0
    near = 0.0
    far = side
    while lean(far) * side > 0.0:
        if abs(far) > 4096.0:
            return prior.copy()
        near, far = far, far * 2.0

    lam = scipy.optimize.brentq(lean, min(near, far), max(near, far), xtol=1e-14)

    return tilted(lam)


def _prior(rows: numpy.ndarray, symmetry: float) -> numpy.ndarray:
    """How the draws split between moving to another tile and turning the
    plane over onto itself.

    A move whose linear part is the identity is a plain translation; every
    other row is one of the isometries that make the group what it is. Left
    to itself the split is whatever the row counts happen to give, which is
    an accident of how many neighbours the lattice has. `symmetry` sets it
    deliberately: it is the share of draws that go to the isometries, so a
    higher value turns the motif through its point group more often before
    carrying it off to the next tile.
    """

    identity = _identity(rows)
    count = int(identity.sum())

    # p1 has no isometries at all, so there is nothing to split.
    if count == 0 or count == len(rows):
        return numpy.full(len(rows), 1.0 / len(rows))

    prior = numpy.empty(len(rows))
    prior[identity] = (1.0 - symmetry) / count
    prior[~identity] = symmetry / (len(rows) - count)

    return prior


@functools.lru_cache(maxsize=32)
def _point_group(group: str) -> numpy.ndarray:
    """The linear part of every isometry the moves compose to, as 2x2
    matrices, the identity first.

    The linear parts are rotations and reflections that carry the lattice to
    itself, so they compose to a finite group -- at most twelve elements."""

    linear = _linear(_moves(group))

    found = [numpy.eye(2)]
    frontier = [numpy.eye(2)]
    while frontier:
        grown = []
        for a in frontier:
            for b in linear:
                c = b @ a
                if not any(numpy.allclose(c, f, atol=1e-9) for f in found):
                    found.append(c)
                    grown.append(c)
        frontier = grown

    return numpy.array(found)


def _growth(
    rows: numpy.ndarray, t: numpy.ndarray, w: numpy.ndarray, group: numpy.ndarray
) -> numpy.ndarray:
    """How much the walk's covariance grows per step, once it has run long
    enough to forget where it started.

    A move is z -> L z + t. Reversing the order of n moves does not change
    their distribution, and in reverse the walk's position is a sum of steps
    R t_k, where R is the product of the linear parts drawn before move k. R
    wanders over the point group `group` and soon is equally likely to be any
    element of it, so every step is averaged over the point group.

    The steps are correlated as well. Move k shares its L with every later
    step, whose expected sum is L h, with h = (I - A)^-1 b summing the
    expected translations A^j b that follow -- A and b being the mean linear
    part and the mean translation. A mirror or a turn moves a point by an
    amount that depends on where the point is, and this cross term is what
    carries it; counting each move by its own translation alone misses it.

    A part of b that every linear part leaves alone would be a drift, which
    grows faster than any spread. The move tables offer every move with its
    inverse so there is none, and the pseudo-inverse drops it if there were.
    """

    linear = _linear(rows)
    mean_linear = numpy.einsum("n,nij->ij", w, linear)
    h = numpy.linalg.pinv(numpy.eye(2) - mean_linear) @ (w @ t)
    follows = linear @ h

    cross = numpy.einsum("n,ni,nj->ij", w, t, follows)
    step = numpy.einsum("n,ni,nj->ij", w, t, t) + cross + cross.T

    return numpy.einsum("kij,jl,kml->im", group, step, group) / len(group)


def _lopsided(m: numpy.ndarray) -> complex:
    """The part of a 2x2 covariance that makes it uneven, as one complex
    number: zero for a round spread, and otherwise as large as the gap
    between its widest and narrowest directions, with twice the angle of the
    widest as its argument. For a single step t it is the complex square
    t**2."""

    return complex(m[0, 0] - m[1, 1], 2.0 * m[0, 1])


def _balance_axis(ax: complex, by: complex, vectors: bool) -> complex:
    """The direction a walk is balanced along, as the lopsided value that
    counts as leaning one way; its opposite counts as leaning the other.

    The groups that take two axis lengths are balanced along x against y,
    which is 1. Every one of them has a mirror, a glide or a turn among its
    linear parts that cancels the walk's xy spread, so a walk that spreads as
    far along x as along y is round.

    An oblique lattice has no preferred axes, so its direction must turn with
    the lattice. Every translation in p1 and p2 is a multiple of a1 or a2,
    and their only turn is a half turn, which cancels nothing; the walk's
    lopsided part, as a share of its spread, therefore lies on the segment
    between u1 = a1**2/|a1|**2 and u2, and the point of that segment nearest
    zero is its midpoint, since both are unit length. So the most even walk
    two directions allow spreads as far along a1 as along a2, and that is
    measured along u1 - u2. Turning the lattice turns u1 - u2 with it, so the
    weights depend on the lattice's shape and not on how it sits in the
    plane. A degenerate lattice, whose two directions coincide, gives zero:
    there is nothing to balance, and every move is left to the prior."""

    if not vectors:
        return 1.0 + 0.0j

    return ax**2 / abs(ax) ** 2 - by**2 / abs(by) ** 2


@functools.lru_cache(maxsize=256)
def _weights(
    group: str, ax: float, by: float, vectors: bool, symmetry: float
) -> tuple[float, ...]:
    rows = _moves(group)
    t = _offsets(rows, ax, by, vectors)
    points = _point_group(group)
    axis = _balance_axis(complex(ax), complex(by), vectors).conjugate()

    def imbalance(w: numpy.ndarray) -> float:
        spread = _growth(rows, t, w, points)
        return (_lopsided(spread) * axis).real / numpy.trace(spread)

    # Each move's part in the lean when counted by its translation alone.
    alone = ((t[:, 0] + 1j * t[:, 1]) ** 2 * axis).real

    return tuple(_solve(alone, imbalance, _prior(rows, symmetry)))


def weights(
    group: str, ax: float, by: float, symmetry: float = 0.5
) -> tuple[float, ...]:
    """The draw probability of each move, in table order."""

    return _weights(group, float(ax), float(by), False, float(symmetry))


def threshold(
    group: str, index: int, ax: float, by: float, symmetry: float = 0.5
) -> float:
    """Cumulative probability up to and including move `index`.

    The kernel draws one uniform value and counts how many thresholds it
    reaches, which picks a move with these probabilities and without
    branching. Only the first n-1 are needed; the last is always 1.
    """

    return float(numpy.cumsum(weights(group, ax, by, symmetry))[index])


def vector_weights(
    group: str, a1: complex, a2: complex, symmetry: float = 0.5
) -> tuple[float, ...]:
    """As `weights`, for the groups whose translations are given by two
    lattice vectors rather than two axis lengths."""

    return _weights(group, complex(a1), complex(a2), True, float(symmetry))


def vector_threshold(
    group: str, index: int, a1: complex, a2: complex, symmetry: float = 0.5
) -> float:
    return float(numpy.cumsum(vector_weights(group, a1, a2, symmetry))[index])


def oblique_threshold(
    group: str, index: int, a: float, b: float, gamma: float,
    symmetry: float = 0.5,
) -> float:
    """As `threshold`, for the groups that take an oblique lattice. The basis
    is reduced first, exactly as the kernel's own lattice vectors are, so the
    weights belong to the moves the kernel will actually make."""

    return vector_threshold(
        group,
        index,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
        symmetry,
    )


def anisotropy(
    group: str, ax: float, by: float, weighted: bool = True, symmetry: float = 0.5
) -> float:
    """How much further the walk spreads along its widest direction than its
    narrowest. 1.0 is a perfectly round spread."""

    rows = _moves(group)
    w = (
        numpy.array(weights(group, ax, by, symmetry))
        if weighted
        else numpy.full(len(rows), 1.0 / len(rows))
    )
    spread = _growth(rows, _offsets(rows, ax, by, False), w, _point_group(group))
    eigenvalues = numpy.linalg.eigvalsh(spread)

    return float(numpy.sqrt(eigenvalues[1] / max(eigenvalues[0], 1e-300)))


#
# The special positions: the points and lines the group holds still
#

# A wallpaper group is not uniform over its tile. Some points sit on a rotation
# centre, some on a mirror line, some on a glide axis, and the rest are held by
# nothing; a decision function that asks which of those a point is near is
# asking the only question about a tile that the group itself answers.
#
# All of it comes out of the same `wp_<name>_moves` table the weights do.
# Nothing here restates a group's geometry, so a decision function can no more
# disagree with the transform it decides for than the weights can -- which is
# the point, since a mirror in the wrong place is exactly the kind of mistake
# that renders as a plausible-looking tiling of the wrong group.


def _basis_matrix(e1: complex, e2: complex) -> numpy.ndarray:
    """The two vectors as the columns of a matrix, which is the map from
    lattice coordinates to the plane."""

    return numpy.array([[e1.real, e2.real], [e1.imag, e2.imag]])


def _reduce(u: numpy.ndarray, v: numpy.ndarray) -> tuple[complex, complex]:
    """The shortest pair generating the same lattice as u and v.

    Lagrange-Gauss reduction: while the longer vector has a whole multiple of
    the shorter one worth taking out of it, take it out. Every step subtracts
    a lattice vector from a lattice vector, so the lattice never changes, and
    each step shortens what it touches, so it ends.

    A tie leaves the pair alone. Two vectors of the same length, or a multiple
    of exactly one half, can be swapped or subtracted either way for a basis
    just as short, and which one comes out would otherwise be decided by the
    last bit of a square root -- a hexagonal group is exactly that case. The
    positions below are all named against this basis, so it settles ties
    rather than inheriting them.
    """

    for _ in range(64):
        if v @ v < u @ u * (1.0 - 1e-9):
            u, v = v, u

        share = (u @ v) / (u @ u)
        if abs(share) <= 0.5 + 1e-9:
            break

        v = v - numpy.round(share) * u

    return complex(*u), complex(*v)


@functools.lru_cache(maxsize=32)
def _cells(group: str) -> tuple[complex, complex]:
    """The two vectors that generate the group's translations, in the (ca, cb)
    coordinates the move table is written in.

    The moves whose linear part is the identity are the translations, so the
    lattice is read from the table rather than restated. Any pair of them that
    writes every other one as a whole-number combination is a basis of it; the
    pair is then reduced, so which one the search happens to find first does
    not change the answer.

    A centred group is why this cannot simply take the first two rows: cm and
    cmm tile with a lattice that has a point at the middle of every rectangle
    their parameters name, and the pair that generates it is a pair of those
    centring vectors, not the sides.

    The search runs in table coordinates rather than in the plane, which keeps
    the answer independent of the lengths the group is given. Reducing in the
    plane instead would let a change of `a` or `b` swap which pair comes out
    shortest, and every position below is named relative to this basis -- so a
    class of rotation centre would change its number under a slider, and a
    decision function would follow it to a different feature.
    """

    rows = _moves(group)
    cells = rows[_identity(rows)][:, 3:5]

    def generates(u: numpy.ndarray, v: numpy.ndarray) -> bool:
        """Is every translation a whole-number combination of u and v?"""

        weight = numpy.linalg.solve(numpy.array([u, v]).T, cells.T)

        return bool(numpy.all(numpy.abs(weight - numpy.round(weight)) < 1e-6))

    def angle(u: numpy.ndarray) -> float:
        return round(float(numpy.arctan2(u[1], u[0]) % (2.0 * numpy.pi)), 9)

    best = None
    for u in cells:
        for v in cells:
            if abs(u[0] * v[1] - u[1] * v[0]) < 1e-9 or not generates(u, v):
                continue

            key = (round(float(u @ u), 9), round(float(v @ v), 9),
                   angle(u), angle(v))
            if best is None or key < best[0]:
                best = (key, u, v)

    if best is None:
        raise ValueError(f"the moves of '{group}' do not generate a lattice")

    e1, e2 = _reduce(best[1], best[2])

    # Fix the handedness so the pair is one basis and not two. Reduction is
    # blind to the order and the sign of what it is given, and the caller reads
    # lattice coordinates off this pair.
    if (e1.conjugate() * e2).imag < 0.0:
        e2 = -e2

    return e1, e2


@functools.lru_cache(maxsize=32)
def _elements(
    group: str,
) -> tuple[tuple[tuple[float, ...], tuple[float, ...]], ...]:
    """The group's isometries, one per class of them that differ by a
    translation, in lattice coordinates.

    Every move is an isometry of the group and so is every composition of
    moves, which is an infinite set; what makes it finite is that two
    isometries differing by a lattice vector do the same thing to the tiling.
    Taking the closure modulo the lattice therefore terminates, and it
    terminates at the order of the point group -- as many elements as one cell
    holds copies of the fundamental domain.

    Each is returned as its linear part and the translation that follows it,
    the translation folded into the cell so a long composition cannot drift.
    """

    rows = _moves(group)
    cell = _basis_matrix(*_cells(group))
    inverse = numpy.linalg.inv(cell)

    # In lattice coordinates the moves are integer arithmetic -- the linear
    # parts permute the lattice and the translations are whole cells -- so the
    # closure is exact rather than a walk through accumulating rounding.
    linear = [inverse @ a @ cell for a in _linear(rows)]
    offset = [inverse @ t for t in _offsets(rows, 1.0, 1.0, False)]

    def fold(a: numpy.ndarray, t: numpy.ndarray):
        """One element, and the name under which it is already known.

        The name is rounded so two arrivals at the same element meet, but what
        is kept is not: every position below is measured off these, and a
        rounded translation would put a floor under how finely two lines can
        be told apart.
        """

        t = t - numpy.floor(t + 1e-9)
        name = (tuple(numpy.round(a, 6).ravel() + 0.0),
                tuple(numpy.round(t, 6) + 0.0))

        return name, (a, t)

    name, start = fold(numpy.eye(2), numpy.zeros(2))
    found = {name: start}
    frontier = [start]
    while frontier:
        grown = []
        for a, t in frontier:
            for b, s in zip(linear, offset):
                name, step = fold(b @ a, b @ t + s)
                if name not in found:
                    found[name] = step
                    grown.append(step)
        frontier = grown

    return tuple((tuple(a.ravel()), tuple(t))
                 for _, (a, t) in sorted(found.items()))


def _rotation_order(a: numpy.ndarray) -> int:
    """How many times a linear part has to be applied to come back to where it
    started, or 0 if it turns the plane over rather than about a point."""

    if numpy.linalg.det(a) < 0.0:
        return 0

    for order in (1, 2, 3, 4, 6):
        turned = numpy.linalg.matrix_power(a, order)
        if numpy.allclose(turned, numpy.eye(2), atol=1e-6):
            return order

    return 0


@functools.lru_cache(maxsize=32)
def _centres(
    group: str,
) -> tuple[tuple[int, tuple[tuple[tuple[float, float], ...], ...]], ...]:
    """The rotation centres, in lattice coordinates, gathered by their order
    and then into the classes the group cannot carry one into another.

    A direct move that is not a translation turns the plane about a single
    point, the one solving (I - A)p = t. Every lattice translate of that move
    is in the group too and turns about its own point, so one move's centres
    already fill the plane -- and because the plane is folded back into one
    cell, a half turn's translates land on quarters and a third of a turn's on
    thirds, which is where the (1/2, 1/2) and (1/3, 1/3) centres come from.

    A centre is listed under the highest order that holds it, so p6's 6-fold
    centre is not also counted among its 3-folds even though a third of a turn
    does hold it. That is what makes the classes here the same count the
    orbifold name gives: 632 for p6, 2222 for p2, 442 for p4.

    Two centres the group carries into one another are one feature seen twice
    -- a motif placed on one appears on the other whether it is asked for or
    not -- so they are gathered into a single class. Centres in different
    classes are independent, and are the ones worth telling apart.
    """

    elements = [(numpy.array(a).reshape(2, 2), numpy.array(t))
                for a, t in _elements(group)]

    # Each element's translates turn about points that differ, so the whole
    # cell's worth of centres needs the neighbouring cells' copies as well.
    # Two either way is more than the finest division any of the 17 makes.
    span = range(-2, 3)

    def same(p, q) -> bool:
        d = numpy.array(p) - numpy.array(q)
        return bool(numpy.all(numpy.abs(d - numpy.round(d)) < 1e-5))

    places: list[tuple[float, float]] = []
    for a, t in elements:
        if _rotation_order(a) < 2:
            continue

        for m in span:
            for n in span:
                point = numpy.linalg.solve(
                    numpy.eye(2) - a, t + numpy.array([m, n])
                )
                point = point - numpy.floor(point + 1e-9)
                if not any(same(point, other) for other in places):
                    places.append((float(point[0]), float(point[1])))

    def order_at(p) -> int:
        """The highest order of any rotation that holds p still."""

        return max((_rotation_order(a) for a, t in elements
                    if same(a @ numpy.array(p) + t, p)), default=1)

    orders: dict[int, list[tuple[float, float]]] = {}
    for place in places:
        orders.setdefault(order_at(place), []).append(place)

    classes: dict[int, tuple] = {}
    for order, group_places in orders.items():
        remaining = sorted(group_places)
        found = []
        while remaining:
            orbit = [remaining.pop(0)]
            for a, t in elements:
                image = a @ numpy.array(orbit[0]) + t
                image = image - numpy.floor(image + 1e-9)
                if not any(same(image, other) for other in orbit):
                    orbit.append((float(image[0]), float(image[1])))
            remaining = [r for r in remaining
                         if not any(same(r, o) for o in orbit)]
            found.append(tuple(sorted(orbit)))
        classes[order] = tuple(sorted(found))

    return tuple(sorted(classes.items(), reverse=True))


def _cluster(values: list[float], close: float) -> list[float]:
    """The distinct values among `values`, in order, counting two as one when
    they are the same to within `close`."""

    grouped: list[list[float]] = []
    for value in sorted(values):
        if grouped and value - grouped[-1][-1] <= close:
            grouped[-1].append(value)
        else:
            grouped.append([value])

    return [sum(one) / len(one) for one in grouped]


def _metric(ax: float, by: float, vectors: bool) -> numpy.ndarray:
    """The map from the table's (ca, cb) coordinates to the plane."""

    if vectors:
        a1, a2 = complex(ax), complex(by)

        return numpy.array([[a1.real, a2.real], [a1.imag, a2.imag]])

    return numpy.array([[ax, 0.0], [0.0, by]])


@functools.lru_cache(maxsize=256)
def _lines(
    group: str, ax: float, by: float, vectors: bool
) -> tuple[tuple[tuple[float, ...], ...], tuple[tuple[float, ...], ...]]:
    """The mirror lines and the glide axes, in the plane, gathered into
    families of parallel lines.

    An opposite move turns the plane over about some line. Split its
    translation into the part along that line and the part across it: the part
    across only says which of the parallel lines it is, since the move fixes
    the one halfway; the part along says what kind of line it is. Nothing along
    it and the move is a mirror, which holds every point of the line still.
    Something along it and the move is a glide, which holds no point at all yet
    still leaves the tiling unchanged.

    A mirror composed with a translation along itself is a glide on that same
    line and is not a place of its own, so those are dropped -- which is why
    pmm comes out with no glide axes despite having glide reflections in
    abundance, and why cm keeps the ones a quarter of a cell from its mirrors.

    Composition is what turns three reflections in p4m's table into the four
    directions it really has, so the whole group is walked and not just the
    moves the kernel draws from.

    Unlike the rotation centres this depends on the lengths the group is given:
    a rectangular group's two families lie `b` apart one way and `a` the other.
    Each family is returned as (direction x, direction y, offset, spacing,
    slip): a unit vector along the lines, the signed distance across that
    direction from the origin to the first of them, how far apart consecutive
    ones are, and how far a glide slides along itself -- zero for a mirror.
    """

    cell = _metric(ax, by, vectors) @ _basis_matrix(*_cells(group))
    inverse = numpy.linalg.inv(cell)
    scale = max(float(numpy.abs(cell).max()), 1e-300)
    close = 1e-9 * scale

    # An opposite move composed with a translation is another opposite move on
    # a parallel line, and it takes a span of them to show how far apart the
    # lines of one family lie.
    span = range(-2, 3)
    seen: dict[float, dict[bool, list[tuple[float, float]]]] = {}
    axes: dict[float, tuple[float, float]] = {}

    for element, offset in _elements(group):
        a = cell @ numpy.array(element).reshape(2, 2) @ inverse
        if numpy.linalg.det(a) > 0.0:
            continue

        # The axis is the direction the reflection leaves alone; the one it
        # negates lies across. Both are faced the same way whichever end of the
        # line they are found from, so one line is one family and not two.
        values, vector = numpy.linalg.eigh(a)
        along = vector[:, numpy.argmax(values)]
        if along[1] < 0.0 or (abs(along[1]) <= close and along[0] < 0.0):
            along = -along
        across = numpy.array([-along[1], along[0]])

        angle = round(float(numpy.arctan2(along[1], along[0])), 6)
        axes.setdefault(angle, (float(along[0]), float(along[1])))
        for m in span:
            for n in span:
                step = cell @ (numpy.array(offset) + numpy.array([m, n]))
                slip = float(step @ along)
                place = float(step @ across) / 2.0
                family = seen.setdefault(angle, {})
                family.setdefault(abs(slip) < close, []).append(
                    (place, abs(slip))
                )

    def gather(found: list[tuple[float, float]]) -> tuple[float, float, float]:
        """One family's first line, its spacing, and its glide's slide."""

        places = _cluster([place for place, _ in found], close)
        gaps = [b - a for a, b in zip(places, places[1:]) if b - a > close]
        spacing = min(gaps) if gaps else 0.0
        slip = min((s for _, s in found if s > close), default=0.0)

        if spacing <= close:
            return float(places[0]), 0.0, slip

        # Name the family by the line in [0, spacing), so which of the window's
        # copies happened to sort first does not show in the answer.
        first = float(numpy.mod(places[0], spacing))

        return (0.0 if spacing - first <= close else first), spacing, slip

    def carries(place: float, first: float, spacing: float) -> bool:
        """Is `place` one of the lines that family already holds?"""

        if spacing <= close:
            return abs(place - first) <= close

        step = float(numpy.mod(place - first, spacing))

        return min(step, spacing - step) <= close

    mirrors, glides = [], []
    for angle in sorted(seen):
        direction = axes[angle]
        straight = seen[angle].get(True, [])
        sliding = seen[angle].get(False, [])

        if straight:
            first, spacing, _ = gather(straight)
            mirrors.append(direction + (first, spacing, 0.0))
            sliding = [s for s in sliding if not carries(s[0], first, spacing)]

        if sliding:
            first, spacing, slip = gather(sliding)
            glides.append(direction + (first, spacing, slip))

    return tuple(mirrors), tuple(glides)


# The accessors an INI expression reaches for. Each hands back one number,
# because that is what an INI argument is; a plugin spells out as many calls as
# the group has positions, the same way it spells out its move weights.
#
# The lattice is given the same two ways the weights are. Most groups name it
# with an axis length each way; p1 and p2 name it with two vectors, and take
# the `vector_` and `oblique_` calls instead. The mirror and glide calls have
# no such pair, because the only groups that name their lattice with vectors
# are the two oblique ones and neither has a mirror or a glide to ask about.


def _resolve(
    group: str, order: int, klass: int
) -> tuple[tuple[float, float], ...]:
    """One class of rotation centre, or a reason there is no such class."""

    classes = dict(_centres(group))
    if int(order) not in classes:
        held = ", ".join(str(n) for n in sorted(classes, reverse=True))
        raise ValueError(
            f"'{group}' has no {order}-fold rotation centre; "
            f"it has {held or 'none'}"
        )

    found = classes[int(order)]
    if not 0 <= int(klass) < len(found):
        raise ValueError(
            f"'{group}' has {len(found)} class(es) of {order}-fold centre, "
            f"so there is no class {klass}"
        )

    return found[int(klass)]


def _place(
    group: str, ax: float, by: float, vectors: bool, u: float, v: float
) -> complex:
    """A point given in lattice coordinates, placed in the plane."""

    cell = _metric(ax, by, vectors) @ _basis_matrix(*_cells(group))
    point = cell @ numpy.array([u, v])

    return complex(point[0], point[1])


def basis(group: str, ax: float, by: float, index: int) -> complex:
    """Lattice vector `index` (0 or 1) of the lattice the group tiles with.

    A decision function needs both to fold a point back into one cell, which
    is what every question about position asks first. For cm and cmm this is
    not the rectangle the parameters name but the smaller centred cell that
    rectangle holds two of."""

    u, v = (1.0, 0.0) if int(index) == 0 else (0.0, 1.0)

    return _place(group, float(ax), float(by), False, u, v)


def vector_basis(group: str, a1: complex, a2: complex, index: int) -> complex:
    """As `basis`, for the groups whose lattice is given by two vectors."""

    u, v = (1.0, 0.0) if int(index) == 0 else (0.0, 1.0)

    return _place(group, complex(a1), complex(a2), True, u, v)


def oblique_basis(
    group: str, a: float, b: float, gamma: float, index: int
) -> complex:
    """As `basis`, for the groups that take an oblique lattice. The basis is
    reduced first, exactly as the kernel's own lattice vectors are."""

    return vector_basis(
        group,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
        index,
    )


def _fold_rows(cell: numpy.ndarray) -> numpy.ndarray:
    """The rows of the inverse of a basis, which turn a point in the plane
    into the lattice coordinates that name which cell it fell in and where in
    that cell it lies."""

    return numpy.linalg.inv(cell)


def fold(group: str, ax: float, by: float, index: int) -> complex:
    """Row `index` (0 or 1) of the inverse of the group's basis.

    `basis` carries lattice coordinates into the plane and this carries them
    back, which is what a decision function needs first: whatever it goes on
    to ask about a point, it asks about the point folded into one cell."""

    cell = _metric(float(ax), float(by), False) @ _basis_matrix(*_cells(group))
    row = _fold_rows(cell)[int(index)]

    return complex(row[0], row[1])


def vector_fold(group: str, a1: complex, a2: complex, index: int) -> complex:
    """As `fold`, for the groups whose lattice is given by two vectors."""

    cell = _metric(complex(a1), complex(a2), True) @ _basis_matrix(*_cells(group))
    row = _fold_rows(cell)[int(index)]

    return complex(row[0], row[1])


def oblique_fold(
    group: str, a: float, b: float, gamma: float, index: int
) -> complex:
    """As `fold`, for the groups that take an oblique lattice."""

    return vector_fold(
        group,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
        index,
    )


def centre_classes(group: str, order: int) -> int:
    """How many independent classes of `order`-fold rotation centre the group
    has. This is the number the orbifold name counts: 4 for p2's 2222, 2 and 1
    for p4's 442, 3 for p3's 333.

    A centre is counted under the highest order that holds it, so p6's 6-fold
    centre is not also one of its 3-folds."""

    return len(dict(_centres(group)).get(int(order), ()))


def centre_count(group: str, order: int, klass: int) -> int:
    """How many centres of one class lie in a single cell. They are the same
    feature seen more than once -- a motif placed on one appears on all of
    them -- so a decision function that wants the class wants every one."""

    return len(_resolve(group, order, klass))


def centre(
    group: str, order: int, klass: int, index: int, ax: float, by: float
) -> complex:
    """Centre `index` of one class of `order`-fold rotation centre."""

    u, v = _resolve(group, order, klass)[int(index)]

    return _place(group, float(ax), float(by), False, u, v)


def vector_centre(
    group: str, order: int, klass: int, index: int, a1: complex, a2: complex
) -> complex:
    """As `centre`, for the groups whose lattice is given by two vectors."""

    u, v = _resolve(group, order, klass)[int(index)]

    return _place(group, complex(a1), complex(a2), True, u, v)


def oblique_centre(
    group: str, order: int, klass: int, index: int,
    a: float, b: float, gamma: float,
) -> complex:
    """As `centre`, for the groups that take an oblique lattice."""

    return vector_centre(
        group,
        order,
        klass,
        index,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
    )


def _family(
    group: str, family: int, ax: float, by: float, glide: bool
) -> tuple[float, ...]:
    """One family of parallel mirror lines or glide axes."""

    found = _lines(group, float(ax), float(by), False)[1 if glide else 0]
    kind = "glide axes" if glide else "mirror lines"
    if not found:
        raise ValueError(f"'{group}' has no {kind}")

    if not 0 <= int(family) < len(found):
        raise ValueError(
            f"'{group}' has {len(found)} families of {kind}, "
            f"so there is no family {family}"
        )

    return found[int(family)]


def mirror_families(group: str, ax: float, by: float) -> int:
    """How many directions of mirror line the group has. p4m has four -- the
    two along the cell and the two along its diagonals -- and p6m six; a group
    with no mirror at all has none."""

    return len(_lines(group, float(ax), float(by), False)[0])


def mirror_direction(group: str, family: int, ax: float, by: float) -> complex:
    """A unit vector along the mirror lines of one family. Turned a quarter
    turn it is the direction to measure across them."""

    line = _family(group, family, ax, by, False)

    return complex(line[0], line[1])


def mirror_offset(group: str, family: int, ax: float, by: float) -> float:
    """How far across its own direction the family's first line lies from the
    origin, measured from 0 up to one spacing."""

    return _family(group, family, ax, by, False)[2]


def mirror_spacing(group: str, family: int, ax: float, by: float) -> float:
    """How far apart consecutive lines of one family lie."""

    return _family(group, family, ax, by, False)[3]


def glide_families(group: str, ax: float, by: float) -> int:
    """How many directions of glide axis the group has, counting only the axes
    that are not already a mirror -- a mirror slid along itself is a glide, and
    is not a place of its own. pmm therefore has none and pgg has two."""

    return len(_lines(group, float(ax), float(by), False)[1])


def glide_direction(group: str, family: int, ax: float, by: float) -> complex:
    """A unit vector along the glide axes of one family."""

    line = _family(group, family, ax, by, True)

    return complex(line[0], line[1])


def glide_offset(group: str, family: int, ax: float, by: float) -> float:
    """How far across its own direction the family's first axis lies from the
    origin, measured from 0 up to one spacing."""

    return _family(group, family, ax, by, True)[2]


def glide_spacing(group: str, family: int, ax: float, by: float) -> float:
    """How far apart consecutive axes of one family lie."""

    return _family(group, family, ax, by, True)[3]


def glide_slip(group: str, family: int, ax: float, by: float) -> float:
    """How far a glide slides along its own axis. It is half a lattice vector,
    which is what makes the glide belong to the group without its square being
    anything but a translation."""

    return _family(group, family, ax, by, True)[4]
