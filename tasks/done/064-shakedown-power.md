# 064 — Great black-back power: Shakedown

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-08

## Goal
The great black-back gets its special. On a full brashness meter the player fires Shakedown: for about 8 s nothing can stop the gull, people flee as it moves, anyone it touches drops their food, and pecking at a stall makes food fly out while the vendor hides. This is a playtest build using existing effects only, so David can judge how it feels before any FX work.

## Context
- Design: `docs/SPECIAL_POWERS_BRIEF.md` (read the Shared rules and Shakedown sections). This task covers those only.
- `scripts/brashness.gd`: `fire()`, `tick()`, `add()`, `clear()` are written for Gang Call. `allies` is the only "power is active" state today. **`clear()` currently has no caller.**
- `data/species.json`: herring has a `power` block; great-black-backed has none. The species picker already shows `power.name`.
- `scripts/game.gd`: `start_slowmo()` is the Q/touch entry to `brash.fire()`; `_peck()` handles grounded pecks; `_stunned()` shows the ground-item format with a `snack` dictionary; `finish()` and `set_paused()` are the level-end and pause paths.
- `scripts/gull.gd`: `invulnerable` is already checked by `stun()`, rival muggings, boss bumps, dog, sweeper and watergun teen. It flickers the sprite each tick, and tumble recovery assigns it a short value.
- `scripts/crowd_panic.gd`: `warn()` then `stampede()`. Panic only starts from `LOOK_UP`, and `look_up` cancels stall orders.
- `scripts/target.gd`: `knock_food(gull, lift)`. `scripts/rival_gull.gd`: `mug()`.
- `scripts/stash_raids.gd`: `_peck_bin()` is the pattern for pecks that spill food.
- `scripts/food_stall.gd`: the vendor is a sprite inside the clipped `ServingWindow`; `COUNTER_REACH` is the shelf half-width. `scripts/stall_service.gd`: `requests`, `abort`, `request_shopper`, `request_family`.
- `scripts/overlay.gd` `_draw_brash()`: hard-coded "CALL!".
- AGENTS.md: no code-drawn characters. Moving the vendor sprite inside the existing mask is allowed. Stall service and its dive-snatch bonus window must be unchanged outside the power.
- Check the matching `godot-prompter:*` skill first (`ability-system`, `state-machine`).
- Line numbers are deliberately omitted because `main` is moving; find code by function name.

## Requirements
**Shared power plumbing (Lightning Strike will reuse this)**
1. Give the great-black-backed a `power` block in `data/species.json`: `id: "shakedown"`, `name: "SHAKEDOWN"`, `duration: 8.0`, `ready_label`, `sound`, and a `fill` map of meter multipliers. Start with `{"bump":1.5,"mug":1.5}`. Add `ready_label: "CALL!"` and `sound: "gang_call"` to herring so Gang Call is unchanged.
2. Meter fill goes through a small `earn(key)` on `BeachBrash` that applies `tuning.brash[key] * power.fill.get(key,1.0)`. Use it for snatch, handover, bump and mug. Stun loss stays on `add()`.
3. Add active-power state (`active_id`, `active_left`) to `BeachBrash`. `fire()` branches on `power.id`; the Gang Call crowd warning and allies move into the Gang Call branch. `add()` and `earn()` do nothing while a power is active. `fire()` returns false while the player is stunned, and the meter is kept.
4. `_draw_brash()` uses `ready_label`. While a power is active the meter shows the time left in gold.
5. `clear()` also ends the active power. Call it from `finish()` and any other path that ends a level. Pausing must freeze the power and leave it intact on resume.
6. Track a `power_fired` analytics event with the power id and level. Add a results-board line, `POWERS: n`, shown only when n > 0 and only if the board has room; report it if it doesn't fit.

**Shakedown**
7. Untouchable: while active, keep `player.invulnerable` at least `active_left` each tick. Add a flag on `BeachGull` that suppresses the flicker. `stun()` emits `stun_ignored` during the power without spending `stun_shield`. Make tumble recovery use `maxf` so it can't shorten the timer. Sand crashes still tumble the gull. On expiry, invulnerability is 0 and the sprite is opaque.
8. Rolling panic: on fire and every `panic_interval` (1.0 s) while active, call `warn` and `stampede` around the gull's position.
9. The shake: within `shake_radius` of the gull, humans lose food through `knock_food(player)`, and rivals with food lose it through `mug()`, which lands as a ground item the player or anyone else can collect. It works in flight and on foot.
10. Counter raid: while active, a grounded peck within `COUNTER_REACH` of a stall's centre, on sand or roof, takes priority over other peck targets. It uses the normal `peck_cooldown` and spits one food item in a bin-style arc, with the existing hit effects. Stop at `raid_cap` items per stall per power (6); pecks after that use `_peck_empty`. Foods come from a `raid_foods` tuning list with no large foods.
11. Vendor: on the first raid peck the stall's active request ends and its vendor moves down inside the mask, out of sight, over about 0.15 s. Until the power ends, `StallService` refuses new requests for that stall. Then the vendor comes back and service resumes normally.
12. Put tunables in a `shakedown` block in `data/tuning.json`: `panic_interval`, `shake_radius`, `raid_cap`, `raid_foods`, plus any others you add.

## Out of scope
- Any perk change. With Bullet Time equipped the power can't be fired; that is a known gap for the perk rethink, so don't work around it.
- New art, new pixelfx sheets, new sounds. Use existing effects and `gang_call`/`gull_call`.
- Lightning Strike, kittiwake data, screeching for other species, or a tutorial.

## Done when (acceptance)
- [ ] A black-back with a full meter fires Shakedown from Q and the touch button; the meter shows its ready label and time left.
- [ ] Herring Gang Call behaves as before, and existing Gang Call and screech lesson checks still pass.
- [ ] During the power stuns are blocked, Strong Skull's charge is unspent, there is no flicker, and a sand crash still tumbles without ending immunity early.
- [ ] People flee around the gull's current position throughout, not only where it fired.
- [ ] Touching a person or a food-carrying rival makes their food drop.
- [ ] Stall pecks spit food up to the cap; the vendor is hidden and no order can start; afterwards the vendor and normal service are back.
- [ ] Level end during the power and pause/resume leave no leftover state.
- [ ] Automated checks added in a new `tests/shakedown_checks.gd` and wired into `tests/integration.gd`, covering each item above.
- [ ] `./tools/validate.ps1` (or headless `tests/integration.tscn`) passes with no new failures.
- [ ] `docs/BRASHNESS_BACKLOG.md` notes Shakedown as built.

## Report
**Files changed:** `data/species.json` (black-back `shakedown` power; herring gets `ready_label`/`sound`), `data/tuning.json` (`shakedown` block), `scripts/shakedown.gd` (new, `BeachShakedown`), `scripts/brashness.gd` (`earn`, `active_id`/`active_left`, `powers_fired`, `fire()` branching, `end_power`, `clear()`), `scripts/gull.gd` (`steady_invulnerable`, `stun()` signal, `maxf` tumble recovery), `scripts/food_stall.gd` (vendor duck), `scripts/stall_service.gd` (`raid()`, refusal while ducked), `scripts/game.gd` (`earn` calls, raid peck priority, `clear()` in `finish()`, `power_fired` event, `result.powers`, stun toast), `scripts/overlay.gd` (ready label, gold time left), `scripts/result_board.gd` (POWERS row), `tests/shakedown_checks.gd` (new), `tests/integration.gd`, `docs/BRASHNESS_BACKLOG.md`, `docs/SPECIAL_POWERS_BRIEF.md`.

**Tests:** baseline 16720 checks, 2 failures (`nobody teleports across the beach while running off`, `data/demo.json enables the four-level demo`; both pre-existing). After: 16778 checks, 2 failures (the same two). 58 new checks in `tests/shakedown_checks.gd`.

**Decisions**
- Shakedown logic lives in its own `BeachShakedown` (RefCounted) held by `BeachBrash`; `fire()` branches on `power.id`.
- Black-back `ready_label` is "SHAKE!" and `sound` is `gang_call`. While active the meter bar drains in gold with the seconds left as text.
- The stun block during the power shows "NOPE!" instead of "SKULL!" (same `stun_ignored` signal).
- Shake contact is a 2D distance from the gull to a person's food (or a rival's body) within `shake_radius` (36 px), so it works in flight and on foot. Rival food drops reuse `_rival_drops_carry` (mug plus a ground item); this also stuns the rival briefly.
- Raid reach is horizontal only (beak x within `COUNTER_REACH` of the stall centre) while grounded, so sand and roof both count. Pecks inside reach during the cooldown are swallowed (no fallthrough to bins). Food items use source `raid` and are collected like normal food (full snack, not scrap).
- `clear()` in `finish()` also runs Gang Call cleanup (frees ally gulls, calms people still looking up), a small change at level end only.
- On natural expiry the vendor slides back up; on `clear()` it snaps up.
- Vendor ducks 64 px (sprite is 64 px tall, window 23 px); `duck_time` 0.15 s.
- Expiry zeroes `invulnerable` as specified, even if a pre-existing shorter immunity was running.

**Not done / known issues**
- POWERS row on the results board only fits when the board has two quests or fewer. Every real level from 2 up shows three (listed quests plus the random "EAT x" one), so in practice it rarely appears. Not forced in because it would overlap the TOTAL row. Needs a layout decision from David.
- Not visually playtested in game (headless tests only). The HUD draw was not rendered or captured.
- Bullet Time perk gap left as the spec says. The stale comment in `menus.gd` ("only herring has a power") was not touched.

**Branch:** `sonnet/064-shakedown-power`, last commit: see `git log -1`.

## Review notes
<!-- Filled in by the reviewer. -->
