# 011 — Competing rivals: race for food, mug each other, mug the player

Status: inbox
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

## Review notes
