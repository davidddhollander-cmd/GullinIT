# 039 — Clear "you can mug this rival" cue

Status: inbox
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

## Review notes
