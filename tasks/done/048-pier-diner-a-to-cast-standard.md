# 048 — Pier diner A candidate on the same pixel grid as diner B

Status: done (awaiting David)
Author: Claude
Assignee: Codex
Depends on: 044
Created: 2026-10-27

## What David should see if this works
The red-cap, teal-stripe diner (diner A) **looks like the same person at the same height**, but with the same pixel size, outline and crispness as diner B (bucket hat) standing next to him. Today diner A is shrunk from much larger frames, so his pixels are finer and less even than diner B's and his edges are soft. **The test:** put the two diners side by side. Do they now look like they belong to the same game?

## Requirements
1. Rebuild diner A's three sheets (`pier-diner-retro-clean.png`, `pier-diner-motion-v2.png`, `pier-diner-reactions-v1.png`) the way task 033 built diner B: 128×128 cells, drawn at 0.5, sharp edges, about 40 px tall on screen. Same design, all 13 animations, same frame counts, fps and food anchors.
2. Register **only** in `data/art_lab.json`: current diner A vs the candidate, with diner B alongside for reference; motions `idle`, `walk_across` plus the swat animation.
3. **Task 042** (diner panic poses) also adds art to diner A. Do 048 first, or include 042's two diner A clips in this candidate, so they aren't drawn twice.

## Cast art standard (measured 2026-10-28 from the shoppers and diner B)
Every new or reworked person sheet must meet this, and the Report states the measured numbers:
- 128x128 cells drawn at exactly `visual_scale` 0.5 (no other scale, no 400 px cells).
- Tallest standing pose about 40 px on screen (cap to shoe, cane or hand-held props excluded). The old man is the one exception: 36-38 px.
- Hard alpha only: no semi-transparent pixels.
- Flat-colour runs of 1.0-1.6 screen px (finer or chunkier than the shoppers will look wrong next to them).
- Navy-black outline, the same colour family as the shoppers (about RGB 0-8, 0-8, 13-25).
- Feet on source row 116 (`sole`), `sprite_offset_y` -26, in every frame of every clip.
- Check it in the Art Lab next to a shopper before marking the task done.

## Done when (acceptance)
- [x] Comparison visible in the Art Lab; captures in the Report
- [x] Report lists the measured height, pixel size and baseline for diner A (current vs candidate) and diner B, per the standard above
- [x] Status `done (awaiting David)`

## Report

Branch: `codex/048-pier-diner-a-to-cast-standard`  
Implementation commit: `c1817275dae82b6794fcfda113e4424d06144531`

### Result

- Added candidate atlases for all 13 existing animation clips: 12 base frames, 14 motion/eating frames and 12 reaction frames. Frame counts, fps, looping and food anchors are inherited unchanged from the live diner A definitions in the Art Lab.
- Candidates are registered only in `data/art_lab.json`; `data/sprites.json` and the live game remain untouched.
- Added Art Lab support for a named animation and a fixed third cast reference. Four comparisons cover idle, walk, swat and the reaction sheet, with diner B alongside at 1x. At 4x, the fixed reference is hidden so the A/B pair fits the 320x180 camera.
- The complete supplied diner A source sheets are preserved under `assets/reference/pier-diner-a-cast-standard-v1/`. No new anatomy or clothing was code-drawn; the preparation tool only crops complete supplied poses, hardens alpha fringe, nearest-resizes and aligns them.

### Measurements

| Art | Cell / scale | Standing height | Pixel-grid ratio | Sole baseline | Alpha |
| --- | --- | ---: | ---: | --- | --- |
| Current diner A | 400x400 / 0.11 | 355 source px = 39.05 screen px | 4.55 source texels per cast art pixel | source y 397 in frame 0 | 56,334 semi-transparent pixels in frame 0 |
| Candidate diner A | 128x128 / 0.5 | 80 source px = 40 screen px | 1.0 (cast standard) | zero-based y 115 / one-based row 116 in every frame | hard alpha only |
| Diner B reference | 128x128 / 0.5 | 80 source px = 40 screen px | 1.0 (cast standard) | zero-based y 115 / one-based row 116 | hard alpha only |

Candidate metadata uses `sprite_offset_y: -26`. The outline remains the supplied diner A navy-black family; the important change is the candidate's one-to-one cast grid instead of sampling 4.55 source texels into each cast pixel.

### Captures

- Idle: `assets/previews/task-048-diner-a-idle-grid_1x_a.png`, `assets/previews/task-048-diner-a-idle-grid_4x_a.png`
- Walk: `assets/previews/task-048-diner-a-walk-grid_1x_b.png`, `assets/previews/task-048-diner-a-walk-grid_4x_b.png`
- Swat: `assets/previews/task-048-diner-a-swat-grid_1x_b.png`, `assets/previews/task-048-diner-a-swat-grid_4x_b.png`
- Reaction: `assets/previews/task-048-diner-a-reaction-grid_1x_b.png`, `assets/previews/task-048-diner-a-reaction-grid_4x_b.png`
- Static three-way sheet preview: `assets/previews/pier-diner-a-cast-standard-v1-comparison.png`

### Tests

`tools/validate.ps1 -Godot <Godot 4.7.2 console>`: **14,502 checks, 0 failures**. The suite still logs the documented pre-existing `tests/level5_checks.gd:16` missing `off_lead_dog` key, but it does not create a test failure.

### Image source / process

No new ImageGen call was needed: the existing supplied/generated diner A sheets were the strict identity and animation sources. The source-preserving import workflow was selected to avoid identity drift and to retain every exact pose and food anchor.

## Review notes
