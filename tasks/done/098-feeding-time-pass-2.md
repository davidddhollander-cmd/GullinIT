# 098 — Feeding Time pass 2: boardwalk, two flocks, bumps

Status: done
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
**Branch** `sonnet/098-feeding-time-pass-2`. **Tests:** headless `tests/integration.tscn`: 18613 checks, 0 failures (baseline 18574). One `SCRIPT ERROR` at `integration.gd:2488` (`food_checks`, level 1 `scraps.crumbs[2]`) appears in the log; unrelated to level 4 and not counted as a failure.

**Files:** `data/levels/level_04.json`, `scripts/feeding_time.gd`, `scripts/pigeon.gd`, `scripts/shakedown.gd` (2 lines in `_scare`), `tests/feeding_checks.gd`.

**Tuning:** world width 1100, `promenade_start` 260, `pier_start` 1100 (boardwalk to the end); zones BEACH 0-260 / CRUMB ROW 260-800 / KIOSK 800-1100. `flocks` 4 at x 380 + 4 at x 720, `min_gap` 9, `wander` 50, lady patrol [300, 800] starting at 450. `seed_crumbs` 14 (340-412 and 690-762), `crumb_cap` 30. `pecks` 3, `peck_time` 0.3, `peck_gap` 0.2. `bump_stun` 1.5, `bump_knock` 5, `pigeon_stun` 0.35, `pigeon_force` 0.3.

**Decisions:**
- New `BeachPigeon.State.STUNNED` (kept the enum style); `grounded()` excludes it so a stunned pigeon can't be re-hit and isn't scattered by neighbours' bumps. Shakedown's repeating pulse scares it once it recovers.
- `BeachFeeding.free_spot()` picks a wander/landing x near the pigeon's own home with the min gap (best of 8 tries); `spots()` on the pigeon exposes position/dest/landing x for that.
- Bump-back uses `gull.swatted(pigeon_stun, pigeon.position, pigeon_force)`, so the species `stun` multiplier applies (black-back 0.245 s, herring 0.35, kittiwake 0.40). No extra carry-drop logic.
- Shakedown scare radius = `CrowdPanic.settings().panic_radius` (170), the same as dogs/teens, via `BeachFeeding.scare_pigeons()` called from `_scare()` (null-safe on other levels).
- Peck sprite is one frame, so a peck = head down (`peck_time`), head up (`peck_gap`, idle frame), repeated; the crumb is removed only after the last peck, and a gull pickup mid-peck stops the pigeon.
- Props re-placed to keep the bench-has-bin and wheelie-near-shed rules; prop-overlap test passes.
- Test helper `_park_pigeons` now also moves `home` so parked pigeons stay away.


## Review notes
<!-- Filled in by the reviewer. -->
