# 029 — Gull carrying food in its beak (art)

Status: inbox
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
- [ ] Carry frames, anchors and overlays exist for every species; a preview shows each species carrying a chip, an ice cream and a hot dog
- [ ] `tools/validate.ps1`: 0 failures

## Report

## Review notes
