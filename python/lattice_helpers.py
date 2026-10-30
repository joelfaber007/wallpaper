import functools
import numpy


#
# Helper functions for the lattices the wallpaper groups tile the plane with
#


@functools.lru_cache(maxsize=64)
def _reduce(a: float, b: float, gamma: float) -> tuple[complex, complex]:
    """The two shortest vectors that generate the same lattice as
    (a, 0) and b*(cos(gamma), sin(gamma)), at an angle of at least 90
    degrees to each other.

    Lagrange-Gauss reduction: repeatedly subtract whole multiples of the
    shorter vector from the longer one. Every step subtracts a lattice
    vector from a lattice vector, so the lattice never changes; only the
    basis naming it does.

    The basis matters because a chaos game on a wallpaper group is a random
    walk, and its steps are the basis vectors and their sum. The walk spreads
    along a direction as the square root of the variance of its steps in that
    direction, so a skewed basis spreads the render into a band even though
    the lattice it names is perfectly reasonable. A reduced basis has its
    two vectors as short and as near perpendicular as the lattice allows.

    The angle is what makes v1 + v2 the shorter diagonal of the cell rather
    than the longer one. The three vectors v1, v2 and -(v1 + v2) then meet
    pairwise at 90 degrees or more -- an obtuse superbase -- and weighting
    each by minus the dot product of the other two spreads the walk evenly
    in every direction, whatever the lattice.
    """

    v1 = numpy.array([a, 0.0])
    v2 = b * numpy.array([numpy.cos(gamma), numpy.sin(gamma)])

    # A degenerate lattice has no reduced basis to find; hand the vectors
    # back and let the caller render whatever they describe.
    if abs(v1[0] * v2[1] - v1[1] * v2[0]) < 1e-12:
        return complex(*v1), complex(*v2)

    # Each pass shortens v2, so this terminates; the bound only stops a
    # rounding pathology from looping forever.
    for _ in range(1000):
        if v2 @ v2 < v1 @ v1:
            v1, v2 = v2, v1

        mu = numpy.round((v1 @ v2) / (v1 @ v1))
        if mu == 0:
            break

        v2 = v2 - mu * v1

    # -v2 generates the same lattice as v2, so the sign is free to choose.
    if v1 @ v2 > 0.0:
        v2 = -v2

    return complex(*v1), complex(*v2)


def reduced(a: float, b: float, gamma: float, index: int) -> complex:
    """Vector `index` (0 or 1) of the reduced basis. Two calls, one per
    lattice vector, share the cached reduction."""

    return _reduce(float(a), float(b), float(gamma))[index]


def anisotropy(a: float, b: float, gamma: float) -> float:
    """How much further the walk spreads along its widest direction than
    its narrowest, when it steps along the reduced basis and its sum with
    equal probability. 1.0 is a perfectly round spread; larger values
    render as a band."""

    v1, v2 = _reduce(float(a), float(b), float(gamma))
    v3 = v1 + v2
    step = numpy.array([[v.real, v.imag] for v in (v1, v2, v3)])
    covariance = (step.T @ step) / 3.0
    eigenvalues = numpy.linalg.eigvalsh(covariance)

    return float(numpy.sqrt(eigenvalues[1] / max(eigenvalues[0], 1e-300)))


#
# The name of the lattice a group's parameters describe
#

# Two values count as equal when they agree to within this share of the larger.
# Parameters are typed or dragged to a handful of decimals, so a lattice meant
# to be square arrives with gamma = 1.5708 rather than pi/2; an exact test
# would call it oblique.
_SAME = 1e-4


def _same(x: float, y: float) -> bool:
    return abs(x - y) <= _SAME * max(abs(x), abs(y))


def oblique_kind(a: float, b: float, gamma: float) -> str:
    """Which of the five lattice types (a, 0) and b*(cos(gamma),
    sin(gamma)) generate: oblique, rectangular, rhombic, square or
    hexagonal.

    The type belongs to the lattice, not to the pair that names it, so it is
    read off the reduced basis: a = 1, b = 2, gamma = 60 degrees is a
    rectangular lattice, named by a skewed pair. The reduced vectors v1 and
    v2, with v3 = -(v1 + v2), come shortest first, and only v1 and v2 can
    meet at a right angle. The lattice has a mirror
    -- rhombic -- when two of the three are the same length, and is
    hexagonal when all three are.
    """

    v1, v2 = _reduce(float(a), float(b), float(gamma))
    l1, l2, l3 = abs(v1) ** 2, abs(v2) ** 2, abs(v1 + v2) ** 2
    right = abs((v1.conjugate() * v2).real) <= _SAME * numpy.sqrt(l1 * l2)

    if _same(l1, l3):
        return "hexagonal"
    if right:
        return "square" if _same(l1, l2) else "rectangular"
    if _same(l1, l2) or _same(l2, l3):
        return "rhombic"

    return "oblique"


def rectangular_kind(a: float, b: float) -> str:
    """The lattice type of an `a` by `b` rectangular cell: square when the
    sides agree, rectangular otherwise."""

    return "square" if _same(float(a), float(b)) else "rectangular"


def centred_kind(a: float, b: float) -> str:
    """The lattice type of an `a` by `b` rectangular cell with a point at
    its centre: rhombic, unless the sides make it more.

    Equal sides give a square lattice, turned 45 degrees to the cell. Sides
    in the ratio sqrt(3) give a hexagonal one, since the centring vector is
    then as long as the shorter side."""

    a, b = float(a), float(b)
    if _same(a, b):
        return "square"
    if _same(max(a, b), numpy.sqrt(3.0) * min(a, b)):
        return "hexagonal"

    return "rhombic"
