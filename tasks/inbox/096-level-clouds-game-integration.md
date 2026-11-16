# 096 — Per-level clouds in the game (after art-lab approval)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 095 (David has approved the art-lab prototype)
Created: 2026-11-16

## What David should see if this works
Each level has its own cloud arrangement (different positions, sizes and mix of shapes). On levels with wind the clouds drift in the wind direction, faster in stronger wind and during gusts, and small/far clouds drift slower than big ones. Level 1 (no wind) has a very slow drift. Level 6 keeps its dusk tint on the clouds.

## Context
- Task 095 built and tuned this in the art lab. Move that prototype into the game as-is (same layouts, tuning values and drift maths David approved); do not redesign it.
- Sky is `scripts/beach_background_art.gd` (`BeachBackgroundArt`): one baked plate, pinned to the screen left edge, `update(camera_x, time)` called from `scripts/beach.gd`. The loading screen (`scripts/loading.gd`) also uses it with `BeachBackgroundArt.new(false)`.
- Wind: `scripts/wind.gd` (`BeachWind`, `direction`, `strength`, gusts). Level wind is in `data/levels/level_0N.json`. In game, `beach.wind_dir` and `beach.strength` are already set from the player's smoothed wind (`game.gd` ~470); use those, not `BeachWind` directly.
- New cloud sheet from task 094: `assets/sprites/background-v2/clouds-v2-alt-pearl.png` + `clouds-v2-alt-pearl.json` (approved; at 0.5 scale; ignore the first `clouds-v2` and the Coastal alt).
- Constraints: nearest-neighbour, 320x180 canvas, only draw clouds at scale 1, 0.5 or 2 so pixels stay crisp. Prefer data changes over code (CLAUDE.md). Invoke `godot-prompter:2d-essentials` before building.

## Requirements
1. Draw the sky as flat `SKY_COLOR` (and the dusk top colour) plus the sun, with clouds as separate sprites from the 094 sheet instead of the baked plate. Keep the sea unchanged.
2. Add a `"clouds"` list to each `data/levels/level_0N.json`: entries `{id, x, y, scale}` (x across the 320 px screen wrap width, y within the sky strip, above the sun/horizon). Give each level a distinct layout; use set B (overcast) clouds on the windier levels (4-6), set A on 1-3. Aim 5-9 clouds per level.
3. Drift: each frame `x += wind_dir * (base_speed + strength * wind_speed) * depth * delta`, where `depth` is larger for bigger clouds (parallax feel). Wrap at screen edges so a cloud re-enters on the other side. Tuning keys (`base_speed`, `wind_speed`) go in `data/tuning.json` under a new `clouds` block. Level 1 uses `base_speed` only.
4. Freeze with the beach clock (pause and results): drive it from `update(camera_x, time)` as the sea does, not from `_process`.
5. Dusk tint (`dusk_tint.gdshader`) applies to cloud sprites on level 6 as it does to the old plate.
6. Loading screen and any level without a `clouds` list fall back to a default arrangement so nothing renders sky-only.
7. Keep the old plate file in place; just stop using it.

## Out of scope
- New cloud art, sun, birds, sea, gameplay or wind logic changes.

## Done when (acceptance)
- [ ] Levels 1-6 each show a different cloud layout
- [ ] Clouds drift with wind direction on levels 2-6, faster in gusts, still very slowly on level 1
- [ ] Clouds stop when the beach is paused
- [ ] Level 6 clouds are dusk-tinted
- [ ] Test added in `tests/` and wired into `tests/integration.gd`: per-level layouts differ, drift direction follows `wind_dir`, wrap keeps x in range, pause freezes drift
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Docs/tuning notes updated for the new `clouds` keys

## Report

## Review notes
