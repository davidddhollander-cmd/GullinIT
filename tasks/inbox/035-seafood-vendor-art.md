# 035 — Seafood vendor art (replace placeholder)

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-25

## Goal
The L6 seafood vendor (`seafood_vendor`, standing at the pier end near x 1235) still uses an early 16x32 placeholder: `assets/sprites/seafood_vendor.png`, a flat block body with no face, hands or broom. He looks out of place next to the generated cast. Replace him with proper generated pixel art.

## Who he is
A fishmonger guarding the pier end. He's very watchful, and when a gull comes close he winds up and swats it with a broom (`twist: "broom"` in `data/targets.json`). He does not sell from a stall. The fish & chips stand has its own vendor; he must look clearly different from that vendor, the pier diners and the shoppers.

Suggestion: a sturdy older fishmonger in a white cap or flat cap, a striped or rubber apron over a jumper, wellies, and a broom.

## Requirements
1. Generate (built-in image generator) a full-body character matching the shoppers' pixel density: 128x128 frames, about 40 px art height, used at `visual_scale` 0.5 (see `kiosk_customer` in `data/sprites.json`). Use the same outline weight and palette style.
2. Animations, keeping the existing names so gameplay picks them up without code changes:
   - `idle` (holding the broom, scanning the sky)
   - `windup` (broom raised; a readable warning to the player)
   - `swat` (broom swing)

   Also add `walk`, `alert` and `angry` for later use. Make the broom clearly visible in every pose.
3. Replace the `seafood_vendor` entry in `data/sprites.json` so it points at the new sheet: frame size, `visual_scale`, `art_height` and any foot offset. His feet must stand on the pier boards where the old sprite stood. Keep the old placeholder file in place but unused (don't delete art).
4. Keep the untouched source artwork and prompts in `assets/reference/seafood-vendor-v1/`. Put a preview in `assets/previews/` showing him beside the fish & chips vendor and a pier diner at in-game size.
5. No gameplay changes beyond the sprite entry. AGENTS.md applies: generated art only, no code-drawn bodies, faces, limbs or broom, not even as placeholders.

## Done when (acceptance)
- [ ] The new sprite sheet and `data/sprites.json` entry are in place; `idle`, `windup` and `swat` play in game
- [ ] A capture of the L6 pier end in `test-output/` shows him standing on the boards at the same scale as the diners
- [ ] Art-check tests cover the new entry
- [ ] `tools/validate.ps1`: 0 failures

## Report

## Review notes
