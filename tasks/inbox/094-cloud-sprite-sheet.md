# 094 — Cloud sprite sheet (separate, transparent clouds)

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-16

## What David should see if this works
A sheet of individual cloud sprites on a transparent background, in a few sizes and moods, that match the current sky art. Task 095 then places them per level and drifts them with the wind. Nothing changes in game from this task alone.

## Context
- Today the sky is one baked plate: `assets/sprites/background-v2/sky-clouds-320x80.png` (5 clouds on flat sky, source in `assets/reference/background-v2/sky-clouds-source.png`). Clouds cannot be moved or varied because they are part of the image.
- Match that plate's cloud style: outline, cream highlight, soft blue-grey underside, palette from `tools/art_audit/palette.hex`. See `assets/reference/sky-clouds-v1/PROMPT.md` for the earlier prompt.
- No code-drawn art: use the image generator, then crop and align. Follow the "Art: resize, don't shrink" rule: keep full detail, smaller on screen comes from draw scale in game (task 095 draws at integer or 0.5 scales).

## Requirements
1. New sheet `assets/sprites/background-v2/clouds-v2.png`, transparent background, sharp edges, no sky colour or halo around clouds. Pack on a regular grid with a gap between cells; add `clouds-v2.json` listing each cloud's id, region `[x,y,w,h]`.
2. Set A, **fair weather** (8 clouds): 3 small wisps (about 16-24 px wide), 3 medium (about 32-48 px), 2 large (about 64-90 px). Varied silhouettes, no two alike, none a copy of the five in the current plate.
3. Set B, **overcast / windy** (4 clouds): flatter, longer, slightly greyer streaks (about 48-96 px wide) for the windier levels.
4. Clouds must read on the sky colour `#5bc7d8` and survive the dusk tint (`assets/shaders/dusk_tint.gdshader`). Check one preview of each.
5. No sky background image is needed; the game fills the sky with `SKY_COLOR`.

## Out of scope
- Any code, data or gameplay change. Do not touch the existing plate (still used by the loading screen until 095 lands).
- Sun, sea, birds.

## Done when (acceptance)
- [ ] `clouds-v2.png` + `clouds-v2.json` with all 12 clouds, transparent, palette-clean
- [ ] Preview image in the Report: all clouds on `#5bc7d8`, and a dusk-tinted copy
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Status `done (awaiting David)`

## Report

## Review notes
