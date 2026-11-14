# 087 — Keyboard flight lock: the mouse aims dives, never steers flight

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-14

## Goal
A player who flies with the keyboard never loses control because their mouse hand moves. Once WASD or the arrows are used, flight steering belongs to the keys; the mouse still dives (mouse 2), pecks and snatches (mouse 3) and aims where the dive goes. Mouse-only players keep today's controls.

## Context
- `scripts/input_controller.gd`: today "the last device used wins". Any `InputEventMouseMotion` sets `key_aim = false` (line ~94), so `update_player()` (line ~161) falls through to `gull.aim = mouse position`. A WASD press sets `key_aim` back to true (line ~166). Mouse buttons are already bound: left = climb, right = dive, middle = peck (line ~62), and clicks do not clear `key_aim`.
- `scripts/gull.gd`: `State.WINDUP` / `State.STRIKE` are the dive; `gull.aim` drives the heading in all states. `flight.cursor_radius` (60) in `data/tuning.json`.
- `scripts/autoload/game_state.gd`: saved settings (see `dive_steer()` for the pattern). Options menu in `scripts/menus.gd`.
- Feedback: libertaine (Reddit) "horrible at driving that bird... plugged in a mouse, much better"; an-04 played with mouse only.
- UI text: GullPixel font, 8 or 16 px only.

## Requirements
1. **Keyboard lock.** Add a saved setting `mouse_role`: `"steer"` (today's behaviour, default on a fresh save) or `"dive_aim"`. The first WASD/arrow steering press in a run switches a `"steer"` save to `"dive_aim"` and saves it. Gamepad and touch never change it.
2. **`dive_aim` behaviour.**
   - GLIDE and GROUNDED: mouse motion never moves `gull.aim`; keys steer, and with no key held the gull keeps its heading (`_aim_without_stick`). Mouse motion must not clear `key_aim`.
   - Mouse 1 (climb), mouse 2 (dive) and mouse 3 (peck/snatch, and the held-E screech) keep working exactly as now.
   - WINDUP and STRIKE: if the mouse moved in the last `input.mouse_aim_fresh` seconds (new tuning key, start 1.5) or the dive was started with mouse 2, aim the dive at the cursor and keep steering the swoop toward it until pull-up. A held key during the dive overrides the cursor (a key press is deliberate). If the mouse is stale and the dive came from Shift, keep today's keyboard dive.
3. **Reticle.** In `dive_aim` mode, draw a small cursor reticle at the mouse position while it is fresh (a simple crosshair or ring from code is fine; it is UI, not a character), so the player sees what the mouse controls. Hide the OS cursor in game if it doubles up; keep it in menus.
4. **Options.** Add a row in the options menu: "MOUSE: STEERS FLIGHT" / "MOUSE: AIMS DIVES", showing and changing `mouse_role`. This is the only way back to `"steer"`.
5. **Analytics.** Add `mouse_role` to `level_start` and `level_end` properties (same place as the other run properties). No new events.

## Out of scope
- Touch and gamepad input, aim assist, dive steer slider.
- Trainer copy changes (lesson 1 says to steer with keys or mouse; leave it, note in the Report if any line becomes wrong).
- Rebinding screen.

## Done when (acceptance)
- [ ] Fresh save, mouse only: flying and diving behave exactly as before; `mouse_role` stays `"steer"`.
- [ ] After one WASD press, mouse motion never changes flight heading in GLIDE (check: move the virtual mouse far off, heading unchanged), and `mouse_role` is `"dive_aim"` and persists.
- [ ] In `dive_aim`, mouse 2 dives toward the cursor; mouse 3 pecks; a dive from Shift with a stale mouse uses the keys; a held key overrides the cursor mid-dive.
- [ ] Options row toggles `mouse_role` both ways and persists.
- [ ] `level_start`/`level_end` carry `mouse_role`.
- [ ] Automated checks added in `tests/` for the rules above and wired into `tests/integration.gd`.
- [ ] `./tools/validate.ps1` (in `GullinIt-main` pass `-Godot ../GullinIt/.tools/Godot_v4.7.2-stable_win64_console.exe`) passes with no new failures.

## Report
Files: data/tuning.json (input.mouse_aim_fresh 1.5), scripts/autoload/game_state.gd (mouse_role/set_mouse_role), scripts/input_controller.gd, scripts/game.gd (analytics), scripts/menus.gd (options row), scripts/overlay.gd (reticle + OS cursor hide), tests/mouse_role_checks.gd (new, wired in integration.gd), tests/analytics_checks.gd, tests/control_mode_checks.gd and tests/touch_stick_checks.gd (reset mouse_role after their W/key presses).
Tests: ./tools/validate.ps1 -> INTEGRATION: 17636 checks, 0 failures.
Decisions: first WASD/arrow KEY press while input is enabled flips steer to dive_aim and saves (pad/touch never). In dive_aim, mouse motion no longer clears key_aim; glide/grounded use _aim_without_stick. WINDUP/STRIKE chase the cursor when mouse moved within mouse_aim_fresh or the dive came from mouse 2 (flag clears when dive ends or on a Shift dive); held key wins. Reticle (gold ring + ticks) drawn in overlay at last mouse position while fresh; OS cursor hidden only then (restored on overlay exit). Options row sits beside FULLSCREEN in one row of small buttons (a full-size row pushed SAVE/BACK off screen); it is hidden on mobile with fullscreen. level_start and _run_stats (so level_end and game_hidden) carry mouse_role.
Not done: no manual playtest. Trainer lesson 1 copy unchanged ("keys or mouse") and stays accurate enough.

## Review notes
<!-- Filled in by the reviewer. -->
