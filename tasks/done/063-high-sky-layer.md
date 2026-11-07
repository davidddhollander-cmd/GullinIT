# 063 — High sky layer with vertical camera follow

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-07

## Goal
Every level gains about 60 px (a third of the 180 px screen) of open sky above the current ceiling. The screen stays 320x180. The camera rises to follow the gull only when it climbs above the old ceiling, so normal play looks exactly as it does today. The new sky is the same flat blue as the existing sky top, extended upward (the dusk colour at dusk).

## Context
- Camera: `scripts/game.gd` creates the Camera2D at `(160,90)` and each step sets `camera.position = Vector2(roundf(camera_x),90)`. Only x follows the gull today.
- Ceiling: `flight.min_y: 20` in `data/tuning.json`, enforced in `scripts/gull.gd` (`if position.y < float(f.min_y)`).
- Sky drawing:
  - `scripts/beach_background_art.gd` `_draw()` fills `Rect2(0, 0, 320, SKY_Y)` with `top_color` (day `SKY_COLOR`, dusk `Color8(236,169,132)`); the cloud plate sits at `SKY_Y`.
  - The old drawn sky in `scripts/beach.gd` (around line 168+) starts at y=0 with `Color("a9d7d2")` / `Color("edb98b")` at sunset.
- Code that turns screen positions into world positions using only `camera_x - 160` (now also needs the camera's y offset):
  - `scripts/input_controller.gd` `update_player()`: mouse aim and touch aim.
  - `scripts/overlay.gd`: the `offset` for digestion/perks, the aim strip shift, the result `board.position.x` shift, plus any marker drawn at a world position ("YOU", "DIVE", landing aim).
- Things drawn or spawned in a screen-sized band from y=0 that should cover the new sky: `scripts/squall_rain.gd` (`position = Vector2(camera_x - 160.0, 0.0)`), the wind feathers in `scripts/effects.gd` `wind_tick()` (y from 14), and the clouds in `scripts/beach.gd`.
- `scripts/art_lab.gd` clamps camera y to `90/zoom .. 180-90/zoom`; leave it alone unless a test breaks.
- Rival gulls cruise at `rival.cruise_y: 65`; they stay where they are.
- HUD and menus are in a CanvasLayer and are not affected.

## Requirements
1. Add tuning keys under `world`: `sky_extra: 60` (px of new sky above y=0) and `camera_y_lerp` (start at the same value as `camera_lerp`). Set `flight.min_y` to `20 - sky_extra` (that is, -40), or derive the ceiling from `sky_extra` so there's one source of truth.
2. Camera y: the center is 90 while the gull is at or below the old ceiling (y ≥ 20). Above that, the camera rises by how far the gull is above y=20, clamped so the top of the view never goes above `-sky_extra` (center y ≥ 90 - sky_extra = 30). Smooth it with `camera_y_lerp`, the same frame-rate-independent lerp the x follow uses, and round it like x. Store it in a `camera_y` var next to `camera_x`. The reset (y=90) applies at level start and when the gull respawns or lands.
3. Every screen↔world conversion listed in Context uses `Vector2(camera_x - 160, camera_y - 90)` instead of x only. Grep for any other `camera_x - 160` / `camera_x-160` and fix those too.
4. Sky: `beach_background_art.gd` fills from `-sky_extra` down to `SKY_Y`. `beach.gd`'s drawn fallback sky also starts at `-sky_extra` with its existing top colour. No new art.
5. Squall rain and wind feathers cover the visible view, including when the camera is raised (follow camera y, or span from `-sky_extra`).
6. No change to gameplay rules, scoring, or rival/NPC behaviour. NPC "gull is high" checks (for example `position.y < 100`) are world coordinates and stay as they are.

## Out of scope
- A gameplay reward for flying high (for example a high-dive bonus). That's a possible follow-up once David has felt the layer in play.
- Sun parallax, new sky art, title flyby and loading scenes.
- Changing the 320x180 viewport or zoom.

## Done when (acceptance)
- [ ] With the gull at y ≥ 20 the camera y stays at 90 (unchanged framing).
- [ ] Holding climb takes the gull up to y = -40; the camera rises smoothly and its view top never goes above y = -60; no grey or empty band shows above the sky in day or dusk levels.
- [ ] Mouse aim and touch aim hit the cursor/stick position correctly while the camera is raised (test: with the camera raised 40 px, aim from a fixed screen point equals that point plus the full camera offset).
- [ ] HUD markers (YOU / DIVE / landing aim) sit on the gull and its target while the camera is raised.
- [ ] Squall rain covers the full screen while the camera is raised.
- [ ] Checks added in `tests/` and wired into `tests/integration.gd`: camera y follow and clamp, ceiling at -40, aim conversion with a vertical offset.
- [ ] Headless `tests/integration.tscn` passes with no new failures (the known `demo.json` lock check in the play copy is expected).
- [ ] Two `-Capture`-style screenshots in the report: normal framing, and fully raised at the ceiling.

## Report
Branch `sonnet/063-high-sky-layer`.
- Tuning: `world.sky_extra` 60, `world.camera_y_lerp` 0.15, `flight.min_y` 20 -> -40 (a test asserts min_y == 20 - sky_extra).
- `game.gd`: `camera_y` var, `camera_target_y()` (90 until gull y < 20, then follows, clamped to 90 - sky_extra), frame-rate-independent lerp, rounded; `update_player` and `wind_tick` get `camera_y`.
- `input_controller.gd` (mouse aim), `overlay.gd` (offset + sign board shift), `squall_rain.gd`/`squall.gd` (rain band follows camera y), `effects.gd` (wind feathers span the raised view), `beach_background_art.gd` and `beach.gd` (sky fills from -sky_extra).
- Touch/stick/pad aim are gull-relative, so need no conversion. Aim-strip shift in overlay only uses x, left unchanged. Respawn/landing needs no explicit reset: camera_y follows the gull back to 90.
- Tests: new `tests/sky_layer_checks.gd` wired into `tests/integration.gd` (9 checks: ceiling, follow, clamp, aim offset, rain band) plus two snapshot calls.
- Results: baseline 16674 checks, 3 failures; after 16683 checks, same 3 pre-existing failures (card 1 perfect steal, nobody teleports while running off, demo.json demo lock).
- Screenshots (gitignored, in worktree): `test-output/sky-layer-normal.png`, `test-output/sky-layer-raised.png`.
- Not done: no dusk-level screenshot (dusk uses the same extended top_color fill); no high-dive bonus (out of scope).

## Review notes
<!-- Filled in by the reviewer. -->
