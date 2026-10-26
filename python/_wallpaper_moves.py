"""Every wallpaper group's move table, as its kernel declares it.

Each kernel spells its moves out in a `__constant PyroReal wp_<name>_moves[]`
table, one row of five numbers (c, s, f, ca, cb) a move: the plane is flipped
when f is -1, turned by the unit complex number c + i*s, and then moved by
(ca, cb) in the kernel's lattice units. The weights and the geometry
`wallpaper_helpers` works out all come from these rows.

A package's Python cannot read the kernels, so the tables are written out here
as well. `tests/test_wallpaper_moves.py` reads every kernel and checks that its
table and the one here are the same, row for row, so the moves the kernel
executes and the weights it draws them with cannot drift apart.

Private to the package's Python: `wallpaper_helpers` reads it, and INI
expressions have no use for the raw rows.
"""

MOVES: dict[str, tuple[tuple[float, float, float, float, float], ...]] = {
    "p1": (
        (1.0, 0.0, 1.0,  1.0,  0.0),  # translation by +a1
        (1.0, 0.0, 1.0, -1.0,  0.0),  # translation by -a1
        (1.0, 0.0, 1.0,  0.0,  1.0),  # translation by +a2
        (1.0, 0.0, 1.0,  0.0, -1.0),  # translation by -a2
    ),
    "p2": (
        ( 1.0, 0.0, 1.0,  1.0,  0.0),  # translation by +a1
        ( 1.0, 0.0, 1.0, -1.0,  0.0),  # translation by -a1
        ( 1.0, 0.0, 1.0,  0.0,  1.0),  # translation by +a2
        ( 1.0, 0.0, 1.0,  0.0, -1.0),  # translation by -a2
        (-1.0, 0.0, 1.0,  0.0,  0.0),  # half turn about the origin
        (-1.0, 0.0, 1.0,  1.0,  0.0),  # half turn about the midpoint of a1
    ),
    "pm": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        (-1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line x = 0
        (-1.0, 0.0, -1.0,  1.0,  0.0),  # mirror in the line x = a/2
    ),
    "pg": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        (-1.0, 0.0, -1.0,  0.0,  0.5),  # glide along the axis x = 0
        (-1.0, 0.0, -1.0,  0.0, -0.5),  # the same, backwards
    ),
    "cm": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        ( 1.0, 0.0,  1.0,  0.5,  0.5),  # centring translation, to the middle of the cell
        ( 1.0, 0.0,  1.0, -0.5, -0.5),  # the same, backwards
        (-1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line x = 0
        (-1.0, 0.0, -1.0,  0.5,  0.5),  # glide along the axis x = a/4
        (-1.0, 0.0, -1.0,  0.5, -0.5),  # the same, backwards
    ),
    "pmm": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        (-1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line x = 0
        ( 1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line y = 0
        (-1.0, 0.0,  1.0,  0.0,  0.0),  # half turn about the origin
    ),
    "pmg": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        (-1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line x = 0
        ( 1.0, 0.0, -1.0,  0.5,  0.0),  # glide along the axis y = 0
        (-1.0, 0.0,  1.0,  0.5,  0.0),  # half turn about (a/4, 0)
    ),
    "pgg": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        ( 1.0, 0.0, -1.0,  0.5,  0.0),  # glide along the axis y = 0
        (-1.0, 0.0, -1.0,  0.0,  0.5),  # glide along the axis x = 0
        (-1.0, 0.0,  1.0,  0.5,  0.5),  # half turn about (a/4, b/4)
    ),
    "cmm": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +b, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -b
        ( 1.0, 0.0,  1.0,  0.5,  0.5),  # centring translation, to the middle of the cell
        ( 1.0, 0.0,  1.0, -0.5, -0.5),  # the same, backwards
        (-1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line x = 0
        ( 1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line y = 0
        (-1.0, 0.0,  1.0,  0.0,  0.0),  # half turn about the origin
        (-1.0, 0.0,  1.0,  0.5,  0.5),  # half turn about (a/4, b/4)
    ),
    "p4": (
        (1.0, 0.0, 1.0,  1.0,  0.0),  # translation by +a, along x
        (1.0, 0.0, 1.0, -1.0,  0.0),  # translation by -a
        (1.0, 0.0, 1.0,  0.0,  1.0),  # translation by +a, along y
        (1.0, 0.0, 1.0,  0.0, -1.0),  # translation by -a
        (0.0, 1.0, 1.0,  0.0,  0.0),  # quarter turn about the origin
        (0.0, 1.0, 1.0,  1.0,  0.0),  # quarter turn about the cell centre
    ),
    "p4m": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +a, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -a
        ( 0.0, 1.0,  1.0,  0.0,  0.0),  # quarter turn about the origin
        ( 1.0, 0.0, -1.0,  0.0,  0.0),  # mirror in the line y = 0
        ( 0.0, 1.0, -1.0,  0.0,  0.0),  # mirror in the diagonal y = x
        (-1.0, 0.0, -1.0,  1.0,  0.0),  # mirror in the line x = a/2
    ),
    "p4g": (
        ( 1.0, 0.0,  1.0,  1.0,  0.0),  # translation by +a, along x
        ( 1.0, 0.0,  1.0, -1.0,  0.0),  # translation by -a
        ( 1.0, 0.0,  1.0,  0.0,  1.0),  # translation by +a, along y
        ( 1.0, 0.0,  1.0,  0.0, -1.0),  # translation by -a
        ( 0.0, 1.0,  1.0,  0.0,  0.0),  # quarter turn about the origin
        ( 0.0, 1.0, -1.0,  0.5, -0.5),  # diagonal mirror through (a/2, 0)
        (-1.0, 0.0, -1.0,  0.5,  0.5),  # glide along the axis x = a/4
    ),
    "p3": (
        ( 1.0,                 0.0, 1.0,  1.0,                  0.0),  # translation by +a1, along x
        ( 1.0,                 0.0, 1.0, -1.0,                  0.0),  # translation by -a1
        ( 1.0,                 0.0, 1.0,  0.5,  0.86602540378443865),  # translation by +a2, at 60 degrees
        ( 1.0,                 0.0, 1.0, -0.5, -0.86602540378443865),  # translation by -a2
        ( 1.0,                 0.0, 1.0,  0.5, -0.86602540378443865),  # translation by +(a1 - a2), at -60 degrees
        ( 1.0,                 0.0, 1.0, -0.5,  0.86602540378443865),  # translation by -(a1 - a2)
        (-0.5, 0.86602540378443865, 1.0,  0.0,                  0.0),  # rotation through 120 degrees about the origin
    ),
    "p3m1": (
        ( 1.0,                 0.0,  1.0,  1.0,                  0.0),  # translation by +a1, along x
        ( 1.0,                 0.0,  1.0, -1.0,                  0.0),  # translation by -a1
        ( 1.0,                 0.0,  1.0,  0.5,  0.86602540378443865),  # translation by +a2, at 60 degrees
        ( 1.0,                 0.0,  1.0, -0.5, -0.86602540378443865),  # translation by -a2
        ( 1.0,                 0.0,  1.0,  0.5, -0.86602540378443865),  # translation by +(a1 - a2), at -60 degrees
        ( 1.0,                 0.0,  1.0, -0.5,  0.86602540378443865),  # translation by -(a1 - a2)
        (-0.5, 0.86602540378443865,  1.0,  0.0,                  0.0),  # rotation through 120 degrees about the origin
        (-1.0,                 0.0, -1.0,  0.0,                  0.0),  # mirror in the line x = 0
    ),
    "p31m": (
        ( 1.0,                 0.0,  1.0,  1.0,                  0.0),  # translation by +a1, along x
        ( 1.0,                 0.0,  1.0, -1.0,                  0.0),  # translation by -a1
        ( 1.0,                 0.0,  1.0,  0.5,  0.86602540378443865),  # translation by +a2, at 60 degrees
        ( 1.0,                 0.0,  1.0, -0.5, -0.86602540378443865),  # translation by -a2
        ( 1.0,                 0.0,  1.0,  0.5, -0.86602540378443865),  # translation by +(a1 - a2), at -60 degrees
        ( 1.0,                 0.0,  1.0, -0.5,  0.86602540378443865),  # translation by -(a1 - a2)
        (-0.5, 0.86602540378443865,  1.0,  0.0,                  0.0),  # rotation through 120 degrees about the origin
        ( 1.0,                 0.0, -1.0,  0.0,                  0.0),  # mirror in the line y = 0
    ),
    "p6": (
        (1.0,                 0.0, 1.0,  1.0,                  0.0),  # translation by +a1, along x
        (1.0,                 0.0, 1.0, -1.0,                  0.0),  # translation by -a1
        (1.0,                 0.0, 1.0,  0.5,  0.86602540378443865),  # translation by +a2, at 60 degrees
        (1.0,                 0.0, 1.0, -0.5, -0.86602540378443865),  # translation by -a2
        (1.0,                 0.0, 1.0,  0.5, -0.86602540378443865),  # translation by +(a1 - a2), at -60 degrees
        (1.0,                 0.0, 1.0, -0.5,  0.86602540378443865),  # translation by -(a1 - a2)
        (0.5, 0.86602540378443865, 1.0,  0.0,                  0.0),  # rotation through 60 degrees about the origin
    ),
    "p6m": (
        (1.0,                 0.0,  1.0,  1.0,                  0.0),  # translation by +a1, along x
        (1.0,                 0.0,  1.0, -1.0,                  0.0),  # translation by -a1
        (1.0,                 0.0,  1.0,  0.5,  0.86602540378443865),  # translation by +a2, at 60 degrees
        (1.0,                 0.0,  1.0, -0.5, -0.86602540378443865),  # translation by -a2
        (1.0,                 0.0,  1.0,  0.5, -0.86602540378443865),  # translation by +(a1 - a2), at -60 degrees
        (1.0,                 0.0,  1.0, -0.5,  0.86602540378443865),  # translation by -(a1 - a2)
        (0.5, 0.86602540378443865,  1.0,  0.0,                  0.0),  # rotation through 60 degrees about the origin
        (1.0,                 0.0, -1.0,  0.0,                  0.0),  # mirror in the line y = 0
    ),
}
