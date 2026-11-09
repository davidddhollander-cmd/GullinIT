# 066 — Black-back: harder Shakedown, real toughness, screech gate

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 064
Created: 2026-11-09

## Goal
David playtested Shakedown and it doesn't feel powerful. Make firing it and every hit land hard, make the gull visibly a bully, let threats bounce off it, and pay the player off. Also make the black-back's "tough" stat matter, and let any species with a screech clip screech.

## Context
- `scripts/shakedown.gd`, `scripts/brashness.gd` (`_impact()` is Gang Call's hit bundle: feathers, crumbs, sand, shake, freeze, rising cries; `tuning.brash.food_lift` is 2.8).
- `scripts/gull.gd`: `begin_tumble()` is the shared path for kicks, sweeps, swats and muggings; `apply` of species stats sets `stun_mult` (player only); `tick()` resets `sprite.scale` and `modulate.a` each frame, so power visuals must be applied after that; `steady_invulnerable`.
- Threats skip an invulnerable gull in their target checks: `off_lead_dog.gd`, `sweeper.gd`, `watergun_teen.gd`, and the `picnic_family` check in `target.gd`.
- `scripts/digestion.gd`: `capacity`, `tick(delta, grounded)`. `game.gd` `_apply_perk()` sets capacity from the perk.
- `scripts/autoload/audio.gd`: `duck_music`. `game.gd`: `_can_screech()`, `_advance_screech_hold()`, `_stunned()`.
- `target.gd` `knock_food(gull, lift)` sets `drop_retrieve` by chance.
- AGENTS.md: scaling and tinting the existing generated sprite is animation and allowed. Do not draw any part of a character. Check `godot-prompter:ability-system` and `tween-animation` first.
- Put every number in `data/tuning.json` (`shakedown` block) or `data/species.json`.

## Requirements
**Screech**
1. `_can_screech()` replaces the herring check with "the player's frames have a `screech` animation". The herring lesson gating stays herring-only. Until task 065's art lands, the black-back behaves as it does today.
2. Add an optional `screech_pitch` species stat, multiplied into the screech audio. Black-back 0.8; default 1.0.

**Toughness**
3. Add a `knockback` species stat (default 1.0, black-back 0.6, set alongside `stun_mult`, player only). `begin_tumble` scales both launch components by it.
4. Black-back `power.fill` gains `"stun": 0.5`, and `_stunned()` uses `earn("stun")` so it loses half as much meter.

**Shakedown punch**
5. Slam on fire: everyone within `slam_radius` (70) of the gull loses food immediately with `food_lift`, and the fire plays one Gang Call-weight impact at the gull (shake, freeze, feathers, sand, dust). Share code with `_impact()` rather than copying it.
6. Heavy hits: every shake knock during the power uses `food_lift` and the same impact bundle with the rising hit cries. Keep shake and freeze per hit modest enough that chained hits don't stutter (cap with a short `impact_gap`). `shake_radius` goes to 50. Food knocked during the power has `drop_retrieve` false.
7. Gorge: while active, stomach capacity is raised by `gorge_capacity` (+4) and digestion runs at `gorge_digest` (3x). Restore the perk's capacity on every end path, including `clear()`. Snacks over normal capacity simply keep digesting after the power ends.
8. Visible bully: while active the player sprite is scaled by `bully_scale` (1.25) with a slow tint pulse. Landing during the power adds a small shake and sand puff. In the last `end_warning` (1.5) seconds, the pulse speeds up and a tick sound plays. Scale must not shift gameplay positions such as the beak or feet.
9. Bounce-offs: add `BeachGull.untargetable()` (invulnerable and not `steady_invulnerable`) and use it in the dog, sweeper, teen and family target checks, so they still attack during Shakedown. Their hit then lands on `stun()`, is blocked, and shows "NOPE!". The dog and sweeper recoil away through their existing retreat or recover behaviour, so they can't hit again for at least `bounce_cooldown` (2.0). Rate-limit the "NOPE!" toast. Rival mugging of the player stays blocked. Outside the power, behaviour is unchanged.
10. Sound: fire uses the black-back's `sound` at a lower pitch (`power.pitch`, 0.75) and ducks the music for about 1 s. Herring is unchanged.
11. Better raids: on each raid peck the stall gives a small shake using existing stall drawing or position (scenery only, never moving through the vendor mask incorrectly), and the spit arc is biased to land within pickup reach of the gull, on the sand directly below if the gull is on the roof.

## Out of scope
- Perks, new art or sound files, Lightning Strike, screech for kittiwake, the results board, keeping held food when stunned.

## Done when (acceptance)
- [ ] A black-back tumbles a shorter distance than a herring from the same hit; a herring's tumble is unchanged
- [ ] A stun costs a black-back half the herring's meter loss
- [ ] Species without a `screech` clip can't screech and their pecks work as before; adding the clip enables it (test with a fixture or the herring)
- [ ] Firing knocks food from people inside `slam_radius` at once
- [ ] Shake hits use the higher lift and can't be reclaimed
- [ ] Capacity and digest speed rise during the power and are restored at expiry and level end, with a perk's capacity preserved
- [ ] Sprite scale is back to normal at every end path; beak and feet positions are unaffected during the power
- [ ] Dog and sweeper attack, are blocked, and recoil during Shakedown, and ignore a gull in ordinary post-hit invulnerability as before
- [ ] Gang Call feel and existing checks unchanged
- [ ] Checks added to `tests/shakedown_checks.gd`; `./tools/validate.ps1` has no new failures

## Report
**Files changed:** `data/species.json` (black-back `knockback` 0.6, `screech_pitch` 0.8, `power.pitch` 0.75, `fill.stun` 0.5), `data/tuning.json` (`shakedown` block: slam/heavy-hit/gorge/bully/bounce/raid numbers, `shake_radius` 50; `brash.hit_cap`), `scripts/shakedown.gd`, `scripts/brashness.gd`, `scripts/gull.gd`, `scripts/game.gd`, `scripts/digestion.gd`, `scripts/food_stall.gd`, `scripts/off_lead_dog.gd`, `scripts/sweeper.gd`, `scripts/watergun_teen.gd`, `scripts/target.gd`, `tests/shakedown_checks.gd`.

**Tests:** baseline on main 16631 checks, 2 failures (the two known ones). After: 16690 checks, 2 failures (identical to baseline: "nobody teleports across the beach while running off", "data/demo.json enables the four-level demo"); 59 new checks in tests/shakedown_checks.gd.

**What was done**
- Screech: `_can_screech()` now requires the player's frames to have a `screech` animation (no species test). Lesson gating stays herring-only. `screech_pitch` multiplies the screech audio (`BeachGame.screech_pitch()`).
- Toughness: `knockback` stat scales both tumble launch components in `begin_tumble`; `_stunned()` uses `brash.earn("stun")` so the black-back's `fill.stun` 0.5 halves the loss.
- Shared impact: `BeachBrash.hit_fx()` is the Gang Call bundle (feathers, crumbs, sand, shake, freeze, rising cry); `_impact()` calls it, so Gang Call is unchanged. The rising index is capped by `brash.hit_cap` (8; Gang Call never gets there).
- Slam on fire: everyone within `slam_radius` loses food with `food_lift`, plus one full-weight impact and stampede dust. Heavy hits: shake knocks use `food_lift`, `drop_retrieve` forced false, one lighter impact per `impact_gap` even if several people are hit in one frame.
- Gorge: capacity +4 and `GullDigestion.speed` 3x while active; the pre-power capacity is stored and restored in `Shakedown.end()` (covers expiry, `end_power`, `clear`, `finish`).
- Bully: `BeachGull.power_scale` / `power_tint` are applied inside `tick()` after the per-frame reset, before the carry sync, and the bill/sole anchor offsets use the scaled size so beak and feet stay put. Slow tint pulse, faster plus a `click` tick in the last `end_warning` seconds. Landing during the power adds shake and a sand puff. Everything is reset in `end()`.
- Bounce-offs: `BeachGull.untargetable()` replaces the `invulnerable <= 0` target checks in dog, sweeper, teen and family. The dog and sweeper recoil `bounce_recoil` px and cannot act again for `bounce_cooldown`. "NOPE!" (and its click) is rate-limited to `nope_gap` while a power runs.
- Sound: fire uses the species `power.pitch` (0.75) and ducks the music for `duck_music` (1 s) using a scene-tree timer.
- Raids: each raid peck rattles the stall (`FoodStall.rattle()` offsets the stall node's x for ~0.18 s, restored exactly to `home_x`; the vendor and mask move with it). The spit arc is aimed with the real gravity at the gull's beak (grounded) or the sand under the gull (on the roof), with a small spread.

**Decisions**
- A blocked teen shot just splashes and shows (rate-limited) NOPE; only the dog and sweeper got the recoil/cooldown, as specified.
- Freeze (hitstop) from the fire slam means the next physics step can be skipped; one existing test needed `effects.freeze = 0` between two fires in the same frame sequence.
- The stall shake moves the stall node, not just a child, because the vendor sits inside a clip mask and a vendor-only wobble is invisible once the vendor has ducked.
- Black-back `_can_screech()` still depends on the art: until task 065 adds a `screech` clip it behaves as before (tests use a fixture clip).

**Not done:** nothing from the requirement list. Not verified visually in game (no screenshots taken).

**Branch / commit:** `sonnet/066-black-back-punch-and-toughness`, single commit at branch tip (see git log).

## Review notes
<!-- Filled in by the reviewer. -->
