# 053 — Sunbather lying-down shoo animation

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-28

## What David should see if this works
When a gull keeps pecking a sunbather's bag, the sunbather **lies there and waves an arm at the gull** (grumpy, still half asleep) before they sit up. Today they just lie perfectly still, then get up. It should read as "go away!" without the sunbather leaving the towel.

## Goal
Playnotes 28 Oct: sunbathers wake slower and start shooing gulls while lying down first. The behaviour is already in the game (`shoo_left` in `scripts/target.gd`, `SunbatherArt.shoo_pose`): from the second bag peck the sunbather plays a `lie_shoo` clip for 0.7 s, then (on the fourth peck) rises. Until the clip exists, the resting pose shakes 1 px as a stand-in. This task provides the art.

## Context
- Sunbather sheets come from `AdultPixelArt.frames(false, female, blue)` (4 variants: male/female × red/blue); resting pose is `rest`, getting up is `rise` (7 frames). See `docs/SUNBATHER_ART.md`.
- The clip must be named `lie_shoo`. `SunbatherArt.shoo_pose` plays it by phase (all frames across 0.7 s), un-flipped like `rest`, so draw it facing the same way as `rest`.

## Requirements
1. For all four variants, generate `lie_shoo` with the built-in image generator: same lying pose, towel and silhouette as `rest`, with one arm lifting and waving side to side, head turned slightly toward the viewer, annoyed face. 4–6 frames, loop-friendly. The body stays on the towel in every frame.
2. Register the clip for each variant in the sunbather atlas data (and wherever `rest`/`rise` are registered) so `sprite.sprite_frames.has_animation(&"lie_shoo")` is true.
3. Same pixel grid, outline weight and palette as the existing sunbathers (cast art standard in task 051 applies). Keep untouched sources and prompts in `assets/reference/sunbather-shoo-v1/` and put a preview in `assets/previews/` (rest vs shoo, 1x and 4x).
4. AGENTS.md: generated art only; code may crop, align and pack but must not draw bodies, faces or limbs.

## Out of scope
- Behaviour/timing (already in code), standing-up animation, other characters.

## Done when (acceptance)
- [ ] `lie_shoo` exists for all four sunbather variants and plays in game after the second bag peck
- [ ] Preview shows the wave clearly at 1x
- [ ] Art check: every variant has `lie_shoo` with 4–6 frames inside its sheet
- [ ] `./tools/validate.ps1` passes with no new failures

## Report

## Review notes
