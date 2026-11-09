# 075 — Enraged black-back: full sprite set

Status: done
Author: Claude
Assignee: Codex
Depends on: 069 (merged)
Created: 2026-11-09

## Goal
David approved the enraged idle and walk pilot in play. Make every remaining black-back animation in the same enraged look, so the bird stays furious for all of Shakedown.

## Context
- The approved look and method are in task 069, `assets/sprites/gull-great-black-backed-enraged-v1.png` and `assets/reference/gull-great-black-backed-enraged-v1/`. Use the approved frames as the identity reference.
- `BeachGull._swap_clip()` plays a clip's `<clip>_enraged` twin wherever one exists, so registering the clips is enough for body and screech frames.
- Shakedown draws the bird at 1.25x. Details must survive at that size.
- AGENTS.md applies: use the built-in image generator. Code may crop, align and pack, but must not draw, repaint, recolour or filter the bird. Removing detached background specks is allowed, as in 069.

## Requirements
1. **Body frames.** Generate enraged cells 8-19, matching the normal sheet `gull-great-black-backed-diner-style.png` pose for pose: fly 8-11, glide 12, dive_windup 13, dive 14, pullup 15, snatch 16, peck 17, landing 18, stunned 19.
2. Extend `assets/sprites/gull-great-black-backed-enraged-v1.png` to 1024x1280, 4x5 cells of 256x256, with the same cell numbers as the normal sheet. Cells 0-7 must stay pixel-identical to the approved pilot.
3. **Screech.** Generate 6 enraged frames matching `gull-great-black-backed-screech-v1.png` (768x512, 3x2 cells), packed at the same size as `assets/sprites/gull-great-black-backed-enraged-screech-v1.png`. The peak frame is held during the Shakedown rear-up, so it should be the angriest pose in the set.
4. **Carry.** Generate 13 enraged carry frames matching `gull-great-black-backed-carry-v1.png` (3328x256, 13 cells: walk 0-7, fly 8-11, glide 12), plus the matching upper-beak overlay. Pack as `gull-great-black-backed-enraged-carry-v1.png` and `gull-great-black-backed-enraged-carry-v1-upper-beak.png`, same size and cell order. The food must still sit correctly between the body and upper-beak layers.
5. **Look.** Same as the pilot: raised spiky hackles, puffed chest, heavy brow, red eye, meaner open bill, read from the silhouette first. Still recognisably a white-bodied black-back. No flames, auras or icons drawn on the bird.
6. **Alignment.** Beak tips within 2 source px of the matching normal cell, for body, screech and carry frames, so existing `frame_beaks` and carry `beak_anchors` still apply. Grounded frames keep the feet on the matching normal frame's baseline. Extra bulk stays inside the cell.
7. **Register**, in `data/gull_art.json` and `data/sprites.json`, on `gull_great_black_backed`: `fly_enraged`, `climb_enraged`, `glide_enraged`, `dive_windup_enraged`, `dive_enraged`, `pullup_enraged`, `snatch_enraged`, `peck_enraged`, `landing_enraged`, `stunned_enraged`, each with the same frames, fps, loop and `source_left` as its normal clip and `file` set to the enraged sheet. Add `screech_enraged` the same way with the enraged screech file. Add a `carry_enraged` block beside `carry` with `file`, `overlay_file` and `source`. Keep every existing value unchanged.
8. Keep untouched source artwork and prompts in `assets/reference/gull-great-black-backed-enraged-v1/`. Add previews in `assets/previews/`: normal and enraged side by side for every new frame at in-game size, including 1.25x, on sand and sky, plus animated GIFs of fly, screech and carry walk.

## Out of scope
- Gameplay code. A follow-up task makes the carry sprites switch to `carry_enraged`, which the loader does not read yet.

## Done when (acceptance)
- [x] All new clips load through the normal `SpriteFrames` path, and every existing clip and carry value is unchanged
- [x] Cells 0-7 of the enraged sheet are pixel-identical to the pilot
- [x] Beak and baseline alignment hold for every new frame
- [x] At in-game size every frame is obviously enraged and obviously the same bird
- [x] Source and prompts are in `assets/reference/`, previews in `assets/previews/`
- [x] Art checks in `tests/black_back_enraged_art_checks.gd` cover the new clips and carry sheets (frame count, baseline, beak alignment)
- [x] `./tools/validate.ps1` has no new failures

## Report
Implemented on `codex/075-enraged-black-back-full-set`. Art/tests commit: `4700d2e`; last implementation/registration commit: `f8669a3`; the final task-report commit is the branch tip (`git log -1`).

- Used the built-in image generator for all 31 new poses: 12 body, 6 screech, 8 carry-walk and 5 carry-flight/glide. Four untouched source PNGs, four exact prompts and their pose references are preserved in `assets/reference/gull-great-black-backed-enraged-v1/`.
- Extended `assets/sprites/gull-great-black-backed-enraged-v1.png` to 1024x1280 (4x5 cells), appending cells 8-19. Cells 0-7 are pixel-identical to the approved pilot; `approved-pilot.png` preserves the original 1024x512 sheet. Verified against the starting commit and in Godot tests.
- Added `gull-great-black-backed-enraged-screech-v1.png` (768x512, six cells), `gull-great-black-backed-enraged-carry-v1.png` and `gull-great-black-backed-enraged-carry-v1-upper-beak.png` (both 3328x256, thirteen cells).
- Every measured bill tip is within one source pixel of the corresponding normal cell. All 17 grounded poses (3 body, 6 screech, 8 carry-walk) match their normal sole baseline exactly. Extra bulk stays inside each 256x256 cell.
- The carry upper mandible is cropped from the generated body in the matching normal overlay contact window; its visible RGBA pixels are identical to the generated body pixels. Existing food anchors, sequence and scale are copied unchanged. `carry-full-source-atlas.png` groups the thirteen original-size source cells without resizing/repainting them; the two untouched carry outputs are also preserved.
- Added the 11 requested clip twins and `carry_enraged` in both `data/gull_art.json` and `data/sprites.json`. Each clip copies its normal frames/fps/loop/source_left and changes only the atlas file. The carry block changes only body, upper-beak and source paths. Structural comparison of both complete registries confirmed every existing value is unchanged; baseline entry snapshots support regression checks.
- Added `tools/art/pack_black_back_enraged_full.py` to reproduce the packed art and previews using crop/resize/alignment and permitted detached-speck removal only. It verifies retained main-silhouette pixels are unchanged. `full-set-packing.json` records all 31 alignments. No character art is drawn, repainted, recoloured or filtered by code.
- Added four comparison PNGs in `assets/previews/`: full body, screech, carry, and chip/ice-cream/hotdog layering. Every new frame appears at normal/enraged 0.375 scale and Shakedown 1.25x on sky and sand. Carry previews follow runtime body -> food -> upper-beak layering, retaining food's runtime size at both gull scales. Added fly, held-peak screech and carry-walk GIFs.
- Expanded `tests/black_back_enraged_art_checks.gd` for the full atlas, pilot preservation, clip runtime loading, beak/baseline alignment, carry metadata/layers, source/preview presence and unchanged existing values. Bill measurement now uses exact byte thresholds to avoid normalized-float edge-rounding discrepancies. Focused art plus atlas-isolation run: **299 checks, 0 failures**.
- Final `./tools/validate.ps1 -Godot <existing Godot 4.7.2 console executable>`: **17,218 checks, 2 failures, no new failures**. The command exits nonzero because main already fails `nobody teleports across the beach while running off` and `data/demo.json enables the four-level demo` (documented in task 074: 16,982 checks / the same 2 failures). Existing UI focus/art-lab warnings remain. Final log: `C:/Users/david/Documents/ChatGPT/GullinIt 2/task-075-validation.log`.
- No gameplay code changed. Body/screech selection uses the existing `_swap_clip()` behavior; selecting `carry_enraged` at runtime remains the specified follow-up task.
- Remote push is not attempted: earlier automatic approval review required explicit approval before uploading source/artwork to GitHub. The implementation is committed locally.

## Review notes
<!-- Filled in by the reviewer. -->




