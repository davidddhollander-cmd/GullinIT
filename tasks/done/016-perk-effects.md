# 016 — Perk effects in play (incl. Bullet time meter)

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
The equipped perk changes how the run plays. All values come from `data/perks.json`.

## Context
- Already on main: `data/perks.json`, `Config.perks`, `GameState.equipped_perk()` (returns "" or an owned perk id). Tests can set `GameState.wallet.owned` and `GameState.options.perk` directly.
- Gameplay code: `scripts/digestion.gd` (`can_collect` capacity 4 units), `scripts/gull.gd` (dive speed — species `dive` stat from task 014 is applied there; `stun()`), `scripts/game.gd` (`_snatched`, handover/COUNTER window via `target.last_theft_handover`, `_stunned`, `effects`, `overlay`), `scripts/stall_service.gd` / `target.gd` (handover window), `scripts/overlay.gd` (HUD), `scripts/input_controller.gd` + `project.godot` input map, touch buttons in overlay.
- A parallel task (015) builds the shop/equip UI in `menus.gd`/`main.gd`; don't touch those. Rivals are unaffected by perks.

## Requirements (perk → effect)
1. `bigger_stomach`: player stomach capacity `stomach` (6) units instead of 4.
2. `keen_eye`: a small gold marker (UI arrow, Godot-drawn) above the best snatch target on screen — the highest-value held food not currently shielded — and the stall handover/COUNTER window lasts `handover_window_mult` (1.5×) longer for the player.
3. `dive_speed`: player dive speed × `dive_mult` (1.15), stacking with the species `dive` stat.
4. `strong_skull`: the first `ignore_stuns` (1) stun/swat per run is ignored — no food drop, no point loss, message `"SKULL!"`. Crashes into the ground still count.
5. `bullet_time`: a HUD meter (small bar near the score) fills by `fill_per_clean_snatch` on each clean direct snatch (same "clean" rule as quests: direct, not scrap, not mugged). When full, a new input action `slowmo` (keyboard Shift, a gamepad shoulder button, and a touch button that appears only when the meter is full) slows the game to `time_scale` (0.5) for `duration` (2.5) real seconds, then empties the meter. Pausing during slow-mo must not leave the game slowed; leaving the level resets time scale to 1.
6. No perk equipped → game plays exactly as now.

## Done when (acceptance)
- [ ] One check per perk proving its effect, and one proving no perk = unchanged
- [ ] Bullet time: meter fills on clean snatches only, triggers only when full, restores time scale after the duration, after pause, and when leaving the level (checks)
- [ ] `slowmo` added to the input map with keyboard + gamepad bindings; touch button only shown when full (checks)
- [ ] HUD meter and Keen eye marker fit the 320x180 layout checks; `-Capture` screenshot of the meter (partly full) and the Keen eye marker, paths in the Report
- [ ] One `tools/validate.ps1 -Capture` run (two at most): **0 failures**

## Report
Files: scripts/digestion.gd (capacity), gull.gd (stun_shield, stun_ignored), game.gd (perk apply, keen_target, bullet time), stall_service.gd (handover_mult), input_controller.gd (slowmo action, touch button), overlay.gd (meter, keen arrow, SLOW touch button), tests/perk_checks.gd (new), tests/integration.gd (one wiring line).
Tests: `validate.ps1 -Capture` run once (first invocation aborted on an import hiccup, second clean): INTEGRATION: 14605 checks, 0 failures.
Screenshots (test-output/): perk-bullet-meter-partial.png, perk-bullet-meter-full.png, perk-bullet-touch-button.png, perk-keen-eye-marker.png.
Decisions:
- Keyboard binding is Q, not Shift: Shift is already DIVE. Gamepad is right shoulder; touch button sits above PECK and is only active/drawn while the meter is full.
- Meter fills in `_swallowed` (same clean rule as quests: not scrap, not mugged), not while slow-mo is running. Starting slow-mo, pausing, finishing, or leaving the level all reset time_scale to 1; pause/finish also empty the meter.
- Slow-mo timer uses the real clock (Time.get_ticks_msec) since Engine.time_scale scales delta.
- Keen eye window multiplier is on StallService, so it applies to any stall counter (rivals included); marker skips sunbathers, leaving and shielded targets.
- Strong skull blocks only gull.stun(); begin_tumble (ground crash, boss bump) is unaffected. Message "SKULL!".
Not done: no dedicated check of the stall COUNTER duration itself, only that handover_mult is 1.5.
Branch: sonnet/016-perk-effects

## Review notes
