# 070 — Shakedown playtest fixes and black-back dog bump

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 068
Created: 2026-11-09

## Goal
David played Shakedown. Fix what he found, and give the black-back an inherent ability to bump dogs.

## Findings (read from the code)
- **Panic only at the start.** `CrowdPanic.look_up()` returns unless `state == NONE`, and `stampede()` only affects `LOOK_UP`. The repeat `_panic()` in `shakedown.gd` therefore does nothing to anyone in `PANIC` or `RETURN`. After `panic_time` (4 s) people walk home, often straight past the gull, and can't panic again until they get there. Their run direction is also never updated.
- **Some actors don't react.** Only `BeachTarget`s can panic. The dog, sweeper and watergun teen are separate classes. `squall.gd` already sends people for cover, and the dog has `flee_to` and `come_home()`.
- **Vendors.** `stand.ducked` is only set by `StallService.raid()`, called from the first raid peck.
- **Slam.** `_knock_around` measures full 2D distance, so a gull high in the air reaches nobody. `ground_slam` only runs within `slam_ground_reach` (24 px). The ring lasts 0.18 s and is the only slam visual that doesn't depend on height or the shake option.

## Requirements
**Text and duration**
1. Remove the "SHAKEDOWN!" banner. Nothing replaces it. Remove `callout_hold` and whatever in `show_callout()` then has no caller, leaving `show_score_announcement` behaving as before.
2. Shakedown lasts 9 s (`data/species.json`).

**Rolling panic**

3. Add a `CrowdPanic` pulse used by Shakedown's repeat `_panic()`: anyone within `panic_radius` of the gull in `PANIC` or `RETURN` goes (back) to `PANIC`, with the timer restarted and direction away from the gull's current x. They keep their original `home`. `NONE` people still go through `look_up` and `stampede`. Gang Call and squall behaviour is unchanged.
4. Non-`BeachTarget` actors flee during the power. Dog, sweeper and teen within `panic_radius` stop attacking and run away from the gull, returning to normal when the power ends on every end path. Reuse existing squall or retreat paths wherever one exists (the dog's `flee_to` and `come_home()`). Check every `BeachTarget` kind too, and fix or list in the Report any kind that still doesn't react, such as a seated, service-locked or sleeping person.

**Vendors and raid marker**

5. During the power, a vendor ducks when the gull is within `duck_reach` (tunable, start at 70 px in x) of the stall, using `StallService.raid()` so orders end. The vendor comes back when the gull moves out of reach. Raid counts persist for the whole power, and every end path still releases the stall.
6. While the power is active, a stall that hasn't reached `raid_cap` shows small glowing gold target corners at the counter window, using `PickupShine.draw_target_corners` (the same marker as a counter steal). It disappears at the cap and when the power ends. It shows from the end of the hold, and doesn't need the gull to be close.

**Slam**

7. The slam knocks food by horizontal distance only (`absf(dx) <= slam_radius`), so it works at any height.
8. `ground_slam` runs under the gull at any height, at ground level (remove `slam_ground_reach`).
9. Make the ring readable: `slam_ring_time` 0.3 and a second, thinner ring 0.08 s behind it. The first ring's final radius is still `slam_radius`.

**Black-back dog bump (inherent, in and out of Shakedown)**

10. Add species flag `bumps_dogs` (black-back only). A player with it in `STRIKE` whose beak sweep hits the dog (`BeachCollisions.segment_hits` in the style of `_mugging()`, with a tunable `dog_bump_hit` box) bumps it: the dog recoils and goes into its cooldown (generalise `_bounce`), flashes white using `HitFlash`, and the game plays `snatch_contact` and shouts "BONK!". The dog can't be bumped again during that cooldown.
11. The bump earns `brash.dog_bump`, start at 0.6, a large reward compared with a rival bump's 0.34. `add()` already blocks earning during a power.
12. If the dog would catch a black-back that is in `STRIKE`, the bump wins. In any other state the dog catches it as today. Other species are unchanged.

## Out of scope
New art or sound; the full enraged sprite set; changes to the rear-up hold, dim or deflate; perks.

## Done when (acceptance)
- [ ] No "SHAKEDOWN!" banner appears, and food score announcements behave as before
- [ ] The power runs 9 s after the hold
- [ ] Someone in `RETURN` near the gull during a pulse panics again, away from the gull's current position, and goes home after the power; Gang Call and squall are unchanged
- [ ] Dog, sweeper and teen flee during the power and return to normal at expiry, level end and `clear()`
- [ ] A vendor ducks inside `duck_reach` before any peck and returns outside it; raid counts persist; every stall is released on every end path
- [ ] Target corners show only during the power on stalls below the cap
- [ ] A slam from high in the air knocks food from people within `slam_radius` horizontally
- [ ] A black-back dive bumps the dog, earns `dog_bump`, can't re-bump during cooldown, and beats the dog's catch; outside `STRIKE` the dog still catches it; a herring's dive doesn't bump
- [ ] Checks added to `tests/shakedown_checks.gd`; `./tools/validate.ps1` has no new failures

## Report
**Branch** `sonnet/070-shakedown-playtest-fixes` (commit hash in the hand-off message; not pushed or merged).

**Files changed** `data/species.json`, `data/tuning.json`, `scripts/shakedown.gd`, `scripts/crowd_panic.gd`, `scripts/food_stall.gd`, `scripts/effects.gd`, `scripts/overlay.gd`, `scripts/brashness.gd`, `scripts/game.gd`, `scripts/gull.gd`, `scripts/off_lead_dog.gd`, `scripts/sweeper.gd`, `scripts/watergun_teen.gd`, `tests/shakedown_checks.gd`.

**Tests** Before: 16,891 checks, 2 failures. After: 16,957 checks, 2 failures. Both are the known ones: "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo". 66 new checks, all in `tests/shakedown_checks.gd` (`_playtest_fix_checks`); none race the wall clock (simulated ticks only).

**Existing checks updated (behaviour deliberately changed)** Power duration 8.0 to 9.0 in the data check, the Q-fire check, the immunity check, the overlay-data check, the hold check, the "full power time follows the hold" check and the shake-off check. The "SHAKEDOWN! shows in the banner" check now asserts no banner is visible. The three `sim(game,9.0)` expiry waits became 10.0.

**Decisions**
- Banner: removed the call, `callout_hold`, and `show_callout`'s `hold`/`pop` parameters (only `show_score_announcement` calls it, with the old defaults). Nothing replaces it.
- `CrowdPanic.pulse()` is called from `_panic()` after warn and stampede. SHELTER (squall) people are never touched.
- Non-crowd actors: dog, teen and sweeper get a `flee_to` (dog already had one) and `come_home()` (dog's existing one; new for teen and sweeper). Shakedown's `_scare()` runs each panic pulse and sends anyone within `panic_radius` to 1.5 radii from the gull's x at that moment. They stay scared until the power ends. The release is in `end()`, so expiry, `end_power`, `clear()` and `finish()` all restore them. A dog is not brought home while a squall is in its SQUALL phase (the squall rewrites `flee_to` every frame and its own `_clear` brings the dog home). A sweeper already leaving (EXIT) is not scared.
- Dog trots home with the existing `homecoming` path; teen and sweeper go back to PATROL.
- Vendors: `_duck_stalls()` each tick calls `StallService.raid()` when the gull is within `duck_reach` (70) in x, and clears `ducked` outside it. `raided` counts are untouched until `end()`.
- Corners: `FoodStall.marker_layer` is a child Node2D drawn above the vendor (a draw on the stall itself would sit behind the vendor sprite). Shown while `gorging`, after the hold, and below `raid_cap`. Radius in `marker_radius`.
- Slam: `_knock_around(radius,flat)`; the slam passes `flat=true` (also for rival carriers), the shake keeps 2D distance. `ground_slam` always runs (it already draws at ground level). Second ring uses a new optional `delay` argument on `BeachEffects.ring`; its `slam_ring2_lag` is 0.08. Because the ring's growth is based on elapsed time, the delayed ring ends slightly short of `slam_radius`; the first ring still ends at exactly `slam_radius`.
- Dog bump: `bumps_dogs` species flag, `BeachGull.bumps_dogs`, `OffLeadDog.bump()` (reuses `_bounce`, so the shakedown `bounce_recoil` and `bounce_cooldown` apply), `bumped` signal, white flash via `HitFlash`, `game._dog_bump_check()` sweeps the beak against `off_lead_dog.dog_bump_hit` ([20,10]; the box centre sits one half-height above the dog's feet). `_try_catch` bumps instead of catching a STRIKE-state black-back. `dog_bump` is 0.6 (rival bump 0.34). A dog already in COOLDOWN or fleeing cannot be bumped, so a normal cooldown after a catch also protects it.
- "BONK!" shout, `snatch_contact` and meter come from `game._dog_bumped`; the dog's flash is its own.

**Findings that turned out differently**
- Vendors only ducked from the first peck, as stated, but `fire()` itself also aborts any order near the gull (via `look_up`), so a gull inside `duck_reach` always finds the order already gone before the duck. The raid call still ends orders for stalls whose customers are out of panic range.
- `ground_slam` already draws at ground level and only checks `x < promenade_start`; only the height gate had to go. `promenade_start` is 430 on level 2, so a test slam must be left of that.

**Actor kinds** Every BeachTarget kind panics through `look_up`: sunbather (asleep or awake), toddler, picnic_family, dog_owner, kiosk_customer (including one mid-order and service-locked, who is released by the abort), pier_diner, lifeguard, and a plain food holder. Each is checked in `_kind_checks`. Kinds that still do not panic by design: `stall_handover` and `loose_item` (`is_loose`, they are food on a counter, not people) and anyone already `leaving` the beach. The crab and rival gulls are not people and are unchanged. `market_cleaner` exists in `data/targets.json` but nothing in the scripts spawns it.

**Not done / not verified** Nothing played in the editor, so the corner marker and double ring were not eyeballed. Fleeing dogs/teens/sweeper run at their normal run speeds and stand idle at the destination (no dedicated panic art). Nothing pushed or merged.


## Review notes
<!-- Filled in by the reviewer. -->
