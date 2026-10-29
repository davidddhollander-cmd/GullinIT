# 056 — Restaurant table, chairs and pier fence regenerated, sharp

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none (the Art Lab entries from the pier-restaurant-props-v1 review are already in `data/art_lab.json`)
Created: 2026-10-29

## Scope update (David, 2026-10-29)
David also sent **the pier wire fence back**: it needs the same regeneration. Everything below applies to both the table set and `pier-wire-fence-v1.png` (72x24, repeatable). For the fence, "chunky" means thick posts and a thick, clearly readable wire (2 px where it carries the read, with simple stepped sag, not a thin diagonal 1 px line that breaks into dots), and the tile must still repeat seamlessly: put two copies side by side in the Art Lab entry to prove the join. Output `pier-wire-fence-v2.png`; change the `PIER WIRE FENCE` Art Lab entry's candidate to it. Keep the restaurant as it is (David is happy with it).

## What David should see if this works
The restaurant table with two chairs, and the pier fence, look **as crisp and chunky as the beach chairs and food stands**: clear flat colour areas, straight 1 px outlines, no speckle or grain. Put it next to the stand and the beach chair in the Art Lab: does it belong?

## Why this task exists
David reviewed `pier-restaurant-props-v1/restaurant-table-chairs-v1.png` in the Art Lab and rejected it as unusably grainy. What the file is: 60x34, only 483 opaque pixels, so every chair slat and table edge is a 1 px feature, and the generator's slightly noisy source turned into speckle when it was nearest-reduced. The restaurant (3.2% isolated single pixels) and the stands are fine; the table set is the problem. The prompts for this set never asked for crispness, and an image generator will not give it unless told.

## Requirements
1. Regenerate the table and two chairs with the built-in image generator. Same idea (small square wood café table, two simple slatted chairs with muted teal seats, no umbrella, no people, no floor, no text), same palette as the existing pier, stands and beach chairs.
2. **Put the sharpness spec below in the prompt**, word for word, and keep the exact prompt in `assets/reference/pier-restaurant-props-v1/PROMPTS.md` (add a "Table and chairs v2" section; keep v1).
3. **Design for the target size.** The set stays about 60x34 on screen and **keeps exactly the live pixel size (1 screen px per art pixel, like the stands and beach chairs)**. "Chunky" means **fewer, larger shapes made of those same pixels**, never bigger pixels: a chair is a seat block, a back block and two legs, not individual slats; the table is a top plane and a thick central post or four thick legs. Fewer shape edges means fewer isolated pixels. Shapes and fills are at least 2 px wide; only the outline and the occasional single highlight pixel may be 1 px (as on the live beach chair). The set should not look blobby: keep the chairs' backs and the table's legs readable as separate parts.
4. Prepare the runtime sprite with a **block-aware reduction**, not plain nearest-neighbour of a noisy source: generate the source on a large clean grid (for example each intended pixel as an 8x8 block), detect the grid, and take the **majority colour of each block**. Then map to the existing 16-colour union palette and clean up lone pixels (a pixel whose four neighbours all differ in colour and which is not part of an outline). Keep the full untouched source in `assets/reference/pier-restaurant-props-v1/`.
5. Output `assets/sprites/pier-restaurant-props-v1/restaurant-table-chairs-v2.png` (about 60x34, bottom-centre origin, hard alpha). Lossless import, nearest filter, no mipmaps. Update `manifest.json` and `tools/prepare_pier_restaurant_props_v1.py` (or add a v2 script).
6. In `data/art_lab.json` change the `RESTAURANT TABLE` entry's candidate to the v2 file. Do not touch `data/sprites.json` or gameplay.
7. AGENTS.md applies: generated art only. Code may crop, grid-sample, palette-map and clean up lone pixels; it must not draw the props.

## Pixel sharpness spec (paste into every prop and character prompt from now on)
> True low-resolution pixel art, designed on a pixel grid of about 60 by 34 pixels and shown with each pixel as a large, perfectly square block. Every pixel block is a single flat colour: no dithering, no noise, no film grain, no texture, no gradients, no anti-aliasing, no soft or blurry edges, no sub-pixel detail. Shapes are bold and simplified with straight edges. One clean, continuous outline exactly one pixel thick in a dark navy, with no broken or doubled outline pixels. Use at most 12 flat colours. Large flat colour areas with simple two-step shading: one light, one base, one shadow. Shapes and fills are at least 2 pixels wide; only the outline and occasional single highlight pixels may be 1 pixel.

## If the first source is still grainy
Generate up to three sources and keep the cleanest, with the measurements of every attempt in the Report. Do not paint over or hand-edit a source to hide noise; AGENTS.md forbids drawn art. If none reaches the target, stop and say so in the Report (and what the generator did wrong) rather than shipping a grainy sprite.

## Measurements to report
For the new table set, the new fence, their v1 versions, the existing fish & chips stand and the beach chair: opaque pixel count, number and share of isolated single pixels (not on the outline), colour count, and the largest flat-colour area. The new set should show clearly fewer isolated pixels than v1 (v1: 99 of 483 = 20.5%) and no more than about 10%.

## Out of scope
- The restaurant (David has not asked for changes).
- Placing props in levels (a later task once all three are approved).
- Characters (the sharpness spec is also to be added to the prompts for 054, but that task is its own).

## Done when (acceptance)
- [ ] `restaurant-table-chairs-v2.png` exists, hard alpha, about 60x34, 16-colour union palette
- [ ] `pier-wire-fence-v2.png` exists, hard alpha, 72x24, repeats seamlessly (two tiles side by side in the Art Lab capture)
- [ ] Prompts with the sharpness spec saved in `PROMPTS.md`; untouched sources preserved
- [ ] The `RESTAURANT TABLE` Art Lab entry shows v2 beside the beach chair and the shopper; 1x and 4x captures in the Report
- [ ] Report lists the measurements above for v2, v1, the stand and the beach chair
- [ ] `./tools/validate.ps1`: 0 new failures
- [ ] Status `done (awaiting David)`

## Report

## Review notes
