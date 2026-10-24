# 027 — Smaller casts; no overlapping props

Status: inbox
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

## Review notes
