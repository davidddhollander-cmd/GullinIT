# 028 — Fish & chips stand and vendor (art)

Status: inbox
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
- [ ] Stall and vendor sprites and art entries exist; a preview image shows them next to the kiosk and hot-dog stand at in-game size
- [ ] Art-check tests (vendor/stall art checks) cover the new ids
- [ ] `tools/validate.ps1`: 0 failures

## Report

## Review notes
