# 096 — Per-level clouds in the game (after art-lab approval)

Status: done (awaiting David)
Author: Claude
Assignee: Claude Sonnet
Depends on: 095 (David has approved the art-lab prototype)
Created: 2026-11-16

## What David should see if this works
Each level has its own cloud arrangement (different positions, sizes and mix of shapes). On levels with wind the clouds drift in the wind direction, faster in stronger wind and during gusts, and small/far clouds drift slower than big ones. Calm (no wind, e.g. level 1) means the clouds do not move at all. Level 6 keeps its dusk tint on the clouds.

## Context
- Task 095 built and tuned this in the art lab. Move that prototype into the game as-is (same layouts, tuning values and drift maths David approved); do not redesign it.
- Sky is `scripts/beach_background_art.gd` (`BeachBackgroundArt`): one baked plate, pinned to the screen left edge, `update(camera_x, time)` called from `scripts/beach.gd`. The loading screen (`scripts/loading.gd`) also uses it with `BeachBackgroundArt.new(false)`.
- Wind: `scripts/wind.gd` (`BeachWind`, `direction`, `strength`, gusts). Level wind is in `data/levels/level_0N.json`. In game, `beach.wind_dir` and `beach.strength` are already set from the player's smoothed wind (`game.gd` ~470); use those, not `BeachWind` directly.
- New cloud sheet from task 094: `assets/sprites/background-v2/clouds-v2-alt-pearl.png` + `clouds-v2-alt-pearl.json` (approved; at 0.5 scale; ignore the first `clouds-v2` and the Coastal alt).
- Constraints: nearest-neighbour, 320x180 canvas, only draw clouds at scale 1, 0.5 or 2 so pixels stay crisp. Prefer data changes over code (CLAUDE.md). Invoke `godot-prompter:2d-essentials` before building.

## Requirements
1. Draw the sky as flat `SKY_COLOR` (and the dusk top colour) plus the sun, with clouds as separate sprites from the 094 sheet instead of the baked plate. Keep the sea unchanged.
2. Add a `"clouds"` list to each `data/levels/level_0N.json`: entries `{id, x, y, scale}` (x across the 320 px screen wrap width, y within the sky strip, above the sun/horizon). Give each level a distinct layout; use set B (overcast) clouds on the windier levels (4-6), set A on 1-3. Aim 5-9 clouds per level.
3. Drift: each frame `x += wind_dir * (strength * wind_speed) * depth * delta`, where `depth` is larger for bigger clouds (parallax feel). Wrap at screen edges so a cloud re-enters on the other side. Tuning key `wind_speed` go in `data/tuning.json` under a new `clouds` block. No wind means no drift.
4. Freeze with the beach clock (pause and results): drive it from `update(camera_x, time)` as the sea does, not from `_process`.
5. Dusk tint (`dusk_tint.gdshader`) applies to cloud sprites on level 6 as it does to the old plate.
6. Loading screen and any level without a `clouds` list fall back to a default arrangement so nothing renders sky-only.
7. Keep the old plate file in place; just stop using it.

## Out of scope
- New cloud art, sun, birds, sea, gameplay or wind logic changes.

## Done when (acceptance)
- [ ] Levels 1-6 each show a different cloud layout
- [ ] Clouds drift with wind direction on levels 2-6, faster in gusts; no movement in calm
- [ ] Clouds stop when the beach is paused
- [ ] Level 6 clouds are dusk-tinted
- [ ] Test added in `tests/` and wired into `tests/integration.gd`: per-level layouts differ, drift direction follows `wind_dir`, wrap keeps x in range, pause freezes drift
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Docs/tuning notes updated for the new `clouds` keys

## Report
Files changed:
- `scripts/beach_background_art.gd`: flat sky strip instead of the baked plate, a `CloudLayer` after the sun, `update(camera_x, time, wind_dir, wind_strength)`; `_init(sunset, layout)` falls back to `Config.tuning.clouds.default_layout`.
- `scripts/cloud_layer.gd`: reads `Config.tuning.clouds`; per-entry `depth` override so clusters drift together.
- `scripts/beach.gd`: `cloud_layout`, passes `wind_dir`/`strength` to the sky each tick. `scripts/game.gd`: `beach.cloud_layout = level.get("clouds", [])`.
- `data/levels/level_01..07.json`: a `clouds` list each (7 distinct layouts). `data/tuning.json`: `clouds` block (`wind_speed`, `sheets`, `depth_by_size`, `default_layout`).
- `assets/shaders/dusk_bands.gdshaderinc` (new): the shared sunset colour table; `dusk_tint.gdshader` and `cloud_dusk.gdshader` include it.
- `scripts/art_lab.gd`, `data/cloud_lab.json` (now wind presets only), `tests/art_lab_checks.gd`, new `tests/cloud_checks.gd` (wired in `tests/integration.tscn` runner), `export_presets.cfg` (cloud_layer.gd and cloud_dusk shader now ship; only `data/cloud_lab.json` stays excluded).

Tests: headless integration 17902 checks, 6 failures. These 6 also fail on `main` (Training Day card, steer freeze text, level card quest count, 2 UI bounds) and are unrelated.

Decisions / differences from the task text:
- The game has 7 levels, not 6; layouts 1-3 are the ones David approved in the art lab, 4-7 are new arrangements from the same clouds (plate cut-outs and pearl-px clusters) for review.
- Sheets used are `clouds-v2-plate` and `clouds-v2-pearl-px` (the approved result of 095), not the Pearl sheet in the original text. Windy levels have no special streak set any more (David dropped it).
- Level 6 no longer has a sunset sky (earlier commit "drop the dusk tint and sunset sky"), so only the title screen uses dusk; its clouds use the default layout and are dusk-tinted. Dusk is also covered in `cloud_checks.gd`.
- Drift follows the gull's smoothed wind (`beach.wind_dir`/`strength`), so gusts speed clouds up; calm (level 1, title, loading) means no movement.
- Old plate file left in place, unused.

Not done / not verified: no in-game playtest (only the art lab captures and tests); a real run of level 3-5 with gusts is worth eyeballing.

## Review notes
