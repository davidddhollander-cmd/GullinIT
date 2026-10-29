# 059 — Beach Hole: cleanup, sign preview and counter anchors

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 057 (merged)
Created: 2026-10-29

## What David should see if this works
David **accepted the Beach Hole design** ("yes, but needs some cleaning"). After this task, the same building looks **clean and deliberate at 1x and 4x**: no ragged cream shapes, no random dark scratches, THE BEACH HOLE sitting centred and fully visible on the sign, and food and vendors landing in the middle of the two windows.

## Why this task exists
`beach-hole-restaurant-v2.png` (132x88, merged in 057) has three problems found in review:
1. **Noise.** Measured on the file at 12x:
   - Ragged, broken cream wedges around the two oval portholes and beside each window frame (the side wings): the cream fills are chopped into stair-steps and holes with navy intrusions.
   - The lower timber panel under each window is covered in random dark vertical strokes of different lengths that read as scribble or a barcode, not as slats.
   - The thatch fringe under the sign is ragged, with dangling single pixels and uneven colour breaks.
   - The centre pillar between the windows has a stray dark spike and broken cream pieces.
   The isolated-pixel count (2 of 10,272) is good, so this is not lone pixels: it is small ragged shapes of 2 to 6 pixels, which the lone-pixel cleanup cannot see.
2. **Name preview is wrong.** `assets/previews/beach-hole-restaurant-v2-name-preview.png` shows "THE BEACH HO" starting about 18 px right of centre and running off the right edge of the panel, where the last letters vanish (navy text on a navy outline). The panel is 94 px of cream and the name 80 px, so the preview script `tools/beach_hole_preview.gd` is misplacing the label, not the art.
3. **Counter anchors are off-centre.** `service_counter_anchors` is `[[50,67],[101,67]]`. Measured from the sprite, the window openings span x 28-59 and x 71-103 (centres about 43.5 and 87). The left anchor is about 7 px right of centre and the right anchor sits at the window's right edge.

## Requirements
1. **Clean the art without changing the design.** Same composition, palette family, 132x88 canvas, bottom-centre origin, sign panel rectangle and two empty windows. Output `beach-hole-restaurant-v3.png`; keep v2 untouched. Try these in order and stop at the first that passes the targets below:
   a. **Code cleanup of the v2 sprite** (allowed by AGENTS.md: cleanup of generated art, not drawing): remove small connected components of a non-outline colour (fewer than 6 pixels, not touching the outline) by merging them into the surrounding colour; apply a 3x3 majority filter to non-outline pixels only; keep outline pixels (the navy line) fixed; keep the sign panel rectangle exactly flat.
   b. **Re-reduce the untouched source** `beach-hole-restaurant-v2-source.png` with a better grid detection (detect the true block size from the source; do not assume it) and the same palette.
   c. **Ask the image generator to clean it**: give it the v2 sprite upscaled 8x with the pixel sharpness spec from task 056 (saved in `PROMPTS.md`) and an instruction to keep the composition, colours and layout exactly and only replace the scratchy timber panel with clean vertical slats, make the cream wing shapes solid and smooth, and tidy the fringe. Save the exact prompt and untouched output in `PROMPTS.md` and prepare it with the same reduction. Do not hand-paint.
2. **The timber panel under each window becomes clean slats**: evenly spaced vertical lines, equal widths, one wood tone plus one shadow tone, no random dashes. This is the one place where approach (a) may not be enough; if so, use (c).
3. **Targets, measured and reported for v2 and v3:** number of connected components of fewer than 6 pixels (non-outline, any colour); share of non-outline pixels with at least 3 of 4 neighbours of a different colour; number of 2x2 solid navy blocks outside the window openings. v3 must show a clear reduction in all three (at least half) and no new colour beyond the v2 palette.
4. **Fix the preview.** Centre the label on `sign_panel` and fully inside it. Find the cause (Label minimum size, font metrics or the panel rectangle) and fix that cause. Name text is the font's dark navy on the cream panel. Regenerate `beach-hole-restaurant-v2-name-preview.png` (rename to v3 if the sprite is v3) and confirm all 14 letters are visible with at least 4 px of cream on each side.
5. **Fix the anchors.** Recompute `service_counter_anchors` from the sprite: the horizontal centre of each window opening and the y of the counter ledge top. Record them in `manifest.json` and state how they were measured in the Report.
6. Update the `PIER RESTAURANT` Art Lab candidate to v3. Do not touch `data/sprites.json` or gameplay.
7. AGENTS.md applies: generated art only, no drawing of the building by code.

## Done when (acceptance)
- [ ] `beach-hole-restaurant-v3.png` exists, hard alpha, 132x88, same palette, sign panel unchanged
- [ ] Targets above met and reported for v2 and v3, with a 12x before/after crop of the left wing and the timber panel in the Report
- [ ] Preview shows the full name inside the sign panel
- [ ] `service_counter_anchors` are the window centres, with the measurement method in the Report
- [ ] Art Lab `PIER RESTAURANT` shows v3 beside the three live stands; 1x capture in the Report
- [ ] `./tools/validate.ps1`: no new failures against the baseline of 30 failures that main had on 2026-10-29 (lesson, demo and sunbather checks, not art)
- [ ] Status `done (awaiting David)`

## Report

## Review notes
