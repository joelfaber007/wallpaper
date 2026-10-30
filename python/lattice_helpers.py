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
