# 066 — Black-back: harder Shakedown, real toughness, screech gate

Status: inbox
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
<!-- Filled in by the implementer: what changed (files), test results (check counts),
decisions/assumptions, anything not done, branch name and last commit hash. -->

## Review notes
<!-- Filled in by the reviewer. -->
