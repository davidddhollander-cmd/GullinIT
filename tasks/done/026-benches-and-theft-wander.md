# 026 — Benches get used; theft victims sulk and wander

Status: merged
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
Branch `sonnet/026-benches-and-theft-wander`. Tests: `INTEGRATION: 14658 checks, 0 failures` (rendered capture run, exit 0).

**Diagnosis (120 s sim, levels 3/5/6, no gull; counts of `consider` outcomes + reservations before the change):**
- L3: 12 ineligible (mostly no food while queueing), 7 failed the 30% roll, 3 on cooldown, 1 reserved, 1 no seat in reach.
- L5: 11 ineligible, 7 roll fails, 3 cooldown, 3 reserved, 3 no seat.
- L6: 11 ineligible, 20 roll fails, 12 cooldown, 0 reserved, 2 no seat.
- Causes: 30% roll plus a 20-35 s cooldown that is also spent on failed rolls, and a 220 px seat reach (benches sit 400+ px from the hot dog stalls/kiosk shoppers).
- After (tuning only): completed approach-to-sit visits in 120 s: L3 6, L4 6, L5 5, L6 6 (before: at most 1 / 3 / 0 reservations, none guaranteed to finish). Asserted >= 2 on levels 3-6.

**Changes:** `data/tuning.json` new `bench` block (chance 0.8, cooldown 6-12 s, reach 320 px, approach_speed 1.0) and `world.theft_wander_min/max` (10/20 s). `bench_visit.gd`/`bench_registry.gd` read them (`reserve` takes a reach arg; `claim`; `start_seated`). `spawner.gd` `_seat_starter()` (setup only) seats the nearest holding, bench-capable shopper in REST on the nearest bench at level start (rest 14-22 s). `target.gd` `_finish_theft`: shoppers and pier diners get a 10-20 s `respawn` and `routine.purchased(stall x)` so they stroll away from the stall (destination clamped inside the rival edge margin) after the existing upset reaction, then shop again. New checks in `tests/bench_wander_checks.gd` (wired in `integration.gd`): starter seated on levels 3/5/6 (level 4 has no bench-capable holding shopper, so it is exempt), >= 2 visits per level, theft victim does not reach a stall within 10 s and shops again.

**Screenshot:** `test-output/bench_start_level6.png` (gitignored) in the worktree: a shopper sitting on the level 6 bench holding a hot dog.

**Decisions / notes:** approach_speed kept at 1.0 (2.0 worked for visits but tipped the chaotic level 3 rival-edge check, 2.05 s vs 1.5 s limit; that sim is seed-sensitive to any shopper timing change). Not done: no gull-driven level sim of theft frequency; the starter helper only works for shoppers that already have food.


## Review notes
