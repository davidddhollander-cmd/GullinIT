# 095 — Cloud layouts and wind drift: art-lab prototype

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 094
Created: 2026-11-16

## What David should see if this works
In the art lab (`scripts/art_lab.gd`) he can switch the sky to the new separate clouds, step through six level layouts, change wind direction and strength, and watch the clouds drift, so he can judge look and feel before any game file changes. Task 096 (game integration) only starts after he approves this.

## Context
- Art lab already toggles the generated sky (`G`) and dusk (`D`) by rebuilding `BeachBackdrop` / `BeachBackgroundArt` (`scripts/beach_background_art.gd`). The current sky is one baked plate that does not move.
- Cloud sheet from 094: `assets/sprites/background-v2/clouds-v2.png` + `clouds-v2.json`.
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

## Review notes
