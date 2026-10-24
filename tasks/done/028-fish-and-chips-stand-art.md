# 028 — Fish & chips stand and vendor (art)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 24 Oct: "there's no artwork for grill or fish n' chip stand." Pier diners currently buy fried fish at the hot-dog stand. Decision: a **new fish & chips stall** with its own vendor sells fried fish; the hot-dog stand stays hot dogs only.

## Requirements
1. Generate (built-in image generator) a fish & chips stall matching the existing kiosk and hot-dog stand: the same footprint (52x56 body), counter height, serving window and sign style ("FISH & CHIPS" sign in the runtime-sign style of `stand-sign-hot-dogs-runtime-v2.png`).
2. Generate a full-body fish & chips vendor at normal adult scale, matching the existing vendors (`vendor_art.json`, vendor-hotdog-full-body-v3). Shown through the serving window, lower body hidden behind the counter (AGENTS.md). Idle, prepare and serve poses like the other vendors.
3. Keep source artwork and prompts in `assets/reference/fish-chips-stand-v1/`. Previews in `assets/previews/`.
4. Pixel density: match the characters that "hit the mark" (shoppers and vendors at `visual_scale` 0.5, same outline weight). Don't invent a new density.
5. Register the sprites in `data/sprites.json` / `data/vendor_art.json` under new ids (`fish_chips_stand`, `vendor_fish_chips`). Wiring the stall into gameplay (`stall_service`, the diner's `purchase_stall_type`, level placement) is a follow-up Sonnet task; don't change gameplay code.

## Done when (acceptance)
- [x] Stall and vendor sprites and art entries exist; a preview image shows them next to the kiosk and hot-dog stand at in-game size
- [x] Art-check tests (vendor/stall art checks) cover the new ids
- [x] `tools/validate.ps1`: 0 failures

## Report

- Files changed: added four untouched ImageGen source PNGs and prompt records under `assets/reference/fish-chips-stand-v1/`; added native stall, roof-sign, eight-pose base vendor and twelve-pose final vendor runtime assets plus import metadata; registered `fish_chips_stand` and `vendor_fish_chips`; added deterministic import/preview tools; extended vendor and retro-environment art checks; added `assets/previews/fish-chips-stand-v1-comparison.png`.
- Tests: required Godot import completed successfully. Direct integration run: `INTEGRATION: 12689 checks, 0 failures`. `tools/validate.ps1`: `INTEGRATION: 12689 checks, 0 failures`.
- Decisions: used a distinct middle-aged fish-and-chips vendor at the established `visual_scale` 0.5 and 80-pixel source-art height. Preserved complete full-body source art and clips it only in the preview/runtime convention. Kept the 52x56 body separate from the 256-pixel runtime roof sign, matching the existing stall pipeline. No gameplay code was changed.
- Built-in image generator prompts and reference roles are recorded in `assets/reference/fish-chips-stand-v1/PROMPTS.md`.
- Branch: `codex/028-fish-and-chips-stand-art`
- Implementation commit: `3f2b152`
- Completion bookkeeping: branch HEAD (reported in handoff after this report commit)

## Review notes
