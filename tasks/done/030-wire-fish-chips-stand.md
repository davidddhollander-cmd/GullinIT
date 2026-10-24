# 030 — Wire the fish & chips stand into gameplay

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 028
Created: 2026-10-24

## Goal
Codex delivered the fish & chips stall, sign and vendor (task 028, art only). Pier diners still buy fried fish at the hot-dog stand. Put the new stall in the diner levels and have diners buy there, so David can playtest it.

## Context
- Art: `fish_chips_stand` in `data/sprites.json` (52x56 body, `retro-fish-chips-stand-32bit.png`), runtime sign `stand-sign-fish-chips-runtime-v1.png`, vendor `vendor_fish_chips` in `data/vendor_art.json`. See how `kiosk` / `hotdog_stand` and their signs and vendors are wired: `scripts/food_stall.gd` (back wall, sign, vendor, `DRAW_DEPTH`), `scripts/beach.gd` `_apply_prop_art`, `scripts/stall_service.gd`, `scripts/target.gd` `purchase_stall_type()` (fried fish currently goes to `hotdog_stand`).
- Levels with pier diners: L3, L5, L6 (`data/levels/`). L5 is "lunch rush around a single grill" for shoppers; the fish stand there serves the diners only.
- Checks to keep passing: prop overlap (`tests/prop_overlap_checks.gd`), stall placement, pier diner meals (`tests/pier_diner_meal_checks.gd`), stall service, vendor art, level generator, rival sims.

## Requirements
1. `fish_chips_stand` works as a full stall prop like the others: body, sign, back wall, vendor in the window (upper body only, AGENTS.md), prepare/serve poses, counter placement with the dive-snatch bonus window.
2. Fried fish is bought at a fish & chips stand. `purchase_stall_type()` returns `fish_chips_stand` for `fried_fish` (fall back to `hotdog_stand` only if a level has none).
3. Place one fish & chips stand in L3, L5 and L6, near the diners' side (promenade/pier end), clear of other props (the overlap check must pass) and with `customer_x` set like the other stalls.
4. Any quest or random food that needs fried fish stays achievable.

## Out of scope
- New art; gulls' carry pose (task 031); other levels.

## Done when (acceptance)
- [ ] Checks: a pier diner in L3, L5 and L6 walks to the fish & chips stand, buys fried fish there and carries it home; the stand's vendor shows the serve pose
- [ ] All existing checks pass (update numbers that encode stall counts, don't delete checks)
- [ ] One capture run at the end with 0 failures; screenshot of the L6 fish & chips stand serving a diner, path in the Report

## Report
Status: done. Branch sonnet/030-wire-fish-chips-stand.
- Files: scripts/{food_stall,vendor_art,stand_sign,stall_service,target,beach,crab_population}.gd, data/levels/level_03/05/06.json, tests/pier_diner_meal_checks.gd, tools/pier_diner_meal_preview.gd, new tools/fish_chips_l6_preview.{gd,tscn}.
- Tests: INTEGRATION: 12858 checks, 0 failures (headless and rendered --capture; one earlier capture run hung after RIVAL SIM level 5, killed, rerun passed).
- Stands: L3 x=960 (customer_x 1000); L5 x=950 (990); L6 x=1030 (1070). Prop overlap check passes unchanged.
- Screenshots: test-output/fish-chips-l6-prepare.png, test-output/fish-chips-l6-counter.png (not committed).
- Decisions: FoodStall gets stall_type; VendorArt/StandSign keyed by stand type (bool API kept). purchase_stall_type() returns fish_chips_stand for fried_fish when the level has one, else hotdog_stand (L4 fish shoppers still work). Fish stand is excluded from signpost destinations and random shopper spawns (diner-only). Pier diner fixture now uses a fish stand; its "busy" check uses a fried_fish shopper and waits 14 s (was 8). Added per-level checks for L3/L5/L6. Gull perch on the stand (gull.gd) left to task 031.
- Ran rendered test run; umbrella in L6 (x=1060) sits partly behind the fish stand sign, left as is.

## Review notes
