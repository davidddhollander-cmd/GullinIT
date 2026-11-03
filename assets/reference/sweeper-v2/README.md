# Sweeper v2 generated artwork

All character artwork was created with the built-in ImageGen tool. Untouched PNG sources are saved beside this file, with exact prompts in `prompts/` and original source SHA-256 hashes in `source-sha256.json`. The corrected walk source replaces the first walk draft; both originals are retained.

The new identity was generated first and supplied as the strict character reference for every animation source. The mum first-cell reference supplied the outline and pixel-density quality target. The exact user palette contains 25 colours, including near-black `#0A0A18`; no extra colours were introduced.

Preparation cropped the generated figures, sampled the enlarged generator output once with nearest-neighbour into the requested native figure scale, aligned the body centre to x=79 and the registered ground to y=154, hardened alpha, snapped colours to the supplied palette, and packed 211x176 cells. No anatomy, clothing, limbs, faces, brooms or silhouette outlines were drawn or patched by code. The darkest source ink tones were snapped globally to near-black without consulting edge geometry. The exact supplied palette colours remain fixed points of that mapping.

The final native atlas is `assets/sprites/sweeper-v1/sweeper-v2-game.png`, six columns and 58 active frames. There is no separate 192x160 master and no later v1 baking/resampling pass. The old `tools/bake_sweeper.py` is retained but is not used for v2.

The runtime clip order is idle, walk, run, alert, warning, angry, windup, swat, surprise, fist_shake, recover, sweep, sweep_bin. Walk and run each have eight phases. Ground registration remains fixed; intentional airborne run/surprise frames rise above it.

Broom anchors were selected directly from opaque pixels in the three exact bristle colours. Ground anchors use the bottom bristle row and its centre contact pixel. Swat and bin-flick anchors use the opaque bristle centroid's nearest actual bristle pixel. No anchors are copied from v1.

The five presentation sheets and packed atlas use the same native cells. `assets/sprites/sweeper-animation-layout-v2.json` records per-clip frame indexes, source crops, uniform preparation scale, sheet slots, runtime regions, root positions, and anchor measurements.

This folder is excluded from Godot imports with `.gdignore`; these are editable source artifacts, not runtime textures.
