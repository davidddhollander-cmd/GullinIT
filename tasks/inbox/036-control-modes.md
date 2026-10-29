# 036 — Control modes: Realistic / Normal / Casual

Status: inbox
Author: Claude
Assignee: Claude Sonnet (game code)
Depends on: none
Created: 2026-10-29

## Goal
The player picks one of three control modes on the gull picker with a 3-step slider. **Realistic** makes every wingbeat a separate tap. **Normal** is today's controls. **Casual** is Normal plus automatic pecking in dives. Players can then choose how hard the flying and snatching should be.

## Context
- Flight and wingbeats: `scripts/gull.gd`, mainly `tick()` in the GLIDE/GROUNDED branch (~line 340) and `wingbeat()` (~line 604). Holding flap now repeats a stroke every `flight.stroke_interval` (0.3 s).
- Input: `scripts/input_controller.gd` `update_player()` sets `gull.climb = Input.is_action_pressed("climb") or touch_climb`. Flap is mouse left, Space, pad A, or the touch FLAP button.
- Dive peck: `gull.gd` `attempt_peck()`/`consume_peck()`, `peck_time`, `peck_sweep_active` (set in `tick`), `scripts/collisions.gd` `resolve()` (hits only count while `peck_sweep_active`; a near miss knocks food when `peck_time` runs out), `scripts/game.gd` `_peck()`.
- Peck HUD: `scripts/overlay.gd` ~396-399 (peck bar) and ~498 ("PECK ACTIVE" / "PECK SPENT" hint).
- Gull picker: `scripts/menus.gd` `gull_picker()`. Choice is saved like `GameState.options.gull`, via `chosen_gull()` and `save_progress()` (`scripts/autoload/game_state.gd`, `scripts/main.gd` ~66).
- Tuning lives in `data/tuning.json`.
- **Name clash:** `casual` already means the PRACTICE game mode (`game.casual`, `main.casual`, `level_select(casual)`). Do not reuse that flag. Call the new setting `control_mode`, with values `"realistic" | "normal" | "casual"`.
- Rival gulls (`scripts/rival_gull.gd`) share `BeachGull`. The mode applies **only to the player gull**. Rivals must behave exactly as they do now.
- UI text uses the GullPixel font at 8 or 16 px only.
- The main working tree has another agent's uncommitted work in `game.gd`, `gull.gd` and `tests/integration.gd` (a herring screech). Work on your own branch from `main` HEAD and keep your edits small, so the merge stays easy.

## Requirements
1. **Setting.** Add `GameState.control_mode() -> String`, defaulting to `"normal"`, stored in `options.control_mode` and saved with `save_progress()`. Invalid saved values fall back to `"normal"`. The game applies it to the player gull when a level starts. Training uses the chosen mode too.
2. **Picker slider.** Add an `HSlider` (min 0, max 2, step 1, ticks shown) to the gull picker, labelled REALISTIC · NORMAL · CASUAL. Below or beside it, show a one-line 8 px description of the current mode, for example "TAP TO FLAP EVERY WINGBEAT", "HOLD TO FLAP", "AUTO PECK IN DIVES". It must fit the 320×180 canvas without squashing the gull cards. Keyboard and gamepad focus can reach it (left and right change it), and so can mouse and touch. A change saves at once. Name the node `ControlModeSlider`.
3. **Realistic flapping.**
   - Holding flap gives no repeated wingbeats. Each new press (mouse, key, pad or touch FLAP finger-down) gives exactly one stroke, with the same lift shape as a stroke today (`stroke_lift` over `stroke_duration`, wind `flap_scale` included).
   - Taps closer together than `control_modes.realistic_tap_interval` are ignored, so mashing is capped. A press must never be lost between frames, so latch it on the input event and consume it in `tick`. Do not rely on `is_action_just_pressed` alone across `_process`/`_physics_process`.
   - With no taps, the gull sinks under normal gravity and sink cap. Rapid tapping (about 4–6 taps a second) must gain height at a rate comparable to holding flap in Normal.
   - Everything else that reads `climb` keeps working through a tap: takeoff from the ground or a perch, pulling out of a dive, cancelling coasting and landing-aim descent. A tap also counts as "flap" for those, so it must not trigger a second stroke on the same tap.
   - The climb animation plays once per stroke. It must not flicker or loop while the button is held.
   - New tuning keys go in `data/tuning.json` → `"control_modes": {"realistic_tap_interval": 0.15}`. Add more keys only if needed, and document them in the report.
4. **Casual auto-peck.** In casual, the player never needs to press peck in a dive. Treat the whole STRIKE as an active peck window. Any food the beak sweep hits during the strike is taken, as a timed peck takes it now. A near miss only knocks food once the strike ends without a clean hit, so it doesn't fire on the first frame. Pressing peck mid-dive must be harmless. Ground pecks (crabs, stash raids) still need the peck button in every mode. Umbrella, shield and "pier food" protections still apply.
5. **HUD.** In casual, the dive peck bar and hint say "AUTO PECK" instead of the timing bar and "PECK SPENT - DIVE AGAIN". Realistic and Normal show what they show now.
6. **Normal is unchanged.** With `control_mode == "normal"`, the existing flight, dive and peck tests pass without edits.

## Out of scope
- Score, star or leaderboard changes per mode (open question for David: should Casual score less?).
- Rival AI, new art and sounds, and new touch buttons.
- Renaming the existing PRACTICE `casual` flag.

## Done when (acceptance)
- [ ] Gull picker shows the 3-step slider. Its value persists across restart (save, reload) and defaults to NORMAL.
- [ ] Realistic test: holding flap for 2 s from mid-air ends **lower** than the start (one stroke at most). 10 presses spaced over 2 s end **higher** than the start. 10 presses inside 0.1 s give one stroke only (tap interval).
- [ ] Realistic test: a single press while grounded takes off.
- [ ] Casual test: a dive whose beak sweep crosses food takes it with **no** `attempt_peck()` call. The same dive in Normal without a peck does not take it.
- [ ] Normal test: existing flight and peck checks are unchanged and green.
- [ ] Rival gulls are unaffected (one check, or a clear argument in the report).
- [ ] New checks live in a new `tests/control_mode_checks.gd` wired into `tests/integration.gd`. Keep that wiring to a minimal, separate hunk.
- [ ] `./tools/validate.ps1` (or headless `tests/integration.tscn`) passes with no new failures. Paste the check counts.
- [ ] README or docs mention the three modes and the new tuning key.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
