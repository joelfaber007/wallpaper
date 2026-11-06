# Branch on which side up a tile lies

Every enter function keeps, for each point, the tile it took the point from, and with it whether that copy of the fundamental domain is the domain only turned, or flipped over. This sends the point one way for each.

## The outputs

| Output | Taken when |
| --- | --- |
| `turned` | The copy is the domain itself, or the domain turned: it has the same side up as the domain. |
| `flipped` | The copy is the domain flipped over by a mirror or a glide, so it is the domain's mirror image. |

In a group with mirrors or glides, half the copies in a cell are flipped, and these are the left- and right-handed tiles of its pattern. The groups with neither -- `p1`, `p2`, `p3`, `p4` and `p6` -- have no flipped copies, and the Cairo enter never flips, so with them every point is `turned`.

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
- `<group>_tile_copy` tells every copy apart, not just the two sides.
- `tile_flip_to_int` loads the same thing into an integer variable, as 1 or -1.
