# 062 â€” Touch: auto-peck by default, readable scaling, bigger buttons

Status: done
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
- `data/tuning.json` â†’ `touch` block (`assist_strength` 0.5, `assist_range`, `assist_angle`).
- The touch overlay draws the same rects as `TOUCH_BUTTONS`; keep them in sync.
- Rules: UI text in GullPixel on its 8 px grid (8 or 16 px). Keep web audio settings in the committed `project.godot` (`default_playback_type.web=0`).

## Requirements
1. **Auto-peck on touch.** When the device is a touchscreen and the player has never chosen a control mode, the effective default is `"casual"` (auto-peck). An explicit choice in settings still wins. Desktop default stays `"normal"`. Do it in `GameState.control_mode()` (one place), not per caller.
2. **Fractional scaling on touch web.** On web builds with a touchscreen, switch the root window to fractional scaling at startup (`get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL`) so the game fills the screen. Desktop keeps integer scaling (crisp pixels). Use nearest filtering, so no blur.
3. **Right-thumb dive stick (replaces the DIVE button).** A fixed aim circle in the bottom-right corner, about 40 logical px across (tuning `touch.dive_stick_radius`). Pushing it past its deadzone starts the dive aimed in the push direction (same path as `touch_dive` today); holding steers the dive/swoop; releasing ends the steering (normal pull-up). While the dive stick is held, it owns `gull.aim` and the left floating stick is ignored for aim, so the two thumbs never fight. The left floating stick keeps steering flight otherwise and must not start on the dive circle.
4. **Button layout.** PECK sits just above the dive circle (separate button, not in its centre, so peck taps and screech holds respond instantly). FLAP sits left of the circle. SLOW-MO keeps a spot in the cluster. PECK, FLAP and SLOW-MO are at least 52x30 logical px; nothing covers the HUD. The touch overlay draws the circle (ring + thumb knob) and the buttons from the same rects used for hit testing. Update tests that hard-code the old rects. PECK stays functional with auto-peck on (bins, screech hold, trainer peck lessons).
5. **Assist on touch.** `_assist_aim()` bends the dive-stick aim during the dive as now (`assist_strength`). Also add approach assist while gliding downward toward a target with the left stick, at new tuning key `touch.approach_assist_strength` = 0.25.
6. Trainer text that names the touch DIVE button (`{dive}` prompt for touch) should say to push the right stick instead. Record the assumption in the Report if `is_touchscreen_available()` misreports on any desktop browser you can test (touch laptops count as touch; that is fine).

## Out of scope
- Keyboard/mouse dive assist, the dive lesson rewrite, settings toggles for assists (separate tasks).
- Portrait mode layout. A "rotate your phone" hint is fine only if it takes a few lines; otherwise skip and note it.
- New art.

## Done when (acceptance)
- [ ] Fresh save on a touchscreen â†’ `control_mode()` returns `"casual"`; after choosing "normal" it returns `"normal"`. Desktop fresh save â†’ `"normal"`.
- [ ] Touch web build fills the screen with fractional scaling; desktop build still integer-scales.
- [ ] Pushing the right dive stick starts a dive aimed in the push direction and steers it while held; the left stick does not change aim during that time; release ends it.
- [ ] No DIVE button remains; PECK (above the circle), FLAP and SLOW-MO are at least 52x30 and tap correctly; PECK hold still screeches with auto-peck on.
- [ ] Approach assist bends aim while gliding toward a target on touch, at 0.25; no change for keyboard, mouse or pad.
- [ ] Checks added in `tests/touch_stick_checks.gd` (or `control_mode_checks.gd`) and wired into `tests/integration.gd`.
- [ ] Headless `tests/integration.tscn` passes with no new failures.
- [ ] README updated for the new tuning key and touch default.

## Report
Branch `sonnet/062-touch-defaults-and-scaling`.
Files: scripts/input_controller.gd, scripts/overlay.gd, scripts/main.gd, scripts/autoload/game_state.gd, data/tuning.json (dive_stick_radius 20, dive_stick_deadzone 0.35, approach_assist_strength 0.25), data/trainer.json, README.md, tests (touch_stick, control_mode, demo_polish, perk, trainer checks).
Tests: baseline main 16647 checks, 3 failures; now 16651 checks, 3 failures. The 3 are pre-existing on main: "card 1 sets up the perfect steal...", "nobody teleports across the beach while running off", "data/demo.json enables the four-level demo".
Decisions:
- Dive circle centre (296,152), radius 20. PECK 52x30 at (264,98), FLAP 52x30 at (218,142), SLOW-MO 52x30 at (208,106). The dive stick starts a dive on the rising edge past the deadzone (touch_dive pulse), owns aim while held (recentred keeps the heading), release hands aim back to the left stick.
- control_mode() defaults to casual when DisplayServer.is_touchscreen_available() or options.touch is on and no mode was saved.
- Fractional scaling set in main.gd _ready on web + touchscreen only; project.godot untouched (texture filter is already nearest).
- Approach assist applies only to the left stick while GLIDE with stick pointing down; touch only.
- Trainer touch {dive} is "the right stick", so the dive prompt reads "DIVE! THE RIGHT STICK" (test updated).
- Old "cluster covers 25% less area" check removed (buttons are now deliberately bigger).
Not done: rotate-your-phone hint; is_touchscreen_available() on desktop browsers not tested (touch laptops count as touch).


## Review notes
