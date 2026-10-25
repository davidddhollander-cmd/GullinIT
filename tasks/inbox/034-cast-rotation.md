# 034 — Cast rotation across levels (code + level data)

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 033 (merged)
Created: 2026-10-25

## Goal
Cut the repetition of the same people from level to level. Rotate the existing looks so no level reuses a look from the level just before it where that can be avoided, and no level contains two identical people. Wire in the second pier diner from task 033 (`pier_diner_b`, `pier_diner_b_motion`, `pier_diner_b_reactions` in `data/sprites.json`).

## Target cast
Bold = change from today. Shopper looks are `ShopperArt.APPEARANCES`: `kiosk_customer` (default shopper), `shopper_mullet`, `shopper_sundress`, `old_man`. Sunbather looks: `male_red`, `male_blue`, `female_red`, `female_blue`.

| Level | Sunbathers | Shoppers | Others |
|---|---|---|---|
| L1 | female_blue | kiosk_customer | 1 family (unchanged) |
| L2 | **male_red** (was female_blue) | shopper_sundress | 2 families (unchanged) |
| L3 | female_red | shopper_mullet, old_man, kiosk_customer | 1 pier diner (unchanged) |
| L4 | male_blue, **female_blue, male_red** (keep three sunbathers, no repeats) | **kiosk_customer, shopper_sundress** (were mullet, old man) | off-lead dog (unchanged) |
| L5 | none | shopper_mullet, old_man | 2 pier diners: **one of each look**, **+1 family (mum + 1 toddler)** |
| L6 | **female_red** (was female_blue) | **kiosk_customer**, old_man, shopper_sundress (replaces mullet) | 2 pier diners: **one of each look**, seafood vendor, off-lead dog |

## Requirements
1. **Level data:** set the `appearance` of each spawn in `data/levels/level_0*.json` to match the table. Keep positions and stations unless something no longer fits (for example the swapped L4 shoppers must still buy at the stands they used: ice cream at the kiosk, hot dog at the hot-dog stand).
2. **Second diner look:** pier diner spawns accept `"appearance": "pier_diner"` (default) or `"pier_diner_b"`. Build `PierDinerArt.frames()` from the matching sprite ids, keep the poses and food anchor working for both looks, and keep the current behaviour when `appearance` is missing.
3. **Least-used look for diners:** diners spawned without an `appearance`, including replacements when one leaves, pick the diner look used least on the beach. Do this the same way `BeachSpawner._least_used_look` already does for shoppers and sunbathers.
4. **L5 family:** add one `picnic_family` and one `toddler` (shared `family_id`) on open sand, clear of the hot-dog queue, the fish & chips stand, the benches (x 895, 1185) and the stall customer spots. They must not overlap props (`tests/prop_overlap_checks.gd`).
5. **Tests:**
   - Update tests that pin the old cast (e.g. `tests/level_generator_checks.gd`, `tests/cast_variety_checks.gd`).
   - Extend `tests/cast_variety_checks.gd` so that no level has two people with the same look. That covers shoppers, sunbathers and diners, and must hold at start and after a replacement arrives.
   - Add a check that L5 and L6 each show both diner looks.
6. **No new art.** Only generated sprites that already exist. AGENTS.md applies.

## Done when (acceptance)
- [ ] Every level's cast matches the table
- [ ] L5 and L6 have one diner of each look; both look right walking, eating and reacting
- [ ] No level repeats a look at start (test enforced)
- [ ] A capture of each level's opening frame is saved in `test-output/` and listed in the Report
- [ ] `tools/validate.ps1`: 0 failures (the play copy's demo-lock check aside)

## Report

## Review notes
