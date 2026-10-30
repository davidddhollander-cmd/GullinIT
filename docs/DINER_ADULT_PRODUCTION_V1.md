# Approved diner-style adult production — 19 October 2026

The user approved the middle row of the diner-led pilot. That finish is now applied to all five production adults: mum, male red/blue and female red/blue. The diner remains unchanged as the reference. Other characters, food and scenery are outside this pass.

## Production files and integration

The existing filenames in `assets/sprites/` now contain the new artwork:

- `retro-mum-32bit.png`: 1024 × 1280, 79 mapped frames.
- `retro-sunbather-male-red-32bit.png` and `retro-sunbather-male-blue-32bit.png`: 1024 × 1408, 88 mapped frames each.
- `retro-sunbather-female-red-32bit.png` and `retro-sunbather-female-blue-32bit.png`: 1024 × 1408, 88 mapped frames each.

All use 128 × 128 source cells, 0.5 display scale and source sole baseline y=116. Standing figures remain around 40 logical pixels tall, with the existing sprite origin at y=-26. The parent registry and direct sunbather atlas loader use the same grid. Source detail and shading are retained rather than reduced to the old 14-colour palette. Lossless PNG, binary alpha, nearest filtering and no mipmaps keep the finish crisp.

The new source sheets provide six walking and six running poses per direction for each identity, six swat poses and six kicks per direction. Mum also has new carry-walk poses in both directions, a low handover sequence, eating, alert and shield poses. Idle uses the exact approved pilot frame. Blue variants derive from the red atlases with a garment-region palette conversion; geometry, timing, skin and hair are shared.

Existing clip names/counts, gameplay movement, warnings, hit timing, stash stock and scoring remain authoritative. The seven-frame sunbather run loop starts with a planted acceleration pose and then uses the six run poses. Idle/rest and some reaction holds retain repeated key poses. Existing rise/pickup artwork is reused from the prior large source sheets at the new source resolution. This pass does not claim a newly drawn breathing loop or a unique image for every held clip slot.

## Source and reproduction

Seven source sheets were created with the built-in image generation tool using the approved pilots and diner as references. They and their complete prompts are in `assets/reference/adult-diner-production-v1/`. Approved idle frames remain in `assets/pilots/adult-diner-v1/`; reused rise/pickup sources remain in `assets/reference/adult-replacement-v3/`.

`tools/diner_adult_atlas_source.gd` finds connected actor silhouettes across each source row so long kicks, open palms and ponytails are not cut at nominal grid columns. It prepares the 128-pixel cells without the old palette reduction. `tools/generate_retro_adults.gd` writes all five atlases, the action contact sheet and `data/adult_art.json`. `tools/map_retro_adults.ps1` maintains the registry frame dimensions and existing clip sequence.

`data/adult_art.json` contains per-frame mum palm anchors in logical world coordinates. `MumArt` reads those anchors for carrying, eating, reactions and low handover; dedicated left-facing travel sources keep their own hand positions. Food remains separate, and its visible position remains the theft position.

## Review artifacts

- `assets/archive/previews/adult-diner-production-cast-v1.png`: actual production idle/walk/swat sprites beside the unchanged diner at their runtime presentation sizes.
- `assets/archive/previews/adult-diner-production-review-v1.png`: five appearances with directional walk, swat, kick, carry/handover or rest/pickup samples.
- Final gameplay captures are retained in `assets/previews/adult-diner-production-v1/` after validation.

## Validation

The existing rendered integration suite covers registry bounds, animation counts, changing adjacent travel/attack frames, native display size, reactions, stash retrieval, family carrying/handover and visible snack theft. Adult-specific checks now enforce the approved 128-pixel grid and hard alpha rather than the superseded 16-colour limit. Additional checks compare walk and chase artwork, and verify red/blue silhouettes and protected skin/hair colours.

Final rendered run: **10,933 checks, zero failures**, with an empty gameplay error log. Results are recorded in `test-output/diner-production-validation.log`. Production captures were visually checked for complete limbs, consistent height, left carry, low handover and female pickup. Source preparation is an offline tool; its standalone shutdown currently emits Godot resource-cleanup warnings. The actual rendered gameplay run is checked separately.
