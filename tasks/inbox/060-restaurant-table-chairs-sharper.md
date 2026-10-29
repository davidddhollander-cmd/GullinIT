# 060 — Restaurant table and chairs v3: sharper, with one mirrored chair

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 056 (merged)
Created: 2026-10-29

## What David should see if this works
David reviewed table and chairs v2 and said **"possible, but needs to be sharper if possible"** (and rejected the pier fence outright, which is dropped, see below). After this task the set looks as crisp as the beach chair and food stands at 1x and 4x: straight clean outlines, flat colour areas, two **identical** chairs, no stray pixels.

## Why this task exists
`restaurant-table-chairs-v2.png` (60x34) is clean by the isolated-pixel measure (1 of 1,016) but still not sharp. Measured on the file at 14x:
- **Doubled outline**: under both seats and at the table post the navy line is 2 to 3 px thick (solid 2x2 navy blocks), so the outline is not an even 1 px line and the shapes look heavy and muddy.
- **Stray detail**: a lone dark-brown dash on the table top, and pale grey-blue single pixels pinned to the seat edges (a highlight that reads as a defect).
- **The two chairs differ**: different leg widths, a different seat shape and different shading, which reads as inconsistency.
- **Mushy construction**: the table's foot is a cluster of broken 1-2 px pieces, and the chair legs change width along their length.
These come from the generator's source not being a true pixel grid, so the reduction samples blurry block edges.

## Requirements
1. **Generate the parts separately, not the whole set at once:**
   - **One chair** (side-on three-quarter view, seat block, back block, two visible legs, muted teal seat) and **one table** (square top, thick central post, a simple broad foot). Two generator prompts. The second chair is the first **mirrored horizontally by code** (flipping a generated image is allowed by AGENTS.md; no drawing). Place them like v2: chair, table, mirrored chair.
   - Put the **pixel sharpness spec from task 056** in both prompts, adapted to the part (a chair is designed on about 18 by 28 pixels, the table on about 26 by 26 pixels). Ask explicitly for each pixel to be an exact 8x8 block and for the outline to be exactly one block thick with no doubled corners.
2. **Prove the source is a real pixel grid before using it.** Detect the block size by autocorrelation or edge periodicity of the source (do not assume 8), then report the **block uniformity**: the share of grid blocks whose pixels are all one colour. Use only a source with block uniformity of at least 95%. If it is lower, regenerate (up to four attempts per part, all measured in the Report, the untouched outputs saved). If none reaches 95%, stop and report instead of shipping.
3. **Reduce with the detected grid** (one pixel per block, majority colour), map to the existing 16-colour union palette, then remove non-outline connected components of fewer than 4 pixels. Do not hand-edit pixels.
4. **Targets, reported for v2 and v3:**
   - Solid 2x2 navy blocks: v3 at most 2 (v2 has many).
   - Isolated non-outline pixels: 0.
   - Colours: at most 9, with the largest flat area at least as big as v2's (124).
   - Both chairs are pixel-identical after mirroring (state it as verified by comparing the two halves).
5. Keep **1 screen pixel per art pixel**, canvas about 60x34, bottom-centre origin (30,33), hard alpha. Do not enlarge the set above v2's 58x28 extent; it may be a little smaller if that is what sharpness needs. Chairs must still read as chairs (back, seat, legs) next to the shopper.
6. Output `restaurant-table-chairs-v3.png`, lossless nearest import, `manifest.json` entry, saved prompts in `PROMPTS.md` ("Table and chairs v3", keep earlier sections), untouched sources in `assets/reference/pier-restaurant-props-v1/`. Update the `RESTAURANT TABLE` Art Lab candidate to v3 (beach chair and shopper stay as reference).
7. **The pier wire fence is dropped.** David rejected `pier-wire-fence-v2.png`. Do not generate another one. Leave the files and the Art Lab entry in place for the record.
8. AGENTS.md applies: generated art only; code may crop, mirror, grid-sample, palette-map and remove tiny components.

## Done when (acceptance)
- [ ] `restaurant-table-chairs-v3.png` exists, hard alpha, about 60x34, at most 9 colours
- [ ] Block uniformity reported for the source of each part (at least 95%)
- [ ] The targets above are met and reported for v2 and v3, with a 14x crop of v2 and v3 side by side in the Report
- [ ] Prompts with the sharpness spec saved; untouched sources preserved
- [ ] The `RESTAURANT TABLE` Art Lab entry shows v3; 1x and 4x captures in the Report
- [ ] `./tools/validate.ps1`: no new failures against the baseline of 30 failures that main had on 2026-10-29 (lesson, demo and sunbather checks, not art)
- [ ] Status `done (awaiting David)`

## Report

## Review notes
