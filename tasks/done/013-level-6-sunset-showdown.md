# 013 — Level 6 "Sunset Showdown" boss (Bev, wind flips, out-eat before dark)

Status: merged
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
- [x] Level 6 hand-built, named Sunset Showdown, passes layout/zone/sign checks
- [x] Bev renders 1.3x, shoves contested gulls (check), can only be mugged from behind (front bounce and rear success checks)
- [x] Sky darkens over time (tint at start vs end check); wind flips during the level
- [x] Win/lose decided by beating every rival; win saves `stage1_complete` (checks for both outcomes)
- [x] `l6_mug_all` needs three different rivals; `l6_double` fires only at ≥2× (checks)
- [x] Rival sim on level 6: all three dive and steal, no crashes/out-of-bounds, rivals leave the scene of a theft
- [x] One `tools/validate.ps1 -Capture` run at the end (two at most): **0 failures**; screenshots of level 6 early and near dark, and the boss result board; paths in the Report

## Report
Branch `sonnet/013-level-6-sunset-showdown`. Tests: `INTEGRATION: 15407 checks, 0 failures` (headless run of the final tree; two earlier `validate.ps1 -Capture` runs found only rival-sim failures, fixed below). The count is lower than the 15,909 baseline because level 6 no longer goes through the generated-layout checks; `tests/boss_checks.gd` adds about 40.

Files: `data/levels/level_06.json` (rewritten), `scripts/boss.gd` (new: sunset tint, shove, rear-only mug guard, verdict), `scripts/game.gd` (small hooks: shove call, tint, mug guards, `rival_mugged_distinct`, boss conclude/verdict in `finish()`), `scripts/gull.gd` (`body_scale`), `scripts/rival_gull.gd` (reads profile `scale`), `scripts/level_generator.gd` (`authored: true` skips regeneration, like levels 1-4), `scripts/overlay.gd` (intro shows level `objective`), `scripts/result_board.gd` (BEACH BOSS! / OUT-EATEN! title), `scripts/autoload/game_state.gd` (`set_flag`), `data/tuning.json` (`boss.bounce_stun`), tests (`boss_checks.gd`; edits in `integration.gd`, `level_generator_checks.gd`, `gull_species_checks.gd`, `rival_ai_checks.gd`).

Decisions:
- Level 6 reuses level 4's world (1280, promenade 430, pier 920). Cast: 2 sunbathers, 2 picnic families (+1 toddler), 3 kiosk customers, 2 pier diners, seafood vendor; lifeguard dropped. The extra family and second diner exist because Bev's shove starves Gary and Chip otherwise (the rival sim needs 2+ thefts each).
- Stars (700/1050/1400), 150 s and wind flip unchanged. Name is now `Sunset Showdown`.
- Bev: `great-black-backed`, `scale` 1.3, `mug_chance` 0.5, `shove_radius` 20, `shove_stun` 0.4, `mug_from_behind`. **Speed 0.78, not 0.75**: at 0.75 she flew only 109 px in the 4 s escape into the headwind and failed the shared "leaves the scene of a theft" check (needs 120 px).
- Shove: before collisions each frame, if Bev is striking at her target and her beak is within `shove_radius` of the food, any other striking gull (player or rival) whose beak is also within that radius is bumped with `begin_tumble(shove_stun)`. `begin_tumble` rather than `stun()` so the player loses no food and no points. The frontal-mug bounce also uses `begin_tumble` (0.6 s, `tuning.boss.bounce_stun`), so no point penalty either.
- Behind = attacker x on the opposite side of Bev's `facing`. Same rule for player and rival mugs.
- `rival_mugged_distinct` fires on the player's first mug of each different rival. `boss_double` fires in `finish()` before `running` goes false, when points >= 2x best rival and > 0.
- Win = `score.points` > best rival score (the numbers the HUD meter shows), arcade mode only; practice is unchanged. A win sets `GameState.progress["stage1_complete"]` and saves.
- Sunset: `beach.modulate` lerps white to `sunset.to` (`4f4a7a`) over `time_limit`; only the backdrop and its props are tinted, never actors. The existing static orange sky flag now keys off `level.sunset`.
- `rival_ai_checks.gd`: a pilot mugged mid-escape now resets its theft timer; before, being mugged made its escape and cooldown windows look violated.
- No Bev taunt added (the level 6 intro quote is already Bev's); `_gary_taunt` untouched, so no conflict with 012.
- Expect trivial merge conflicts with 012 in `level_generator.gd`, `level_generator_checks.gd` (the `number <= 4` branch) and possibly `rival_ai_checks.gd`.
- Species test: Bev's expected species changed from herring to great-black-backed.

Screenshots (worktree `test-output/`, from the first capture run; later data edits only added an off-screen family and diner): `boss-intro.png`, `boss-start.png`, `boss-dusk.png` (93% of time), `boss-result.png`, in `C:\Users\david\Documents\ChatGPT\GullinIt\.claude\worktrees\agent-a161e7fdf7f32bc48\test-output\`.

Not done: no human playtest of the shove feel.

## Review notes
