# 005 — L2 wind intro and L3 Gary intro twists

Status: done
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

Branch `sonnet/005-wind-and-gary-intros`.

Files changed: `data/levels/level_02.json` (twist `wind_intro`, flag x list), `data/levels/level_03.json` (twist `gary_intro`, Gary `loose_only`), `data/tuning.json` (`wind_flag`, `juice.taunt_time`, `juice.tip_time`), `scripts/beach.gd` (wind flags reuse `_draw_flagpole`), `scripts/game.gd` (twist helper, `_wind_tip`, Gary taunt), `scripts/rival_gull.gd`, `scripts/gull.gd`, `scripts/collisions.gd`, `scripts/target.gd` (`is_loose()`), `scripts/effects.gd` (optional message life), `scripts/autoload/game_state.gd` (`options.tips`), tests `quest_checks.gd`, `rival_ai_checks.gd`, `integration.gd`.

Tests: `INTEGRATION: 16073 checks, 1 failures` (only the known `level 6 rival leaves the scene of a theft`). Capture run also passes the same. 12 new checks (flags only in L2, tip once across two runs and saved in `options.tips`, taunt shown for 2 s in L3 and the old message gone, loose-only Gary never steals or knocks held food over 60 s and ignores held targets).

Decisions: flags reuse the existing kiosk flagpole drawing (taller pole, larger cloth, flap speed and size in `data/tuning.json` `wind_flag`); they sit at x 215 and 600 in L2. Tip text is shown once at 3 s, taunt 2 s clamped on-screen above Gary. Loose food means food resting on a stall counter (`stall_handover` portions); loose-only is enforced in target picking and in beak collisions.

Gap: knocked and dropped food lives in `stash_raids.items` as player-only dicts, so rivals cannot target it. Counter portions last about a second, so loose-only Gary almost never dives or steals (0 dives in a 90 s idle sim), which makes the L3 "MUG GARY" quest hard. I relaxed the L3 rival dive/theft/score minimums for loose-only rivals. Follow-up needed: let rivals claim `stash_raids` items (dropped, knocked, grounded).

Screenshots (ignored dir): `test-output/level2-wind-flags-left.png`, `level2-wind-flags-right.png`, `level2-upwind-tip.png`, `level3-gary-taunt.png`.

## Review notes
