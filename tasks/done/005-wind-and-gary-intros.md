# 005 — L2 wind intro and L3 Gary intro twists

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 003
Created: 2026-10-22

## Goal
Family Picnic introduces wind with flags and a one-time upwind tip; Boardwalk Bustle introduces Gary with a taunt and loose-food-only stealing.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 4**. Its Files, Interfaces, data values and test steps are the requirements for this task.
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`
- AGENTS.md: no code-drawn character bodies/faces/limbs; GullPixel 8/16 px only; tuning in `data/`.

## Requirements
1. Do everything in the plan section named above, in its step order (tests first for code tasks).
2. Record any value or choice the plan left open in the Report.

## Out of scope
- Other plan tasks and later phases (levels 4+, shop, diving).

## Done when (acceptance)
- [ ] Every step of the plan section is checked off
- [ ] `./tools/validate.ps1` passes with no new failures (report check count)

## Report

Branch `sonnet/005-wind-and-gary-intros` (review round 2 applied).

Files changed: `data/levels/level_02.json`, `level_03.json` (twists, Gary `loose_only`), `data/tuning.json` (`wind_flag`, `juice.taunt_time/taunt_delay/tip_time`), `scripts/beach.gd` (wind flags reuse `_draw_flagpole`), `scripts/game.gd` (twist helper, tip, delayed taunt, loose-target sync), new `scripts/loose_food.gd`, `scripts/rival_gull.gd`, `scripts/gull.gd`, `scripts/collisions.gd`, `scripts/target.gd` (`is_loose()`), `scripts/effects.gd` (message life and rise speed), `scripts/autoload/game_state.gd` (`options.tips`), tests `quest_checks.gd`, `rival_ai_checks.gd`, `integration.gd`.

Tests: `INTEGRATION: 16088 checks, 1 failures` (only the known level 6 theft-scene check), headless and capture runs.

Round 2 changes:
- Gary plays: `LooseFood` (a `BeachTarget` stand-in per claimable `stash_raids` item: dropped, knocked, ground, bin food; never garbage, respects the pickup delay) is offered only to loose-only pilots and loose-only beak sweeps. Claims use the normal claims path; `take()` removes the item (or runs the owner's `claim_dropped`) and emits `snatched`, so `carried_food_id`, `took_food`, `_mugging` and `mugged_from` work. Level 3 sim (food scattered every 4 s): 14 dives, 3 steals, score 135; the original minimums are restored. Levels 4-6 counts unchanged. New checks: loose-only rivals never target held food, and the player mugging a Gary who claimed sand food completes `l3_mug_gary`.
- Upwind tip: fixed band at screen y 84, no rise; check that it is on screen and clear of the top bar, goal box and hint.
- Gary taunt: waits 1.5 s after release and until the score banner and floating score text are gone; drawn 22 px below Gary, clamped on screen. Checks: not shown while the banner is up, covers neither Gary nor his tag.

Screenshots (`test-output/`): `level2-upwind-tip.png`, `level3-gary-taunt.png`, `level2-wind-flags-left.png`, `level2-wind-flags-right.png`. No dedicated capture of Gary diving on loose food (covered by the sim checks).

## Review notes
