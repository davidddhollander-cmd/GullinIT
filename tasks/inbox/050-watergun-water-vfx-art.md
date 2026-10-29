# 050 — Water-gun stream, muzzle flash and splash art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-29

## Goal
Replace the code-drawn placeholder water effects used by the level 4-6 water-gun teenager with generated pixel art, so shots, muzzle flashes and splashes read as part of the same hand-made world as the teenager sprite.

## Context
- Relevant files: `scripts/water_shot.gd` (`_draw` paints the placeholder stream), `scripts/effects.gd` (`water_splash`, `water_muzzle` emit placeholder droplets), `scripts/watergun_teen.gd`, `data/sprites.json`, `data/watergun_teen_art.json`.
- These are effects, not characters, so AGENTS.md's no-code-art rule for characters does not block them, but the final look should still come from the image generator.
- Shot speed is 170 px/s, hit radius 10 x 7 px (`data/tuning.json` -> `watergun_teen`).

## Requirements
1. A water-stream sprite (3-4 frames, pointing right, mirrored/rotated in code) about 12-16 px long on the 320x180 canvas.
2. A muzzle-flash puff (3 frames) anchored to the frame-1 muzzle positions in `watergun_teen_art.json`.
3. An impact splash (4-5 frames) usable both on sand and on a gull.
4. Add the sheets and entries to `data/sprites.json`, then switch `BeachWaterShot._draw` and `BeachEffects.water_splash`/`water_muzzle` to use them.

## Out of scope
- The teenager sprite sheets and his behaviour.

## Done when (acceptance)
- [ ] Generated art in `assets/sprites/watergun-teen-v1/` with preserved sources in `assets/reference/watergun-teen-v1/`
- [ ] Placeholder drawing removed
- [ ] Headless `tests/integration.tscn` passes with no new failures

## Report

## Review notes
