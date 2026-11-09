# 076 — Black Back card, name and raid balance

Status: done
Author: Claude
Assignee: Sonnet
Depends on: none
Created: 2026-11-09

## Goal
Show the black-back as slow on its card, shorten its name, and stop Shakedown stall raids from being an automatic points fountain.

## Review findings
- Raided food is emitted with `scrap = false` (`stash_raids.gd`, `collected.emit(..., source == "bin")`), so it goes through `_award()`: every no-skill pickup gets the combo multiplier and raises the combo.
- Each stall gives 6 items averaging 20 points, about 120 before combo, in roughly a second of pecking, and the food is aimed at the gull's feet while it is untouchable. Level 1's first star is 100.

## Requirements
1. `data/species.json`, `great-black-backed`: `card.speed` from 2 to 1 (card only; leave `flight` alone), `name` to `BLACK BACK`.
2. Raided food scores as a flat scrap: no combo multiplier, no combo rise. Make the shared `collected` emit treat source `"raid"` like `"bin"`. Do not add a separate scoring path.
3. `data/tuning.json`, `shakedown`: `raid_cap` 6 to 4; `raid_foods` to `["single_chip", "cookie", "half_eaten_doughnut", "half_eaten_sandwich"]`.
4. Update tests that assert the old values or name, and add a check that a collected raid item leaves `score.tier` unchanged and adds exactly the food's points.

## Done when (acceptance)
- [ ] Card shows speed 1, every place shows BLACK BACK, and the text fits the picker on the 8 px grid
- [ ] Raided food adds flat points and does not touch the combo
- [ ] A stall yields 4 items, all from the new list
- [ ] `tools/validate.ps1` shows only the 2 standing failures

## Report
Files: data/species.json, data/tuning.json, scripts/stash_raids.gd, tests/shakedown_checks.gd.
- Card speed 2 -> 1 (flight untouched); name BLACK BACK (only place the name is stored; 10 chars, fits the 8 px grid picker).
- stash_raids.gd `collected.emit` scrap flag is now `source in ["bin","raid"]`; no new scoring path.
- raid_cap 4, raid_foods = single_chip, cookie, half_eaten_doughnut, half_eaten_sandwich.
- Tests: tuning check updated (cap 4 + food list); the cap check already uses raid_cap. New check: a grounded raid item collected and digested leaves score.tier unchanged and adds exactly the cookie's points (simulated ticks).
- Results: INTEGRATION 17025 checks, 2 failures (only the standing "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo").
- Branch sonnet/076-black-back-raid-balance.

## Review notes
<!-- Filled in by the reviewer. -->
