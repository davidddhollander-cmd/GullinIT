# 065 — Great black-back screech art

Status: merged
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
- [x] `screech` is registered for the black-back with 6 frames and loads through the normal `SpriteFrames` path
- [x] Feet match the idle baseline in every frame
- [x] The source and prompt are in `assets/reference/`, the preview is in `assets/previews/`
- [x] Art checks in `tests/` cover the clip (frame count, baseline)
- [x] `./tools/validate.ps1` passes with no new failures

## Report
Implemented on `codex/065-black-back-screech-art`; artwork/tests commit `7443652`.

- Built-in image generator created six black-back poses using its production sheet for identity and the herring screech sheet for timing. Preserved both untouched generation outputs and both prompts in `assets/reference/gull-great-black-backed-screech-v1/`.
- Added `assets/sprites/gull-great-black-backed-screech-v1.png`: 768x512, 3x2 cells of 256x256, frames 0-5 at 7 fps, non-looping, right-facing. Frame 4 is the wide-open peak with spread wings; frame 5 recovers.
- Registered only the black-back screech in `data/gull_art.json` and `data/sprites.json`. A structural comparison against HEAD before implementation confirmed all pre-existing registry values were identical.
- All six frames end at the idle sole baseline y=140. Code only crops/resizes/aligns/packs generated art; no character pixels are drawn or recoloured. Nearest-neighbour sampling sizes vary by at most a few pixels to keep feather tips connected. The packer and crop/destination records are committed.
- Added a game-scale comparison of idle + all six frames at `assets/previews/gull-great-black-backed-screech-v1.png`.
- Added 18 focused screech checks in `tests/black_back_screech_art_checks.gd`, called from the existing gull species suite. A focused run including all black-back atlas isolation checks passed **70 checks, 0 failures**.
- Existing base-sheet `frame_beaks` and `frame_bounds` remain unchanged because these indices belong to existing clips. Grounded placement uses the fixed sole offset; separate generated screech bounds are preserved in `packing.json`. No gameplay code changed; enabling screech remains task 066.
- Final `./tools/validate.ps1 -Godot <existing Godot 4.7.2 console executable>`: **16,661 checks, 2 failures, no new failures**. The command exits nonzero because main already has `nobody teleports across the beach while running off` and `data/demo.json enables the four-level demo` failures, documented in tasks 062-064. Existing UI focus/art-lab warnings remain. Final log: `C:/Users/david/Documents/ChatGPT/GullinIt 2/task-065-final-validation.log`.
- An earlier complete run found a JSON-number array comparison issue in the new test; that assertion was corrected before both the passing focused run and the final full run above.
- Artwork and validation are complete. Remote push remains pending: automatic approval review rejected the upload because explicit approval of the GitHub destination was not established. Branch is retained locally for review. Last implementation commit: `7443652`; the following task-report commit is the branch tip (`git log -1`).
## Review notes
<!-- Filled in by the reviewer. -->



