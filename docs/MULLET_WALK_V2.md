# Mullet man walking correction

20 October 2026. First replacement following the shopper walk reassessment. The original yellow-shirt shopper supplies the six approved motion references. The mullet man's existing idle supplies his character identity. Six complete body poses were generated with the built-in ImageGen tool; the exact prompts, reference roles, original output locations and untouched generated images are preserved in `assets/reference/mullet-walk-v2/`.

The replacement makes the lifted sandal, bent trailing knee and extended contact pose more distinct below his shorts. It retains the cap, mullet, moustache, coral shirt, navy shorts, sandals and stocky build. Preparation only crops, scales, hardens alpha and aligns complete generated drawings; it does not construct limbs or alter the animation system.

Runtime uses `assets/sprites/shopper-mullet-walk-v2.png`. Only walk cells 1–6 replace the earlier atlas. Idle, run, warning and attack cells, including unused atlas cells, remain pixel-identical to `shopper-mullet-diner-style.png`. Timing remains six frames at 8 fps, with 128-pixel cells, 0.5 display scale, 40-pixel art height and source sole baseline 116. Food anchors were measured again for each new palm and retain the existing facing mirroring. The original shopper and older woman are unchanged.

`tools/prepare_mullet_walk.gd` builds this versioned atlas and its review metadata in `data/mullet_walk_v2.json`. The common `tools/prepare_shopper_variants.gd` rebuild also applies these six replacement cells, so rebuilding the shoppers does not silently restore the old walk. Register the common rebuild with `tools/map_staff_art.py` as before.

`tools/mullet_walk_preview.tscn` captures the approved original, previous man and new man at identical frame indices, plus enlarged lower legs and moving views in both directions. `assets/archive/previews/mullet-walk-v2.gif` presents two complete loops at the existing 8 fps. Visual review shows the raised foot now separates clearly from the ground in passing poses. This is a comparison for user review, not an automatic claim of animation quality based on pixel changes.

Validation: the integration suite includes `tests/mullet_walk_checks.gd`, which checks the narrow metadata change and pixel preservation outside walking. Existing staff checks cover complete isolated sprites, alpha, gutters and feet alignment. The shopper variants scene checks food-hand mirroring, chase and swat selection, theft and identity persistence after config reload.

Completed validation: 11,986 rendered integration checks and 51 standalone shopper checks, zero failures. Render logs are in ignored `test-output/mullet-walk-validation.log`; the synchronized review frames are in `test-output/mullet-walk-frames/`.
