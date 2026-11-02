# 061 — Landed vanilla ice cream art (pilot)

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-02

## What David should see if this works
Drop a vanilla ice cream and it no longer sits upright on the sand like it's still being held. It lands one of two ways: **cone-up** (the scoop squashed flat on the sand, the cone standing up from it) or **lying down** (cone horizontal, the scoop smeared against the sand at one end). Both show a clearly squashed, messy scoop. The test: does it read as "dropped ice cream" at real size, on the sand?

## Context
- The game side is already wired (placeholder art in `assets/sprites/food-ice-cream-landed-v1.png`; sprites `food_ice_cream_vanilla_landed_up` / `_lying` in `data/sprites.json`; the `landed` block on `ice_cream_vanilla` in `data/foods.json`; drawing in `scripts/stash_raids.gd`). **Replace the placeholder sheet only.**
- The held ice cream is `food-slices-icecream-v1.png` region `[299,0,16,33]`, shown at scale 0.25 (about 4x8 px on screen). Match its outline, palette and shading so the landed version is clearly the same ice cream.
- No code-drawn art: use the image generator, then crop and align.

## Requirements
1. Replace `assets/sprites/food-ice-cream-landed-v1.png` with generated art. Keep the same two regions, or update the `regions` and `frame_w`/`frame_h` of the two sprites in `data/sprites.json` to match:
   - `up` (region `[0,0,24,26]` now): squashed scoop splat at the bottom, cone upright (slightly tilted is fine) on top of it. Bottom edge of the art sits on the sand line.
   - `lying` (region `[25,10,34,16]` now): cone horizontal pointing **right**, squashed scoop at the left end. The game mirrors it for the other direction.
2. Same on-screen scale as the held sprite (0.25). If you draw at 2x native instead, set `landed.scale` to 0.5 in `data/foods.json` and say so in the Report.
3. Sharp edges, only colours from `tools/art_audit/palette.hex`, transparent background, bottom edge of each frame on the ground line (no empty rows under the art).
4. Do not change the held-ice-cream sprites or any other food.

## Out of scope
- The other four flavours and other foods (follow-up once David approves this pilot).
- Any gameplay or code change.

## Done when (acceptance)
- [ ] Both frames in the sheet, matching the held vanilla cone's style
- [ ] Capture at real size and 4x of both landed states on sand in the Report
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Status `done (awaiting David)`

## Report

## Review notes
