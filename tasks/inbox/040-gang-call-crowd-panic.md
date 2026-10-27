# 040 — Gang Call crowd panic (behaviour, existing poses)

Status: inbox
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

## Review notes
