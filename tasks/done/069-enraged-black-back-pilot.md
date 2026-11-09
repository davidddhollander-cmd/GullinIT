# 069 — Enraged black-back art pilot (idle and walk)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-09

## Goal
During Shakedown the great black-back should look like a different animal: the same bird, but furious. Before making every animation, generate only idle and walk so David can judge the look in game. If he approves it, a follow-up task makes the remaining frames and the carry sheets.

## Context
- Target bird: `gull_great_black_backed` in `data/gull_art.json`, sheet `assets/sprites/gull-great-black-backed-diner-style.png`, 1024x1280, 4 columns x 5 rows of 256x256 cells, `visual_scale` 0.375, `art_height` 21, `native_alpha: true`, right-facing.
- Pilot frames: cell 0 is `idle`; cells 1-7 plus 0 are `walk` (`[1,2,3,4,5,6,7,0]`, 8 fps, looping).
- `scripts/gull.gd` places the sprite using `frame_beaks` and a fixed sole position, looked up by each clip's frame number. Clips may name their own `file`, as the black-back's `screech` does.
- Shakedown also draws the bird at 1.25x, so it is about 36 px long in game. Details must survive at that size.
- AGENTS.md applies: use the built-in image generator. Code may crop, align and pack, but must not draw or repaint the bird. A code recolour or filter of the existing sheet is not acceptable.

## Requirements
1. Generate 8 frames of the enraged black-back, using the existing sheet as the identity and style reference and matching its idle and walk poses frame for frame. Same bird, same pixel density, outline and proportions.
2. It must read as enraged **at game size**, from the silhouette first: hackles and neck feathers raised and spiky, chest puffed out, head lowered and thrust forward, a heavy angry brow, a red or blazing eye, beak slightly open and meaner. Plumage may darken or redden a little if that reads better, but the bird must still be recognisably a white-bodied black-back. No flames, auras, icons or other effects drawn on the bird.
3. Alignment: every frame's feet stay on the existing idle baseline, and the beak tip stays within 2 source px of the same cell in the normal sheet, so existing `frame_beaks` still apply. The extra bulk goes into the body and neck, staying inside the 256x256 cell.
4. Pack as `assets/sprites/gull-great-black-backed-enraged-v1.png`, 1024x512, 4x2 cells of 256x256, using the same cell numbers 0-7 as the normal sheet, so the full set can later extend it without renumbering.
5. Register clips `idle_enraged` (`[0]`, 1 fps, looping) and `walk_enraged` (`[1,2,3,4,5,6,7,0]`, 8 fps, looping) on `gull_great_black_backed` in `data/gull_art.json`, and wherever else the screech clip needed a matching entry, each with a `file` pointing at the new sheet. Keep every existing clip unchanged.
6. Keep the untouched source artwork and prompts in `assets/reference/gull-great-black-backed-enraged-v1/`. Put a preview in `assets/previews/` showing normal and enraged idle side by side at in-game size (including the 1.25x enraged size), plus the walk frames, on sand and sky, and an animated walk GIF.

## Out of scope
- Gameplay code: task 068 plays these clips during Shakedown.
- Flying, diving, landing, snatch, peck, stunned, screech and carry frames, until David approves the pilot.

## Done when (acceptance)
- [x] `idle_enraged` and `walk_enraged` load through the normal `SpriteFrames` path; every existing clip is unchanged
- [x] Feet match the idle baseline in every frame, and beak tips are within 2 source px of the matching normal frames
- [x] At in-game size the enraged bird is obviously different from the normal one, and obviously the same bird
- [x] Source and prompts are in `assets/reference/`, previews in `assets/previews/`
- [x] Art checks in `tests/` cover the clips (frame count, baseline, beak alignment)
- [x] `./tools/validate.ps1` has no new failures

## Report
Implemented on `codex/069-enraged-black-back-pilot`. Last implementation commit: `525d70c`; the following task-report commit is the branch tip (`git log -1`).

- Generated eight enraged idle/walk poses with the built-in image generator using the production black-back sheet for identity/style and its eight normal poses for footfall reference. Selected the cleanup pass; preserved both untouched generation outputs, both prompts and the pose reference in `assets/reference/gull-great-black-backed-enraged-v1/`.
- Packed `assets/sprites/gull-great-black-backed-enraged-v1.png`, 1024x512, four columns by two rows of 256x256 cells. Raised spiky hackles, puffed chest, hunched head, heavy brow, red eye and slightly open bill remain visible at game scale. The bird keeps white head/breast, dark wings and pink feet. No flames, auras or icons are drawn into the art.
- Added only `idle_enraged` ([0], 1 fps, loop) and `walk_enraged` ([1,2,3,4,5,6,7,0], 8 fps, loop), right-facing, with the new atlas file in both `data/gull_art.json` and `data/sprites.json`. Structural comparison against the original registries confirmed every pre-existing value is unchanged.
- Every sole ends at the normal idle baseline, y=140. Every measured bill tip is within one source pixel of its corresponding normal cell. The horizontal footprint is the normal frame width plus four pixels; extra height is in the chest/hackles. Existing `frame_beaks` and base-sheet bounds are unchanged.
- David explicitly approved removing only detached background specks. The reproducible packer `tools/art/pack_black_back_enraged.py` crops/resizes/aligns the generated poses, removes detached components, and asserts that every RGBA pixel of the main connected bird remains unchanged. It does not draw or recolour the bird. `packing.json` records crops, resizing, removed-speck counts and contact anchors.
- Added `assets/previews/gull-great-black-backed-enraged-v1.png`: normal/enraged idle at 0.375, plus the 1.25x Shakedown version, followed by all eight normal/enraged walk cells on sky and sand. Added the animated `-walk.gif`, eight frames in production order, exact 1-second loop (alternating 120/130 ms GIF timing).
- Added 37 checks in `tests/black_back_enraged_art_checks.gd`, wired into `gull_species_checks.gd`. Focused run including the normal black-back atlas isolation checks: **105 checks, 0 failures**.
- Final `./tools/validate.ps1 -Godot <existing Godot 4.7.2 console executable>`: **16,843 checks, 2 failures, no new failures**. These are the same documented main failures: `nobody teleports across the beach while running off` and `data/demo.json enables the four-level demo`. Task 067 reported 16,790 checks / the same 2 failures; this pilot adds 37 direct checks and 16 automatically exercised atlas-isolation checks. The command exits nonzero because those baseline failures remain. Log: `C:/Users/david/Documents/ChatGPT/GullinIt 2/task-069-validation.log`.
- Gameplay switching remains task 068. No flight, dive, landing, snatch, peck, stunned, screech or carry art was changed. Approval of this pilot's look remains David's decision before expanding the set.
- Remote push is not attempted: the earlier automatic approval review required explicit approval before uploading source/artwork to GitHub. Implementation will be committed locally.

## Review notes
<!-- Filled in by the reviewer. -->



