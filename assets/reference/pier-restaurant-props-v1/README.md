# Pier restaurant props v1

Generated pixel-art source files for three environment assets:

- modular pole-and-wire pier fence
- empty two-counter beach restaurant stand
- matching table and two-chair set

The full generated sources are preserved here. Runtime sprites are cropped,
nearest-neighbour reduced, hard-alpha cleaned, and mapped to the exact 16-color
union used by the existing pier, food stands, and beach-chair sprites.

Runtime outputs live in `assets/sprites/pier-restaurant-props-v1/`.
The preparation script is `tools/prepare_pier_restaurant_props_v1.py`.

## Runtime contract

| Asset | Canvas | Suggested origin | Role |
| --- | ---: | --- | --- |
| `pier-wire-fence-v1.png` | 72 x 24 | bottom center | repeatable pier-edge scenery |
| `two-counter-restaurant-v1.png` | 132 x 88 | bottom center | two independent service/counter bays; larger than standard stalls |
| `restaurant-table-chairs-v1.png` | 60 x 34 | bottom center | promenade dining prop |

Use lossless import, nearest-neighbour filtering, no mipmaps, and integer
positions/scales. The restaurant contains no vendor, food, or signage text so
gameplay can layer vendor and food sprites independently.
