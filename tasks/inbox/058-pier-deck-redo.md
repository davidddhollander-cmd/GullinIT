# 058 — Pier deck redo: a pier people walk on

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 055 (merged: shoreline and sand)
Created: 2026-10-29

## What David will see if this works
At the right end of levels 3-6 the walkway turns into a proper **wooden pier**: a planked deck that people, stalls and diner tables stand on, a chunky front beam, thick pilings with cross-bracing down into the sand, and a simple railing behind the walkers. It reads as a pier at a glance, sits next to the existing promenade without a jump, and is in the same calm 1990s arcade style as the new sky, sea, shoreline and sand.

## Why 055's pier failed (read this first)
See `tasks/done/055-beach-ground-textures.md`, Review notes. In short:
- It was a **side-on rail on thin stilts**: a 2 px deck lip, then a fascia, then 6 px posts every 64 px standing in dry sand. Nobody can walk on it; people at ground y 160 stood on the fascia. The 055 spec asked for that shape, so this brief changes the shape.
- The **structure was rebuilt in code** from the spec (plank seams, posts, nails placed by the prep script), so it looked flat and programmatic. This time the generated plate is the source of the forms. The prep script may crop, quantise, cut one repeat bay out of the plate and repeat it, but it must not draw planks, posts, bracing or rails itself.

## Context
- Levels 3-6: world width 1280, `promenade_start` 430, `pier_start` 920 (`data/levels/*.json`). Ground y is 160 for everyone: shoppers, vendors, gulls on foot, bins, the fish-and-chips stall and the pier-diner tables (`assets/sprites/pier-diner-*`).
- The promenade is still the old drawn boardwalk: `c18e68` boards at y 151-164 with `a57b5c` joints every 16 px (`scripts/beach.gd` `_draw()`). The pier deck must line up with it at x 920.
- The new shoreline (y 120-139) and sand (y 140-179) from 055 are drawn under the pier: `assets/sprites/beach-ground-v1/`. Anything transparent in the pier shows that sand.
- Dusk: the game multiplies all ground by `GROUND_DUSK` (0.82, 0.66, 0.72). Bake no lighting or glow, no pure white.
- Style and rules: `assets/reference/background-v2/PROMPTS.md`, `assets/reference/beach-ground-v1/PROMPTS.md`, `docs/RETRO_ENVIRONMENT_STYLE.md`, `docs/ART_AUDIT_2026-10-27.md` (native 1x, binary alpha, no half-pixels).

## Runtime specs (native 1x)
| Asset | File | Size | Screen rows (y) | Repeat |
|---|---|---|---|---|
| Pier deck | `pier-deck-320x29.png` | 320 x 29 | 151-179 | seamless every 320 px from `pier_start`, one bay every 32 px |
| Pier railing | `pier-railing-320x14.png` | 320 x 14 | 137-150 | seamless every 320 px, posts aligned with the pilings |
| Pier start | `pier-start-16x43.png` | 16 x 43 | 137-179 | once, its right edge at `pier_start` |

**Pier deck (rows inside the 29 px tile):**
- Rows 0-13 (y 151-164): the **walking surface**, seen slightly from above so the top of the boards shows. Boards run across the pier, so seams are vertical, roughly every 8 px. Weathered driftwood: cooler grey-brown than the promenade's warm `c18e68`, with a lighter top edge, a few grain dashes, the odd nail head and the odd slightly lighter or darker board. Rows 6-11 (around y 160, where feet stand) stay the calmest.
- Rows 14-18 (y 165-169): a **chunky front beam** (fascia) in a darker wood with bolt heads at each piling.
- Rows 19-28 (y 170-179): **substructure**, transparent between pieces: one thick piling (6-8 px wide, lit side and shaded side) every 32 px, with simple diagonal cross-bracing between pairs of pilings, and a small hard-edged darker footing where each piling meets the sand.
- Opaque everywhere in rows 0-18; binary alpha in rows 19-28.

**Pier railing:** a top rail and one mid rail with a post every 32 px (aligned with the pilings), all transparent between. It draws behind the walkers. Keep it light and thin (top rail 2 px, mid rail 1 px, posts 2-3 px) so it never competes with characters' heads and arms.

**Pier start:** where the promenade ends and the pier begins: a thicker end post, the railing's first post and a 1-2 px step from the promenade boards to the pier deck. Its right edge sits at `pier_start`.

**Palette and detail:** 10 colours or fewer across the three files, no dither, no pure white. Detail pixels (grain, nails, bolts, board variation) at 12% or less of the opaque pixels in the deck surface rows. The pier must be visibly different from the promenade (cooler, weathered, with pilings) but no busier than the sand.

## Ready-to-paste image-generator prompts
Generate wide opaque plates; the prep script crops one 32 px bay and repeats it. Save every generated image unchanged in `assets/reference/pier-deck-v2/`.

### 1. Pier deck source
Use case: stylized-concept. Asset type: source plate for a walkable wooden seaside pier deck in a 2D side-scrolling game. Use the supplied sand, sea and sky only as colour and style references. Create one extremely wide straight-on view of an old wooden seaside pier seen from the side and very slightly from above, so the top surface of the deck boards is clearly visible as a band people can stand on. The boards run across the pier with thin dark gaps between them, weathered grey-brown driftwood with a lighter top edge, a few short grain lines and an occasional nail head. Under the deck, a chunky darker front beam with a bolt at each piling. Below the beam, thick round wooden pilings evenly spaced, each lit on its left side and shaded on its right, joined by simple diagonal cross-braces, standing in flat pale-gold sand with a small darker footing where each enters the sand. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained palette; calm and readable. Plain flat pale-gold sand behind the pilings so it can be removed. No railing, people, lamps, benches, boats, water under the pier, barnacles, seaweed, ropes, shadows as gradients, glow, black outlines, perspective vanishing, blur, antialiasing, dithering, text, border or watermark.

### 2. Pier railing source
Use case: stylized-concept. Asset type: source plate for a simple wooden pier railing in a 2D side-scrolling game, matching the supplied pier deck. Create one extremely wide straight-on strip of a plain old wooden seaside railing: a top rail, one thinner middle rail and evenly spaced square posts, in the same weathered grey-brown driftwood with a lighter top edge. Thin and light, nothing ornate. Plain flat pale turquoise background so it can be removed. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained palette. No deck, pilings, people, lamps, signs, ropes, nets, lifebuoys, glow, black outlines, blur, antialiasing, dithering, text, border or watermark.

### 3. Pier start source
Use case: stylized-concept. Asset type: source plate for the landward end of a wooden seaside pier in a 2D side-scrolling game, matching the supplied pier deck and railing. Show the point where a warm brown promenade boardwalk on the left meets the weathered grey-brown pier deck on the right: a single thick end post rising slightly above the railing, the first railing post, and a small one-step rise from the boardwalk onto the pier deck, with one piling below. Plain flat pale-gold sand and pale turquoise sky behind so they can be removed. Same style, palette and exclusions as the pier deck.

## Requirements
1. Generate the three plates (a second try of any that fails the checks) and store them unchanged with a `PROMPTS.md` in `assets/reference/pier-deck-v2/`.
2. Write `tools/prepare_pier_deck_v2.py` (model: `tools/prepare_beach_ground_v1.py`). Crop and shrink with nearest-neighbour, quantise to a fixed palette without dither, key out the flat background to binary alpha, and build the 320 px tiles by **cutting one clean 32 px bay from the plate and repeating it**. Allowed: crop, quantise, align to the grid, cut and repeat plate pixels, wrap. Not allowed: drawing planks, posts, bracing, rails or nails in code. Measure the palette count, detail density and alpha, print them, and exit non-zero on a breach.
3. Runtime PNGs go to `assets/sprites/pier-deck-v2/`. Do not touch `scripts/`, `data/`, `tests/` or the Art Lab; Claude wires it in after David's review.
4. Previews (nearest-neighbour, 1x and 4x), composited over the real background-v2 sky, sun and sea frame 1 and the 055 shoreline and sand at their game rows:
   - `pier-deck-v2-join-320x180.png`: the promenade (old drawn boards: `c18e68` y 151-164, `a57b5c` joints every 16 px) ending at screen x 160, with the pier from there to the right edge. Put real sprites on the deck at y 160 for scale: a shopper or vendor, a bin, and a pier-diner table set if one fits. Do not code-draw characters.
   - `pier-deck-v2-pier-320x180.png`: a full screen of pier with the same sprites.
   - The same two with every ground pixel multiplied by (0.82, 0.66, 0.72) and the dusk sky, named `...-dusk-...`. For the dusk sky, reuse the colours in `assets/shaders/dusk_tint.gdshader`, or a screenshot of the Art Lab with `G` and `D` on.
   - A version of each without the railing, so David can choose.
   - `pier-deck-v2-tile-check.png`: the deck and railing repeated three times (960 px wide).
5. Run `./tools/validate.ps1` (no new failures expected; nothing in the game changes).

## Out of scope
- Any game code, data or Art Lab change (Claude does the wiring).
- The promenade (stays the old drawn boards), the end of the pier at the world's right edge, lamps, benches, signs, water under the pier.

## Done when (acceptance)
- [ ] Three plates preserved unchanged with `PROMPTS.md`; three runtime PNGs at exactly 320x29, 320x14 and 16x43
- [ ] The deck's top surface is a visible walkable band (rows 0-13) and sprites at y 160 clearly stand on it in the previews
- [ ] Pilings, bracing, beam and rails come from the generated plate; the prep script only crops, quantises, cuts, repeats and wraps
- [ ] Seamless every 320 px; one bay every 32 px; railing posts line up with the pilings
- [ ] 10 colours or fewer, binary alpha, no `ffffff`, no dither; deck-surface detail 12% or less; the prep script prints and enforces these
- [ ] Day and dusk previews of the promenade-to-pier join and of a full pier screen, with and without the railing, at 1x and 4x
- [ ] Reads as a pier at a glance, visibly different from the promenade, no busier than the sand
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] Status set to `done (awaiting David)`

## Report

## Review notes
