# 042 — Pier diner look_up + panic_run art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 041, 054
Created: 2026-10-27

## Goal
Give both pier diners the same two Gang Call crowd reactions as the shoppers in task 041. They **look up at the sky in surprise** just before the gang gulls dive, then **run away in a panic** after the hit. The poses must match the shoppers' 041 poses (same beats, same body language), so the whole crowd reacts as one. Task 040's behaviour picks up these animation names automatically.

## Characters (existing sheets)
- **Pier diner A:** `pier_diner` (`assets/sprites/pier-diner-retro-clean.png`), `pier_diner_motion` (`pier-diner-motion-v2.png`), `pier_diner_reactions` (`pier-diner-reactions-v1.png`). 400x400 frames, `visual_scale` 0.11, registered in `data/pier_diner_art.json`.
- **Pier diner B:** `pier_diner_b`, `pier_diner_b_motion`, `pier_diner_b_reactions` (`assets/sprites/pier-diner-b-*-v1.png`). 128x128 frames, `visual_scale` 0.5, registered in `data/sprites.json`.

## Requirements
1. Use the merged 041 shopper `look_up` and `panic_run` frames as the pose reference, and generate the same two clips for each diner with the built-in image generator. Match each diner's own pixel density, outline weight, palette and proportions; they must read as the same people.
   - `look_up`: 2 frames. The head is tilted back so the face points at the sky, eyes wide, mouth open. A held meal or fork stays at the existing food anchor. The feet stay planted on the existing sole baseline. The timing and pose beats match the shoppers' version.
   - `panic_run`: 6–8 frames, a looping run cycle, clearly different from the existing angry `run`. Arms flailing or hands up by the head, leaning forward, and a scared face. It has the same frame count and fps as the shoppers' `panic_run`, and faces the same way as the diner's current `run`, so the code can flip it.
2. Add the clips to each diner's reactions sheet (or a companion sheet) and register `look_up` (no loop) and `panic_run` (loop) next to their existing clips. Use the same fps as the shopper clips, and include food anchors where the existing clips have them. Keep every existing animation working unchanged.
3. Keep the untouched source artwork and prompts in `assets/reference/pier-diner-panic-v1/`. Put a preview in `assets/previews/` showing both diners in both poses at in-game size, next to a shopper doing the same pose from 041.
4. No gameplay changes. AGENTS.md applies: generated art only. Code may crop, align and pack, but must not draw bodies, faces or limbs, not even as placeholders.

## Cast art standard (measured 2026-10-28 from the shoppers and diner B)
Every new or reworked person sheet must meet this, and the Report states the measured numbers:
- 128x128 cells drawn at exactly `visual_scale` 0.5 (no other scale, no 400 px cells).
- Tallest standing pose about 40 px on screen (cap to shoe, cane or hand-held props excluded). The old man is the one exception: 36-38 px.
- Hard alpha only: no semi-transparent pixels.
- Flat-colour runs of 1.0-1.6 screen px (finer or chunkier than the shoppers will look wrong next to them).
- Navy-black outline, the same colour family as the shoppers (about RGB 0-8, 0-8, 13-25).
- Feet on source row 116 (`sole`), `sprite_offset_y` -26, in every frame of every clip.
- Check it in the Art Lab next to a shopper before marking the task done.

## Out of scope
- Other characters (sunbather, mum/parent, lifeguard, market cleaner). The old man gets the same two clips in task 051.
- The panic behaviour (task 040).

## Done when (acceptance)
- [ ] Both diners have `look_up` and `panic_run` registered, with feet on the existing baseline and food anchors aligned
- [ ] The clips match the shoppers' 041 poses: same beats, same frame counts and fps
- [ ] The preview (diners next to a shopper) is in `assets/previews/`; the sources and prompts are in `assets/reference/pier-diner-panic-v1/`
- [ ] Art-check tests cover the new clips (frame counts, baseline)
- [ ] `./tools/validate.ps1`: 0 new failures

## Report

## Review notes
