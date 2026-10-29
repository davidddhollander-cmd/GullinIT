# 054 — Pier diner A regenerated with more detail and depth

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 044, 048 (merged: it adds the Art Lab `reference`/`animation` support and the diner A comparison entries this task replaces)
Created: 2026-10-28

## What David should see if this works
The red-visor, teal-stripe diner (diner A) **looks like the same person**, but drawn like the shoppers: softer inner contours, shaded hair, cloth and skin, and real depth, instead of the flat navy and purple masses with heavy black lines he has now. Next to the mullet shopper and diner B, does she belong to the same cast?

## Why this task exists
Task 048 resampled the old diner A art down to the cast grid. The grid, height and hard alpha are right, but David judged the look wrong: the art is too heavy and flat. Measured against the shoppers (idle frames, 128 px cells):
- Outer silhouette line is fine and the same on everyone: about 1 px, near black.
- **Interior dark pixels: diner A 43% vs shoppers 14-38%** (the purple hair, navy shorts and teal bands merge with the outline into black masses).
- **Interior line darkness (mean luma): shoppers 29-40, diner B 20, diner A 28.** The shoppers' inner contours are dark brown or navy, not black.
- A recolour touch-up softens the lines but cannot add detail to the hair and shorts. This needs new art.

## Requirements
1. **Regenerate** diner A with the built-in image generator. Do not resample or recolour the old art. Use the old sheets (`pier-diner-retro-clean.png` etc., or the copies in `assets/reference/pier-diner-a-cast-standard-v1/`) only as the **identity reference**: same woman, same red visor, same big purple afro, teal hoop earring, teal-and-white striped T-shirt, navy shorts, teal sandals with orange straps. Show the shoppers (`shopper-mullet-walk-v2-bite-panic-v1.png`) as the **style reference** in the prompt.
2. **More detail and depth**, in the shoppers' style:
   - Hair: two or three purple tones with highlights and visible curl clumps, not one dark mass.
   - Shorts: a lighter navy mid-tone with folds, highlights and a darker shadow side, so the leg shape reads.
   - T-shirt: shaded stripes that follow the body, with fold shadows.
   - Skin: at least three tones (light, mid, shadow); face with a nose, cheek and eye detail like the shoppers'.
   - Inner contours in **dark brown or navy**, not near-black. Keep only the outer silhouette near-black (about RGB 0-8, 0-8, 13-25), 1 px.
   Put the **pixel sharpness spec** from task 056 (flat single-colour pixel blocks, no dithering, noise, gradients or anti-aliasing, one clean 1 px outline) in every prompt, adapted to a 128 px cell, and save the exact prompts in the reference folder.
3. **Poses:** the same 13 animations, frame counts, fps, looping and food anchors as the live diner A: base sheet 12 frames (`idle`, `notice`, `watch`, `alert`, `brace`, `windup`, `swat`, `angry`), motion 14 frames (`walk`, `run`, `eat`), reactions 12 frames (`surprise`, `fist_shake`). She holds fried fish where the old art does. Consistent character and proportions across every frame.
4. Apply the **Cast art standard** below. Prepare the sheets with a tool like `tools/prepare_pier_diner_a_cast_standard.gd`, but this time scale **every frame of a sheet by the same factor** (not each pose fitted to height) and anchor on a shared centre, so there is no size or position jitter between frames.
5. Register **only** in `data/art_lab.json`: replace the four `DINER A ...` comparisons from 048 so each shows current diner A vs the regenerated candidate, with the mullet shopper alongside as the style reference. Do not touch `data/sprites.json`; swapping the live art is a later step for David.
6. Keep untouched sources and exact prompts in `assets/reference/pier-diner-a-regen-v1/`. Put a preview next to the mullet shopper and diner B in `assets/previews/`.
7. AGENTS.md applies: generated art only. Code may crop, align and pack; it must not draw bodies, faces or limbs, not even as placeholders. Do not add 042's `look_up` and `panic_run` here; that task follows.

## Cast art standard (measured 2026-10-28 from the shoppers and diner B)
Every new or reworked person sheet must meet this, and the Report states the measured numbers:
- 128x128 cells drawn at exactly `visual_scale` 0.5 (no other scale, no 400 px cells).
- Tallest standing pose about 40 px on screen (cap to shoe, cane or hand-held props excluded).
- Hard alpha only: no semi-transparent pixels.
- Flat-colour runs of 1.0-1.6 screen px.
- Navy-black outer outline, the same colour family as the shoppers (about RGB 0-8, 0-8, 13-25), 1 px.
- Feet on source row 116 (`sole`), `sprite_offset_y` -26, in every frame of every clip.
- **Detail targets (new):** interior dark pixels (luma < 70, not on the outer edge) at most 35% of opaque pixels in the idle frame; interior line mean luma at least 28; at least three distinct skin tones and two hair tones present.
- Check it in the Art Lab next to a shopper before marking the task done.

## Out of scope
- Swapping diner A into the live game, gameplay changes, or `data/sprites.json`.
- Diner B (David approved it as is) and any other character.
- Task 042's panic poses (it depends on this task).

## Done when (acceptance)
- [ ] The regenerated diner A sheets exist for all 13 animations with matching frame counts, fps and anchors
- [ ] Comparisons in the Art Lab (current vs regenerated, mullet shopper beside) for idle, walk, swat and reaction; captures in the Report
- [ ] Report lists the measured numbers: height, pixel size, baseline, interior-dark share and interior line luma for regenerated diner A, the mullet shopper and diner B
- [ ] Sources and prompts in `assets/reference/pier-diner-a-regen-v1/`; preview in `assets/previews/`
- [ ] Art-check tests cover the new sheets (cell layout, hard alpha, sole row), wired into `tests/integration.gd`
- [ ] `./tools/validate.ps1`: 0 new failures
- [ ] Status `done (awaiting David)`

## Report

## Review notes
