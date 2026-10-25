# 034 — Cast rotation across levels (code + level data)

Status: merged
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
- [x] Every level's cast matches the table
- [x] L5 and L6 have one diner of each look; both look right walking, eating and reacting
- [x] No level repeats a look at start (test enforced)
- [x] A capture of each level's opening frame is saved in `test-output/` and listed in the Report
- [x] `tools/validate.ps1`: 0 failures (the play copy's demo-lock check aside)

## Report

**Files changed:** `data/levels/level_01.json` through `level_06.json`; `scripts/pier_diner_art.gd`, `scripts/spawner.gd`, `scripts/target.gd`; `tests/cast_variety_checks.gd`, `tests/integration.gd`, `tests/level_generator_checks.gd`, and `tests/prop_overlap_checks.gd`.

**Tests:** `./tools/validate.ps1` — **13,773 checks, 0 failures**. `./tools/validate.ps1 -Capture` — **13,773 checks, 0 failures** using the GL Compatibility renderer. `git diff --check` also passed. The rendered run retains the existing non-failing focus warning and preview-image import warning.

**Captures:** `test-output/cast-rotation-level-1-opening.png`, `test-output/cast-rotation-level-2-opening.png`, `test-output/cast-rotation-level-3-opening.png`, `test-output/cast-rotation-level-4-opening.png`, `test-output/cast-rotation-level-5-opening.png`, and `test-output/cast-rotation-level-6-opening.png`. These are local ignored review artifacts, as established by `.gitignore`.

**Decisions:** Authored appearances now match the target table, including explicit original/alternate diner assignments in L5 and L6. `BeachTarget` keeps diner appearance per person so `PierDinerArt` selects the matching base, motion, reaction and food-anchor metadata without mutating `Config.targets`. Missing or invalid appearances retain the original diner look; un-authored diners created by the spawner use the least-used of the two valid looks, with list order making the first diner the original. The L5 family uses shared `family_id: family_1`, with the toddler at x 210 and mum at x 255 on open sand; automated prop-base and busy customer/bench spot checks plus the opening capture verify the placement. No new art or code-drawn character imagery was added.

The worktree was clean, so nothing was stashed. The branch was created directly from the local `main` commit `e3e4037` as requested; `main` was never checked out.

**Not done:** Nothing. The branch is intentionally unmerged for Claude review.

**Branch:** `codex/034-cast-rotation`

**Implementation commit:** `eb5f7d6` (`Implement cast rotation across levels`). The task-report move is committed separately after this report.

## Review notes
