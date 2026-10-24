# 023 — Give each level its own cast and layout

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playtest note: "Levels all have the same population and set-up — need more variation." Levels 3–6 share one prop layout and nearly the same cast. Give each level a recognisable identity through level data only.

## Context
- Level files: `data/levels/level_01.json` … `level_06.json` (`world`, `zones`, `spawns`, `props`, `quests`, `twist`). Spawn types: `kiosk_customer` (with `appearance`, `station`, `food_id`), `sunbather`, `picnic_family`, `toddler`, `pier_diner`, `seafood_vendor`, `off_lead_dog`. Families are linked parent→toddler in `spawner.gd`.
- Props: palms, parasols, chairs, bins, wheelie bins, lamps, benches, rocks, castle, hut, umbrella, kiosk, hotdog_stand (stalls take `customer_x`). Benches feed Codex's bench snack visits (shoppers, level > 2). The crab habitat and stall placement have their own checks.
- Quests in each file reference foods and events. Every quest must stay achievable. Tests in `tests/` check spawns, crowd spacing, stall placement, quests and rivals per level.
- Plan: `docs/superpowers/plans/2026-10-24-playnotes-fixes.md` (section "023 level identity").

## Requirements
Follow this table. Adjust numbers if a test or quest needs it, and record why.

| Level | Feel | Cast | Layout |
|---|---|---|---|
| L1 Training Day | Quiet morning | Unchanged | Unchanged |
| L2 Family Picnic | Families | 3 families (parent + toddler), 1 shopper, 1 sunbather | Families cluster mid-beach, hut at the far end, fewer palms |
| L3 Boardwalk Bustle | Busy promenade | 4 shoppers, 2 pier diners, 1 sunbather, no families | Benches and lamps in a row along the promenade, stalls close together |
| L4 Dog Day Afternoon | Sunbathers' strip | 4 sunbathers, 1 family, 2 shoppers, the dog | Rocks and parasols, open middle for the dog's home patch |
| L5 Three's a Crowd | Lunch rush | 2 diners and 3 shoppers around a single grill (no kiosk) | Grill centre stage, fewer parasols, bins spread wide |
| L6 Sunset Showdown | Everyone's out | Full mix including the seafood vendor | Widest spread, the two stalls near opposite ends |

1. No two of L3–L6 may share the same prop list or the same spawn counts.
2. Keep the existing `world.width`, twists, Bev and rival setup, and quests (change a quest only if it becomes impossible, and note it).
3. Leave starting clearance around the player spawn and keep crowd spacing valid (no overlapping people at start).

## Out of scope
- New art, code changes (data only; a code change is acceptable only if a test needs a new spawn option, and must be noted), Stage 2.

## Done when (acceptance)
- [ ] Check: L3–L6 have pairwise-different prop and spawn count signatures
- [ ] All level, quest, stall, crowd-spacing, crab and rival checks pass
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures. One wide screenshot per level 2–6 in the Report.

## Report

## Review notes
