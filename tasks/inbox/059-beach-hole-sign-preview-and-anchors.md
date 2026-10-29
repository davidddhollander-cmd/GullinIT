# 059 — Beach Hole: sign preview and counter anchor fixes

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 057 (merged)
Created: 2026-10-29

## What David should see if this works
The Beach Hole preview shows **THE BEACH HOLE** sitting centred on the sign panel, all fourteen letters inside the cream, and the two counter anchors sit in the middle of their service windows.

## Why this task exists
Review of 057 found two defects in otherwise-accepted art (`beach-hole-restaurant-v2.png`, measured 132x88, sign panel `[19, 7, 94, 15]`):
1. **Name preview is wrong.** `assets/previews/beach-hole-restaurant-v2-name-preview.png` shows "THE BEACH HO" starting about 18 px right of where a centred label would start and running off the right edge of the panel; the last letters are navy on navy and vanish. The panel (94 px of cream) should fit the 80 px name, so the preview script (`tools/beach_hole_preview.gd`) is misplacing the label, not the art. As it stands the preview cannot show that the name fits.
2. **Counter anchors are off-centre.** `manifest.json` has `service_counter_anchors` `[[50,67],[101,67]]`. Measured from the sprite, the window openings span x 28-59 and x 71-103 (centres about 43 and 87). The left anchor is about 7 px right of centre and the right anchor sits at the window's right edge. Gameplay will misplace food and vendors from these.

## Requirements
1. Fix the preview so the label is centred on `sign_panel` and fully inside it. Find why it is offset (Label minimum size, font metrics, or the sign panel rectangle) and fix that cause. Show the name in the font's dark navy on the cream panel. Regenerate `beach-hole-restaurant-v2-name-preview.png` and check that all 14 letters are visible.
2. Recompute `service_counter_anchors` from the sprite itself: the horizontal centre of each window opening and the y of the counter ledge top. Record both values in `manifest.json` and say how they were measured in the Report.
3. Do **not** regenerate or edit `beach-hole-restaurant-v2.png`. No other file changes beyond the preview script, the preview image and `manifest.json`.

## Optional note for David's review (no action unless he asks)
He may also ask for fewer tropical-stripe motifs or a clearer palm/hibiscus motif and cleaner cream patches beside the portholes; that would be a new task, not part of this one.

## Done when (acceptance)
- [ ] Preview shows the full name inside the sign panel
- [ ] `service_counter_anchors` are the window centres, with the measurement method in the Report
- [ ] `./tools/validate.ps1`: 0 new failures
- [ ] Status `done (awaiting David)`

## Report

## Review notes
