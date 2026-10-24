# 031 — Gulls use the beak-carry art while holding food

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 029
Created: 2026-10-24

## Goal
Codex delivered beak-carry frames for every gull (task 029, art only). Today the held food is just pasted on top of the normal frames. Switch to the carry frames whenever a gull holds food, so David can playtest it.

## Context
- Art data: `data/gull_art.json` (new carry animations, per-frame beak anchors, upper-beak overlay atlas) and `data/gull_carry_art.json`; sprites `gull-<species>-carry-v1.png` and `...-carry-v1-upper-beak.png` for herring, kittiwake, great black-backed and the rival tint base. Preview tool: `tools/gull_carry_preview.gd` shows the intended stacking (bird, then food at the anchor, then the upper beak on top).
- Gull drawing and held food: `scripts/gull.gd` (find where the carried food sprite is positioned; the player, rivals and Bev all use `BeachGull`). Rivals use the tint shader on the rival base.
- Species come from `data/species.json` / the gull picker.

## Requirements
1. While a gull carries food (player and rivals, all species), play the matching carry animation instead of fly/glide/walk, place the food at that frame's beak anchor, and draw the upper-beak overlay above the food, all following flip/facing and depth.
2. When the food is swallowed, dropped, mugged or stolen, switch back to the normal animation on the same frame.
3. Rivals keep their tint (the overlay must be tinted the same as the body). Bev, scaled up, scales the anchors too.
4. Keep the existing swallow timing, mug window and food-size rules.

## Out of scope
- New art; changing gull density or `visual_scale`.

## Done when (acceptance)
- [ ] Checks: each species switches to carry frames on pickup and back on swallow; food sits at the frame anchor (±1 px) with facing left and right; the overlay draws above the food; a tinted rival's overlay shares the tint
- [ ] All existing gull, rival, digestion and mugging checks pass
- [ ] One capture run at the end with 0 failures; screenshots of the player and a rival carrying food (left and right facing), paths in the Report

## Report
Files: scripts/gull.gd (carry sprites, `sync_carry`, `carry_for`), scripts/rival_gull.gd (`carry_source` callable), scripts/overlay.gd (removed the old pasted food draw; belly panel kept), tests/integration.gd (`carry_pose_checks`).
Tests: `INTEGRATION: 12864 checks, 0 failures` (capture run, GL compatibility).
Screenshots: test-output/gull-carry-right.png, test-output/gull-carry-left.png (player on the left, rival Gary on the right, both carrying ice cream).
Decisions:
- Carry data is read from data/gull_art.json (`carry` blocks); sprites.json does not contain it.
- Three child sprites on the gull (carry body, food, upper beak) copy the normal sprite's position, rotation, scale, flip, modulate and material (so the rival tint is shared); the normal sprite is hidden only while food is held. Sync runs at the end of `tick` and in `_process`, so swallow/drop/mug switch back on the same rendered frame.
- Grounded idle uses carry walk frame 7 (the idle source); airborne uses `fly` while climbing, otherwise `glide` (dive/windup/stun also glide).
- Anchors are multiplied by `body_scale` (Bev). Player food = first snack when not resting; rival food = `carried_food_id` while `carry_window` > 0.
Not done: nothing. Branch sonnet/031-wire-gull-carry-pose.

## Review notes
