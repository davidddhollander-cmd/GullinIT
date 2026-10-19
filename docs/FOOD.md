# First food set

| Category | Food | Base points | Where it appears |
| --- | --- | ---: | --- |
| Small | Crumbs | 5 | Sand, bins |
| Small | Chip | 10 | Sand |
| Small | Cookie | 15 | Picnic families |
| Small | Doughnut | 10 | Bins |
| Small | Sandwich | 15 | Bins |
| Small | Pizza | 20 | Bins |
| Medium | Box of crisps | 35 | Sunbathers, picnic families, kiosk customers |
| Medium | Ice cream | 25 | Toddlers, kiosk customers |
| Medium | Bag of crisps | 30 | Sunbathers, picnic families, kiosk customers |
| Large | Full hotdog | 45 | Dog owners |
| Large | Fried fish | 55 | Pier diners, seafood vendors |

Ground pickups repeat two crumbs followed by one chip and replenish after 18 seconds. They award their listed points without combos or practice-snatch credit. Held food receives the existing risk, upwind and combo bonuses. Rivals use the same food values. Food category controls digestion capacity and eating time; the normal queue awards points on swallowing. Lifeguards carry no food. A crash retains half the current points, rounded up for odd totals, and resets the combo.

Bins include the three half-eaten leftovers as finite edible scraps alongside crumbs, wrappers and paper. Each bin contains one of each new leftover, two crumb pickups and four inert litter objects. Four pecks release three objects, for three bursts before depletion. Leftovers render at 8 × 8 pixels and use the normal small-snack digestion time (0.5 seconds airborne, twice as fast grounded); points are awarded only on swallowing, without combo or practice credit. See `BIN_LEFTOVER_ART.md` for the fixed sequence, artwork and validation.

`data/foods.json` owns food definitions independently from the person carrying them. `data/targets.json` provides each person's pool of allowed foods, selected using the level's random generator when they spawn. Replenishment retains that person's selected food. Restart a level to apply changed pools.

Seven transparent sprites were created with the built-in ChatGPT image generator and saved as `assets/sprites/food_bites.png`. The actual output is 1774×887, with four columns and two rows; the last cell is empty. `data/food_art.json` records each icon's exact region, merged into the live sprite manifest. No labels or background are part of the artwork. The placeholder generator preserves these curated food entries and does not overwrite the atlas or food catalog.

The game draws small foods at 7×5 pixels, medium foods at 7–11×11–13 pixels, and large foods at 17–18×12–13 pixels. Pickup areas follow those sizes. `tests/food_preview.gd` renders both enlarged previews and actual sizes, captured to `test-output/food-preview.png` by `tools/validate.ps1 -Capture`.

The new values keep bin leftovers below the medium and large meals while making each progressively richer. Level star thresholds are unchanged; human playtesting should assess the new score balance.

## Generation prompt

Create a production sprite atlas for a cozy seaside pixel-art seagull arcade game. Exactly 8 equal cells arranged 4 columns by 2 rows on a 1024x512 canvas, each cell 256x256. Genuine transparent background. Seven separate isolated food icons centered in their cells, last cell empty. Row 1 left to right: a small cluster of golden bread crumbs; ONE golden French fry chip; an open red-and-cream striped cardboard snack box filled with crisps (thin potato chips, not fries); a waffle cone with white vanilla ice cream. Row 2 left to right: a sealed teal crisp packet with yellow potato-chip illustration and crimped ends (NO lettering); a complete hotdog with golden bun, brown sausage and mustard zigzag; a whole golden battered fried fish fillet with recognizable tapered fish silhouette; EMPTY transparent cell. Crisp chunky pixel-art silhouettes, dark navy outlines, restrained cream/golden-yellow/coral-red/teal palette, simple shading, no gradients, no cast shadows, no text, labels, numbers, borders or background. Design as if each icon were 24x24 pixel art enlarged with nearest-neighbor: minimal large clusters, readable at tiny sizes. Consistent three-quarter side view. Keep each icon entirely inside a centered 180x180 area within its own 256x256 cell, generous transparent separation. No plates, hands, people, utensils, scenery, or extra food icons.
