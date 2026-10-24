# 018 — Touch floating stick and aim assist

Status: inbox
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
- [ ] Checks: dragging from the anchor gives the expected aim (right, down-left, capped at the radius); a touch inside the deadzone produces no aim change; the anchor follows past the radius; releasing falls back to the no-input rules; stick and FLAP/DIVE/PECK work together with two fingers.
- [ ] Checks: assist bends the dive toward a target inside the cone and leaves one outside the cone alone; `assist_strength` 0 turns it off; assist never applies with mouse or gamepad aim; rivals are unaffected.
- [ ] Checks that mouse is unchanged: with mouse aim, `gull.aim == mouse_position + camera offset` and a right-click dive follows the mouse direction exactly as before; a mouse motion event within 0.5 s of a touch doesn't change the aim source, but one after that does.
- [ ] Existing touch tests updated to the new behaviour (for example, "former PECK position now steers" becomes "starts the stick"). The tutorial hint still reads correctly for touch.
- [ ] One `./tools/validate.ps1 -Capture` run (two at most) with 0 failures. A `-Capture` screenshot at phone size showing the stick, knob, reticle ahead of the gull and the buttons, with paths in the Report.
- [ ] README/docs updated with the new `touch` tuning keys.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
