# 013 — Level 6 "Sunset Showdown" boss (Bev, wind flips, out-eat before dark)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 011
Created: 2026-10-23

## Goal
Level 6 becomes the Stage 1 boss: **out-eat Gary, Chip and Bev before dark**. Winning ends Stage 1. Hand-built, replacing the generated level.

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` (Stage 1, level 6 boss; "Rivals compete, never cooperate"; progression: "the last level of each stage is a boss/story level, won by its objective").
- Competing rivals (task 011) are merged. Wind flip already exists (`level.wind.flip`, `BeachWind`, "WIND TURNING!" message) — reuse it.
- Hand-built level format: `data/levels/level_01..04.json`, `docs/OPENING_LEVELS.md`, task 010 changes (`level_generator.gd` authored list, layout checks).
- A parallel task (012) does level 5 and generalises the rival intro taunt; don't edit `data/levels/level_05.json`. If you need a taunt for Bev, keep that change small and isolated so it merges with a generalised taunt; note it in the Report.
- AGENTS.md: no code-drawn characters. **Bev uses the existing `great-black-backed` gull sprite scaled up ~1.3x** (scaling generated art is allowed; a dedicated sprite may replace it later — keep the scale in data, e.g. profile `"scale": 1.3`).

## Requirements
1. `data/levels/level_06.json`: id 6, name `Sunset Showdown`, hand-built with sand, promenade, pier and the seafood vendor; keep 150 s, wind with `flip: true`, star targets (note any change).
2. **Rivals:** Gary (0.3), Chip (0.8), **Bev** (`scale` 1.3, `mug_chance` 0.5, slightly slower `speed` ~0.75). All present from the start.
   - **Big and bossy:** when Bev reaches food another gull (rival or player) is also diving for within `shove_radius` (data, ~20 px), the other gull is bumped away (short stun `shove_stun` ~0.4 s, no food lost) — Bev gets the food.
   - **Mugged only from behind:** a mug on Bev (by the player or a rival) succeeds only if the attacker comes from behind her (attacker x on the opposite side of her facing). A frontal attempt bounces off with `"NOPE!"` and stuns the attacker briefly.
3. **Sunset:** the scene tints towards dusk over the level's time (sky/sea/sand modulate — scenery only), reaching dark at the time limit.
4. **Boss objective:** at the end, the player wins if their score is higher than every rival's. The result board title reflects win/lose (e.g. `"BEACH BOSS!"` / `"OUT-EATEN!"`), and a win sets `GameState` progress flag `stage1_complete` (saved). Show the objective at level start (intro line `"OUT-EAT THE GANG BEFORE DARK"`). Stars stay score-based.
5. Quests: `{"id":"l6_mug_all","text":"MUG ALL 3 RIVALS","event":"rival_mugged_distinct","filter":{},"count":3,"bonus":80}` — record `rival_mugged_distinct` the first time the player mugs each different rival; `{"id":"l6_double","text":"WIN BY DOUBLE","event":"boss_double","filter":{},"count":1,"bonus":100}` — record at finish when the player's score ≥ 2× the best rival's; `"random_quest": {"count":[3,5],"bonus":40}` with `random_foods` that really appear in level 6. End-of-level quest events must still count (record before `running` turns false) and show on the result board.

## Done when (acceptance)
- [ ] Level 6 hand-built, named Sunset Showdown, passes layout/zone/sign checks
- [ ] Bev renders 1.3x, shoves contested gulls (check), can only be mugged from behind (front bounce and rear success checks)
- [ ] Sky darkens over time (tint at start vs end check); wind flips during the level
- [ ] Win/lose decided by beating every rival; win saves `stage1_complete` (checks for both outcomes)
- [ ] `l6_mug_all` needs three different rivals; `l6_double` fires only at ≥2× (checks)
- [ ] Rival sim on level 6: all three dive and steal, no crashes/out-of-bounds, rivals leave the scene of a theft
- [ ] One `tools/validate.ps1 -Capture` run at the end (two at most): **0 failures**; screenshots of level 6 early and near dark, and the boss result board; paths in the Report

## Report

## Review notes
