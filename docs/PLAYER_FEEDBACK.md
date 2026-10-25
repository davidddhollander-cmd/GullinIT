# Player feedback dock

One entry per playtest report, newest first. Quotes are the player's words (lightly trimmed). "Suggestions" are proposals for Opus to turn into tasks in `tasks/inbox/`; nothing here is implemented yet.

Status key: `open` (not yet actioned), `tasked` (a task file exists), `fixed`.

---

## 2026-10-25 - Training Day replay, reached lesson 3 (keyboard + mouse)

**What worked**
- Landing on crumbs and grabbing the chip felt good.
- The `CRUMBS +5` popups are satisfying.

**Issues**

| # | Feedback | Status |
|---|----------|--------|
| F1 | Overshoots the snack on the dive; the gull carries a lot of speed. May be learning, but a little more slowdown on releasing flap would make lining up a dive fairer. | open |
| F2 | Lesson 3 showed `DIVE: B / TAP X` on keyboard and switched to `SHIFT / E` once the mouse moved. Keyboard-only players see controller prompts until they touch the mouse. | fixed (suggestion 1) |

**Unknown:** no clean snatch landed yet, so no verdict on whether stealing feels great. Worth asking for a follow-up report, and checking the `first_steal` seconds in analytics for the Training Day cohort.

### Findings from the code

**F2 root cause (a bug, not a taste issue).** `scripts/input_controller.gd` `update_player()` reads `Input.get_vector("aim_left","aim_right","aim_up","aim_down")` and sets `gamepad = true` whenever the result is over 0.15. Those actions are also bound to `A/D/W/S` and the arrow keys (line 33), so any WASD or arrow press counts as a "stick" and flips `gamepad` on. Only `InputEventMouseMotion` flips it back (line 66). `training_text()` in `scripts/game.gd:729` and the key hints in `scripts/overlay.gd:472` both read that flag, so keyboard steering produces controller prompts. A stray joypad event (connected pad, drift) causes the same thing.

**F1 root cause.** `flight.coast_drag` is 8 px/s² (`data/tuning.json`). Releasing flap starts a `coasting` decay of `coast_speed` (`scripts/gull.gd:336`), but at 8 px/s² a gull at the 140 px/s `max_speed` takes over 17 seconds to stop, so letting go barely slows it. The dive then starts at `max(dive.start_speed, current speed)` (`scripts/gull.gd:271`), so the horizontal speed carries straight into the dive.

### Suggestions

1. **Fix prompt device detection (F2), small and safe.**
   - In `update_player()`, test the joypad axes directly (`Input.get_joy_axis(device, JOY_AXIS_LEFT_X/Y)` above a deadzone) instead of the `aim_*` actions, so keyboard presses never set `gamepad`.
   - Set `gamepad = false` on `InputEventKey` and `InputEventMouseButton` in `_input()`, and `true` only on `InputEventJoypadButton` or joypad motion above the deadzone, so the last device used wins.
   - Add a regression check in `tests/`: after a simulated `A` key press `input.gamepad` is false, and after a `JOY_BUTTON_A` press it is true.
   - Optional polish: when prompts differ by device, have lesson 3 show only the active device's keys (it already does once the flag is correct).
2. **Tune the coast slowdown (F1), data-only first.**
   - Raise `flight.coast_drag` from 8 to somewhere in 25-40 and playtest; target is a gull that bleeds roughly half its speed in about a second after releasing flap.
   - If that hurts normal flight, keep the base drag and add a separate `dive_setup_drag` that applies only while flap is released and the aim is below the horizon, which is the "lining up a dive" case.
   - Do not touch `dive.start_speed`, `acceleration` or `max_speed`; the dive itself reads well, the carried-in speed is the problem.
3. **Make the overshoot readable.** A cheap aid for lesson 3 and early levels: show a faint aim line or target marker on the snack while a dive is possible, so the player can judge the intercept earlier. This needs a design decision, so treat it as optional after 1 and 2.
4. **Measure it.** Add an analytics event (or extend `level_end`) for dive outcomes: dive started, peck window reached, snatched, overshoot (passed the target's x without a peck). Then the "is this just learning?" question can be answered from data rather than anecdote.
5. **Follow up on the unknown.** Ask this player (itch.io comments are the feedback link in `data/demo.json`) whether stealing feels good once F1 is eased and they have landed a snatch.

**Done 2026-10-25:** suggestion 1 (the last device used now sets the prompts; WASD/arrows steer without switching to pad prompts; stick drift under 0.3 is ignored; checks in `tests/touch_stick_checks.gd`) and suggestion 4 (`level_end` now carries `dives`, `dive_pecks`, `dive_snatches` and `dive_overshoots`; an overshoot is a dive that ends past the snack nearest its dive line without a snatch; checks in `tests/analytics_checks.gd`). Suggestions 2, 3 and 5 are still open.

**Suggested task split (Opus to confirm):** one Sonnet task covering suggestions 1 and 2 (both small, both testable); suggestions 3 and 4 as separate later tasks.
