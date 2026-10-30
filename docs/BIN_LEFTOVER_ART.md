# Half-eaten bin food assets

Created 19 October 2026 with built-in ImageGen. Three isolated half-eaten foods for edible bin leftovers: iced ring doughnut, lettuce-and-tomato sandwich, and pepperoni pizza slice.

## Deliverables

- `assets/sprites/retro-food-half-eaten-doughnut-32bit.png`
- `assets/sprites/retro-food-half-eaten-sandwich-32bit.png`
- `assets/sprites/retro-food-half-eaten-pizza-32bit.png`
- `assets/sprites/retro-food-bin-leftovers-atlas-32bit.png`: three 16 × 16 cells, left to right doughnut, sandwich, pizza.
- `assets/archive/previews/bin-leftovers-review-v1.png`: the same three native sprites enlarged 12× with nearest-neighbour scaling.

The individual PNGs use equal 16 × 16 transparent cells, with artwork fitting inside 14 × 14 pixels. Each uses a subset of the game palette (navy outline, cream, gold, tan, brown, coral, muted coral, lettuce green) and binary alpha. Ground anchor is bottom-centre (8, 15); nearest filtering, lossless import, mipmaps off. Raw generated artwork is preserved under `assets/reference/bin-leftovers`.

Integrated into bin drops on 19 October 2026. The individual sprites are registered in both `data/sprites.json` and the preserved curated manifest `data/food_art.json`. The original 16 × 16 artwork is drawn at 8 × 8 gameplay pixels with nearest filtering; pickup radii are 4 × 4.

All three foods are small snacks: half-eaten doughnut awards 10 points, sandwich 15, and pizza 20. They enter the normal digestion queue and award points only when swallowed. As bin scraps they grant no combo or practice-snatch credit, keep the existing 0.3-second pickup protection, and remain on the sand when the gull's mouth is full. They are not added to beachgoer food pools or the separately replenishing ground scraps.

Each bin still holds nine objects, released in three bursts of three after four pecks apiece. The fixed burst sequence is:

1. Crumbs, wrapper, half-eaten doughnut.
2. Paper, half-eaten sandwich, crumbs.
3. Wrapper, half-eaten pizza, paper.

That preserves five edible pickups and four pieces of inert litter per bin. Empty bins stay empty until the level resets; the existing training assistance rule remains in effect. `data/tuning.json` owns the sequence, mirrored by `tools/generate_assets.py`. Bin classification accepts registered food IDs rather than treating every item except crumbs as litter.

`tests/bin_leftover_checks.gd` exercises real pecks, the complete finite distribution, pickup protection, digestion, per-food scoring, capacity blocking, duplicate prevention, depletion and retry. The food gallery includes all eleven food definitions; `test-output/bin-leftovers.png` is the rendered in-game capture.

Validation: headless and rendered integration runs each passed 10,746 checks with zero failures. Visually inspected the in-game bin scatter and the updated eleven-food gallery at gameplay size.

## Preparation

`tools/prepare_bin_leftovers.gd` crops solid-alpha bounds, reduces by nearest neighbour, maps the shared food palette, aligns the ground baseline, and writes the individual sprites, atlas and review sheet. It verifies that saved sprites have binary alpha and at most eight opaque colors.

## Generation prompts

### Half-eaten doughnut

Use case: stylized-concept. Asset type: ONE isolated edible bin-leftover pickup sprite for Gullin' It, a seaside 2D pixel-art arcade game at 320x180 logical resolution. Style: chunky 32-bit-era game food sprite with a strict coarse 16x16 logical pixel grid enlarged by an integer nearest-neighbor scale. Every pixel is a big solid square, one logical pixel thick navy #183B4E outline, broad flat color clusters, no more than 8 opaque colors. Light from upper left, one flat highlight and one flat shadow per material only. Three-quarter top-side view so the food and missing bites are easy to read. Entire food centered and fits within a 14x14 logical pixel area on a 16x16 logical pixel transparent canvas; enlarge the whole square for the generated image, keep clear margins. Genuine transparent alpha around the food and inside any removed/bitted portions. No backdrop, checkerboard, gradient, glow, antialiasing, semitransparent edges, cast shadow, microtexture, plate, packaging, hands, extra crumbs, additional items, text, face, or watermark. Subject: ONE HALF-EATEN RING DOUGHNUT, golden baked dough with coral-pink icing and just three big cream/gold sprinkle marks. Around half the ring is eaten away from its right side: preserve the left arc with the original central hole visibly opening into the missing half, and two broad jagged bite steps exposing cream-colored dough at the cut ends. Recognizable as the remaining half of a bitten iced ring doughnut, not a full donut with one tiny bite, not a crescent moon, not a croissant. Palette only navy #183B4E, cream #FFF4DA, gold #FFC65C, tan #D59A5E, wood-brown #AA7047, coral #EF725C, muted coral #B94D4E.

### Half-eaten sandwich

Use case: stylized-concept. Asset type: ONE isolated edible bin-leftover pickup sprite for Gullin' It, a seaside 2D pixel-art arcade game at 320x180 logical resolution. Style: chunky 32-bit-era game food sprite with a strict coarse 16x16 logical pixel grid enlarged by an integer nearest-neighbor scale. Every pixel is a big solid square, one logical pixel thick navy #183B4E outline, broad flat color clusters, no more than 8 opaque colors. Light from upper left, one flat highlight and one flat shadow per material only. Three-quarter top-side view so the food and missing bites are easy to read. Entire food centered and fits within a 14x14 logical pixel area on a 16x16 logical pixel transparent canvas; enlarge the whole square for the generated image, keep clear margins. Genuine transparent alpha around the food and inside any removed/bitted portions. No backdrop, checkerboard, gradient, glow, antialiasing, semitransparent edges, cast shadow, microtexture, plate, packaging, hands, extra crumbs, additional items, text, face, or watermark. Subject: ONE HALF-EATEN SANDWICH, the remaining half of a chunky triangular white-bread sandwich. Toasted tan crust along its intact left/back edge, cream bread on the top and bottom, a broad green lettuce strip and coral tomato filling visible between. Roughly half of the original sandwich has been bitten away along the right edge; use two large obvious stepped bite notches that cut through bread AND filling so it clearly reads as eaten leftovers, not a complete neat sandwich. The pale exposed bite interior is visible. Compact low wedge silhouette, layers readable with very few pixels. Palette only navy #183B4E, cream #FFF4DA, tan #D59A5E, wood-brown #AA7047, green #68A65D, coral #EF725C, muted coral #B94D4E.

### Half-eaten pizza

Use case: stylized-concept. Asset type: ONE isolated edible bin-leftover pickup sprite for Gullin' It, a seaside 2D pixel-art arcade game at 320x180 logical resolution. Style: chunky 32-bit-era game food sprite with a strict coarse 16x16 logical pixel grid enlarged by an integer nearest-neighbor scale. Every pixel is a big solid square, one logical pixel thick navy #183B4E outline, broad flat color clusters, no more than 8 opaque colors. Light from upper left, one flat highlight and one flat shadow per material only. Three-quarter top-side view so the food and missing bites are easy to read. Entire food centered and fits within a 14x14 logical pixel area on a 16x16 logical pixel transparent canvas; enlarge the whole square for the generated image, keep clear margins. Genuine transparent alpha around the food and inside any removed/bitted portions. No backdrop, checkerboard, gradient, glow, antialiasing, semitransparent edges, cast shadow, microtexture, plate, packaging, hands, extra crumbs, additional items, text, face, or watermark. Subject: ONE HALF-EATEN PIZZA SLICE, golden puffy curved back crust and a small remnant of the triangular cheesy slice, with one large coral-red pepperoni patch. Roughly half the slice, including the entire pointed tip and part of one side, has been eaten; broad stepped scalloped bite notches expose cream dough along the missing front/right edge. Keep the back crust and some melted gold cheese so it unmistakably reads as a half-eaten pizza slice, not a complete triangle with a tiny notch, not a whole pizza, not a sandwich. The pizza rests flat in a shallow three-quarter view, broad crust at back upper-left and bitten edge toward front lower-right. Palette only navy #183B4E, cream #FFF4DA, gold #FFC65C, tan #D59A5E, wood-brown #AA7047, coral #EF725C, muted coral #B94D4E.

