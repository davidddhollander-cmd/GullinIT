# Two additional seaside shoppers

Created 19 October 2026 with the built-in image-generation tool. The existing shopper pilot and approved pier diner were supplied as style references. Complete generation prompts and untouched source sheets live in `assets/reference/shopper-variants-v1/`.

- `shopper_mullet`: fat adult man, brown mullet and moustache, teal baseball cap, coral T-shirt, navy shorts and sandals.
- `shopper_sundress`: older woman, silver bun and glasses, yellow sundress with coral flowers and green leaves, sandals.

Both use the existing `kiosk_customer` gameplay type. Each source contains six walk poses, six run poses, six utility poses and six swat poses. Runtime atlases include idle, walk, run, alert, warning, angry, windup and swat, at the existing 40-pixel adult height on 128-pixel canvases displayed at 0.5 scale. Food stays a separate stealable sprite and mirrors with the actor. Raised gesture anchors follow the visible hand.

Production atlases:

- `assets/sprites/shopper-mullet-walk-v2.png` (walking corrected on 20 October; earlier atlas retained as reference)
- `assets/sprites/shopper-sundress-walk-v2.png` (walking corrected on 20 October; earlier atlas retained as reference)

Appearance is chosen once per person. Automatic customers cycle original / mullet / sundress without consuming gameplay random numbers. Authored spawns can set `appearance` to any of those registry IDs. Boardwalk Bustle introduces the mullet shopper at the ice cream kiosk and the older woman at the hotdog stand. Art/config reload preserves their identities; the shared customer definition is never mutated.

Rebuild using Godot's `--headless --path . --script tools/prepare_shopper_variants.gd`, then run `tools/map_staff_art.py`. The preparation reuses the established adult cropping, alpha cleanup and nearest-neighbor resizing pipeline; source artwork stays intact. Registry entries are also saved in `data/shopper_variants_art.json`.

Preview: `tools/shopper_variants_preview.tscn` writes `assets/archive/previews/shopper-variants-production-v1.png` beside existing cast members at production scale.

Validation: existing staff art checks cover both atlases for hard alpha, transparent gutters, isolated actors, baseline alignment and distinct drawn animation frames. `tests/shopper_variants_checks.tscn` checks appearance rotation, refresh/reload persistence, hand mirroring, chase/windup/contact selection and swept food theft for both new characters. Run it headlessly after importing the project. The full integration suite also exercises the new appearances through ordinary spawning.
