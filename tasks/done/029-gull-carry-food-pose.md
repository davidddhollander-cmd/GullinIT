# 029 — Gull carrying food in its beak (art)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 23 Oct: "Gull carrying food in beak needs slightly different sprite, now it's just the same food sprite pasted on top." Carrying should read as the gull gripping the food in its beak.

## Requirements
1. Generate beak-carry variants of the gull's fly, glide and walk frames for each species (herring, kittiwake, great black-backed, plus the rival tint base): head slightly raised, beak open around a held item. The food sprite still comes from the food art, but is placed in the beak at a per-frame anchor, with the beak's upper mandible drawn over it (a mask/overlay layer from the generated art, not code-drawn).
2. Add the per-frame beak anchor and overlay to `data/gull_art.json`.
3. Keep sources and prompts in `assets/reference/gull-carry-v1/`. Match the existing gull density (`visual_scale` 0.375; flag in the Report if it should move to the 2x grid later).
4. Wiring the carry pose in `gull.gd` is a follow-up Sonnet task; you may add a preview tool only.

## Done when (acceptance)
- [x] Carry frames, anchors and overlays exist for every species; a preview shows each species carrying a chip, an ice cream and a hot dog
- [x] `tools/validate.ps1`: 0 failures

## Report

- Files changed: added four untouched ImageGen sources and recorded prompts under `assets/reference/gull-carry-v1/`; added separate 13-frame carry and 13-frame generated upper-beak overlay atlases for herring, kittiwake, great black-backed and the neutral rival tint base; added measured per-frame anchors/overlay mappings to `data/gull_art.json` and the reproducible generated metadata in `data/gull_carry_art.json`; added import/mapping and preview tools; extended gull art checks; added `assets/previews/gull-carry-v1-comparison.png` with all four gull sets carrying a chip, ice cream and hot dog.
- Tests: required Godot import completed successfully. Direct integration run: `INTEGRATION: 12791 checks, 0 failures`. `tools/validate.ps1`: `INTEGRATION: 12791 checks, 0 failures`.
- Decisions: retained native 256-pixel cells and `visual_scale` 0.375. The generated bird frames are aligned to the existing production bounds; food remains separate and is drawn at measured bill-gap anchors; the generated upper-mandible pixels are cropped to a separate atlas for the final grip layer. The rival has a distinct pale, low-saturation generated base suitable for the existing tint shader. No gameplay code or carry-state wiring was changed.
- Density follow-up: do not move these carry variants to a 2x grid independently; they intentionally match the current gull production sheets. Revisit only as a coordinated migration of every gull animation so idle/dive/carry density remains consistent.
- Built-in image generator prompts and reference roles are recorded in `assets/reference/gull-carry-v1/PROMPTS.md`.
- Branch: `codex/029-gull-carry-food-pose`
- Implementation commit: `6a726c2`
- Completion bookkeeping: branch HEAD (reported in handoff after this report commit)

## Review notes
