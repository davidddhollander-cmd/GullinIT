# 035 — Seafood vendor art (replace placeholder)

Status: done
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
- [x] The new sprite sheet and `data/sprites.json` entry are in place; `idle`, `windup` and `swat` play in game
- [x] A capture of the L6 pier end in `test-output/` shows him standing on the boards at the same scale as the diners
- [x] Art-check tests cover the new entry
- [x] `tools/validate.ps1`: 0 failures

## Report

**Files changed:** `assets/reference/seafood-vendor-v1/` (two untouched final built-in ImageGen source sheets, exact prompts and README), `assets/sprites/seafood-vendor-generated-v1.png` plus lossless import metadata, `assets/previews/seafood-vendor-v1-comparison.png` plus import metadata, `data/sprites.json`, `tests/staff_art_checks.gd`, and `tools/prepare_seafood_vendor.gd` plus UID. The legacy `assets/sprites/seafood_vendor.png` remains present and unchanged but is no longer referenced by the sprite registry.

**Tests:** `./tools/validate.ps1 -Capture` — **13,904 checks, 0 failures**. `git diff --check` also passed. The rendered L6 review capture is `test-output/seafood-vendor-l6-pier-end.png`.

**Decisions:** Built-in ImageGen produced a sturdy older fishmonger with a cream fisherman beanie, grey moustache, forest-green jumper, mustard rubber apron, charcoal trousers, red wellies and a generated wooden/straw broom visible in every pose. The palette and broad silhouette clearly separate him from the white-apron/blue-shirt fish-and-chips stall vendor, both pier diners and the shoppers. The final atlas contains 4 idle, 2 windup, 2 swat, 6 walk, 2 alert and 2 angry frames on 128×128 cells at `visual_scale: 0.5`, `art_height: 40`, `sprite_offset_y: -26`. The preparation tool only copies connected generated figure-and-broom pixels, hardens alpha, crops, nearest-resizes, aligns the sole baseline and packs/composites images; it draws no character or broom pixels. A targeted built-in background-extraction pass supplied genuine transparency for the walk source; its exact prompt is preserved.

The checkout was clean at start, so no new stash was needed. The previously preserved cafeteria work remains untouched in `stash@{0}`. As requested, the branch was created directly from local `main` commit `51616e7` without checking out or modifying the `GullinIt-main` worktree.

**Not done:** No gameplay, target, level or tuning code/data changed beyond the `seafood_vendor` sprite entry. The newly supplied `walk`, `alert` and `angry` clips are registered for later use, as requested.

**Branch:** `codex/035-seafood-vendor-art`

**Implementation commit:** `1133534` (`Replace seafood vendor placeholder art`). The task-report move is committed separately after this report.

## Review notes
