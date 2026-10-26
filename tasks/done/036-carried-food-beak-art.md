# 036 — Carried-food beak art (rival mug clarity)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-26

## Goal
Playnotes 25 Oct: "Should be clearer when you can mug a rival gull — the food in their beak is not clear enough." At 320x180 the food in a gull's beak is the normal ground-food sprite shrunk to a few pixels, so it melts into the gull. Give carried food its own bold, readable "in the beak" sprites.

## Context
- `scripts/gull.gd` ~line 556: `carry_item.texture` is the food's `idle` frame from `Config.frames(definition.sprite)`, cropped to one half and scaled to the food's `size` from `data/foods.json`. Rivals and the player share this path.
- Carry body/beak overlay: `data/gull_carry_art.json` (tasks 029/031). Don't change those.
- AGENTS.md: generated art only (built-in image generator), no code-painted pixels.

## Requirements
1. For every food id a gull can carry (entries in `data/foods.json`), generate a small carried version at in-game size (roughly 6–10 px across): chunky silhouette, 1 px dark outline, one bright highlight, high contrast against white/grey gull plumage. Same outline weight as the cast.
2. Put them on one sheet, e.g. `assets/sprites/carried-food-v1.png`, plus `data/carried_food_art.json` mapping food id -> region (and an optional pixel offset). Do not wire it into `gull.gd`; Sonnet does that in task 039.
3. Keep untouched sources and prompts in `assets/reference/carried-food-v1/`. Put a preview in `assets/previews/` showing each item in a herring-gull beak (existing carry frames) at 1x and 4x.
4. Add an art check in `tests/` that every carryable food id has a region in the new data file and the region lies inside the sheet.

## Out of scope
- Gameplay code, `gull.gd`, ground food sprites.

## Done when (acceptance)
- [x] Sheet + `data/carried_food_art.json` cover every carryable food id
- [x] Preview shows items clearly readable at 1x in the beak
- [x] Art check added and wired into `tests/integration.gd`
- [x] `./tools/validate.ps1`: 0 failures

## Report

- Files changed: added the complete untouched ImageGen source and exact prompt/provenance under `assets/reference/carried-food-v1/`; added the 48×36 native production atlas `assets/sprites/carried-food-v1.png`; added `data/carried_food_art.json` with a bounded region, beak offset and source cell for all 12 entries in `data/foods.json`; added lossless/no-mipmap import metadata; added deterministic preparation and herring-gull preview tools; added `assets/previews/carried-food-v1-comparison.png`; added `tests/carried_food_art_checks.gd` and wired it into `tests/integration.gd`.
- Tests: `tools/validate.ps1 -Godot C:\Users\david\Documents\ChatGPT\GullinIt\.tools\Godot_v4.7.2-stable_win64_console.exe` — `INTEGRATION: 14071 checks, 0 failures`.
- Decisions: the generated sheet is an exact 4×3 grid. The production atlas uses twelve 12×12 cells with 6–10 px-wide silhouettes, hard alpha, a dark navy outline and a warm or white highlight. The preparation step only thresholds alpha, crops, nearest-neighbour reduces and packs generated pixels; it does not paint or recolor art. The preview composes the real herring carry body and upper-beak overlay, showing each food at 1× and 4×. Per-food offsets bias the readable silhouette forward from the bill.
- Not done: gameplay wiring in `gull.gd` and the mug-range shine remain intentionally out of scope for dependent task 039.
- Branch: `codex/036-carried-food-beak-art`
- Implementation commit: `c706367`
- Completion bookkeeping: branch HEAD after this report commit (reported in the handoff).

## Review notes
