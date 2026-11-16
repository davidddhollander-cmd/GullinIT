# 095 — Cloud layouts and wind drift: art-lab prototype

Status: merged (David approved the lab prototype; layouts 1-3 kept)
Author: Claude
Assignee: Claude Sonnet
Depends on: 094
Created: 2026-11-16

## What David should see if this works
In the art lab (`scripts/art_lab.gd`) he can switch the sky to the new separate clouds, step through six level layouts, change wind direction and strength, and watch the clouds drift, so he can judge look and feel before any game file changes. Task 096 (game integration) only starts after he approves this.

## Context
- Art lab already toggles the generated sky (`G`) and dusk (`D`) by rebuilding `BeachBackdrop` / `BeachBackgroundArt` (`scripts/beach_background_art.gd`). The current sky is one baked plate that does not move.
- Cloud sheet from 094: `assets/sprites/background-v2/clouds-v2-alt-pearl.png` + `clouds-v2-alt-pearl.json` (approved; at 0.5 scale; ignore the first `clouds-v2` and the Coastal alt).
- Constraints: nearest-neighbour, 320x180 canvas, draw clouds at scale 1, 0.5 or 2 only. Invoke `godot-prompter:2d-essentials` first.

## Requirements
1. **Touch art-lab and new lab-only files only.** Do not edit `data/levels/*.json`, `data/tuning.json`, `beach.gd`, `game.gd`, `loading.gd`, or the live `BeachBackgroundArt` behaviour. Put the prototype in a new script (e.g. `scripts/cloud_layer.gd`, class `CloudLayer`, a Node2D) and its layouts/tuning in a new `data/cloud_lab.json`.
2. `CloudLayer`: draws flat sky colour is NOT its job; it draws only clouds from the 094 sheet over whatever sky the backdrop shows. API: `setup(layout: Array, dusk: bool)` and `update(time: float, wind_dir: int, wind_strength: float)`.
3. `cloud_lab.json` holds: six layouts (one per level, entries `{id, x, y, scale}`, 5-9 clouds each, distinct; set A on 1-3, set B overcast on 4-6, nothing over the sun or below the horizon) and tuning `{base_speed, wind_speed, depth_by_size}`.
4. Drift per cloud: `x += wind_dir * (base_speed + strength * wind_speed) * depth * delta`, bigger clouds faster; wrap at screen edges. Drive it from the lab's clock so `P` (pause) and `.` (step) freeze/step it.
5. Dusk tint (`dusk_tint.gdshader`) applies to the clouds when dusk is on.
6. New art-lab keys, shown in the lab's flags line: `K` toggles the new clouds (hides the baked plate's clouds by drawing a flat sky behind, only while on), `L` cycles layout 1-6, `W` cycles wind: none / left weak / right weak / left strong / right strong / gusting (a sine on strength). Do not reuse existing keys.
7. Capture support: `C` capture shows the active layout; add `--capture` output for all six layouts at 1x and 4x to `test-output/art_lab/`.
8. Keep everything in the lab: the game must behave exactly as before.

## Out of scope
- Any change to the game, level data, tuning, loading screen or the live sky.
- New art (that is 094).

## Done when (acceptance)
- [ ] `K`, `L`, `W`, `D`, `P`, `.` work together in the lab; six layouts visibly differ
- [ ] Drift direction and speed follow the wind setting; big clouds move faster than small ones
- [ ] Dusk-tinted clouds look right on layout 6
- [ ] Capture images of all six layouts (1x and 4x) listed in the Report
- [ ] `git diff main --stat` in the Report shows no game/level/tuning files changed
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Status `done (awaiting David)`: David judges look and feel in the lab, then approves 096

## Report
Files changed (game files, level data and live tuning untouched; `git diff main` shows only these):
- `scripts/cloud_layer.gd` (new): `CloudLayer`, `setup(layout, dusk)` and `update(time, wind_dir, wind_strength)`.
- `data/cloud_lab.json` (new): six layouts (levels 1-3 fair-weather clouds, 4-6 wind streaks), wind presets, tuning `{base_speed 1.5, wind_speed 28, depth_by_size small .6 / medium 1 / large 1.4}`.
- `assets/shaders/cloud_dusk.gdshader` (new): lab copy of `dusk_tint` that reads the sky row from the sprite's position, because the plate shader reads it from UV and a small cloud sprite would get the wrong colour. Duplicates `band_color()`; 096 should share one include.
- `scripts/art_lab.gd`: keys `K` clouds, `L` layout, `W` wind; `--capture-clouds` mode; flags line shows `CLD L<n> <wind>`.
- `tests/art_lab_checks.gd`: 12 new checks. `export_presets.cfg`: new files added to the lab exclude filter.

Tests: `tests/integration.tscn` headless: 17895 checks, 8 failures. Baseline `main` is 17883 checks with the same 8 failures (Training Day card, steer freeze text, level card quest count, UI bounds, two flaky key-mode checks that pass in some runs). No new failures.

Captures (render with `godot scenes/art_lab.tscn -- --capture-clouds`): `test-output/art_lab/clouds-layout-1..6_{1x,4x}.png` and `clouds-layout-6-dusk_{1x,4x}.png` in the worktree `GullinIt 2/task-095` (not committed; `test-output/` is ignored).

Decisions:
- Clouds sit on a flat sky (the baked plate is replaced by a flat `SKY_COLOR` texture only while `K` is on), added after the sun so they pass in front of it. `K` turns the generated sky (`G`) on; `G` off turns clouds off.
- Drift: `x += heading * (base_speed + strength * wind_speed) * depth * delta`; calm wind (dir 0) drifts right at base speed; wrap period is screen width + cloud width. Depth comes from the Pearl sheet's `size` field (small/medium/large).
- "Nothing over the sun" applies to the starting layout only; drifting clouds pass in front of it.
- Layouts use scale 0.5 (one medium cloud at 1.0 on layout 3). Pearl's wind streaks look puffy next to the fair set, so layouts 4-6 read as similar to 1-3 at a glance; worth David's judgement.
- Gust preset is a sine on strength (period 6 s).

Not done / notes: in paused capture frames the long flags line overlaps the lab title (cosmetic, only with the long self-test title).

## Review notes

## Final state (after David's review)
- Three layouts: 1 = flat-bottomed plate cut-outs (`clouds-v2-plate`, plate-05 dropped: cut off in the source plate), 2 and 3 = Pearl clusters shrunk to 0.4x and palette-snapped (`clouds-v2-pearl-px`), drawn at scale 1. Clusters share a depth so they drift together.
- Calm wind means no drift (no `base_speed`).
- Dusk checked for all three layouts (`--capture-clouds` now shoots every layout by day and at dusk).
- Last integration run: 17895 checks, 8 failures, identical to the baseline `main` failures.
