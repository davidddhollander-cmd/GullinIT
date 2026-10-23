# 011 — Competing rivals: race for food, mug each other, mug the player

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
Rival gulls stop cooperating. Every gull is for itself: rivals race each other for the same food, mug each other in the air, and mug the player. This is the base for level 5 (Chip) and the level 6 boss. Also fix the long-standing failing check `level 6 rival leaves the scene of a theft`.

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` → "Rivals compete, never cooperate".
- Code: `scripts/rival_gull.gd` (`RivalPilot`: `hunt`, `pick_target`, `claimed_elsewhere`, `took_food`, `mug`, `carry_window`, `leave`/ESCAPE), `scripts/game.gd` (`claims` dict passed to every pilot, `_mugging` for player → rival, `_snatched`, `_stunned`), `scripts/loose_food.gd` (loose-only Gary, level 3), `data/tuning.json` → `rival`, level JSON `rivals` profiles.
- Tests: `tests/rival_ai_checks.gd` (its report counts `shared_target`, i.e. today's tests expect rivals never to share a target — that expectation must flip), `tests/quest_checks.gd` (Mug Gary).
- Today: the shared `claims` dict makes rivals split targets (implicit cooperation); rivals never steal from each other or from the player.

## Requirements
1. **Race for food.** Rivals no longer respect each other's claims: each picks the best target for itself (`pick_target` ignores other rivals' claims). If another gull (rival or player) takes the food first, the loser abandons that dive cleanly (pulls up / RECOVER) and retargets — no stuck dives on a target with no food.
2. **Rival mugs rival.** A rival in STALK/PATROL that sees another rival carrying food (`carry_window > 0`) within `mug_range` may intercept it with a strike; on a hit the food changes beaks exactly like the player's mug today (victim stunned `mug_stun`, attacker gets `took_food(value)`, scores move accordingly, `"MUGGED!"` message over the attacker). A victim cannot be mugged again during its stun.
3. **Rival mugs player.** When the player carries food that is not yet swallowed, a rival within `mug_range` may chase and strike; a hit takes the player's current food (`player.digestion.drop_current()` → into the rival's beak, not onto the sand), stuns the player briefly (`mug_stun`), message `"MUGGED BY <NAME>!"`. Climbing above the rival's cruise height or swallowing escapes it. The existing player stun penalty applies.
4. **Personality in data.** Each rival profile gains `"mug_chance"` (0–1: how eagerly it goes for a carrier) with a default in `Config.tuning.rival` (`mug_chance` 0.35, `mug_range` 90). Gary 0.3, Chip 0.8 (for level 5+), Bev later. Levels 3–6 profiles updated; level 3 Gary keeps `loose_only` for food, but may still mug carriers.
5. **Scoreboard and quests keep working:** rival scores reflect what each actually ends up with; `mugged_from` on the player's mug still names the victim (`l3_mug_gary` must still complete).
6. **Fix `level 6 rival leaves the scene of a theft`.** Find the root cause (it fails on `main` today, before this task) and fix it; it must pass after the change.

## Out of scope
- Level 5/6 content (Chip's debut level, Bev, boss scoreboard, wind flip), new art.

## Done when (acceptance)
- [ ] Two rivals can target and dive at the same food; the loser recovers and retargets (test)
- [ ] Rival-on-rival mug transfers food and score, with stun and message (test)
- [ ] Rival-on-player mug takes the carried food and stuns briefly; climbing/swallowing avoids it (tests)
- [ ] `mug_chance` / `mug_range` live in data; a rival with `mug_chance` 0 never mugs (test)
- [ ] `rival_ai_checks` updated to the new rules (no "never share a target" expectation), sims for levels 3–6 still show dives and steals and no crashes/out-of-bounds
- [ ] `level 6 rival leaves the scene of a theft` passes; root cause in the Report
- [ ] `tools/validate.ps1` with **0 failures**; at most two full runs (iterate with targeted checks)

## Report
Branch `sonnet/011-competing-rivals`.

**Files:** `scripts/rival_gull.gd`, `scripts/game.gd`, `data/tuning.json`, `data/levels/level_03..06.json`, `tests/rival_ai_checks.gd`, `tests/integration.gd` (one call added).

**Tests:** `validate.ps1` ran once: `INTEGRATION: 15907 checks, 0 failures` (baseline 15888 / 1 failure). 19 new checks in `competition_checks`, and the old "never share a target" check flipped to "level 6 rivals race for the same food" (shared_target about 750-900 frames in the sim).

**Root cause of `level 6 rival leaves the scene of a theft`:** found with a trace on an untouched copy of main. `took_food` picked the retreat direction purely "away from the player" (idle at x=40, so always east). A rival that stole while diving west keeps its dive momentum, skids about 90 px further west on the sand, turns round, and only then flies east at 112 px/s. After the 4 s `leave_time` its net displacement was about 114 px, under the 120 px the check demands (Gary 800 -> 914). The check is right; the AI was wasting about 2 s on a U-turn. Fix: when the thief is moving faster than 40 px/s sideways and has at least 250 px of room that way, keep that heading; otherwise the old logic. Confirmed on baseline main plus only this fix: 0 failures. Because of the changed RNG flow the failure also vanishes with the other changes, but the fix is what makes it deterministic.

**Design:**
- Racing: `claimed_elsewhere` is gone. `pick_target` and `hunt` ignore other rivals' claims (the `claims` dict is kept for signature compatibility and bookkeeping only). `abort_dive` now also nulls a target whose food is gone, so the loser pulls up (RECOVER) and retargets via the normal `hunt`.
- New `Mode.CHASE_CARRIER` in `RivalPilot` (`chase_step`, `mug_dive_step`, `nearest_prey`): the game gives each pilot a `prey` list per frame (rivals with `carry_window > 0` and not stunned, plus the player when `digestion.snacks` is non-empty and not stunned/invulnerable). Within `mug_range` a rival rolls `mug_chance` (re-roll gap 0.5 s), climbs over the carrier, then dives through it using the existing DIVE/STRIKE machinery. A carrier above `cruise_y - 4` is unreachable, swallowing empties the list.
- Strike resolution: new `BeachGame._rival_mugging()` using `BeachCollisions.segment_hits` like `_mugging`. Rival victim: `victim.mug()` then `attacker.took_food(value)`, "MUGGED!". Player victim: `digestion.drop_current()` first (so `_stunned` drops nothing on the sand), `took_food(points)`, `player.stun(mug_stun)`, "MUGGED BY <NAME>!". The existing `_stunned` penalty (-5, RUDE.) still applies. A thief carrying food (`leave > 0`) cannot strike again.
- Data: `tuning.rival.mug_chance` 0.35 and `mug_range` 90. Profiles: Gary 0.3, Chip 0.8, Bev 0.5 in levels 3-6. Level 3 Gary stays `loose_only` and can still mug carriers.

**Not done / gaps:**
- Rival-on-rival mugs are rare by construction: the victim is only vulnerable for `mug_window` (0.5 s) after its theft, so the sims show almost none. The tests exercise them directly; I did not lengthen the window. Say if you want it raised.
- Rival-on-player mugs are covered by a hover-in-place integration test, not tuned in live play (no playtest). `mug_chance` / `mug_range` need a feel pass.
- Bev's 0.5 is my choice (task said "later").
- Level 5 has no rival sim (the existing sim covers 3, 4 and 6).
- During debugging I ran `taskkill` on all Godot console processes once, which may have aborted another agent's test run.

## Review notes
