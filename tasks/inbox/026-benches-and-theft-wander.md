# 026 — Benches get used; theft victims sulk and wander

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 24 Oct:
- "there's almost nobody going to sit down on the benches — either the mechanic doesn't work, or the characters are not getting there. Fix this. Each level starts with at least one bench occupied."
- "too many characters clustering together after a while … an idle or wander pattern for characters that have their food stolen, so they don't immediately go to the stands."

## Context
- Benches (Codex's bench snacks): `scripts/bench_visit.gd` (`eligible`, `consider` with a 30% roll and a 20–35 s cooldown, `registry.reserve(owner, routine.bounds)`), `scripts/bench_registry.gd`, `scripts/beach_routine.gd` (`purchased`, `_rest` call `consider`), `scripts/spawner.gd` (`bench_visit.enabled` only for `kiosk_customer` in level > 2, and only appearances with `seated_idle` art: `ShopperArt.supports_bench`). Tests: `tests/bench_snacks.gd`.
- Theft flow: `scripts/target.gd` `_finish_theft` (sets `respawn`, `recover`), then the `respawn` countdown sends shoppers/diners straight back to `_tick_shopping`. Reactions: `scripts/adult_reaction.gd`.
- Interview decision: after a theft → **sulk, then wander**: a few seconds of upset reaction, then a 10–20 s stroll away from the stall before going to buy again.
- Another agent works on lane offsets in `spawner.gd apply_spacing()` and depth (task 025), and another on level JSON (027). Keep your `spawner.gd` changes to setup/creation.

## Requirements
1. **Diagnose first:** run a 120 s sim of levels 3, 5 and 6 and record bench visits before your change (count, and why `consider` failed: roll, eligibility reason, no seat in bounds). Put the numbers in the Report.
2. Fix the cause(s) so benches are used regularly: target at least 2 visits per bench-level per 120 s sim. Likely levers: the roll chance, eligibility being too strict (alert/recover), and seats outside `routine.bounds`. Keep tuning in data (`data/tuning.json`).
3. **Start occupied:** in every level that has a bench and a bench-capable shopper, one shopper starts already seated with food (phase REST) on a bench.
4. **Sulk and wander:** after a theft, shoppers and pier diners play their existing upset reaction, then wander (use `BeachRoutine` walking away from the stall, 10–20 s, tunable) before shopping again. No new art.

## Out of scope
- Lane offsets and depth (025), level layouts and cast sizes (027), new art.

## Done when (acceptance)
- [ ] Report has before/after bench visit counts
- [ ] Checks: a level starts with one bench occupied; ≥ 2 bench visits in a 120 s level 6 sim; a theft victim doesn't reach a stall within 10 s of the theft and does shop again later
- [ ] Existing bench snack, stall service and pier diner meal checks pass
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures. Screenshot of an occupied bench at level start, path in the Report.

## Report

## Review notes
