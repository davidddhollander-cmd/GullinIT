# 041 — Shopper look_up + panic_run art

Status: done
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-27

## Goal
Gang Call (the herring gull's power) needs two new crowd reactions. First, beachgoers **look up at the sky in surprise** just before the gang gulls dive. Then, after the hit, they **run away in a panic**. Start with the three shoppers, the most common characters. Task 040 adds the behaviour and picks up these animation names automatically when they exist.

## Characters (existing sheets, 128x128 frames, `visual_scale` 0.5)
- `kiosk_customer`: `assets/sprites/shopper-diner-style-v2-bite-v1.png` (`data/shopper_art.json`)
- `shopper_mullet`: `assets/sprites/shopper-mullet-walk-v2-bite-v1.png` (`data/shopper_variants_art.json`)
- `shopper_sundress`: `assets/sprites/shopper-sundress-walk-v2-bite-v1.png` (`data/shopper_variants_art.json`)

## Requirements
1. Generate the animations below for each of the three shoppers with the built-in image generator. Match their current pixel density, outline weight, palette and proportions exactly; they must read as the same people.
   - `look_up`: 2 frames. The head is tilted back so the face points at the sky, eyes wide, mouth open. One hand may still hold food at the existing food anchor. The feet stay planted on the same sole baseline.
   - `panic_run`: 6–8 frames, a looping run cycle, clearly different from the existing angry `run`. Arms flailing or hands up by the head, leaning forward, and a scared face (not angry). Draw it facing the same way as the sheets' current `run`, so the code can flip it.
2. Add the frames to each character's sheet or a companion sheet, and register `look_up` (about 6 fps, no loop) and `panic_run` (about 12 fps, loop) in the same art JSON, including food anchors where the existing clips have them. Keep every existing animation working unchanged.
3. Keep the untouched source artwork and prompts in `assets/reference/shopper-panic-v1/`. Put a preview in `assets/previews/` showing all three shoppers in both new poses at in-game size, next to their current `idle`.
4. No gameplay changes. AGENTS.md applies: generated art only. Code may crop, align and pack, but must not draw bodies, faces or limbs, not even as placeholders.

## Out of scope
- Other characters (sunbather, mum/parent, pier diners, lifeguard, market cleaner, old man). These follow as separate tasks once these look right.
- The panic behaviour itself (task 040).

## Done when (acceptance)
- [ ] All three shoppers have `look_up` and `panic_run` registered, with feet on the existing baseline and food anchors aligned
- [ ] The preview image is in `assets/previews/`; the source and prompts are in `assets/reference/shopper-panic-v1/`
- [ ] Art-check tests cover the new clips (frame counts, baseline)
- [ ] `./tools/validate.ps1`: 0 new failures

## Report

- Files changed: added three untouched ImageGen source sheets and their prompt record under `assets/reference/shopper-panic-v1/`; added three versioned production atlases, a real-runtime preview, reproducible crop/pack and preview tools, `look_up`/`panic_run` registrations and food anchors in both art registries plus `data/sprites.json`, and shopper art coverage in the integration suite.
- Art: each shopper has 2 `look_up` frames at 6 fps (non-looping) and 6 `panic_run` frames at 12 fps (looping), at the existing 128x128 cell / 0.5 visual scale. Generated frames are nearest-neighbour resized to the approved 80 source-pixel adult height and aligned to sole y=116. Existing animation cells, including master-registry-only bench clips, remain visibly pixel-identical.
- Preview: `assets/previews/shopper-panic-v1.png` renders current idle, look-up, right-facing panic and flipped panic at in-game scale through the production `SpriteFrames` and separate-food anchor path.
- Tests: clean staged patch validated in a detached worktree with `./tools/validate.ps1 -Godot <Godot 4.7.2 console>`: **14,414 checks, 0 failures** (exit 0). The new shopper panic suite contributes 71 source/registration/timing/frame-density/baseline/legacy-pixel/preview checks. The working checkout itself retains unrelated user edits; its direct run had one pre-existing `data/demo.json` failure, while task 041 added none.
- Decisions: used the built-in image generator once per shopper with the current production atlas as the identity/style reference. Panic frames are allocated after the highest frame in the composed master registry, not only the local art JSON, so bench animations cannot be overwritten. Food anchors inherit the closest approved idle/run hand tracks and were visually checked in both directions.
- Anything not done: none.
- Branch: `codex/041-shopper-look-up-panic-art`
- Last commit: task completion commit at the pushed branch head.

## Review notes
