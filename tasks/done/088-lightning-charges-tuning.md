# 088 — Lightning Strike charges and tuning

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 086 (merged)
Created: 2026-11-14

## Goal
Playtest verdict on 086: it's fun but overpowered. Each full brash bar becomes one **charge** worth 2 Lightning marks. You can bank 2 charges, which gives 4 marks. Firing spends every banked charge. A full bar used to buy 3 steals and now buys 2, and the only way to reach the 4-steal strike is to skip firing for a whole extra bar. On top of that, the tuning gets tighter.

## Context
- `scripts/brashness.gd`:
  - `meter` is clamped to 0..1 in `add()`.
  - `is_full()` is `meter >= 1.0`.
  - `fire()` sets `meter = 0.0` and branches on `power.id`.
- `scripts/lightning_strike.gd` (BeachLightning) caps marks with `tuning.lightning_strike.max_marks`.
- `scripts/overlay.gd` `_draw_brash()` draws the top-bar meter and its label.
- `data/species.json` has the kittiwake `power` block. `data/tuning.json` has the `lightning_strike` block.

## Requirements
1. **Charges are data-driven.** Add an optional `"charges": 2` to the kittiwake's `power` block. Every other power defaults to 1 and must behave exactly as it does today (Gang Call, Shakedown).
2. **Meter.** `add()` clamps to `0..charges` instead of `0..1`. `is_full()` keeps meaning at least one charge (`meter >= 1.0`), so the ready label, the touch button and the "power ready" cue all still fire when the first charge lands. Play the ready cue again when the second charge fills.
3. **Firing.** `fire()` spends `floor(meter)` charges and keeps the fractional remainder, so progress toward the next charge isn't lost. Lightning gets `marks = charges_spent * marks_per_charge`. Replace `max_marks` in tuning with `marks_per_charge: 2`. Make the spent count available to BeachLightning, for example through a field set before `start`.
4. **HUD.** The bar shows progress toward the next charge (`fmod(meter, 1.0)`, full once all charges are banked). For each banked charge, add a small gold pip or a "x2" next to the label. Use the GullPixel font only (8 or 16 px) and keep it inside the existing top-bar layout. Nothing changes for one-charge powers.
5. **Tuning** in data only:
   - kittiwake `fill` snatch and handover: 1.4 → 1.0
   - `windup_time`: 2.5 → 1.5
   - `mark_angle`: 25 → 15
   - `mark_range`: 140 → 110
   - `land_invulnerable`: 0.5 → 0
6. Pause, level end and `clear()` still reset everything, including the meter, to 0.

## Done when
- The kittiwake can bank 2 charges. Firing on 1 charge allows 2 marks, and firing on 2 charges allows 4. A fractional remainder survives firing.
- Herring and great black-backed powers fill and fire exactly as before.
- The HUD shows next-charge progress and the banked-charge pips.
- Add tests to `tests/lightning_strike_checks.gd` for:
  - meter cap, mark count and remainder with 1 and 2 charges
  - a 1-charge power still clamps at 1
- The integration suite shows no new failures. Main currently has 12 failures from this machine's environment: flash, name field and PostHog.

## Report

Files: data/species.json, data/tuning.json, scripts/brashness.gd, scripts/lightning_strike.gd, scripts/overlay.gd, tests/lightning_strike_checks.gd.
Tests: headless integration run, 12 failures, all the known environmental ones (9 flash, dive release rings, name field HERRING, PostHog page_open). New charge checks pass.
Decisions: `max_charges()` on BeachBrash; `fire()` spends int(meter) and keeps the remainder, passing `lightning.charges_spent`; cancel refunds `meter += charges_spent`. HUD: bar shows fmod(meter,1) (full when all banked) plus one gold 4x3 pip per banked charge under the bar (no new text). Ready cue replays whenever the whole-charge count rises. Existing lightning tests adjusted for the new tuning (2 marks per charge, windup 0.525 game s, mark positions inside 110 range, no landing immunity).
Not done: none.
