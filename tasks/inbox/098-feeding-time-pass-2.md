# 098 — Feeding Time pass 2: boardwalk, two flocks, bumps

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 097
Created: 2026-11-18

## Goal
David's playtest notes on level 4 "Feeding Time" (task 097): add more boardwalk and more crumbs on the ground from the start, and split the pigeons into two flocks. Pigeons eat more slowly, can be bumped and bump back, and react to the black-back special.

## Context
- Built in 097: `scripts/feeding_time.gd` (manager, `BeachFeeding`), `scripts/crumb_lady.gd`, `scripts/pigeon.gd` (`BeachPigeon`), thrown crumbs in `scripts/scraps.gd` (entries with `thrown: true`), tuning in the `feeding` block of `data/levels/level_04.json`, tests in `tests/feeding_checks.gd`.
- Gull stun: `BeachGull.swatted(duration, attacker, force)` in `scripts/gull.gd`. Each species has a `stun` multiplier in `data/species.json` (herring 1.0 / tough 3, great black-back 0.7 / tough 5, kittiwake 1.15 / tough 2). See how other stuns scale with it and reuse that.
- Black-back special = Shakedown, `scripts/shakedown.gd`. `_scare()` sends dogs and teens running and `come_home()` brings them back on every end path. `_knock_around()` handles the slam radius.
- Promenade/boardwalk comes from `world.promenade_start` / `pier_start` and the zones (see level 3 `data/levels/level_03.json`).
- All tuning in data. Sprites only, no code-drawn characters.

## Requirements
1. **More boardwalk.** Move `promenade_start` well forward (for example ~260, so most of the level is boardwalk). Lengthen the world a bit if that helps (e.g. ~1100). Re-place props and spawns so nothing overlaps (benches, lamps and bins on the boardwalk, like level 3) and update the zones. The lady and both flocks should mostly be on the boardwalk.
2. **Crumbs on the floor at the start.** Seed about 12-16 thrown-type crumbs (they never respawn, the same as her throws) spread around both flock areas when the level starts. Count and positions come from data, and they count toward the crumb cap. Raise the cap if needed so her throws still land.
3. **Two flocks.** Replace the single `flock` with a `flocks` list, each with a home x and a size (e.g. 4 + 4). Each flock idles and wanders around its own home, not the lady, and lands back at its home after a scatter. Both flocks go for crumbs within `notice`. Widen her patrol so she feeds both areas over time.
4. **Spacing.** Pigeons stay clustered but keep a minimum gap of ~9-10 px from each other (data) when idling, wandering and choosing landing spots. Two pigeons may never claim the same crumb (already true).
5. **Slower eating.** A pigeon needs 3 pecks to eat a crumb (data `pecks: 3`, plus per-peck time; the peck frame plays once per peck with a short head-up between). The crumb stays edible by the gull until the last peck. If the gull takes it, the pigeon stops.
6. **Bumps.** When the gull's dive/strike hits a pigeon, that pigeon is bumped and stays on the ground: knock it back a few px, show the stunned crouch frame for ~1.5 s (data), then it goes back to normal. The other grounded pigeons within the scatter radius fly away (current scatter/return behaviour). A bumped pigeon can't be hit again while stunned. Keep the "SHOO!" cue and quest event on the scatter.
7. **Bump back.** Each bump also gives the gull a small stun: base `pigeon_stun` (e.g. 0.35 s, data) x the species stun multiplier, via `swatted()` with a light force, so tougher gulls recover faster. Make sure it doesn't drop the gull's carried food unless other small stuns already do; follow the existing rule.
8. **Black-back special.** When Shakedown runs, every grounded pigeon within the shakedown scare/slam radius (use the same radius the dogs and teens use) flies away like a scatter and comes back after the normal return delay. Hook it in the same place dogs/teens are scared, through the manager (`game.feeding` may be null on other levels).

## Out of scope
- New art or sounds, other levels, the crumb lady's swat/throw behaviour (except her patrol range).

## Done when (acceptance)
- [ ] Most of level 4 is boardwalk, there are crumbs on the ground at the start, and props don't overlap (the existing prop-overlap test passes for level 4).
- [ ] Two separate flocks cluster at their own homes with the minimum gap.
- [ ] A pigeon takes 3 pecks to eat a crumb, and the gull can steal it mid-peck.
- [ ] A dive into a pigeon bumps it (crouch, stays) and scatters the others nearby. The gull gets a short stun scaled by species (black-back shortest, kittiwake longest).
- [ ] Shakedown scares nearby pigeons away, and they return.
- [ ] `tests/feeding_checks.gd` updated and extended for each point above. Headless `tests/integration.tscn` has no new failures.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
