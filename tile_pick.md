# Branch on a random pick of tiles

Every enter function keeps, for each point, the tile it took the point from: the copy $k$ of the fundamental domain and the cell $(m, n)$. This picks a share of the tiles at random and sends the point one way if its tile is picked and the other if not.

## The pick

The tile and `salt` are mixed by an integer hash $h$ into one 32-bit number, and its top 24 bits into a number spread evenly over $[0, 1)$:

```math
u = \frac{\lfloor h(\text{salt}, k, m, n) / 2^{8} \rfloor}{2^{24}}
```

The tile is picked when $u <$ `share`. Since $u$ depends on nothing but the tile, every point of a tile goes the same way, and the same tiles are picked on every iteration; tiles next to one another are picked independently. Changing `salt` picks a different set of the same size.

## The outputs

| Output | Taken when |
| --- | --- |
| `picked` | The tile is one of those picked. |
| `rest` | The tile is not. |

## Works with

- Every group's `<group>_enter`, and `p4g_cairo_enter`, keep the tile this reads. Give it the same `tile_id`.
- The matching `<group>_exit` carries the point back to that tile; this can come before it or after it.
