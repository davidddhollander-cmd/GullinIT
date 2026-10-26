# 039 — Clear "you can mug this rival" cue

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 036
Created: 2026-10-26

## Goal
Playnotes 25 Oct: players can't tell when a rival carries food worth mugging. Use the new carried-food art and add a small in-range cue.

## Context
- `scripts/gull.gd` ~line 556 (`carry_item`), `scripts/rival_gull.gd` (`carry_window`, `carried`, mug logic), `rival.mug_range` in `data/tuning.json`.
- `scripts/pickup_shine.gd` already makes the ground-food shine; reuse it.
- Task 036 adds `assets/sprites/carried-food-v1.png` + `data/carried_food_art.json`.

## Requirements
1. `carry_item` uses the carried-food region from `data/carried_food_art.json` when one exists (fallback: current behaviour).
2. While a rival holds food and the player is within `mug_range`, apply the `PickupShine` overlay to that rival's carried item (respect `juice.shine`).
3. Nothing else: no HUD text, no arrows.

## Done when (acceptance)
- [ ] A rival carrying food shows the new beak sprite, which shines when the player is in mug range
- [ ] Test covers region lookup and shine toggling by distance
- [ ] `./tools/validate.ps1 -Capture`: 0 failures, with a capture of a rival holding food in `test-output/`

## Report
- Files changed: scripts/gull.gd (carried-food atlas lookup `BeachGull.carried_food_art()`, `carry_item` uses it with per-food offset, fallback unchanged; new `carry_glint` overlay + `mug_cue` flag), scripts/rival_gull.gd (tick sets `gull.mug_cue` while it holds food and the player is within `rival.mug_range`), tests/integration.gd (anchor test includes food offset; new atlas-region and shine-by-distance checks).
- Tests: headless `tests/integration.tscn` 14081 checks, 0 failures. Capture run (`--capture`): 14081 checks, 1 failure "fish follows the eating hand toward the mouth" (unrelated to this task, only in rendered mode, not touched by this diff; headless passes).
- Capture: test-output/gull-carry-right.png and gull-carry-left.png (Gary holding ice cream with new sprite). Not committed (gitignored).
- Decisions: reused PickupShine unchanged, respecting juice.shine through PickupShine.overlay; shine uses wall clock with an instance-id seed. Native atlas art is drawn at body_scale, flipped by facing, no half-clipping. Player carrying also uses the new art. Did not run validate.ps1 wrapper (worktree had no .godot; ran import + equivalent commands manually).
- Branch: sonnet/039-rival-mug-cue
## Review notes

Reviewer (Claude Opus): moved the shine check after the beak-anchor scale check. Its 6 s of real-time waiting let the rival animation drift, which failed "scaled gull scales the beak anchor" in the rendered run.
