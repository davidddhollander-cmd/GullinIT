# 040 — Gang Call crowd panic (behaviour, existing poses)

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-27

## Goal
David's playtest of the herring Gang Call power: "it works well but the reaction from the characters needs to be tweaked." When Gang Call fires, everyone nearby looks up in surprise 0.5 s before the gang gulls dive. When the gulls hit, they all run away from the player in a panic and come back after 4 s.

## Context
- Gang Call lives in `scripts/brashness.gd` (`fire()`, `tick()`). Allies spawn offscreen and dive along curves; `ally.t` starts at `-stagger*i`. Tuning: herring `power` in `data/species.json`, `brash` in `data/tuning.json`.
- Beachgoers: `scripts/target.gd` (`knock_food`, `recover`, `leaving`, `update_art_pose`), `scripts/adult_reaction.gd` (theft `surprise`/`chase`/swat modes), `scripts/beach_routine.gd`, `scripts/bench_visit.gd` (`interrupt`), stall queues in `scripts/food_stall.gd` / `scripts/stall_service.gd`.
- Each character family has its own pose script: `BeachgoerArt` (kiosk_customer, dog_owner), `ShopperArt`, `MumArt` (picnic_family), `PierDinerArt`, `LifeguardArt`, the sunbather and old-man art, and `ToddlerArt`.
- Existing poses to use until task 041's art lands: `surprise` (kiosk_customer, pier diners), `alert` (most others), `run` (shoppers, sunbather, lifeguard, pier diners), `cry_run` (toddler). The parent/mum have no run, so use `chase` or a faster `walk`.

## Requirements
1. **Warning beat:** when Gang Call fires, every beachgoer within `panic_radius` of the player (default 170 px, about one screen) enters a `look_up` state for `look_up_time` (0.5 s). The allies' first dive starts only after that, so add a `lead_time` before ally 0's `t` reaches 0 (the stagger stays as it is).
2. **Panic:** when the first ally reaches its food (the existing `knocked` moment), everyone still in `look_up` switches to `panic`: they run directly away from the player at run speed for `panic_time` (4 s). After that they walk back toward their pre-panic x and resume their normal routine (patrol, queue, bench, eating).
3. **Panic overrides other behaviour:** no theft chase, no swat, no warning windup during `look_up`/`panic`. Bench visits and stall queues are interrupted cleanly, using the existing interrupt paths. Food they still hold stays in hand and stays snatchable. That free-grab window is intended.
4. **Who is included:**
   - Exclude stall vendors (inside stalls) and the seafood vendor.
   - Sleeping sunbathers wake up and panic.
   - The toddler uses `cry`, then `cry_run`.
   - Pier diners stay on the pier: clamp their run to the pier span.
   - Keep everyone inside the world bounds and in their own lane/depth. No lane switching while panicking.
5. **Poses:** add `look_up` and `panic_run` pose requests in each family's art script. Each request falls back to an existing animation when the sheet doesn't have that name yet: `look_up` → `surprise` → `alert`, and `panic_run` → `run` → `chase` → `walk` (sped up). This way task 041's sheets get picked up automatically when they land, with no code change.
6. Put the tunables in a `panic` block in `data/tuning.json`: `panic_radius`, `look_up_time`, `lead_time`, `panic_time`, `panic_speed_mult`.

## Out of scope
- New art (task 041). The other gull species' powers. Brashness fill rates.

## Done when (acceptance)
- [ ] Firing Gang Call: nearby characters hold a look-up/surprise pose for about 0.5 s, then the gulls dive
- [ ] On the first hit, they run away from the player, then return after 4 s and resume their routine
- [ ] No swats or chases happen while panicking; vendors are unaffected; pier diners stay on the pier
- [ ] Tests: look_up starts on fire and precedes the dive; panic direction is away from the player; the return happens after `panic_time`; the fallback pose resolves on a sheet without `look_up`
- [ ] `./tools/validate.ps1`: 0 new failures (known: the pier-diner fish check in rendered mode, and the play copy's demo lock)

## Report

Branch `sonnet/040-gang-call-crowd-panic`, built in a worktree off `main` (19fd1b2) so the play copy was left alone.

**Files changed**
- `scripts/crowd_panic.gd` (new): `CrowdPanic` state machine per person (`NONE → LOOK_UP → PANIC → RETURN`), held as `BeachTarget.panic`. Static `warn / stampede / calm` for the crowd, `resolve / present` for poses.
- `scripts/brashness.gd`: `fire()` warns the crowd (player x ± `panic_radius`) and delays every ally by `lead_time`; the first `knocked` moment calls `stampede`; `clear()` calms a crowd whose gang never struck.
- `scripts/target.gd`: `panic` member; `panic.tick` runs ahead of the bench/service/reaction code; toddler and sunbather pose hooks in `update_art_pose`.
- `scripts/{beachgoer,shopper,lifeguard,mum,pier_diner}_art.gd`: one `CrowdPanic.present` line each, then the family's own `align_food`.
- `scripts/stall_service.gd`: new `abort(person)` (wraps the existing `_finish(stand,false)` path).
- `scripts/spawner.gd`: panicking people keep their current lane offset (no lane switching).
- `data/tuning.json`: `panic` block.
- `tests/integration.gd`: `crowd_panic_checks()`.

**Tests:** headless `tests/integration.tscn`: 14213 checks, 0 failures (baseline on main 14170 checks, 0 failures, so +43). The two console messages (`!is_inside_tree()` and the `off_lead_dog` script error in `level5_checks`) are identical on unmodified main. Rendered `-Capture` mode not run.

**Decisions**
- Tunables: `panic_radius` 170, `look_up_time` 0.5, `lead_time` 0.5, `panic_time` 4.0, `panic_speed_mult` 4.0 (a multiple of the person's walk speed, 36 px/s, so about 144 px of running). I added one extra, `return_speed_mult` 2.5 (22.5 px/s), so the walk back takes about 6 s rather than 16 s at plain walk speed. Change it if "come back after 4 s" should mean a faster return.
- `look_up_time` is the minimum hold. Everyone stays in `look_up` until the first gull hit (1.2 s after firing with the herring numbers), and the stampede is held back if the hit ever comes sooner than `look_up_time`.
- Panic direction is fixed at the first hit (away from the player's x then) and does not flip if the player flies past.
- Pose chains: `look_up → surprise → alert`; `panic_run → run → chase → walk` (walk plays at 3x). Sheets with drawn `_left` clips (mum, sunbather, old man) use them instead of flipping. Toddler: `look_up → cry`, `panic_run → cry_run`. Task 041's sheets are picked up automatically.
- Panic start clears the chase, swat, warning, shield and bite state. Food in hand is untouched and stays snatchable.
- Seated shoppers stand up via `bench_visit.interrupt`, and panic starts when they are on their feet. A shopper or family mid-order has the order cancelled by `StallService.abort`; any food already placed on the counter is withdrawn (same as the existing interrupt), and the shopper re-queues after the panic.
- Bounds: everyone 20..width-20; pier diners from `pier_start`; sunbathers within the beach range. A person blocked by a bound keeps the run animation against it.
- A theft during the walk back hands control to the normal reaction.
- Stall vendors and the seafood vendor are not `BeachTarget`s in `spawner.targets`, so they are unaffected by construction. Leaving and loose (stall portion) targets are skipped.

**Not done:** no rendered capture or in-game eyeball pass; the new art (task 041) is out of scope. The mum's family trip and the toddler's parent-follow simply pause during panic and carry on afterwards.

## Review notes
