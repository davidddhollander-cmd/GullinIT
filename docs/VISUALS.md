# First visual pass — seagull

## Proposed order

1. **Character readability (implemented):** use the supplied white/grey gull artwork, standing and walking poses, wing animation, aim-aligned dives, and a soft ground shadow.
2. **Food readability:** make food silhouettes and pickup highlights clearer, especially against sand and people.
3. **Rival identity:** give rival gulls distinct markings while keeping the same animation quality as the player.
4. **Beach depth:** improve foreground props, distant water, and light without cluttering the play area.

## Implemented assets

- `assets/reference/gull_sheet_original.png`: preserved user attachment, unchanged.
- `assets/archive/sprites/gull_reference_clean.png`: transparent derivative prepared with the built-in image tool.
- `data/sprites.json`: live player atlas regions, frame padding, scale and animation definitions.
- `data/gull_art.json`: curated manifest override preserved by `tools/generate_assets.py` when regenerating placeholders.
- `assets/shaders/gull_cutout.gdshader`: suppresses faint extraction fringes during rendering; source PNG remains intact.

The original supplied sheet has irregular spacing, unequal pose sizes, overlapping right-walking birds, and an overlapping final right-flight group. The game uses its clean left-walking sequence mirrored for rightward movement, six separate right-flight poses, one standing pose, and a flatter flying pose from the dive row. The latter rotates with the current dive angle, avoiding a second rotation on top of a pre-angled drawing. This is a first pass using available frames, not a newly authored full wingbeat cycle.

Each region is padded into a shared 240×200 logical canvas and displayed at 0.18 scale. Ground frames share a foot baseline; airborne frames align around the body. Walking frames follow distance travelled and stop at rest. Rivals retain their existing placeholder art for this pass. Movement, scoring, and collision dimensions were not changed.

The asset-import, animation, and shader workflows were used for integration. Validation: 322 checks pass in rendered Godot, including frame bounds, shared canvas size, standing/walking selection, facing, takeoff scale, and dive angle. Inspected `test-output/gull-standing.png`, `gull-walking.png`, `gull-flight.png`, and `gull-dive.png` at the game's actual 320×180 resolution.

## Image preparation prompt

Tool: built-in `image_gen`, edit mode, `transparent_background=true`. Input: the original user attachment. Final prompt:

> Edit target: supplied seagull sprite sheet. Prepare this exact supplied artwork for a game by removing the blue background, ALL text headings, ALL frame numbers, and ground shadows. Preserve the individual gull sprites, their pixel-art style, poses, relative sizes and locations as faithfully as possible. Keep the original 1536x1024 composition and layout, including idle and walking along top, walk-left second row, fly-right third row, fly-left fourth row, dive bottom row. No new birds, no redesign, no extra details, no labels, no grid. Real transparent alpha background, not checkerboard. Clean isolated bird silhouettes including white feathers, dark grey wings, yellow beaks and legs. This is a background-extraction edit, not a new sprite design.
