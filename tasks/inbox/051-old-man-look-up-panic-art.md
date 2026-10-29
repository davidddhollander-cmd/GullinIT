# 051 — Old man look_up + panic_run art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 041, 049
Created: 2026-10-28

## What David should see if this works
When the gang gulls dive, the old man **looks up at the sky** like the shoppers and diners, then **runs away in a panic** after the hit, instead of just standing in his "alert" pose and doing his normal hurried run. Do the whole crowd now react as one?

## Goal
Give the old man the same two Gang Call crowd reactions as the shoppers (041) and diners (042): `look_up` and `panic_run`. Task 040's behaviour (`scripts/crowd_panic.gd`) falls back to `alert` and `run` when a character has no such clip, so the old man is currently the one person who reacts differently.

## Context
- Do this **after 049 item 1** is accepted: that task redraws the old man at 0.5 and 36-38 px tall. Draw these clips on the accepted redraw, so nothing is drawn twice.
- Clip names and counts: the shoppers' 041 clips are the reference (`look_up` 2 frames at 6 fps, no loop; `panic_run` 6 frames at 12 fps, loop). Registered in `data/shopper_variants_art.json`.
- The old man is not mirrored. His art uses separate `_left` clips (`walk_left`, `run_left`, `stick_hit_left`), so he needs `look_up` (looks straight up, so one version is enough, as with the others) and `panic_run` **and** `panic_run_left`. `CrowdPanic.resolve` already picks a `_left` clip when the sheet has one, so no code change is needed; `look_up` is flipped like the others.
- His clips are built by `scripts/old_man_art.gd` (CLIPS table + atlas) and the preview tool `tools/old_man_art_preview.gd`.

## Requirements
1. Generate `look_up` and `panic_run` (and `panic_run_left`) for the old man with the built-in image generator, matching the shoppers' beats: head tilted back, eyes wide, mouth open for `look_up`; arms up or flailing, leaning forward, scared face for `panic_run`, clearly different from his `run`. The cane stays in his hand and attached in every frame; he keeps his cap, moustache, cardigan and trousers.
2. Append the frames to his atlas and register the clips in `OldManArt.CLIPS` (with `LOOPING` for the panic runs, `_speed` 12 for them). Keep every existing clip unchanged.
3. Apply the **Cast art standard** below. Feet on the existing sole row; same on-screen height as the redrawn old man.
4. Keep untouched sources and prompts in `assets/reference/old-man-panic-v1/`. Put a preview in `assets/previews/` showing him next to a shopper in both poses at in-game size.
5. AGENTS.md applies: generated art only. Code may crop, align and pack; it must not draw bodies, faces or limbs, not even as placeholders.

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
- The panic behaviour (task 040) and any gameplay change.
- Other old-man gaps (bench seating, `warning`, `windup`, `angry`).
- Other characters.

## Done when (acceptance)
- [ ] The old man has `look_up`, `panic_run` and `panic_run_left` registered, feet on the sole row, cane attached in every frame
- [ ] Frame counts and fps match the shoppers' 041 clips
- [ ] The preview (old man next to a shopper) is in `assets/previews/`; sources and prompts in `assets/reference/old-man-panic-v1/`
- [ ] Art-check tests cover the new clips (frame counts, baseline, no semi-transparent pixels), wired into `tests/integration.gd`
- [ ] `./tools/validate.ps1`: 0 new failures

## Report

## Review notes
