# 025 — Calmer lane switching; people pass behind bins

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 24 Oct:
- "characters switching lanes too chaotic, once they lane switched they should stay there for a few seconds so there's no chaotic switching with larger groups."
- "In second lane characters still walk over rather than behind the green bins — check and create a clearer rule for object placement."

## Context
- Lane/crowd offsets: `scripts/spawner.gd` `apply_spacing()` (`CROWD_OFFSETS`, `visual_offsets`, `placed`, the family ground-lane rule, bench walking footprints). Offsets are recomputed every frame, so people flip between lanes.
- Depth: prop z in `scripts/beach.gd` `_apply_prop_art` (ordinary props z 1, palms/huts z 2, stalls `FoodStall.DRAW_DEPTH`); people z in `scripts/target.gd`; crabs in `scripts/crab.gd` (rear lane below scenery). Wheelie bin type `BeachBackdrop.WHEELIE_BIN_TYPE`.
- Another agent works on `bench_visit.gd`, `beach_routine.gd` and the after-theft behaviour in `target.gd` (task 026). Keep your `target.gd` changes to depth only, and don't touch level JSON (task 027).

## Requirements
1. **Lane hold:** once a person's chosen offset changes lane (y differs), they keep that offset for at least 3 s (tunable `world.lane_hold`) unless it becomes blocked by a stationary person, a service lock or a bench footprint. Horizontal nudges within a lane may still ease each frame.
2. **Depth rule (write it down in `docs/CHARACTER_BEHAVIOUR_DRAFT.md`):** anything in the rear lane draws behind ground props whose base is in front of it (bins, wheelie bins, benches, chairs, castles, rocks); anything in the front lane draws in front of them. Decide by comparing the person's feet y with the prop's base y (y-sort), not by a fixed z per type. Palms, huts and lamps keep their current behaviour unless the rule fixes them too.
3. People in the rear lane must visibly pass behind a wheelie bin, and people in the front lane in front of it.

## Out of scope
- Level layout (027), bench and theft behaviour (026), new art.

## Done when (acceptance)
- [ ] Check: in a 6-person crowd sim, no person changes lane more than once per 3 s
- [ ] Check: a rear-lane walker crossing a wheelie bin has a lower draw order than the bin; a front-lane walker has a higher one
- [ ] Existing crowd-spacing, family-lane and bench footprint checks pass
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures. Screenshot of a rear-lane walker behind a wheelie bin, path in the Report.

## Report
Files: scripts/spawner.gd (lane hold via `lane_holds`, `_free_offset`, y-sort against `depth_props`), data/tuning.json (`world.lane_hold` 3.0), tests/crowd_spacing_checks.gd (+ lane hold and bin depth checks; the "offset clears" check now advances by lane_hold), tests/bin_depth_preview.gd/.tscn (screenshot scene), docs/CHARACTER_BEHAVIOUR_DRAFT.md (depth rule).
Tests: INTEGRATION: 14672 checks, 0 failures (capture run).
Screenshot: test-output/bin-depth.png (gitignored; in the worktree): rear-lane walker behind wheelie bin, front-lane walker in front.
Decisions: ground props (bin, wheelie_bin, beach_bench, beach_chair_blue, beach_castle, beach_rocks) keep z 1; a person overlapping a prop's x-extent (0.4 x sprite width + 6 px) gets z 0 if feet y is >4 px above the prop base y, else z 3. Lane hold ends early if the held lane has no free slot. Palms/huts/lamps/stalls unchanged. Target.gd untouched.
Branch: sonnet/025-lanes-and-bin-depth

## Review notes
