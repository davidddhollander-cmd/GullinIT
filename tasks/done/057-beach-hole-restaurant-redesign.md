# 057 — "The Beach Hole" restaurant: 70s tropical redesign

Status: done (awaiting David)
Author: Claude
Assignee: Codex
Depends on: none (the `PIER RESTAURANT` Art Lab entry from the pier-restaurant-props-v1 review already exists in `data/art_lab.json`)
Created: 2026-10-29

## What David should see if this works
A pier restaurant that is clearly **a different, more modern building from the old stands: 70s style with a tropical beach theme**, and is called **The Beach Hole**. Lined up in the Art Lab next to the hot dog stand, ice cream kiosk and fish & chips stand, does it read as the fancier sit-down place on the pier, and does it still look like it belongs in the same game?

## Why this task exists
David reviewed `two-counter-restaurant-v1.png` (coral-and-cream striped awning, teal panelling, shell crest: a traditional British seaside kiosk) and sent it back: it should be more modern, 70s, tropical, and have its own name. It was otherwise functionally right (two service windows, empty interior, right size), so keep that contract.

## Requirements
1. **Regenerate** the restaurant with the built-in image generator. Do not recolour or edit the v1 art; use v1 only as the **functional/size reference** and the three live stands as the **pixel-density and outline reference**.
2. **Look:** 70s modern tropical beach bar.
   - Architecture: low, wide, flat or gently angled roof with a deep overhang, chunky geometric forms and a stepped or angled front, instead of the striped scalloped awning. Think 1970s beach club: bold horizontal bands, a sunburst or stripe motif, rounded corners, timber slat screen, hexagon or circle windows.
   - Tropical theme: palm fronds, a hibiscus or monstera leaf motif, bamboo or tiki-wood trim, a rattan or thatch fringe, a few hanging lanterns. Keep it readable at about 132 px wide.
   - Colour: warm 70s palette (burnt orange, mustard, avocado or palm green, teal, cream, brown) so it stands out from the stands but is still the same game. You may add **up to 8 colours** beyond the 16-colour union of the existing pier and stands. Report the final colour count.
3. **Name sign:** a clear, **blank flat panel** on the roof or fascia, big enough for the name in the game's bitmap font on its 8 px grid: **"THE BEACH HOLE"** is about 80 px wide and 8 px tall in GullPixel (letters advance 6 px, spaces 4), so make the panel at least **92 x 12 px** with a plain flat fill and a simple frame. **Do not generate any lettering in the art**: image generators cannot spell pixel text reliably, and the game draws its sign text with code, as it does for the other stands. Record the panel rectangle in `manifest.json` as `sign_panel` (x, y, w, h in sprite pixels).
4. **Function stays the same:** about 132x88 canvas (up to 140x92 if the design needs it; say why), bottom-centre origin, **two clearly separate service windows with two counter bays**, an **empty interior with no vendor, food, people or text baked in**, so gameplay can layer vendors and food. Record `service_counter_anchors` for both counters in `manifest.json` as before.
5. **Sharpness:** paste the **pixel sharpness spec from task 056** into the prompt, adjusted to this canvas, and prepare the sprite with the same **block-majority reduction** and lone-pixel cleanup described in 056. Save the exact prompt in `assets/reference/pier-restaurant-props-v1/PROMPTS.md` (new "Beach Hole v2" section; keep v1) and the untouched source alongside.
6. Output `assets/sprites/pier-restaurant-props-v1/beach-hole-restaurant-v2.png`, hard alpha, lossless import, nearest filter, no mipmaps. Update `manifest.json` and the prepare script.
7. **Art Lab:** change the `PIER RESTAURANT` entry's candidate to the v2 file (the current side is already the row of the three live stands at 1:1). Also add a **preview image** to `assets/previews/` showing the name "THE BEACH HOLE" rendered with GullPixel on the `sign_panel`, using the game font through Godot (a text overlay on a preview, not baked into the sprite).
8. AGENTS.md applies: generated art only. Code may crop, grid-sample, palette-map and clean up lone pixels, and may render text with the game font on a preview; it must not draw the building.

## Out of scope
- Placing the restaurant in a level, wiring vendors or counters, drawing the sign text in the live game (a later Sonnet task once the art is approved, using `sign_panel`).
- The table, chairs and fence (task 056).
- Changing `data/sprites.json` or gameplay.

## Measurements to report
Canvas size, tallest and widest extents, colour count (and which colours are new), isolated single pixel count and share (v1: 198 of 6,226 = 3.2%; target no worse), sign panel rectangle, counter anchors.

## Done when (acceptance)
- [x] `beach-hole-restaurant-v2.png` exists: hard alpha, about 132x88, two service windows, empty interior, blank sign panel of at least 92x12
- [x] `manifest.json` has `sign_panel` and both counter anchors
- [x] Prompt (with the sharpness spec) and untouched source saved
- [x] Art Lab `PIER RESTAURANT` shows v2 beside the three live stands; 1x capture in the Report; preview with "THE BEACH HOLE" on the sign
- [x] Report lists the measurements above
- [x] `./tools/validate.ps1`: 0 new failures
- [x] Status `done (awaiting David)`

## Report

### Result

Completed the generated-art redesign as a distinct low, wide 1970s tropical restaurant. The runtime sprite keeps two empty service windows and counter ledges, with no vendor, food, people or text baked in. The sign remains blank in the runtime asset; the separate preview renders **THE BEACH HOLE** through Godot with GullPixel.

### Files changed

- Added the three untouched image-generator outputs under `assets/reference/pier-restaurant-props-v1/` and documented the exact prompts in `PROMPTS.md`.
- Added `assets/sprites/pier-restaurant-props-v1/beach-hole-restaurant-v2.png`, its lossless Godot import, and the manifest metadata.
- Added `tools/prepare_beach_hole_restaurant_v2.gd` for block-majority palette reduction and lone-pixel cleanup.
- Added `tools/beach_hole_preview.gd` / `.tscn` to reproduce the GullPixel sign overlay.
- Updated `data/art_lab.json` so `PIER RESTAURANT` uses v2.
- Added `assets/previews/task-057-pier-restaurant-art-lab-1x.png` and `assets/previews/beach-hole-restaurant-v2-name-preview.png`.
- Included the prerequisite unmerged pier-restaurant-props-v1 asset set and preparation script so this branch is self-contained from `main`.

### Measurements

- Canvas: **132 × 88 px**; opaque extents: **130 × 86 px**, bbox `(1,1)–(130,86)`; bottom-centre origin `(66,87)`.
- Visible colours: **15** total.
- New colours beyond the 16-colour union, all eight allowed additions: `(232,79,24)`, `(247,137,32)`, `(229,174,51)`, `(117,137,61)`, `(48,105,70)`, `(92,55,32)`, `(193,109,39)`, `(245,216,128)`.
- Opaque pixels: **10,272**.
- Isolated non-outline single pixels after cleanup: **2 / 10,272 = 0.02%**, better than v1's 198 / 6,226 = 3.2%.
- Blank sign panel: **`[19, 7, 94, 15]`**, exceeding 92 × 12.
- Service counter anchors: **`[[50,67],[101,67]]`**.
- Import: lossless (`compress/mode=0`), nearest project filtering, mipmaps disabled.

### Decisions

- Used three generated passes. Attempt 1 established the design; attempt 2 widened the sign; attempt 3 was selected because its uninterrupted cream panel survives reduction above the required 92 × 12.
- The untouched selected source is block-majority sampled into the existing 132 × 88 contract with independent X/Y sampling, palette mapping and lone-pixel cleanup. No part of the building was drawn in code.
- The preview title uses Godot/GullPixel at the font's measured 80 × 8 size and is not baked into the runtime sprite.

### Verification

- `godot --headless --path . --script res://tools/prepare_beach_hole_restaurant_v2.gd`: exit **0**.
- `./tools/validate.ps1`: exit **0**.
- Direct integration log: **14,573 checks, 0 failures**. The pre-existing post-summary `off_lead_dog` dictionary script error and existing image-load warnings remain baseline-only; no new task failure.
- Live Godot Art Lab capture: `assets/previews/task-057-pier-restaurant-art-lab-1x.png`.
- GullPixel overlay preview: `assets/previews/beach-hole-restaurant-v2-name-preview.png`.

### Branch

- Branch: `codex/057-beach-hole-restaurant-redesign`
- Last commit: branch tip completion commit (local; GitHub push attempted after commit)

## Review notes
