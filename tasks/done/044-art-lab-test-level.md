# 044 — Art Lab: a test level for judging art changes by eye

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-27

## What David will see
A separate test level, not reachable from the normal game menus. It looks like a normal beach (same sky, sand, camera and renderer as a real level), but each row shows **the current art on the left and a proposed replacement on the right**, both moving the way they do in play: gulls flying across and diving, people walking, food lying on the sand and held in a beak.

Keys in the lab:
- **1–9 / arrows:** switch between comparisons (one per art task).
- **Z:** toggle between real size and 4× zoom.
- **B:** blind mode. Swaps left and right at random and hides the labels, so David picks the better one without knowing which is new. Press again to reveal.
- **F:** toggle smooth vs sharp (Nearest) filtering on the shown sprites.
- **I:** toggle integer window scaling on and off (to preview task 045).
- **P:** pause; **.** steps one frame.
- **Esc:** quit.

## Why
Agents can't reliably judge how art looks on screen. From now on, every art change appears here first, next to the current version. **Only David decides** whether it goes into the game. Nothing in the live game changes until he approves.

## Requirements
1. New scene `scenes/art_lab.tscn` with script `scripts/art_lab.gd`. It runs from the editor (F6) or `godot --path . scenes/art_lab.tscn`. It is not linked from any menu and is excluded from the web export.
2. It reuses the real level backdrop and the real sprite nodes and animation code where possible, so what is shown is what the game draws. No mock-ups and no screenshots of screenshots.
3. Comparisons come from a new file `data/art_lab.json`, one entry per comparison: a title, a one-line description, the current sprite id, the candidate sprite definition (same shape as `data/sprites.json` entries), and a motion (`fly_across`, `dive`, `walk_across`, `idle`, `on_sand`, `in_beak`, `static`). Candidates are **only** registered here, never in `data/sprites.json`.
4. The first entry is a self-test: the current herring gull against itself, so David can confirm both sides look identical before trusting the lab.
5. `F` and `I` change settings only inside the lab at runtime (per-node `texture_filter`; the window's `content_scale_stretch`). They never touch `project.godot`.
6. A **Capture** button (key `C`) saves a PNG of the current screen at both zoom levels to `test-output/art_lab/`, named after the comparison, for the task Report.

## Out of scope
- Any change to existing art, data or settings.

## Done when (acceptance)
- [x] David can open the lab and see the herring gull self-test, with both sides identical, flying and diving
- [x] All keys above work
- [x] `./tools/validate.ps1`: 0 new failures; the lab does not appear in the web export

## Report
Branch `sonnet/044-art-lab-test-level`; see `git log` for the last commit.

**How David opens it:** `godot --path . scenes/art_lab.tscn` (or open `scenes/art_lab.tscn` in the editor and press F6). Keys: 1-9/arrows pick, Z zoom, B blind, F filter, I integer scale, P pause, `.` step, C capture, Esc quit.

**Files changed**
- `scenes/art_lab.tscn`, `scripts/art_lab.gd`: the lab. It uses the real `BeachBackdrop` and the real `BeachGull` (flight, dive, glide/climb animation code), driven by a small scripted pilot. Both sides receive identical commands, so identical art stays frame-for-frame identical.
- `data/art_lab.json`: comparisons (title, description, `current` sprite id, `candidate`, `motion`). First entry is the herring gull self-test (`"candidate": {"clone": "gull_herring"}`).
- `export_presets.cfg`: both presets now exclude `scenes/art_lab.tscn`, `scripts/art_lab.gd`, `data/art_lab.json`.
- `tests/art_lab_checks.gd` (+ one line in `tests/integration.gd`).

**Tests:** `tests/integration.tscn` headless: 14490 checks, 0 failures. One pre-existing script error remains, `tests/level5_checks.gd:16` (`Config.targets` has no `off_lead_dog`); it is level data this task does not touch.

**Captures:** `test-output/art_lab/herring-gull-self-test_{1x,4x}_{a,b,c}.png` (three moments, both zoom levels; `-- --capture` makes them, or press C in the lab). Both gulls match in all of them.

**Decisions**
- Candidates are registered in memory only (`Config.sprites["lab_N"]` / `"gull_lab_N"`), never in `data/sprites.json` (checked by a test). `candidate` may carry `"clone": "<sprite id>"` to copy a live entry first, then override fields.
- Gull sprites (id `gull_<species>`) play through a real `BeachGull`; every other sprite is a plain `AnimatedSprite2D` using `Config.frames`. `fly_across` and `dive` need a gull sprite (otherwise the lab logs an error and shows it static).
- Layout: the pair always moves together; sides sit 160 px apart at 1x and 44 px apart at 4x so both fit the screen. The camera follows the pair.
- `in_beak`: a real herring gull flies carrying the two food sprites at its beak position. It does not use the generated carry-pose sheets.
- B shuffles sides and hides CURRENT/PROPOSED; pressing again reveals the labels on the shuffled sides. I toggles `Window.content_scale_stretch` at runtime only; `project.godot` is untouched.
- The backdrop has no props and uses default-world signs, so a "PROMENADE" sign scrolls by.

**Follow-up (David asked for more to look at):** added four self-tests (current vs itself): mullet shopper walk, sundress shopper walk, hotdog on sand, fried fish in a gull's beak. Comparisons may carry `"size": [w, h]` (px, as in `data/foods.json`) for sprites that have no `visual_scale`. `-- --capture` now saves every comparison. All five were checked in screenshots: both sides match.

**Not done / limits:** no real candidates yet, by design. Self-tests only prove both sides render identically. Web export itself was not run (no templates here); exclusion is checked in `export_presets.cfg`.

## Review notes
