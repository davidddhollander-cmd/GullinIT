# 099 — Feeding Time pass 3: pigeon tumble, pigeons bump back, brash, bin pecking (+ food_checks fix)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 098
Created: 2026-11-18

## Goal
Notes from David's playtest of level 4 "Feeding Time" after 098:
- A bumped pigeon should tumble away physically, like a bumped gull.
- Pigeons should actively bump the gull once it gets greedy.
- Bumping pigeons should fill the brash meter.
- Pigeons should peck bins too.

Also fix a long-standing script error in `food_checks`.

## Context
- Feeding code: `scripts/feeding_time.gd` (`BeachFeeding`), `scripts/pigeon.gd` (`BeachPigeon`, enum state machine), `scripts/crumb_lady.gd`, tuning in the `feeding` block of `data/levels/level_04.json`, tests in `tests/feeding_checks.gd`.
- Gull tumble physics: `scripts/gull.gd` (`tumble_*` vars, the gull-on-gull hit model near line 331, `tuning.tumble.*` in `data/tuning.json`). Copy the *feel* (launch arc, spin, bounce, recovery), not the whole gull code: a small self-contained tumble in pigeon.gd driven by data. Use the pigeon sheet's stunned crouch / wingbeat frames. Sprites only, no code-drawn birds. Rotating the sprite for spin is fine.
- Brash meter: `scripts/brashness.gd` `earn(key)`, keys in `data/tuning.json` `brash` (e.g. `bump` 0.34, `dog_bump` 0.6). See how `_dog_bumped` in `scripts/game.gd` calls `brash.earn("dog_bump")`.
- Bins: `game.stash_raids.bins` (`remaining`, `requires_top_landing` for wheelie bins). Rivals peck bins as a ground job in `scripts/rival_gull.gd` (~lines 466-560). Reuse the same bin-opening path a rival uses, so the bin spills or gives food exactly as it does for a rival.
- **food_checks error:** `SCRIPT ERROR: Out of bounds get index '2'` at `tests/integration.gd:2488` (`var chip = game.scraps.crumbs[2]` after `main.start_level(1)`). Level 1's `scrap_max_x` filter now leaves fewer than 3 crumbs. Fix the test so it finds a `single_chip` crumb robustly (or starts a level with no `scrap_max_x`). Keep what it checks, and make sure the rest of `food_checks` now runs and passes. Report how many extra checks now run.

## Requirements
1. **Fix food_checks** as above. No gameplay change.
2. **Pigeon tumble.** When the gull's dive bumps a pigeon, it launches away from the gull in an arc (speed and lift from data, scaled a little by gull speed), spins, bounces once on the sand, slides to a stop, then shows the stunned crouch for the rest of `bump_stun` and recovers. It can't be hit again or eat while tumbling or stunned. It stays within the world bounds. The neighbours still scatter as now.
3. **Pigeons bump back (aggro).** Count thrown crumbs the player eats. When the count reaches a threshold (data, random 2-3 each time), the pigeons get annoyed: up to N pigeons (data, e.g. 2) that are grounded and within notice range go AGGRO. Show a small "!" or angry shout via existing effects. An aggro pigeon takes off (wingbeat) and flies at the gull. On contact (simple distance/box check, data) it bumps the gull: `swatted(pigeon_stun, pigeon.position, pigeon_force)` (scaled by the species stun multiplier, so the black-back shrugs it off quickest) plus the existing hit effects. Then it flies back to its home and lands. If it misses or the gull escapes (time limit or distance, data), it gives up and goes home. The count resets after each aggro wave. Only one wave at a time. No aggro while the gull is stunned, and Shakedown cancels aggro (those pigeons scatter instead). Put this in its own state(s) in pigeon.gd, with the trigger and counting in feeding_time.gd.
4. **Brash from pigeon bumps.** The gull bumping a pigeon calls `brash.earn("pigeon_bump")`. Add `pigeon_bump` to `tuning.brash` (e.g. 0.25, a bit under a rival bump). Species `power.fill` scaling must apply as for other keys.
5. **Pigeons peck bins.** When there is no crumb to go for, an idle pigeon may (chance and range from data) walk to a nearby ground bin that still has `remaining` and peck it (same 3-peck rhythm). Wheelie bins that need a top landing are skipped. On the last peck it opens/spills the bin through the same path rivals use, so the gull can then race for the spilled food. At most one pigeon per bin. Pigeons don't eat the spilled food (only thrown crumbs), and they keep their flock home.

## Out of scope
- New art or audio, other levels, the crumb lady.

## Done when (acceptance)
- [ ] `food_checks` runs to the end with no SCRIPT ERROR.
- [ ] A bumped pigeon visibly arcs, spins, bounces and recovers, and can't be re-hit meanwhile.
- [ ] After the player eats 2-3 thrown crumbs, 1-2 nearby pigeons fly at the gull and bump it (short stun scaled by species), then go home. Missing gives up, the count resets, and Shakedown cancels.
- [ ] Bumping a pigeon raises the brash meter by `pigeon_bump`.
- [ ] Pigeons with no crumbs peck ground bins open, and the spill is available to the gull.
- [ ] `tests/feeding_checks.gd` extended for each point. Headless `tests/integration.tscn` passes with no failures and no SCRIPT ERROR lines.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
