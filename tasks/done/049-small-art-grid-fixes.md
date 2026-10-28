# 049 — Small art candidates (one comparison each)

Status: done (awaiting David)
Author: Claude
Assignee: Codex
Depends on: 044
Created: 2026-10-27

## What David should see if this works
Each item is its own comparison in the Art Lab, so each can be accepted or rejected separately. In every case except item 1 the size on screen stays the same; what changes is listed here. Item 1 is a deliberate size change: the old man is currently too small.

| # | What | Today | Candidate should look like |
| --- | --- | --- | --- |
| 1 | Old man with stick | Drawn at 0.3, so only 28 px tall (shoppers are 40) with uneven pixels | Same old man redrawn in a 128 px cell at 0.5, **36-38 px tall** (stooped, so a little shorter than the shoppers, but adult), pixel size matching the shoppers |
| 2 | Red and blue crabs | Shrunk from bigger art; may read as noise when scuttling | Same crabs drawn at their real size; claws and eyes readable at 1× |
| 3 | Stand roof signs (HOT DOGS / ICE CREAM / FISH & CHIPS) | Much finer pixels than the stand under them | Same signs, pixel size matching the people (lettering must stay readable) |
| 4 | Green wheelie bin | Shrunk to 80%, so slightly smeared; many more colours than the other props | Clean, chunky prop like the small grey bin and the stands |
| 5 | Feathers (dive hits) | Soft-edged, finer than everything else | Sharp little feathers in the game's colours |
| 6 | Title logo | Soft edges (task 045 fixes the blur; this fixes the source) | Same logo with crisp edges |
| 7 | Loading backdrop | Shrunk from a large painting | Same scene at the game's pixel size |
| 8 | Score numbers font (arcade font) | Soft edges | Same digits, crisp edges |
| 9 | Beach direction signs | Wood texture squashed to fit 8 px boards | Native board pieces (left end, repeatable middle, arrow end, post). Shown in the lab as a composed sign; wiring into the game is task 050 |

## Requirements
1. Each candidate is a new file, keeps the same on-screen size (except the old man, item 1: 36-38 px tall at 0.5, using the old-man scale in the standard below), has sharp edges and is drawn at 0.5 (people, crabs, signs, feathers, logo, backdrop) or 1:1 (wheelie bin, beach sign pieces).
2. Register every item **only** in `data/art_lab.json` as its own comparison, with the matching motion. Keep untouched sources in `assets/reference/art-grid-fixes-v1/`.

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
- [x] Nine comparisons in the Art Lab; captures in the Report
- [x] Status `done (awaiting David)`; David accepts or rejects each item separately

## Report

### Result

- Added nine independent `GRID FIX` Art Lab comparisons. Every proposal is registered only in `data/art_lab.json`; `data/sprites.json` and all live art remain unchanged.
- Preserved untouched inputs under `assets/reference/art-grid-fixes-v1/` and added the repeatable preparation script `tools/prepare_art_grid_fixes.gd`.
- Added paired source composites where a comparison needs multiple live assets (crabs, stand signs, feathers, and score digits), plus candidate-only files for every requested item.
- Extended the Art Lab to accept inline definitions on the current side and to honor `sprite_offset_y`, so source composites and cast-standard alignment can be compared without live metadata changes.

### Measured cast standard — old man

- Cell: 128 x 128; `visual_scale`: 0.5.
- Upright pose source height: 74 px, giving 37 px on screen.
- Every non-empty pose ends at source row 116; `sprite_offset_y`: -26.
- Alpha: hard only (zero semi-transparent pixels, enforced by preparation and tests).
- Outline remains in the source character's navy-black family; nearest-neighbour resizing retains roughly 2-3 source-pixel flat runs, or 1.0-1.5 px on screen.
- Cane and wide/low action silhouettes are preserved without using them to inflate the body-height measurement.

### Captures

Each comparison has a committed 1x and 4x capture in `assets/previews/`:

1. `task-049-01-old-man-{1x,4x}.png`
2. `task-049-02-crabs-{1x,4x}.png`
3. `task-049-03-roof-signs-{1x,4x}.png`
4. `task-049-04-wheelie-bin-{1x,4x}.png`
5. `task-049-05-feathers-{1x,4x}.png`
6. `task-049-06-title-logo-{1x,4x}.png`
7. `task-049-07-loading-backdrop-{1x,4x}.png`
8. `task-049-08-score-digits-{1x,4x}.png`
9. `task-049-09-beach-sign-{1x,4x}.png`

The large logo, backdrop, and score sheets are shown at a matched reduced comparison scale so both complete images fit inside their 160 px Art Lab panes; this affects only the lab view, not the candidate files.

### Verification

- `tools/validate.ps1 -Godot C:\Users\david\Documents\ChatGPT\GullinIt\.tools\Godot_v4.7.2-stable_win64_console.exe`
- `INTEGRATION: 14497 checks, 0 failures`
- The runner still logs the pre-existing `tests/level5_checks.gd:16` missing `off_lead_dog` dictionary entry; it did not count as a failure and was also present on task 048's baseline.
- Added checks for exactly nine comparisons, expected candidate dimensions, hard alpha, old-man sole alignment/height, and absence of candidate filenames from live sprite metadata.

### Decisions

- Reused the supplied generated/source artwork and limited processing to crop, nearest-neighbour resize, palette reduction for the bin, alignment, and composition. No character anatomy was drawn in code, and full source artwork is preserved.
- Kept beach-sign pieces modular (left end, one-pixel repeatable middle, arrow end, and post) and included a composed lab preview; live wiring remains task 050.
- No acceptance item was omitted. Final approval remains per item, as requested.

Branch: `codex/049-small-art-grid-fixes`

Last implementation commit: `a72935ac79314ec3a1e793c1e8e63ff56e96e887`

## Review notes
