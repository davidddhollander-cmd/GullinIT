# 014 — "Pick your gull" at arcade start, with species stats

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
Pressing ARCADE opens a **PICK YOUR GULL** screen before level select, so players see from the start which gulls exist and what they'll unlock later. The three species get real gameplay differences. For testing, all three are pickable now; prices are shown but not enforced until the Feathers shop exists.

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` → "Feathers shop" (species table: Herring baseline free; Great black-backed slower/heavier, shoves rivals, stunned less, 6 Feathers; Kittiwake best in wind and dives, 6 Feathers).
- Species art already exists for both roles: `data/gull_art.json` (`gull_herring`, `gull_kittiwake`, `gull_great_black_backed`), `BeachGull.species`, `refresh_art()`, `species_speed()` (reads `flight_speed_mult` from the art entry), `game.gd` sets `player.species` from `level.player_species`. See `docs/GULL_SPECIES_PRODUCTION_V1.md`.
- Bev's shove (level 6) lives in `scripts/boss.gd` (`BeachBoss.shove`, `_bump` via `begin_tumble`).
- Menus: `scripts/menus.gd` (`title()`, `level_select()`, `choose()`), navigation in `scripts/main.gd` `_navigate`. UI rules: GullPixel 8/16 px (HUD face 6 px allowed), 320x180, keyboard/controller/touch.

## Requirements
1. **Data** `data/species.json` — one entry per species: display `name`, one-line `blurb`, `price` (Feathers), and stats: `flight` (horizontal flight multiplier), `dive` (dive speed multiplier), `wind` (how strongly wind pushes the gull, 1 = normal), `stun` (stun duration multiplier), `shove` (bool). Starting values:
   - `herring`: "HERRING GULL", "ALL-ROUNDER", price 0, flight 1.0, dive 1.0, wind 1.0, stun 1.0, shove false
   - `great-black-backed`: "GREAT BLACK-BACK", "SLOW AND HEAVY. SHOVES RIVALS", price 6, flight 0.9, dive 0.95, wind 0.8, stun 0.7, shove true
   - `kittiwake`: "KITTIWAKE", "QUICK. BEST IN WIND AND DIVES", price 6, flight 1.1, dive 1.15, wind 0.6, stun 1.15, shove false
   - top level `"unlock_all": true` (testing switch).
   Move the flight multiplier here (stop reading `flight_speed_mult` from the art file for gameplay) and keep current kittiwake speed if it differs (note it).
2. **Stats apply to the player** (rivals keep their own profile tuning; rival species stays visual + flight multiplier as today): flight, dive, wind push, stun duration. `shove`: when a great-black-backed player and a rival dive for the same food within the boss `shove_radius`, the rival is bumped (reuse/generalise `BeachBoss` shove + `_bump`; no food or points lost).
3. **Picker screen** `PICK YOUR GULL`: shown when the player presses ARCADE on the title, before level select. Three cards side by side, each with the real animated species sprite (generated art only), name, blurb, and either `UNLOCKED` (owned/free/testing) or `UNLOCK: 6 FEATHERS` (dimmed, not pickable) when `unlock_all` is false. The last pick is pre-selected; confirm goes to level select; BACK returns to the title. Keyboard, controller and touch all work.
4. **Saved choice:** `GameState.options.gull` (default `herring`), saved; arcade and practice games use it for `player.species` unless a level sets `player_species`.
5. Title screen and result board keep working with whichever species is picked.

## Out of scope
- Spending Feathers / the shop, perks, new art.

## Done when (acceptance)
- [ ] ARCADE → PICK YOUR GULL → level select; BACK works; last pick pre-selected (checks)
- [ ] Picking each species changes the player's species in game and the stats from `data/species.json` (checks per stat: flight, dive, wind push, stun duration)
- [ ] Great black-backed player bumps a rival contesting the same food (check)
- [ ] With `unlock_all` false, priced species show `UNLOCK: 6 FEATHERS` and can't be picked (check)
- [ ] Layout + font-grid checks pass on the picker; `-Capture` screenshot of the picker, path in the Report
- [ ] One `tools/validate.ps1 -Capture` run (two at most): **0 failures**

## Report
Branch `sonnet/014-gull-picker`. Tests: `INTEGRATION: 14496 checks, 0 failures` (second and last `validate.ps1 -Capture`; the first found 2 failures caused by rivals picking up the new 0.9 gull speed, fixed). A final cosmetic edit (3 px bottom padding on the picker cards) came after that run.

Files: `data/species.json` (new), `scripts/menus.gd` (`gull_picker()`), `scripts/main.gd` (`arcade`/`casual` open the picker, new `gull` action), `scripts/autoload/config.gd` (loads `species`), `scripts/autoload/game_state.gd` (`options.gull`, `gull_owned()`, `chosen_gull()`), `scripts/gull.gd` (player stats), `scripts/game.gd` (species from the saved pick, `shove_player` call), `scripts/boss.gd` (`shove_player`), `data/tuning.json` (`boss.player_shove_radius/stun`), `data/sprites.json` + `data/gull_art.json` + `tools/prepare_gull_species.py` (dropped `flight_speed_mult`), tests (`gull_picker_checks.gd` new; `integration.gd`, `gull_species_checks.gd` edited).

Decisions:
- Kittiwake `flight` is 1.2 (its current art value), not the 1.1 in the task text, per "keep current kittiwake speed".
- Rivals keep their pre-picker speeds through a `rival_flight` key (1.0 / 1.0 / 1.2); only the player reads `flight` (great black-back 0.9). Otherwise Gary and Bev slowed 10% and broke the "leaves the scene of a theft" rival check. The old species test was changed to expect kittiwake faster and great black-back slower as player gulls.
- Stats apply via `BeachGull.apply_species_stats()` (player only): flight = cruise speed, dive = acceleration and speed cap, wind = drift push (lift and HUD wind are untouched), stun = tumble length (also scales shove bumps).
- Shove: `BeachBoss.shove_player`, radius 20 / bump 0.4 s from `tuning.boss` (matches Bev), runs every frame on any level; both gulls must be striking with beaks within the radius of the rival's target food. No food or points lost.
- Picker: three card Buttons with the animated `glide` sprite, name, blurb and status; clicking a card picks and confirms. Last pick is focused, BACK returns to the title. Cards for unowned gulls are disabled with `UNLOCK: 6 FEATHERS`; `chosen_gull()` falls back to herring if the saved pick is not owned. `GameState.options.gull` is saved on pick. Level `player_species` still overrides it.
- Level select BACK still goes to the title (not back to the picker).
- Numeric stats are not shown on the cards (space); the blurb carries the description.

Screenshot: `test-output/gull-picker.png` in the worktree `the agent-a9d3e1b178acd0d9c worktree under .claude/worktrees`.

Not done: no human playtest of the feel of the species stats or the shove; the shop and spending Feathers are out of scope.

## Review notes
