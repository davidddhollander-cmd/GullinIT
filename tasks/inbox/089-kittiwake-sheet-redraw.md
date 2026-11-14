# 089: Kittiwake screech art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-14

## Goal
The kittiwake can stand and screech like the herring and the great black-back. It needs a 6-frame `screech` animation made with the image generator. The game already turns screeching on for any gull that has this clip (task 066), so this task is art and registration only.

This replaces the earlier version of 089, a full sheet redraw. David has since retouched the main kittiwake sheet himself.

## Context
- **Identity and style reference:** the live sheet `assets/sprites/gull-kittiwake-diner-style.png` (David's retouch, commit 383d99b). Match it: clean continuous dark outline, flat shading, the same proportions and pixel density. Registered as `gull_kittiwake` in `data/gull_art.json` and `data/sprites.json`: 256x256 cells, `visual_scale` 0.375, `art_height` 12.75, `native_alpha: true`.
- **Pose and timing reference:** `assets/sprites/gull-herring-screech-v1.png` and `assets/sprites/gull-great-black-backed-screech-v1.png`. Each is 768x512, 3 columns x 2 rows of 256x256 cells, 6 frames, registered as `{"frames":[0,1,2,3,4,5],"fps":7,"loop":false,"source_left":false,"file":...}`. `gull.gd` holds frame 4 while the screech is held, and frame 5 is the recovery.
- **Precedent:** task 065 (`tasks/done/065-black-back-screech-art.md`) did the same job for the black-back. Follow its approach, packer and tests.
- **Art rule (AGENTS.md):** use the built-in image generator. Code may crop, align and pack, but must not draw, repaint or recolour the bird.

## Requirements
1. Generate a 6-frame screech for the kittiwake, using the live kittiwake sheet for identity and style and the herring screech for the poses. It should read as a small, sharp, shrill bird: neck stretched up, bill wide open at the peak (frame 4), and wings lifting a little. Keep the species details:
   - dark eye
   - plain yellow bill with no red spot
   - black legs
   - solid black wingtips
2. Pack it as `assets/sprites/gull-kittiwake-screech-v1.png` in the 3x2 layout of 256x256 cells. Keep the feet on the existing idle baseline in every frame.
3. Register `screech` on `gull_kittiwake` in `data/gull_art.json` and `data/sprites.json`, with the same frames, fps and loop as the herring. Leave every existing clip unchanged.
4. Keep the untouched source and prompt in `assets/reference/gull-kittiwake-screech-v1/`. Put a preview in `assets/previews/` showing all 6 frames at in-game size next to the kittiwake idle.

## Out of scope
- Gameplay code, the main sheet and the carry sheet.

## Done when (acceptance)
- [ ] `screech` is registered for the kittiwake with 6 frames and loads through the normal `SpriteFrames` path.
- [ ] The feet match the idle baseline in every frame.
- [ ] The source and prompt are in `assets/reference/` and the preview is in `assets/previews/`.
- [ ] Art checks in `tests/` cover the clip (frame count and baseline), in the style of 065's checks.
- [ ] `./tools/validate.ps1` shows no new failures. Main has 12 environmental ones on David's machine: flash, name field and PostHog.

## Report

## Review notes
