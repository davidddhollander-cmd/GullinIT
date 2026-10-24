# 027 — Smaller casts; no overlapping props

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 24 Oct:
- "too many characters clustering together after a while — start with reducing the number of characters per level."
- "in level 5, there's also objects overlapping, palm tree and bench on the right side."

## Context
- Level files `data/levels/level_02.json` … `level_06.json` (task 023 just gave each level its own identity; keep each level's feel). Checks that encode casts: `tests/level_generator_checks.gd`, `tests/integration.gd`, `tests/rival_ai_checks.gd`, `tests/crowd_spacing_checks.gd`.
- Prop footprints: `data/sprites.json` frame sizes (palm 44x62, bench 42x22, …) and offsets. Bench seats are registered by `scripts/bench_registry.gd`.
- Interview decision: **about a third fewer people** per level (e.g. L3 from 7 to 5, L6 from 9 to 6). A family is parent + toddler.
- Other agents are working on `spawner.gd`, `target.gd`, bench code and the dog (024–026). This task is data plus tests only.

## Requirements
1. Cut each level's cast by about a third (round sensibly; L1 unchanged), keeping each level's identity from 023. Every quest stays achievable and every bench level keeps at least one bench-capable shopper (appearance with seated art: kiosk_customer, shopper_mullet, shopper_sundress).
2. Fix the L5 palm/bench overlap and any other overlap in L1–L6.
3. Add a check: in every level, no two ground props' footprints (the sprite's visible base width) overlap horizontally when both sit in the same depth band, and no prop overlaps a stall. Tall background props (palms, lamps) may stand behind low ones only if their bases are at least 8 px apart.

## Out of scope
- Code changes to spawning or behaviour, new art, quests (unless one becomes impossible; note it).

## Done when (acceptance)
- [ ] Per-level before/after cast counts in the Report
- [ ] The prop-overlap check passes for all levels, and fails if you temporarily put the L5 bench back
- [ ] All level, quest, rival, crowd-spacing and stall checks pass
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures. Screenshot of L5's right side, path in the Report.

## Report
Review fix (L4): the cast is now 3 sunbathers (170, 365, 410) with their parasols restored (190, 385, 430), 2 stall shoppers and the dog, no family (still 6 spawns, dog index 5). Sunbathers sit outside the dog patch [250,330] and the start. `tests/level_generator_checks.gd` L4 type list updated; the one-child family test in `tests/integration.gd` now uses level 2 (L4 has no family). Re-run: `INTEGRATION: 12599 checks, 0 failures` (headless). The L4 line in the table and the "1 sunbather ... 1 family" wording below are superseded by this.

Branch `sonnet/027-smaller-casts-and-prop-overlaps`. Test: `INTEGRATION: 12605 checks, 0 failures` (headless and the `--capture` run).

Cast counts (spawns, family = toddler + parent, dog and vendor counted):
| Level | Before | After | Cast now |
|---|---|---|---|
| L1 | 4 | 4 | unchanged |
| L2 | 8 | 6 | sunbather, 2 families, ice-cream shopper (dropped family 3) |
| L3 | 7 | 5 | sunbather, 3 shoppers, 1 pier diner (dropped one shopper, one diner) |
| L4 | 9 | 6 | 1 sunbather, 2 shoppers (one per stand), 1 family, dog (dropped 3 sunbathers) |
| L5 | 6 | 4 | 2 hotdog shoppers, 2 pier diners (dropped sunbather and the stroller) |
| L6 | 10 | 7 | sunbather, 3 shoppers, 2 diners, seafood vendor (dropped the family and one sunbather) |

Props: L5 palm/bench fixed by moving the right bench 1225 to 1185 and its bin 1200 to 1160. Other overlaps found by the new check and fixed: L1 blue chair 470 to 474 (under parasol pole), L5 bin 870 to 860, L6 bin 1170 to 1160. Orphan parasols removed in L4 (190, 430).

New check `tests/prop_overlap_checks.gd` (registered in integration.gd): base span is read from the sprite's lowest opaque pixel rows; props within 10 px ground-line of each other must not overlap, tall props (palm, lamp, parasol, umbrella) need an 8 px clear gap, and nothing may overlap a stall in any band. It first failed on L1, L5 (x3) and L6 with the old data, and a built-in case (palm 1230 + bench 1225) proves it flags the old L5 clash.

Test updates for the new casts: `level_generator_checks.gd` (L2, L3, L4, L5 type lists, spawn indexes), `off_lead_dog_checks.gd` (dog spawn index 8 to 5).

Decisions: L4 keeps both stall shoppers because a stand with no station customer makes the spawner add one (an existing check failed otherwise); every bench level still has bench-capable shoppers (mullet, sundress, kiosk_customer); no quest changed or became impossible (L5 keeps both fish diners). L2/L4/L6 cuts are 25-35%, rounded to keep each level's identity.

Screenshot: `test-output/level5-right-side-props.png` (in the worktree; added to `tests/level5_checks.gd`). Not pushed.

## Review notes
