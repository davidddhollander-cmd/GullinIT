# Sunbather animation set — 6 October 2026

## Stationary towel restoration — 20 October 2026

The current diner-style character atlases contain no baked towel. The legacy pursuit-only towel condition therefore left resting and rising sunbathers directly on the sand. A separate striped towel now draws beneath every sunbather pose at the fixed home position, including settlement and pursuit. All four appearance variants use the same ground layer; the title beach uses it too. The 64-pixel towel spans the current 58-pixel reclining silhouette, with cream fringes and the existing blue, coral and yellow palette. Character sources and reaction timings are unchanged.

## Reaction pass — 7 October 2026

Pickup now uses the upright-to-crouch part of the rise sequence during a short pause; returning home reverses the full rise sequence to settle down. Swats use raised arms from the run sheet, a visible warning cue and forward swing offset before the range-checked impact. These adapt existing supplied art rather than inventing new frames. Per-raid action timers live in `stash_raids.gd`; durations and pose mapping live in `SunbatherArt`.

The shader converts atlas UVs to local frame coordinates and masks towel colours only in the lower band of moved rise frames. Resting/home frames and all running frames remain unmasked. This avoids dragging a second towel around while preserving hands and feet; colour-key extraction still has limits compared with separately authored transparent character art. Parent visually reviewed pickup, warning, impact and settlement captures. Validation: 935 checks, zero failures.

## Female set and revised proportions

The second user-supplied sheet is preserved unchanged as `assets/archive/sprites/sunbather-female-sheet.png` (1536×1024). The same atlas helper now selects male/female and red/blue sets through each level spawn's `appearance` field. All four combinations are distributed across the six levels. Female frames have their own crop regions and resolution-adjusted scale so they match male adults in the game, with the same wake timer, running clock, facing and stationary towel behaviour.

Adults are 10% larger than the first integration (male scale 0.209; female scale 0.209/1.2). Towels increase to match. Toddler scale is now 0.0525, exactly 70% of the previous 0.075; its food anchor also scales to 70% to stay at the hand. Food item sizes and score values are unchanged. High-resolution canvas rendering and toddler mipmapped filtering remain enabled.

Rendered validation: **889 checks, zero failures**, including both female colours, every atlas boundary, running baseline alignment and revised toddler size. Captures: `female-sunbathers-rest.png`, `female-sunbathers-rise.png` and `female-sunbathers-run-0.png` through `-6.png` in `test-output`.

## Original male integration

Source: the user's attached `1-Pasted-Image-1.jpg`, copied unchanged to `assets/archive/sprites/sunbather-user-sheet.jpg` (1280×853). No regeneration or raster editing was used.

`scripts/sunbather_art.gd` is the frame manifest: seven getting-up regions and seven running regions per colour, with the first getting-up region also used for resting. The lower two rows provide blue trunks and a yellow towel; upper rows provide red trunks and a blue towel. Atlas regions are sampled directly from the original JPEG. Black background is discarded by `assets/shaders/sunbather_black_key.gdshader`; this is a colour key, not an authored alpha mask, so very dark details are also affected.

Sprites render at 0.19 scale with nearest filtering inherited from the project, bottom-aligned to the ground. Home position determines the variation without consuming gameplay randomness. Getting up follows the last 0.6 seconds of the existing wake timer. The seven-frame run loop advances at 10 fps only while the owner moves; leftward movement mirrors the run poses. Animation clocks follow gameplay ticks, so pause stops them. The towel drawn during pursuit remains at the fixed home position; the baked-in towel is used for rest/getting up. On returning home, the resting pose is restored.

Existing food, bag stock, retrieval speed, swat timing and scoring are unchanged. This set does not contain dedicated bending-to-collect or swatting poses; those remain future art work. Picnic-bag refill trips remain cancelled.

Validation captures: `test-output/sunbather-new-rest.png`, `sunbather-new-wake.png`, and `sunbather-new-run.png`.

20 October validation: 16/16 rendered stationary-towel checks passed for all four appearances and four pose states. Full integration: 11,844 checks, zero failures.
