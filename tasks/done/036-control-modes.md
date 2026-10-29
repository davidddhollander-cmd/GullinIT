# 036 — Control modes: Realistic / Normal / Casual

Status: done
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
**Files:** `scripts/gull.gd`, `scripts/input_controller.gd`, `scripts/collisions.gd`, `scripts/menus.gd`, `scripts/overlay.gd`, `scripts/autoload/game_state.gd`, `scripts/game.gd` (1 line), `data/tuning.json`, `README.md`, `tests/integration.gd` (1 line), new `tests/control_mode_checks.gd`.

**Test run** (headless `tests/integration.tscn`): `INTEGRATION: 14693 checks, 0 failures`. The one `SCRIPT ERROR` (`off_lead_dog` in `tests/level5_checks.gd:16`) is outside this task; it is not from my changes. 31 of the checks are new, all in `control_mode_checks.gd`.

**Design**
- `GameState.control_mode()` / `set_control_mode()` (`options.control_mode`, invalid -> "normal"). `game.gd` sets `player.control_mode` at level start (training included, same code path). Rivals never get it set; `auto_peck()` and the realistic branch also test `not rival`.
- Realistic: `GullInput` latches a press in `_input` (`climb` action key/mouse/pad press, non-echo, plus touch FLAP finger-down) in `flap_tap`; `update_player` hands it to `gull.flap_tap_pending`. At the top of `tick`, the latch is consumed: if `tap_cooldown` (`control_modes.realistic_tap_interval`) is over, `climb` is true for that tick only, otherwise the press is dropped. Takeoff, pull-out, coast-cancel and landing-aim all read that one-tick `climb`. The tap resets `stroke_cooldown` to 0 so `wingbeat` fires; takeoff sets it back to `stroke_interval`, so a takeoff tap gives no second stroke (same as Normal).
- Animation: `flap_anim_left` (= `stroke_interval`) keeps the climb clip (and the carried-food "fly" clip) playing for one loop per tap; frame resets on each tap.
- Casual: `auto_peck()`, `peck_window_open()` (= `peck_time > 0` or casual and not yet `peck_used`). `tick` and `collisions.gd` use it instead of `peck_time > 0`; identical in Normal. `consume_peck()` marks `peck_used` in casual so a dive takes/knocks once. A near miss only knocks when the strike ends (state leaves STRIKE). `attempt_peck()` returns false in casual (harmless press, no "PECK!" popup/stat).
- HUD: casual strike shows "AUTO PECK" next to the beak (replaces the timing bar) and as the hint. Realistic ground hint says TAP instead of HOLD.
- Picker: `ControlModeSlider` (HSlider 0-2, step 1, ticks) sits in the header beside the title, with a description line "MODE: TEXT" (TAP EVERY WINGBEAT / HOLD TO FLAP / AUTO PECK IN DIVES). I could not put it below the cards: the GREAT BLACK-BACKED card needs the full height (the existing shop check "picker card content fits" failed by 6 px with a 17 px header block, and by far more with a separate row). The stock 16 px slider grabber also grew the header, so it gets a 5x7 gold knob override. REALISTIC / CASUAL end labels are not drawn (no room); the description names the current mode and the tooltip lists all three. Focus/left-right keys, mouse and touch work through the stock HSlider.
- New tuning key: `control_modes.realistic_tap_interval` = 0.15. No other keys.

**Balance note:** a tap gives the same 36 px/s lift as a Normal stroke, so tapping 5/s (180 px/s^2 average) out-climbs Normal's held flap (120 px/s^2). The test asserts at least 75% of Normal's gain. Raise the tap interval (or add a lift multiplier) if Realistic climbs too easily.

**Not done / notes:** touch flap in Realistic uses finger-down only. Rival isolation is argued by the code (`not rival` guards) and checked with a rival gull set to casual and realistic strings. No rendered screenshot was captured. Stray untracked `.uid` files from other tasks were left out of the commit.

**Branch:** `sonnet/036-control-modes`, last commit: see git log (filled in the final message).

## Review notes
<!-- Filled in by the reviewer. -->
