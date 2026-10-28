# 045 — Even pixels at every window size; sharp title and loading screen

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 044, and David's OK in the Art Lab (keys `I` and `F`)
Created: 2026-10-27

## What David will see in game
- **Odd window sizes (e.g. a 1366×768 laptop, or a resized window):** today some pixel columns come out wider than others, so stripes and outlines look uneven. After this change every pixel is the same size. The price: thin black bars appear at the edges at sizes that aren't a multiple of 320×180. At 1280×720 and 1920×1080 nothing changes.
- **Title screen:** the GULLIN' IT logo and the sandcastle are slightly blurred today. They become sharp-edged like everything else.
- **Loading screen:** the beach backdrop and the flying gull are slightly blurred today. They become sharp.
- **During play:** nothing visible changes.

## Before starting
David previews this in the Art Lab: `I` toggles integer scaling, `F` toggles sharp vs smooth. If he prefers how anything looks today, drop that item and note it in the Report.

## Requirements
1. `project.godot`: `display/window/stretch/scale_mode="integer"` and `rendering/2d/snap/snap_2d_vertices_to_pixel=true`. Keep `window/stretch/mode="canvas_items"`.
2. Switch to Nearest filtering in `scenes/loading.tscn` (Backdrop and Gull nodes), `scripts/main.gd:29` (castle) and `scripts/menus.gd:43` (logo). If the logo's glint shader needs smooth filtering, keep that one and say so in the Report.
3. Housekeeping (no visible change): remove the seven unused 8×8 food entries from `data/sprites.json` (`chips`, `cone`, `fish_chips`, `hot_dog`, `ice_cream`, `sandwich`, `seafood`) once a grep confirms nothing uses them; leave the PNGs on disk. Turn mipmaps off in `toddler_polished.png.import`.

## Done when (acceptance)
- [ ] Captures of the title, loading screen and level 1 at 1280×720 and 1366×768 attached to the Report
- [ ] **David has looked at the captures and approved** (the reviewer must not merge before this)
- [ ] `./tools/validate.ps1`: 0 new failures

## Report
Branch `sonnet/045-pixel-render-settings-cleanup`. David approved sharp + integer scaling in the Art Lab (keys `I`, `F`) on 2026-10-28. He still needs to look at the captures before this merges.

**Files changed**
- `project.godot`: `window/stretch/scale_mode="integer"`, `2d/snap/snap_2d_vertices_to_pixel=true` (`stretch/mode` stays `canvas_items`).
- `scripts/main.gd`: castle uses NEAREST (comment updated). `scripts/menus.gd`: title logo uses NEAREST. The glint shader only changes colour, so it works unchanged with NEAREST.
- `data/sprites.json`: removed the seven unused 8x8 food entries (`chips`, `cone`, `fish_chips`, `hot_dog`, `ice_cream`, `sandwich`, `seafood`). The PNGs stay on disk.
- `assets/sprites/toddler_polished.png.import`: `mipmaps/generate=false`.
- `scripts/art_lab.gd`, `tests/art_lab_checks.gd`: the lab now reads its starting scale mode from the window (the project default is now integer), and its `I` test checks "toggles and switches back" instead of assuming fractional first.

**Tests:** `INTEGRATION: 14490 checks, 0 failures`. The log still shows the existing script error `tests/level5_checks.gd:16` ('off_lead_dog' missing from `Config.targets`), which is unrelated to this task.

**Captures** (title, loading, level 1; `test-output/captures-045/`, not committed): `after-1280x720-*.png` and `after-1366x768-*.png`. At 1366x768 the game is drawn at exactly 4x (1280x720) with 43 px bars left and right and 24 px top and bottom. The captures are the game area only, so the bars are not in the images. Title logo, castle and level 1 are sharp-edged.

**Decisions**
- `scenes/loading.tscn`: the Backdrop and Gull nodes already had `texture_filter = 1` (NEAREST), so I changed nothing there. The loading backdrop still looks slightly soft because its 1672x941 source is shrunk by about 5x. That is 049 item 7.
- The seven food entries: checked for sprite-id uses in scripts, tests, tools, data and scenes. Matches such as `fish_chips` and `ice_cream` are food or station ids, not sprite ids, and the suite passes.
- No before captures: the play copy's `project.godot` has local edits, so I did not run a baseline from it.

**Merge note:** `GullinIt-main` has uncommitted edits to `project.godot` (Godot's reformat), so stash or reconcile that file before merging.

**Not done:** nothing. Awaiting David's look at the captures.

## Review notes
