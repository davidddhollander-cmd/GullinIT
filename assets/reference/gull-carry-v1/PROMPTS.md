# Gull beak-carry variants v1

Generated on 2026-10-24 with ChatGPT's built-in `image_gen` tool and `transparent_background=true`. Every source PNG in this directory is preserved intact. `tools/prepare_gull_carry.gd` only alpha-thresholds, crops, nearest-neighbour scales, aligns and measures the generated pixels. It derives each upper-mandible overlay by copying generated beak pixels; it does not draw bird anatomy.

All four generations used the same layout and action request: one genuinely transparent 4-by-4 sheet, thirteen complete right-facing birds in cells 0-12 and empty cells 13-15. Cells 0-7 form the eight-frame folded-wing walk loop; cells 8-11 form the four-frame wingbeat (up, half-lowered, down, half-raised); cell 12 is the horizontal glide. Every pose raises the head slightly and opens the bill around a narrow empty gap for a separately rendered snack. No food, props, text, grids, shadows or detached effects were requested.

## Herring gull

References: `assets/reference/gull-production-v1/herring-source.png` and `assets/sprites/gull-herring-diner-style.png`.

> Preserve the approved friendly adult herring gull: rounded head and full breast, pale yellow iris, pale-grey mantle and wings, black primary ends with white mirror spots, white head/body/flight tail, pink legs/webbed feet, and yellow bill with red lower-mandible spot. Match the crisp restrained detailed 32-bit-inspired cel/pixel art and fine dark outline. Keep the adult flight tail white.

## Black-legged kittiwake

References: `assets/reference/gull-production-v1/kittiwake-source.png` and `assets/sprites/gull-kittiwake-diner-style.png`.

> Preserve the approved agile slender adult kittiwake: angular silhouette, small plain yellow bill with no red spot, solid dark eye, grey mantle, solid black wingtip ends with no white spots in the black tips, white head/body/flight tail, and black legs/webbed feet. No black hood or juvenile markings.

## Great black-backed gull

References: `assets/reference/gull-production-v1/great-black-backed-source.png` and `assets/sprites/gull-great-black-backed-diner-style.png`.

> Preserve the approved powerful broad-chested adult great black-backed gull: intense pale iris, heavy yellow bill with red lower-mandible spot, near-black back/upper wings, white trailing margins and primary mirror spots, white head/body/flight tail, and strong pink legs/webbed feet.

## Rival tint base

References: the same approved great black-backed source and runtime atlas for silhouette, pose language and density.

> Create a neutral rival-tint-base using the approved powerful rival silhouette. Keep the white head/body/tail, heavy yellow and red-spotted bill and pink legs, but use pale neutral cool-grey mantle and upper wings with near-white highlights, low saturation and enough brightness for the existing runtime tint shader. Avoid near-black wing fields; retain fine dark outlines and small dark wingtip accents.
