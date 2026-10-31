import functools

import numpy

import lattice_helpers
import wallpaper_helpers


#
# Helper functions for folding a point into one copy of a wallpaper group's
# fundamental domain, and for scattering it to a random copy
#

# A fundamental domain is a piece of the plane the group's isometries carry
# onto every other piece without overlap, so that the domain and the group
# together are the whole tiling. One cell of the lattice holds as many copies
# of it as the group's point group has elements: one for p1, twelve for p6m.
#
# The domain used here is the Dirichlet domain of a seed point p: everything
# nearer p than any other image of p under the group. Folding a point is then
# a matter of finding the image g(p) nearest to it and applying g's inverse,
# which carries the point into the domain. Where the group has mirrors they
# are edges of the domain whatever the seed, since a mirror is exactly the set
# of points as near p as its reflection, so a kaleidoscopic group folds into
# its kaleidoscope's chamber.
#
# Each kernel holds its group's copies as a `__constant PyroReal
# wp_<name>_copies[]` table, one row of five numbers (u, v, c, s, f) a copy:
# (u, v) is the image of the seed in the lattice coordinates of
# `wallpaper_helpers.basis`, and the plane is flipped when f is -1 and then
# turned by c + i*s to carry the domain onto that copy. The rows are the ones
# `copies` gives, and a kernel's table has to match them row for row.


# The finest division of the cell the seed is searched over. Every special
# position of the 17 groups lies on a multiple of 1/12 of the cell, so 1/48
# leaves room between them.
_SEED_STEPS = 48


@functools.lru_cache(maxsize=32)
def _seed(group: str) -> tuple[float, float]:
    """The seed point, in lattice coordinates.

    A seed that some isometry holds still -- one on a mirror, or on a rotation
    centre -- has fewer images than the group has elements, and its Dirichlet
    domain is that many times too big. The seed is therefore the point of a
    fine grid that lies furthest from the nearest of its own images, which
    puts it as deep inside a domain as the grid allows.

    Distances are measured in the coordinates the move table is written in,
    not in the plane, so the seed does not jump from one place to another as
    the lattice parameters move. Whether an isometry holds a point still does
    not depend on the metric, so a seed that is clear of every special
    position stays clear of them for any lattice the group takes.

    Ties go to the first point in (u, v) order, so the choice is the same
    every time.
    """

    elements = [(numpy.array(a).reshape(2, 2), numpy.array(t))
                for a, t in wallpaper_helpers._elements(group)]
    cell = wallpaper_helpers._basis_matrix(*wallpaper_helpers._cells(group))
    shifts = numpy.array([(m, n) for m in (-1, 0, 1) for n in (-1, 0, 1)])

    steps = numpy.arange(_SEED_STEPS) / _SEED_STEPS
    grid = numpy.array([(u, v) for u in steps for v in steps])

    nearest = numpy.full(len(grid), numpy.inf)
    for a, t in elements:
        # Folded into the cell first, so that the nearest copy of the image is
        # within one cell of the point either way.
        image = grid @ a.T + t
        image = image - numpy.floor(image + 1e-9)
        for shift in shifts:
            moved = image + shift - grid
            gap = numpy.einsum("ij,nj->ni", cell, moved)
            far = numpy.einsum("ni,ni->n", gap, gap)

            # The identity's own image at no shift is the point itself.
            if numpy.allclose(a, numpy.eye(2)) and not shift.any():
                continue

            nearest = numpy.minimum(nearest, far)

    best = int(numpy.argmax(nearest > nearest.max() * (1.0 - 1e-9)))

    return float(grid[best, 0]), float(grid[best, 1])


@functools.lru_cache(maxsize=32)
def copies(
    group: str,
) -> tuple[tuple[float, float, float, float, float], ...]:
    """The copies of the fundamental domain in one cell, as (u, v, c, s, f)
    rows.

    The first row is the domain itself, holding the seed. The direct copies --
    the ones the group only turns -- come next, in order of the angle they are
    turned through, and the copies that are mirror images of the domain come
    last, in order of the angle of the mirror that makes them.

    Every linear part of every group here is a rotation or a reflection in the
    plane as well as in the table's coordinates: the groups that turn through
    other than a half turn take a square or a hexagonal lattice, whose two
    axis lengths are equal. So (c, s, f) does not depend on the lattice
    parameters, and the table can be a constant.
    """

    p = numpy.array(_seed(group))
    cell = wallpaper_helpers._basis_matrix(*wallpaper_helpers._cells(group))
    inverse = numpy.linalg.inv(cell)

    rows = []
    for a, t in wallpaper_helpers._elements(group):
        a = numpy.array(a).reshape(2, 2)
        image = a @ p + numpy.array(t)
        image = image - numpy.floor(image + 1e-9)

        turn = cell @ a @ inverse
        flip = float(numpy.sign(numpy.linalg.det(turn)))
        c, s = float(turn[0, 0]), float(turn[1, 0])

        if not numpy.allclose(turn, [[c, -s * flip], [s, c * flip]], atol=1e-9):
            raise ValueError(f"'{group}' has a linear part that is not an isometry")

        rows.append((float(image[0]), float(image[1]), c, s, flip))

    return _ordered(rows)


def _ordered(
    rows: list[tuple[float, float, float, float, float]],
) -> tuple[tuple[float, float, float, float, float], ...]:
    """Copy rows in the order a kernel's table lists them: the turned copies
    by the angle they are turned through, the domain itself first, then the
    mirror images by the angle of their mirror.

    Rounded so the table in the kernel and the one here are written alike."""

    def order(row) -> tuple[float, float]:
        angle = numpy.arctan2(row[3], row[2]) % (2.0 * numpy.pi)

        # A mirror's angle is half the angle the reflection is written with.
        if row[4] < 0.0:
            return (1.0, round(float(angle / 2.0), 9))

        return (0.0, round(float(angle), 9))

    return tuple(
        tuple(round(x, 12) + 0.0 for x in row) for row in sorted(rows, key=order)
    )


#
# The basis the kernel searches for the nearest image with
#

# The kernel finds the copy of an image nearest to a point by folding their
# difference into one cell and trying the cell's four corners. That is exact
# only for a reduced basis, whose cell is split by its shorter diagonal into
# two triangles with no obtuse angle; the basis `wallpaper_helpers.basis`
# names positions against is reduced in the move table's coordinates, which
# need not be reduced in the plane once a and b differ. So the search is
# handed a basis of its own, reduced in the plane.


def _near(cell: numpy.ndarray) -> numpy.ndarray:
    """A reduced basis of the lattice `cell` generates, as matrix columns."""

    e1, e2 = wallpaper_helpers._reduce(cell[:, 0], cell[:, 1])

    return wallpaper_helpers._basis_matrix(e1, e2)


def _plane_cell(group: str, ax, by, vectors: bool) -> numpy.ndarray:
    return wallpaper_helpers._metric(ax, by, vectors) @ wallpaper_helpers._basis_matrix(
        *wallpaper_helpers._cells(group)
    )


def _column(m: numpy.ndarray, index: int) -> complex:
    return complex(m[0, int(index)], m[1, int(index)])


def _row(m: numpy.ndarray, index: int) -> complex:
    return complex(m[int(index), 0], m[int(index), 1])


def near_basis(group: str, ax: float, by: float, index: int) -> complex:
    """Vector `index` (0 or 1) of the basis the nearest image is searched
    with."""

    return _column(_near(_plane_cell(group, float(ax), float(by), False)), index)


def near_fold(group: str, ax: float, by: float, index: int) -> complex:
    """Row `index` (0 or 1) of the inverse of `near_basis`, which takes a
    step in the plane into that basis's coordinates."""

    near = _near(_plane_cell(group, float(ax), float(by), False))

    return _row(numpy.linalg.inv(near), index)


def oblique_near_basis(
    group: str, a: float, b: float, gamma: float, index: int
) -> complex:
    """As `near_basis`, for the groups that take an oblique lattice."""

    cell = _plane_cell(
        group,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
        True,
    )

    return _column(_near(cell), index)


def oblique_near_fold(
    group: str, a: float, b: float, gamma: float, index: int
) -> complex:
    """As `near_fold`, for the groups that take an oblique lattice."""

    cell = _plane_cell(
        group,
        lattice_helpers.reduced(a, b, gamma, 0),
        lattice_helpers.reduced(a, b, gamma, 1),
        True,
    )

    return _row(numpy.linalg.inv(_near(cell)), index)

