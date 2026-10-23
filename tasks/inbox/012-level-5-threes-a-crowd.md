# 012 — Level 5 "Three's a Crowd" (Chip debut)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 011
Created: 2026-10-23

## Goal
Level 5 becomes **Three's a Crowd**, hand-built: Chip debuts as a fast, eager thief and Gary, Chip and the player all fight over the pier food. Replaces the generated "Pier patrol".

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` (Stage 1 table + "Rivals compete, never cooperate").
- Competing rivals are merged (task 011): racing, rival-on-rival and rival-on-player mugs, `mug_chance` / `mug_range` per profile, mug window = food swallow time.
- Hand-built level format and helpers: `data/levels/level_01..04.json`, `docs/OPENING_LEVELS.md`, level 4 work in task 010 (`scripts/level_generator.gd` authored-level list, `tests/level_generator_checks.gd`, spawn/zone/sign checks).
- A parallel task (013) does level 6; don't edit `data/levels/level_06.json`.

## Requirements
1. `data/levels/level_05.json`: id 5, name `Three's a Crowd`, hand-built (`world`, `zones`, `spawns`, `props`, `map_version`) with promenade and **pier** (pier diner + fried fish), based on level 4's boardwalk. Keep current time (150 s), wind and star targets unless the layout needs a change (note it).
2. Rivals: Gary (mug_chance 0.3) from the start; **Chip debut**: Chip (fast — `speed` ~1.1, good `accuracy_px`, `mug_chance` 0.8) joins after the player's first swallowed snack with an intro taunt `"CHIP: FINDERS KEEPERS!"` using the same delayed, non-overlapping taunt approach as Gary's level 3 intro (`_gary_taunt` / `taunt_wait`); generalise that code to any named rival rather than copying it. No dog, no loose-only.
3. `"twist": {"id": "chip_intro"}`; quests: `{"id":"l5_fish","text":"2 FRIED FISH","event":"swallowed","filter":{"food":"fried_fish"},"count":2,"bonus":50}`, `{"id":"l5_mug_chip","text":"MUG CHIP","event":"swallowed","filter":{"mugged_from":"Chip"},"count":1,"bonus":60}`, `"random_quest": {"count":[3,5],"bonus":40}` with `random_foods` that really appear in level 5.
4. Update the level name everywhere it shows (level select, docs).

## Done when (acceptance)
- [ ] Level 5 is hand-built, named Three's a Crowd, passes the layout/zone/sign checks
- [ ] Chip arrives after the first swallow with a taunt that never overlaps the score banner or covers Chip/name tag (check)
- [ ] Rival sim on level 5 shows both rivals diving and stealing, no crashes/out-of-bounds; at least one rival-vs-rival contest (shared target or mug) in the sim
- [ ] `l5_mug_chip` completes when the player mugs Chip (check)
- [ ] One `tools/validate.ps1 -Capture` run at the end (two at most): **0 failures**; screenshot of Chip's intro, path in the Report

## Report

## Review notes
