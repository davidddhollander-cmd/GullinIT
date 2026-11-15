# 089: Kittiwake screech art

Status: done
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
- [x] `screech` is registered for the kittiwake with 6 frames and loads through the normal `SpriteFrames` path.
- [x] The feet match the idle baseline in every frame.
- [x] The source and prompt are in `assets/reference/` and the preview is in `assets/previews/`.
- [x] Art checks in `tests/` cover the clip (frame count and baseline), in the style of 065's checks.
- [x] `./tools/validate.ps1` shows no new failures. Main has 12 environmental ones on David's machine: flash, name field and PostHog.

## Report

Implemented on `codex/089-kittiwake-screech-art` in `C:/Users/david/Documents/ChatGPT/GullinIt 2/task-089`, from main `d9d93b0`. Implementation commit: `2607e238266ec9bfdaea93e712ae8cddd9d84ddc`; this report is committed immediately after it.

- Built-in image generator created the kittiwake screech using David's live retouched identity sheet and herring screech poses. Two refinements improved the silhouette and added the slight wing lifts to frames 3 and 4. All three untouched source outputs, exact prompts and an enlarged idle identity reference are preserved in `assets/reference/gull-kittiwake-screech-v1/`.
- Added `assets/sprites/gull-kittiwake-screech-v1.png`: transparent 768x512, six right-facing 256x256 cells. Dark eye, plain yellow bill, black legs and black wingtips. Frame 4 stretches the neck, opens the bill and slightly lifts the wings; frame 5 recovers.
- Added only the `gull_kittiwake.animations.screech` entry in each of `data/gull_art.json` and `data/sprites.json`, with frames 0-5, 7 fps, non-looping and `source_left: false`. The registration helper verifies every pre-existing JSON value is unchanged. No gameplay code or main/carry artwork changed.
- `tools/art/pack_kittiwake_screech.py` only crops, nearest-samples and aligns generated RGBA pixels. A common nominal scale matches the production idle width; per-frame sampling adjustments of at most three pixels preserve connected toes/feathers, as in 065. Each frame ends at the live idle baseline y=140; foot centers are within 0.5 atlas pixels of idle. Exact crops, sizes and destinations are recorded in `packing.json`. No character pixels were painted, recoloured or alpha-masked.
- `assets/previews/gull-kittiwake-screech-v1.png` shows idle plus all six poses at game scale 0.375 and a second row at 2x atlas pixels. Inspected the final preview visually.
- Added `tests/kittiwake_screech_art_checks.gd` and registered it in `tests/gull_species_checks.gd`: 25 checks for clip metadata, production SpriteFrames loading, atlas isolation, baseline, horizontal foot stability, distinct poses, peak stretch and source/preview retention. A focused run including all kittiwake isolation checks passed **77 checks, 0 failures** (`../task-089-focused.log`).
- Fresh baseline `./tools/validate.ps1 -Godot <existing Godot 4.7.2 console executable>` passed **17,700 checks, 0 failures** (`../task-089-baseline.log`). The task's stated 12 environmental failures did not reproduce here. Final full validation passed **17,737 checks, 0 failures**, exit 0 (`../task-089-final-validation.log`). Existing focus, missing archived-reference and exit cleanup diagnostics remain in both baseline and final logs.
- An intermediate full run found three disconnected downsampling fragments; nearby nearest-neighbour sampling sizes fixed these before the final passing focused and full runs. An initial standalone script runner lacked autoload scope; the focused checks were rerun successfully through a normal scene.
- The obsolete delayed-start automation was deleted to prevent duplicate execution. Task is ready for review and merge; main was not modified by this implementation.

## Review notes

