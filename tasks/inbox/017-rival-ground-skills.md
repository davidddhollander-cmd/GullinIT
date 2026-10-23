# 017 — Rival gulls that land, scavenge, peck bins/bags and catch falling food

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
David playtested level 3: Gary is "very incapable" — he doesn't catch food, can't land to pick food up, and never pecks bins. Rivals today only dive-snatch from the air (`RivalPilot`: PATROL/STALK/LINE_UP/DIVE/ESCAPE/RECOVER/CHASE_CARRIER). Give rivals the player's ground skills so every rival is always busy and a real competitor, with personality differences in data.

## Context
- Rival AI: `scripts/rival_gull.gd` (`RivalPilot`), driven each tick from `scripts/game.gd` (`pilots`, `food_targets`, `loose_targets`/`_sync_loose_targets`, `_rival_mugging`). Rivals steer a `BeachGull` through the same API as the player (`aim`, `climb`, `dive()`, states incl. `GROUNDED`, landing helpers `landing_aim()`, `landing_perch()`, perches/`support`).
- Player ground mechanics to reuse (don't duplicate): `scripts/stash_raids.gd` (`peck()`, `nearby_bin`, `nearby_stash`, `_peck_bin`, stash/bag peck, `items` = loose ground/falling food incl. knocked/dropped/bin scraps, `collected` signal), scraps/crumbs (`scripts/scraps.gd`), `game._peck`, `_scrap_collected`. Wheelie bins need a top landing (`requires_top_landing`).
- Level 3 Gary is `loose_only` (never takes food from a person's hands) via `scripts/loose_food.gd` proxies — keep that rule for level 3 (gentle intro) but make him competent within it.
- Competing rivals (task 011): racing, mugging, mug window = food swallow time. Boss rules: `scripts/boss.gd`.
- Rival sims and checks: `tests/rival_ai_checks.gd` (today level 3's sim scatters extra food every 4 s, which hides the problem).

## Requirements
1. **Diagnose first.** Run a level 3 rival sim *without* artificial food scattering for 90 s and record Gary's dives, landings, items eaten, pecks; put the before numbers in the Report.
2. **Land and pick up:** a rival can choose a ground item (dropped/knocked food, scraps, crumbs, bin scraps — not garbage), glide down and land near it (no crash), walk to it, eat it (counts like a theft: `took_food`, score, mug window = swallow time), then take off. Never lands in the sea or off the world.
3. **Peck bins:** land at a bin (top landing for wheelie bins), peck it like the player (`bin_pecks` taps) to release scraps, then eat what it can reach. Bins emptied by a rival stay empty for the player too.
4. **Peck bags:** land beside a sunbather bag/stash and peck it open like the player (same reactions/risks a sunbather gives the player — if the owner wakes and swats, the rival is stunned).
5. **Catch falling food:** knocked/dropped food still in the air can be caught by a rival flying through it.
6. **Personality in data** — each rival profile gains a `ground` block with weights 0–1 for `scraps`, `bins`, `bags`, `catch` (defaults in `Config.tuning.rival`). Starting values: Gary (scavenger) scraps 0.9, bins 0.9, bags 0.6, catch 0.7; Chip (thief) 0.3, 0.2, 0.3, 0.8; Bev (bully) 0.6, 0.5, 0.5, 0.5. Target choice weighs food value, distance and these weights against air snatches/mugs.
7. **Level 3 Gary stays a scavenger:** keeps `loose_only` (no snatching from hands) but uses all four skills. A 90 s level 3 sim with no artificial food must show Gary eating at least 4 items and using at least two different skills.
8. Players still win food fairly: a rival walking to an item can lose it to a player who gets there first (no stuck rival).

## Out of scope
- New art (rivals reuse the gull sprite's existing walk/peck/land animations), level layout changes.

## Done when (acceptance)
- [ ] Report has before/after numbers for level 3 Gary (no artificial food)
- [ ] Checks: rival lands and eats a ground item; pecks a bin open and eats a scrap; pecks a bag open; catches a falling item; a `ground` weight of 0 disables that skill
- [ ] Level 3 sim (no artificial food): Gary eats ≥ 4 items using ≥ 2 skills; no crashes, no out-of-bounds, no stuck-on-ground > 6 s
- [ ] Levels 4–6 sims still pass (dives, thefts, leave the scene of a theft, no crashes/out-of-bounds)
- [ ] One `tools/validate.ps1 -Capture` run (two at most): **0 failures**; screenshots of a rival on the ground pecking a bin and eating a scrap, paths in the Report

## Report

## Review notes
