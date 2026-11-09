# 065 — Great black-back screech art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-09

## Goal
The great black-back can stand and screech to charge its brashness meter, as the herring does. Screeching needs a `screech` animation drawn for this bird using the image generator to create a sprite sheet. Once the clip is registered, task 066's code turns the screech on by itself.

## Context
- Reference clip: `assets/sprites/gull-herring-screech-v1.png`, 768x512, 3 columns x 2 rows of 256x256 cells, 6 frames. Registered in `data/gull_art.json` under `gull_herring` and `player_gull`, and in `data/sprites.json`, as `{"frames":[0,1,2,3,4,5],"fps":7,"loop":false,"source_left":false,"file":...}`.
- Timing in code: `gull.gd` holds frame 4 while the screech is held. Frame 5 is the recovery back towards idle.
- Target bird: `gull_great_black_backed` in `data/gull_art.json`, sheet `assets/sprites/gull-great-black-backed-diner-style.png`, 256x256 cells, `visual_scale` 0.375, `art_height` 21, `native_alpha: true`. It is bigger and darker than the herring.
- AGENTS.md applies: use the built-in image generator. Code may crop, align and pack, but must not draw or repaint the bird. A code recolour of the herring sheet is not acceptable.

## Requirements
1. Generate a 6-frame screech for the great black-back, using the existing black-back sheet as the identity and style reference and the herring screech as the pose reference. Same bird: same pixel density, outline, palette and proportions. It should read as a big, loud bully: head thrown back, beak wide open at the peak. Wings spreading outwards.
2. Pack it as `assets/sprites/gull-great-black-backed-screech-v1.png` in the herring's layout (3x2, 256x256 cells). Feet stay on the existing idle baseline in every frame.
3. Register `screech` on `gull_great_black_backed` in `data/gull_art.json` and wherever else the herring's clip needs a matching black-back entry (`data/sprites.json`), with the same frames, fps and loop values. Keep every existing clip unchanged. Add `frame_beaks` or `frame_bounds` entries if the black-back's existing clips rely on them for this frame range.
4. Keep the untouched source artwork and prompt in `assets/reference/gull-great-black-backed-screech-v1/`. Put a preview in `assets/previews/` showing all 6 frames at in-game size next to the black-back's idle.

## Out of scope
- Gameplay code. Task 066 removes the herring-only screech check.
- Kittiwake screech art. Other existing clips.

## Done when (acceptance)
- [ ] `screech` is registered for the black-back with 6 frames and loads through the normal `SpriteFrames` path
- [ ] Feet match the idle baseline in every frame
- [ ] The source and prompt are in `assets/reference/`, the preview is in `assets/previews/`
- [ ] Art checks in `tests/` cover the clip (frame count, baseline)
- [ ] `./tools/validate.ps1` passes with no new failures

## Report
<!-- Filled in by the implementer: what changed (files), test results (check counts),
decisions/assumptions, anything not done, branch name and last commit hash. -->

## Review notes
<!-- Filled in by the reviewer. -->
