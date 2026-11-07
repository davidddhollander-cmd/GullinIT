# 062 — Touch: auto-peck by default, readable scaling, bigger buttons

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-07

## Goal
Phone players can play the demo comfortably. PostHog shows 6 of 20 real sessions (Oct 24 to Nov 6) on touch, and none finished training. Touch players should not have to hit a small PECK button mid-dive, and the buttons must be big enough for a thumb on a phone held sideways.

## Context
- `scripts/input_controller.gd`: `TOUCH_BUTTONS`, `SLOWMO_BUTTON`, `_assist_aim()`, `touch_button_at()`.
- `scripts/autoload/game_state.gd:206-214`: `control_mode()` defaults to `"normal"`; only `"casual"` auto-pecks (`gull.gd:389`).
- `scripts/game.gd:283` and `scripts/main.gd:160`: `touch_visible` is set from `DisplayServer.is_touchscreen_available()` or `options.touch`.
- `project.godot`: `window/stretch/mode="canvas_items"`, `scale_mode="integer"`. On a phone (and in the itch iframe) integer scaling falls to 1x, so the 320x180 canvas and the 42x22 px buttons render tiny with black borders.
- `data/tuning.json` → `touch` block (`assist_strength` 0.5, `assist_range`, `assist_angle`).
- The touch overlay draws the same rects as `TOUCH_BUTTONS`; keep them in sync.
- Rules: UI text in GullPixel on its 8 px grid (8 or 16 px). Keep web audio settings in the committed `project.godot` (`default_playback_type.web=0`).

## Requirements
1. **Auto-peck on touch.** When the device is a touchscreen and the player has never chosen a control mode, the effective default is `"casual"` (auto-peck). An explicit choice in settings still wins. Desktop default stays `"normal"`. Do it in `GameState.control_mode()` (one place), not per caller.
2. **Fractional scaling on touch web.** On web builds with a touchscreen, switch the root window to fractional scaling at startup (`get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL`) so the game fills the screen. Desktop keeps integer scaling (crisp pixels). Use nearest filtering, so no blur.
3. **Bigger touch buttons.** Grow PECK / FLAP / DIVE / SLOW-MO to at least 52x30 logical px each, still a right-thumb cluster in the bottom-right corner, not covering the HUD. Update the overlay drawing and any tests that hard-code the old rects.
4. **Approach assist on touch.** Let `_assist_aim()` also bend aim while the gull is gliding downward toward a target (not only after a dive starts), at a lower strength: new tuning key `touch.approach_assist_strength` = 0.25. Dive-time assist stays at `assist_strength`.
5. Record the assumption in the Report if `is_touchscreen_available()` misreports on any desktop browser you can test (touch laptops count as touch; that is fine).

## Out of scope
- Keyboard/mouse dive assist, the dive lesson rewrite, settings toggles for assists (separate tasks).
- Portrait mode layout. A "rotate your phone" hint is fine only if it takes a few lines; otherwise skip and note it.
- New art.

## Done when (acceptance)
- [ ] Fresh save on a touchscreen → `control_mode()` returns `"casual"`; after choosing "normal" it returns `"normal"`. Desktop fresh save → `"normal"`.
- [ ] Touch web build fills the screen with fractional scaling; desktop build still integer-scales.
- [ ] Touch buttons are at least 52x30 logical px and tap correctly (`touch_button_at` tests updated).
- [ ] Approach assist bends aim while gliding toward a target on touch, at 0.25; no change for keyboard, mouse or pad.
- [ ] Checks added in `tests/touch_stick_checks.gd` (or `control_mode_checks.gd`) and wired into `tests/integration.gd`.
- [ ] Headless `tests/integration.tscn` passes with no new failures.
- [ ] README updated for the new tuning key and touch default.

## Report

## Review notes
