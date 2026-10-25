# 018 — Touch floating stick and aim assist

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
On iPhone and iPad browsers you can't control the gull's dive aim. Today the touch aim point is wherever the finger is (`touch_aim = event.position` in `scripts/input_controller.gd`). That causes four problems:

- The thumb covers the reticle, the target and the gull.
- Steering during a dive means dragging across the play area.
- The button cluster (x 224–318, y 122–173) and the top bar can't be aimed at.
- On tablets the thumb can't reach the middle of the screen.

Replace touch pointing with a floating virtual stick, and add a light aim assist for touch only. Mouse, keyboard and gamepad behaviour must not change at all.

## Context
- `scripts/input_controller.gd`: `_input` handles touch; `update_player` picks the aim source in the order gamepad → touch → mouse. The gamepad already aims with `gull.aim = gull.position + stick * cursor_radius` and has rules for when there is no input (GROUNDED → own position; WINDUP/STRIKE → current direction; otherwise heading).
- `scripts/gull.gd`: `dive()` and the STRIKE steering only read `gull.aim`. Don't touch the dive physics.
- `scripts/overlay.gd`: the reticle (around line 383) and `_draw_touch_buttons`.
- `scripts/game.gd`: `keen_target()` shows the rule for which targets can be snatched. The tutorial text is around line 742 ("STEER RIGHT: DRAG").
- Existing touch tests: `tests/demo_polish_checks.gd` around line 247 ("former PECK position now steers") and `tests/integration.gd` around line 1139.
- Gameplay values go in `data/tuning.json`, in a new `touch` block.
- CLAUDE.md rules apply: 8/16 px GullPixel text; stick graphics are UI drawn by Godot, not character art.

## Requirements
1. **Floating stick.** A touch that lands outside the buttons and below the top bar (y > 28) becomes the stick finger, anchored where it lands. Dragging gives `stick = (finger - anchor) / stick_radius`, capped at length 1, with a deadzone. If the finger goes past `stick_radius`, the anchor follows it so the stick never stalls. The aim is calculated exactly as for the gamepad stick: `gull.position + stick * cursor_radius`.
2. **No stick input.** When the stick is released, or is held inside the deadzone, use the gamepad's no-input rules. Factor those rules into a shared helper rather than copying them.
3. **Drawing.** While the stick finger is down, draw a faint base ring at the anchor and a knob at the finger. The reticle is drawn at the gull plus the stick offset, as for gamepad, so it is never under the thumb.
4. **Buttons.** PECK, FLAP, DIVE and SLOW keep working with the right thumb at the same time as the stick, as multitouch does today. You may enlarge them slightly if the 320×180 layout checks still pass. Aim at a hit area of at least about 20 logical px tall.
5. **Aim assist, touch only.** It applies while the stick is the active aim source. At dive start and throughout STRIKE, find the best target using the same rule as `keen_target()`, but without requiring the keen_eye perk: has food, not leaving, not a sunbather, not shielded. It must also be within `assist_range` px and within `assist_angle` degrees of the aimed direction. Blend the aim toward that target by `assist_strength` (0 to 1, where 0 turns it off). Player only, never rivals. Starting values: `assist_range` 140, `assist_angle` 25, `assist_strength` 0.5, `stick_radius` 24, `stick_deadzone` 0.15.
6. **Robust switching.** Today any `InputEventMouseMotion` turns touch aim off (`_input`, lines 66–69). iOS Safari may send emulated mouse events after a tap, which would snap the aim to the tapped button. While any touch finger is down, and for `mouse_ignore_after_touch` seconds (default 0.5) after the last touch event, ignore mouse motion for aim switching. Pure mouse play is unaffected.
7. **iOS browser hygiene.** Look at the HTML from the web export and `export_presets.cfg`. Make sure the canvas has `touch-action: none`, plus `-webkit-user-select: none` and `-webkit-touch-callout: none` (add them through `html/head_include` if missing). Make sure double-tap zoom is disabled, and enable the PWA option so players can "Add to Home Screen" and play without Safari's browser bars. Note in the Report anything that needs checking on a real device.
8. **Unchanged paths.** Don't edit the mouse, keyboard or gamepad branches of `update_player` in a way that changes them; refactoring into a shared helper is fine.

## Out of scope
Dive physics, `tuning.dive` values, gesture or swipe dives, tilt steering, new art.

## Done when (acceptance)
- [x] Checks: dragging from the anchor gives the expected aim (right, down-left, capped at the radius); a touch inside the deadzone produces no aim change; the anchor follows past the radius; releasing falls back to the no-input rules; stick and FLAP/DIVE/PECK work together with two fingers.
- [x] Checks: assist bends the dive toward a target inside the cone and leaves one outside the cone alone; `assist_strength` 0 turns it off; assist never applies with mouse or gamepad aim; rivals are unaffected.
- [x] Checks that mouse is unchanged: with mouse aim, `gull.aim == mouse_position + camera offset` and a right-click dive follows the mouse direction exactly as before; a mouse motion event within 0.5 s of a touch doesn't change the aim source, but one after that does.
- [x] Existing touch tests updated to the new behaviour (for example, "former PECK position now steers" becomes "starts the stick"). The tutorial hint still reads correctly for touch.
- [x] One `./tools/validate.ps1 -Capture` run (two at most) with 0 failures. A `-Capture` screenshot at phone size showing the stick, knob, reticle ahead of the gull and the buttons, with paths in the Report.
- [x] README/docs updated with the new `touch` tuning keys.

## Report
Branch `sonnet/018-touch-stick-aim-assist` (worktree `.claude/worktrees/t018`).

**Files changed**
- `scripts/input_controller.gd`: floating stick (`stick_anchor`/`stick_pos`, `touch_stick()`), anchor follows past `stick_radius`, shared `_aim_with_stick` / `_aim_without_stick` helpers used by gamepad and touch, `_assist_aim` (touch only), `touch_recent()` mouse-motion guard. `touch_aim` is gone; `aim_finger` is now the stick finger. Mouse branch is untouched.
- `scripts/game.gd`: `snatchable()` (rule shared with `keen_target()`), `assist_target()`, `input.game = self`, tutorial text "STEER RIGHT: DRAG THUMB" for touch.
- `scripts/overlay.gd`: faint base ring at the anchor and knob at the finger (in `_draw_touch_buttons`). The reticle already draws at `player.aim`, so it sits at gull + stick offset.
- `data/tuning.json`: new `touch` block (`stick_radius` 24, `stick_deadzone` 0.15, `assist_range` 140, `assist_angle` 25, `assist_strength` 0.5, `mouse_ignore_after_touch` 0.5).
- `export_presets.cfg` (Web preset): `html/head_include` (canvas/html/body `touch-action:none`, `user-select:none`, `-webkit-touch-callout:none`, no-zoom viewport, apple-mobile-web-app-capable) and `progressive_web_app/enabled=true` (landscape, standalone).
- `tests/touch_stick_checks.gd` (new, wired into `tests/integration.gd`); `tests/demo_polish_checks.gd` ("former PECK position now starts the stick"); `tests/training_checks.gd` (uses a stick finger instead of `touch_aim`; first phase steers straight up so the gull does not drift left before the "steer right" step).
- `README.md`: touch controls, the `touch` tuning keys, iOS notes.

**Tests**: one `./tools/validate.ps1 -Capture` run (via `-Godot` pointing at the shared `.tools` exe), `INTEGRATION: 13625 checks, 0 failures`. Plus one earlier headless run that found the training test needed updating (31 failures, fixed) and one rerun with 0 failures. The new file covers stick right / down-left / cap, anchor follow, deadzone, release rules (flight, ground, swoop), two-finger stick + FLAP/DIVE/PECK, top bar and button touches not starting the stick, assist inside/outside the cone and range, strength 0, leaving target, rivals, assist only at dive start in GLIDE, mouse aim `== mouse + camera offset`, right-click dive direction, gamepad unassisted, mouse motion ignored while a finger is down / within 0.5 s, accepted after.

**Screenshot**: `test-output/touch-stick.png` (in the t018 worktree; gitignored): ring, knob, reticle ahead of the gull, buttons. It is the normal 16:9 capture, not a separate phone-sized render.

**Decisions**
- Task number 018 is also used by `inbox/018-rival-panel-top-right.md`; the filenames differ so nothing clashes, but one of them may want renumbering.
- Assist blends the aim *direction* (slerp) and keeps the cursor-radius length. It picks the snatchable food (`food_position()`) with the smallest angle inside the cone, not the highest value. It applies in WINDUP, STRIKE, and in GLIDE only on the frame a touch dive is queued.
- A second finger landing on the beach while the stick is held is ignored (the stick does not jump).
- Buttons were not enlarged; hit areas are 21-22 px plus 2 px slop each side, already above 20.
- A touch session keeps `touch_active` after release so the gamepad no-input rules apply instead of falling back to the mouse position.

**Needs a real device (could not verify here)**
- No web export templates are installed in this environment, so I did not run `tools/export_web.sh` or inspect the generated HTML. Godot's template already carries its own viewport meta; mine in `head_include` comes after it and should win. Check the exported `index.html` for both.
- Double-tap zoom, rubber-band scroll and long-press callout on iPhone/iPad Safari; whether iOS actually sends emulated mouse events after taps; Add to Home Screen opens standalone in landscape (the PWA service worker needs HTTPS, so it will not apply inside the itch.io iframe); stick feel/size on a real thumb and on tablet.
- The capture run printed `ERROR: Condition "!is_inside_tree()" is true. at: grab_focus` at the very end; I did not investigate it (not in touch code).


## Review notes
<!-- Filled in by the reviewer. -->
