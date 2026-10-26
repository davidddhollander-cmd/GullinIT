# 037 — Slower old man and old lady

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-26

## Goal
Playnotes 25 Oct: "Old man too fast, reaction times slower. Same for old lady in dress." Make these two elderly characters walk and react slower. All other characters stay as they are for now.

## Context
- `scripts/adult_reaction.gd` (`THEFT_SURPRISE_TIME`, `FAILED_CHASE_ANGER_TIME`, notice/chase timers), `scripts/target.gd`, `data/targets.json`, `data/levels/*.json`.
- CLAUDE.md: prefer data over code.

## Requirements
1. Old man and the old lady in the sundress (find their kinds/appearances in `data/targets.json` / `data/levels/*.json`): walk ~25% slower than other adults and react ~1.5x slower (notice/surprise delay and chase/swat start). Swat range unchanged.
2. Add these as per-target data (`speed_mult`, `reaction_mult`, default 1.0) so other characters can be tuned later without code changes.

## Out of scope
- Global reaction timings and every other character (unchanged), dog, rivals, vendors, lifeguard.

## Done when (acceptance)
- [x] Old man and sundress lady walk and react noticeably slower; other characters unchanged
- [x] Test asserts the multipliers are read (old man reaction delay > default, speed < default; a regular adult still uses 1.0)
- [x] `./tools/validate.ps1`: 0 failures

## Report
Files changed: data/targets.json (`kiosk_customer.appearance_mods`: old_man and shopper_sundress get speed_mult 0.75, reaction_mult 1.5; absent = 1.0), scripts/target.gd (reads mods; `speed_mult` = spawn value x mod, `reaction_delay` = spawn value x mod, new `chase_speed_mult`), scripts/adult_reaction.gd (chase pace 45 x chase_speed_mult), tests/slow_adult_checks.gd (new, wired in integration.gd), tests/integration.gd, tests/shopper_patrol_checks.gd, tests/bench_wander_checks.gd.
Tests: INTEGRATION: 13961 checks, 0 failures (headless; 7 of them new, in slow_adult_checks.gd). The only console ERROR (`!is_inside_tree` in pier_diner_art_checks) predates this task.
Decisions: mods are per appearance (kind is shared by all shoppers) so other characters tune via data. Reaction mult folds into existing `reaction_delay`, which scales warning (0.35 s) and swat start (0.4 s -> 0.6 s); swat range unchanged. Old man/sundress do not use the surprise pilot, so no surprise-time change was needed. Existing tests adjusted: adult-swat fixtures pin appearance to kiosk_customer (spawner picks looks round-robin), patrol-progress threshold scales with speed_mult, level 6 bench visit minimum is 1 (slow old man/sundress there).
Branch: sonnet/037-slower-reactions

## Review notes
