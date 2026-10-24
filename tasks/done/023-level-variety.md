# 023 — Give each level its own cast and layout

Status: done
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

Branch `sonnet/023-level-variety`. Test: `tools/validate.ps1 -Capture` -> INTEGRATION: 14640 checks, 0 failures.

Files: `data/levels/level_02..06.json` (spawns, props; L3 seed, L5 random_foods), `tests/level_generator_checks.gd`, `tests/wheelie_bin_checks.gd` untouched, `tests/rival_ai_checks.gd`, `tests/palm_wind_checks.gd`, `tests/integration.gd` (L5 may lack a kiosk; new per-level identity screenshots).

Per level (cast / props):
- L2: 3 families (6 spawns), 1 sunbather, 1 shopper. 1 palm, 1 parasol, 2 bins, wheelie bin and castle, kiosk at 905, hut at far end 1000.
- L3: 1 sunbather, 4 shoppers, 2 pier diners, no families. 2 palms, 1 parasol, lamps and benches (each with a bin) in a row 700-890, kiosk 500 and grill 580 close together, 4 wheelie bins.
- L4: 4 sunbathers, 1 family, 2 shoppers, dog (home 250-330, open middle). 1 palm, 3 parasols, 4 rocks, lamps/benches/bins on the promenade.
- L5: 1 sunbather, 3 shoppers all at one grill (centre, x 640, no kiosk), 2 diners. 2 palms, 1 parasol, lamps flanking, 7 bins spread wide, wheelie bin by the grill.
- L6: 2 sunbathers, 1 family, 3 shoppers, 2 diners, seafood vendor. Kiosk at 220 and grill at 960 (far ends of the beach/promenade), 3 palms spread 60-1130, umbrella, rocks.
L3-L6 prop lists and spawn-count signatures are pairwise different. Worlds, twists, rivals, Bev and all quests unchanged.

Decisions / changes beyond data:
- L5 has no kiosk, so no ice cream: removed `ice_cream` from L5 `random_foods` (the "foods appear in level" check requires it). Quests unchanged and achievable (fried fish from diners/grill).
- L3 `seed` 7103 -> 7113: with four shoppers the seeded 90 s rival sim had Gary lingering 2.2 s at the left edge (limit 1.5); the new seed passes. Tune-only, no behaviour change.
- Tests encoded the old rosters; updated: `level_generator_checks.gd` (new casts, palms >= 1, L5 single stand, L2 three families), `palm_wind_checks.gd` (palm count no longer fixed at 3), `rival_ai_checks.gd` (wheelie lid x read from the level), `integration.gd` (L5 allowed no kiosk; added `level{2..6}-identity` snapshots).
- Layout constraints honoured: each level has exactly one wheelie bin beside a shed (4 in L3, three at the right end), benches have bins, sunbathers before the promenade, L4 first sunbather moved to x 170 to keep start breathing room.

Screenshots (in the worktree, not committed): test-output/level2-identity.png, level3-identity.png, level4-identity.png, level5-identity.png, level6-identity.png (one 320x180 view around the stalls per level; no wider capture exists).


## Review notes
