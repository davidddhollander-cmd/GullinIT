# 074 — Bumps use weight and impact speed

Status: done
Author: Claude
Assignee: Claude Haiku
Depends on: none
Created: 2026-11-09

## Goal
Gull-on-gull hits should depend on who hit whom and how fast. A black-back hitting a kittiwake at full dive sends it a long way; the same bump is smaller at low speed; and when the dive has completely slowed there is no bump at all.

## Today
`scripts/gull.gd` `begin_tumble()` always launches at `tumble.launch_speed`/`launch_up` times `knockback`, and `knockback` is set for the player only.

Gull-on-gull hit sites, all of them in scope:
- `game.gd` `_mugging()` calls `pilot.bump()` and `pilot.mug()` (`scripts/rival_gull.gd:397` and `:416`)
- `game.gd:387` fly-in bump of the player, and `game.gd:1171` a rival mugging the player
- `scripts/boss.gd` `_bump()`, used by `blocks_mug`, `shove`, and `shove_player`

Kicks, sweeps, water, dogs and sand crashes are not gull-on-gull and stay exactly as they are, `knockback` included.

## Model
1. Add `weight` to each species in `data/species.json`: herring 1.0, great black-back 1.6, kittiwake 0.7. Read it for players and rivals alike (`species_weight()` on `BeachGull`, default 1.0).
2. Add `BeachGull.impact_speed()`: `dive_speed` when in `STRIKE`, otherwise `velocity.length()`.
3. Add one shared calculation, tunables in a new `tumble.impact` block: `min_speed`, `full_speed`, `low_force` (0.35), `max_force` (2.5):
   - below `min_speed`: result is 0, meaning **no bump**
   - otherwise `force = lerp(low_force, 1.0, s) * attacker_weight / victim_weight`, where `s` is the speed's position from `min_speed` to `full_speed`, clamped to 0..1; `force` is capped at `max_force`
   - A herring at `full_speed` hitting a herring gives force 1.0, exactly today's launch.
   - Pick `min_speed` and `full_speed` from `data/tuning.json` flight and dive values so a gliding gull is normally above `min_speed`, a dive that has bled off nearly all its speed is below it, and `full_speed` is `dive.max_speed`. Record the values and why in the Report.
4. `stun()` and `begin_tumble()` take an optional `force` (default -1). When `force >= 0`, launch speed is multiplied by `force` instead of `knockback`, so toughness isn't counted twice. Default calls behave exactly as now. Stun duration is unchanged.

## Requirements
5. Every hit site above uses the model, with the real attacker gull.
6. Force 0 at a bump site: no stun, no score loss, no brash, no BONK, no effects, and it doesn't consume the hit. In `_mugging()` the player's dive carries on.
7. Force 0 at a mug site: the steal still happens (it's a theft, not a collision), but the victim does not tumble.
8. Pass `clampf(force/max_force, 0, 1)` as the `weight` of `effects.snatch_contact` at player bump sites, so bigger hits land harder on screen.

## Out of scope
Attacker recoil; hits with dogs, people or sweepers; rival AI changes; species card stats.

## Done when (acceptance)
- [x] Herring on herring at `full_speed` launches at today's values
- [x] Black-back on kittiwake at `full_speed` launches further than herring on herring, at most `max_force`; at half speed it is shorter; below `min_speed` nothing happens
- [x] A kittiwake hitting a black-back launches it less than the reverse
- [x] Each hit site in the list is covered by a check using the real attacker's speed and weight
- [x] Force 0 costs the victim nothing and gives no brash; a mug at force 0 still takes the food
- [x] A black-back's `knockback` still applies to kicks and sweeps, and doesn't also apply to gull hits
- [x] Checks added on simulated ticks; `./tools/validate.ps1` has no new failures

## Report

Branch: `haiku/074-bump-physics` (worktree `GullinIt-haiku-074`), code commit `2e6d00e`. Not pushed, not merged.

### Files changed
- `data/species.json`: `weight` on each species (herring 1.0, great-black-backed 1.6, kittiwake 0.7).
- `data/tuning.json`: `tumble.impact` = `min_speed` 25, `full_speed` 340, `low_force` 0.35, `max_force` 2.5.
- `scripts/gull.gd`: `species_weight()`, `impact_speed()`, static `bump_force(speed, attacker_w, victim_w)`, `bump_force_on(victim)`; `stun()` and `begin_tumble()` take `force` (default -1 keeps knockback).
- `scripts/rival_gull.gd`: `mug(attacker, force = -1)` skips the stun at force 0 but still steals; `bump(attacker, force = -1)` returns 0 before any state change at force 0.
- `scripts/game.gd`: fly-in (`_fly_in_step`), `_mugging` (bump and mug branches, snatch weight), `_rival_mugging` (rival mugs rival, rival mugs player).
- `scripts/boss.gd`: `_bump(gull, force, from, seconds)`; `blocks_mug`, `shove`, `shove_player` use the model.
- `tests/bump_physics_checks.gd` (new, plus `.uid`): 25 checks, registered in `tests/integration.gd` after the impact pass checks.

### Test results
`tools/validate.ps1`: INTEGRATION 16982 checks, 2 failures. Both are the known ones: "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo". No new failures.

### Hit-site audit
Grepped every `stun(` and `begin_tumble(` caller. The gull-on-gull sites are exactly the spec's list. Not gull-on-gull and left alone: `off_lead_dog.gd` (dog), `sweeper.gd` (broom), `target.gd` (toddler swat), `adult_reaction.gd` (person swatting a gull), `stash_raids.gd` (sunbather swat), `watergun_teen.gd` (teen water shot), `gull.gd:565` (self crash). The one call that passes a Vector2 attacker into `RivalPilot.mug` is the dog catch in `game.gd` `_rival_drops_carry`; it keeps the default force, so it is unchanged.

### min_speed and full_speed
- `full_speed` = 340 = `dive.max_speed`, as specified.
- `min_speed` = 25: between `dive.exit_speed` (20, the speed at which a dive pulls up) and `flight.ground_speed` (28). A dive that has bled off reaches exit speed and is below the threshold. Gliding gulls are well above it.
- The first pick was 40. That broke Gary's scripted fly-in: he is GROUNDED and walks in at 28 px/s at contact, so the bump was 0 and the "Gary's entry bumps the player" check failed. At 25 he still bumps, weakly (force about 0.36 for a herring).

### Decisions
- `blocks_mug` (Bev's guard) takes its force from the mugger's hit: `attacker.bump_force_on(victim)`. The mugger tumbles by that force. A frontal mug too slow to bump is not blocked and goes through.
- The "MOVE IT!" message in `shove` and `shove_player` is skipped when force is 0.
- Fly-in: a hit needs force > 0 and range. A zero-force pass keeps flying until the normal timeout.
- Requirement 8: the snatch weight is passed at the `_mugging` bump branch, the only bump site with `effects.snatch_contact`. The fly-in has no snatch call today; I did not add one.
- Force 0 at a rival-on-player mug skips only the player's stun. The snack is still taken and the "MUGGED BY" message still shows.

### Existing tests changed (no assertions weakened)
Each change sets a real dive speed on a gull that is in STRIKE, since a STRIKE at speed 0 now bumps nothing. Each is marked `task 074` in code.
1. `tests/boss_checks.gd` `_strike_at`: `dive_speed = dive.max_speed`.
2. `tests/boss_checks.gd` `_player_mug`: player `dive_speed = dive.max_speed`.
3. `tests/rival_ai_checks.gd`: chip (rival mugs rival) and gary (rival mugs player) `dive_speed = dive.max_speed`.
4. `tests/training_checks.gd`: player `dive_speed = dive.max_speed` before the dummy bump check.

### Not done
- No game-level check drives the fly-in directly with a new check. It is covered by the existing quest test "Gary's entry bumps the player", which now passes under the real walk-in speed.
- No recoil on the attacker, no change to rival AI or species card stats, as specified.

### Last commit
`2e6d00e` Task 074: gull-on-gull bumps use weight and impact speed
