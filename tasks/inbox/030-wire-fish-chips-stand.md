# 030 — Wire the fish & chips stand into gameplay

Status: inbox
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

## Review notes
