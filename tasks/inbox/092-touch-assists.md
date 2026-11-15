# 092 — Touch: one ASSIST setting and assist analytics

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-10 (renumbered from 079-081 on 2026-11-15)

> Written against main on 10 Nov. Main has moved since (practice rework, demo lock at level 3, task 087 mouse role, kittiwake Lightning Strike); re-check line numbers and current code before editing. 15 Nov playtest reviews back these tasks: dive timing and miss feedback, level 2 overload, mobile timing.

## Goal
Touch players crash far less. Real data (26 Oct to 10 Nov): dives crash 30% of the time on touch (41 of 135) vs 6% on keyboard and mouse (32 of 511); about a third of sessions are touch and players see phone as the main platform. Give touch players one clear ASSIST setting, on by default for touch, that bundles auto-peck and aim assist, and send enough analytics to tell whether it works. Crash forgiveness is left to the 8 Nov changes (below) for now.

## What is already on main (do not redo)
- Task 062 (merged 7 Nov): `GameState.control_mode()` defaults to `"casual"` (auto-peck) on touch; right-thumb dive stick; aim assist on the dive stick (`touch.assist_strength` 0.5) and approach assist (`touch.approach_assist_strength` 0.25), touch only.
- 7 Nov: DIVE STEER slider in options, `touch.dive_steer_default` 0.55 (`GameState.dive_steer()`, applied as `gull.dive_turn_scale` in `input_controller.gd:162` on touch only).
- 8 Nov: `dive.pull_up_turn_boost` 1.5 and `score.crash_keep` 0.75. David decided these should be enough crash help for now; no crash save in this task.
- **Live build:** the live itch upload (html id 20354008, first seen 7 Nov 22:02 UTC, still served 10 Nov) is the 7 Nov build. The 8 Nov zip (`build/GullinIt-web-demo-2026-11-08.zip`) contains both 8 Nov changes but was never uploaded, so the 30% baseline is without the pull-up boost and crash cost change.

## Context
- Auto-peck is the control mode `"casual"` (`gull.gd:426` `auto_peck()`), shown on the gull-picker slider as "CASUAL: AUTO PECK IN DIVES" (`menus.gd` `_control_mode_slider`, `CONTROL_MODE_TEXT`). Practice mode is a different thing (`main.casual`, the "CASUAL / PRACTICE" button), which is why players read auto-peck as "only in Casual/Practice". Trainer copy also says "Casual mode does the pecking" (`trainer.json` `training.lessons[4].how.casual`, owned by task 090).
- Touch pull-up: `input_controller.gd:175` `gull.climb = ... or touch_climb` (FLY stick up). While the right dive stick is held the left stick is ignored for aim; confirm `touch_climb` still works then, since the crash prompt says "Push FLY up!".
- Options screen: `menus.gd` ~465-485 (DIVE STEER slider, SHAKE/TOUCH/STATS toggles). Options are saved in `GameState.options`.
- Analytics: `game.gd` `track()` sets `input` (touch/gamepad/keyboard_mouse); `_run_stats()` feeds `level_end`; `mode` is practice/arcade/training only, so `level_end` does not say whether auto-peck or assists were on.

## Requirements
1. **One ASSIST option.** Add `options.assist` (bool) with `GameState.assist()`: default on when touch (same test as `control_mode()`), off otherwise; an explicit choice wins. Show it as an "ASSIST: ON/OFF" toggle in the options screen next to DIVE STEER. When on it gives:
   - auto-peck in dives (the effective control mode is `"casual"` while ASSIST is on, unless the player picked `"realistic"`; keep one code path through `control_mode()` / `auto_peck()`),
   - the existing touch aim and approach assist (today always on for touch; gate them on `assist()` so a touch player can turn them off).
   Keyboard, mouse and pad players can switch it on too; then the aim assist uses the same `_assist_aim` path with their aim. If that path is touch-specific in a way that makes this more than a few lines, keep aim assist touch-only and say so.
2. **Rename the slider label** so auto-peck no longer reads as Practice: show the third control mode as "EASY: AUTO PECK IN DIVES" (display text only; keep the saved id `"casual"` so saves still work). If the slider would contradict ASSIST, make the slider show the effective mode.
3. **Analytics.** Add `control_mode`, `assist` (bool) and `dive_steer` to the `level_start` and `level_end` properties (one place, e.g. `_run_stats()` plus the `level_start` call). No new events.
4. Keep `touch.dive_steer_default` at 0.55; record any reason to change it.

## Out of scope
- Crash save or any change to `dive.crash_vertical_speed`, crash cost or pull-up boost (David's call: the 8 Nov changes come first).
- The training copy and the approach-angle cue (task 090 owns `trainer.json` lesson text and the overlay dive line).
- New touch layout or buttons (task 062 is done), portrait layout, new art.

## Done when (acceptance)
- [ ] Fresh save on touch: `assist()` true, auto-peck on, aim assist on. Fresh desktop save: `assist()` false and behaviour unchanged. Toggling ASSIST in options changes both and persists.
- [ ] The gull-picker slider reads "EASY: AUTO PECK IN DIVES" for the third stop; old saves with `"casual"` still load.
- [ ] `touch_climb` pulls up while the dive stick is held (check added).
- [ ] `level_start` and `level_end` carry `control_mode`, `assist`, `dive_steer`.
- [ ] Checks in `tests/control_mode_checks.gd` (or a new `assist_checks.gd`) wired into `tests/integration.gd`, covering the bullets above.
- [ ] Headless `tests/integration.tscn` passes with no new failures (report check counts before and after).
- [ ] README updated for `options.assist`.
- [ ] **Analytics (after the next itch upload, not blocking merge):** compare the touch crash rate per dive (sum of `level_end.crashes` / sum of `level_end.dives` where `input` = touch) against the 30% baseline (41 of 135); target 15% or less over the next ~100 touch dives, split by `assist`.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
