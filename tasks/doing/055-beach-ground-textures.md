# 055 — Beach ground textures: shoreline, sand, promenade and pier

Status: doing
Author: Claude
Assignee: Codex
Depends on: none (background-v2 sky/sun/sea is already on `main`)
Created: 2026-10-29
Visual direction: **approved by David, 2026-10-29**

## Approved implementation clarifications
- The generated source plates remain the authority for the ground's visual forms. The prep script may crop, quantise, extract, reposition, wrap and repeat plate-derived bands and marks to meet the exact runtime grid, including plank and post spacing. It must not invent decorative ground forms with vector primitives or programmatic pixel painting.
- The roughly 18-level sand-luminance limit applies to the new close-neighbour `SAND_LIGHT` and `SAND_SHADE` colours. The existing `fff1cc` highlight and `d4ad78` shade are approved exceptions for sparse shell, pebble and legacy-compatible marks; they still count toward density caps.
- Seam validation is deterministic: every stamp that reaches either horizontal edge is wrap-placed on the opposite edge, the script asserts that no tracked stamp is clipped, and the 3x repeated tile-check must show no visual seam. Flat band colours must continue across the wrap; columns 0 and 319 need not be identical.
- Freeze the exact RGB palette near the top of the prep script before producing the final files. All source-derived colours snap to that list, with the existing per-file and 20-colour shared caps unchanged.
- Preview matrix and filenames are fixed as follows. Each after image has a matching old-ground before image at both sizes:
  - Beach: `beach-ground-v1-composite-320x180.png`, `beach-ground-v1-composite-1280x720.png`, `beach-ground-v1-before-composite-320x180.png`, `beach-ground-v1-before-composite-1280x720.png`.
  - Promenade: `beach-ground-v1-promenade-320x180.png`, `beach-ground-v1-promenade-1280x720.png`, `beach-ground-v1-before-promenade-320x180.png`, `beach-ground-v1-before-promenade-1280x720.png`. Show a promenade-focused screen immediately before the pier, with the pier edge at or just beyond the right edge.
  - Pier join: `beach-ground-v1-pier-320x180.png`, `beach-ground-v1-pier-1280x720.png`, `beach-ground-v1-before-pier-320x180.png`, `beach-ground-v1-before-pier-1280x720.png`. Centre the promenade-to-pier join at world x 920.

## What David will see if this works
The sea no longer ends in a flat pale stripe on a flat yellow rectangle. A **gentle shoreline** sits where the new sea meets the sand: a stepped foam edge, a little shallow water, then a band of darker wet sand that dries out into the beach. The **sand** gains one level of detail beyond flat colour: a few pebbles, shell flecks, faint ripple marks and footprint dimples. The **promenade boardwalk and the pier** get plank grain, nail heads, plank joints and, on the pier, support posts standing in the sand beneath the deck.

All of it is the same calm, polished 1990s arcade pixel style as the new sky and sea, and stays **quieter than the sprites**: a gull, a shopper or a chip on the ground always reads before any mark in the sand.

This task delivers the **assets only**, reviewed as previews. Nothing is wired into the game or the Art Lab by Codex; a follow-up Sonnet task does that once David likes the previews.

## Context
- Current ground is code-drawn rectangles in `scripts/beach.gd` `_draw()`: sand `e8c58e` from y 130 to 180, a 3 px `fff1cc` strip at y 130, 2x1 `d4ad78` specks, promenade `c18e68` y 151-164 with `a57b5c` joints every 16 px from `promenade_start`, pier from `pier_start` with light top lip `efb984` (y 157-158) and body `9b6650` (y 158-162). Stalls, bins, palms, people and gulls stand on ground y 160.
- Worlds are 800, 1040 or 1280 px wide (`data/levels/*.json`; default in `data/tuning.json` is `promenade_start` 640, `pier_start` 960). Levels 1-2 have no promenade or pier; levels 3-6 use promenade 430, pier 920, width 1280.
- Palette and style to match: `assets/sprites/background-v2/` (sky 320x80, sun 34x34, sea frames 320x40 with the horizon at y 94, so the sea covers y 94-133), `assets/reference/background-v2/PROMPTS.md` and `SEA_REDO_PLAN.md`, `assets/previews/background-v2-composite-320x120.png`. Prep model: `tools/prepare_background_v2.py` (fixed-palette quantise, no dither, the plate is a colour and style reference and marks are re-placed, not copied).
- Rules: `docs/RETRO_ENVIRONMENT_STYLE.md` (native 1x on the 320x180 grid, binary alpha, no feathered edges, shared environment palette), `docs/ART_AUDIT_2026-10-27.md` (no half-pixels, no resampled in-between scales). AGENTS.md: generate the art with the image generator; do not draw the ground in code. Code may only crop, quantise, re-place marks, tile and composite.
- Dusk: the game tints the sea (`SEA_DUSK` modulate) and sky (`dusk_tint.gdshader`) under the peach sunset. Ground must survive a multiplicative tint, so **bake no lighting, shadows-as-gradient or glow**, and use no pure white.

## Runtime specs (all at native 1x, no scaling in game)
Colours are sampled from the plates and then snapped to the fixed palette in `PALETTE` below. Alpha is **binary (0 or 255) everywhere**; no semi-transparent pixel.

| Asset | File | Size | Screen rows (y) | Repeat |
|---|---|---|---|---|
| Shoreline | `shoreline-320x20.png` | 320 x 20 | 120-139 | seamless every 320 px |
| Sand | `sand-320x40.png` | 320 x 40 | 140-179 | seamless every 320 px |
| Promenade | `promenade-320x14.png` | 320 x 14 | 151-164 | seamless every 320 px, plank joint every 16 px |
| Pier | `pier-320x22.png` | 320 x 22 | 157-178 | seamless every 320 px, post every 64 px |

All four are placed from world x 0 (shoreline, sand) or from `promenade_start` / `pier_start` (wood) and repeated, cropped to the world width. 320 divides every plank (16) and post (64) spacing, so the wood phase is always plank-aligned at its start. No tile may contain a feature so distinctive that its 320 px repeat is noticed; keep marks small and evenly scattered.

**Shoreline (320 x 20, y 120-139).** It overlaps the bottom of the sea frame (sea rows y 124-133) and the top of the sand.
- Rows 0-3 (y 120-123): fully transparent; the sea shows through.
- Rows 4-8 (y 124-128): sparse transparent-gap foam lacing, short 2-6 px stepped dashes of `FOAM`, at most ~25% coverage, drawn above the sea.
- Rows 9-12 (y 129-132): the shallow-water lip. Opaque pale aqua (`SHALLOW`) with a stepped scalloped lower boundary that wobbles +/-2 rows over about 40-60 px waves; a 1-2 px `FOAM_EDGE` (cream, never pure white) runs along that boundary.
- Rows 13-16 (y 133-136): wet sand, opaque `WET` with one darker `WET_DARK` stepped band; the wet/dry boundary is a stepped line with no dark outline.
- Rows 17-19 (y 137-139): damp-to-dry stepped fringe that ends in the exact base sand colour `e8c58e`, so the sand tile can start at y 140 with no visible seam.
- Net effect: the old pale line at y 130 is replaced by foam and shallows around y 129-132; the waterline stays near y 130.
- No dark outline anywhere at the sea/sand boundary. The only dark tones are `WET_DARK` and the sea's own `DEEP`.
- Optional (only if it stays very simple): 4 frames `shoreline-anim-01..04-320x20.png`, 300 ms each, 1.2 s loop. Only the foam rows 4-8 and the `FOAM_EDGE` run change; each foam piece moves at most 1 px or toggles one dash between frames; anim-01 is identical to the static file; frame 4 returns cleanly to frame 1. If the animation looks busy, deliver the static file only.

**Sand (320 x 40, y 140-179).** Base `e8c58e` with `fff1cc` highlights and `d4ad78` shade, plus one or two new close neighbours (`SAND_LIGHT`, `SAND_SHADE`).
- Detail: a few single-pixel pebbles (`SAND_SHADE` with a 1 px `SAND_LIGHT` top where it helps), tiny 1-3 px shell flecks (cream/`fff1cc`, one or two warm-coral flecks allowed), faint 4-8 px ripple-mark dashes in `SAND_SHADE`, and a few footprint dimples (2x2 or 3x2 `SAND_SHADE` pair, not a recognisable foot).
- Every mark's colour is within about 18 luminance levels (0-255) of its surrounding base, so marks stay below sprite contrast.
- The ground line must read at y 160: **rows 152-168 carry the lowest density (3% or less), no ripple dashes longer than 4 px and no band/edge crossing them.** All value changes (a gentle lighter sweep or ripple clusters) belong in rows 0-10 and 24-39 of the tile.
- No pale strip, horizon, or hard value band across the tile.

**Promenade (320 x 14, y 151-164).** Boards run across, so seams are vertical, a plank every 16 px (20 per tile).
- Base `c18e68`; joints `a57b5c` (the current seam colour), top row a lighter lip `d3a07a`, bottom row 13 a darker edge `a57b5c`.
- Detail: per plank, 2-5 short horizontal grain dashes (1-3 px, one step darker or lighter than base), a 1 px nail head 2 px in from each joint (`a57b5c`, not black). Use 4 plank variants (grain placement and one slightly lighter or darker plank) in a seeded sequence that wraps.
- Ground y 160 is inside the walkway; keep rows 8-12 calm so feet and shadows read.

**Pier (320 x 22, y 157-178).**
- Rows 0-1 (y 157-158): light deck lip `efb984` with a joint notch every 16 px.
- Rows 2-6 (y 159-163): fascia/body `9b6650` with one slightly lighter beam highlight row and nail heads every 32 px.
- Rows 7-18 (y 164-175): transparent except the support posts, every 64 px, 6 px wide, two tones (lit left 3 px `b5805f`, shaded right 3 px `85553f`), stepped cap where they meet the deck. Posts may have one or two 1 px grain flecks.
- Rows 18-21 (y 175-178): a hard-edged opaque contact shadow at each post foot (`SAND_SHADE`-based, about 10 x 3 px, stepped, binary alpha). No translucent shadow.
- The deck top stays calm because the ground line y 160 falls inside the deck rows.

**Shared palette** (`PALETTE`, fixed, no dither): the three sand colours `e8c58e`, `fff1cc`, `d4ad78`; the background-v2 tones used by the shoreline (`FOAM` 137,207,194 and `SHALLOW` about 96,191,190 from `FAR`); the wood colours above; plus the few new neighbours named above. Final counts: sand 6 colours or fewer; shoreline 9 or fewer; promenade 6 or fewer; pier 8 or fewer; **20 or fewer unique colours across all four files**. Record the exact RGB list in the prep script.

**Detail-density cap.** A "detail pixel" is any pixel that differs from the dominant base colour of its band (joints, lips and edges excluded). Sand: detail is **8% or fewer** of pixels (target 4-6%). Promenade and pier: **10% or fewer**. Shoreline: foam, shallows and wet-sand bands are structure and don't count, but foam lacing in rows 4-8 stays at or under 25% coverage. The prep script measures and prints these numbers and exits non-zero if any cap is exceeded.

## Ready-to-paste image-generator prompts
Generate each as a **wide opaque source plate** (not the final size); the prep script crops and re-places. Save every generated image unchanged in `assets/reference/beach-ground-v1/`.

### 1. Shoreline source
Use case: stylized-concept. Asset type: source plate for a shoreline strip in a 2D side-scrolling game. Use the supplied calm green-blue sea and the pale-gold sand only as colour and style references. Create one extremely wide, thin horizontal strip showing a gentle shoreline, as seen straight on. From top to bottom: deep teal-green sea, a narrow band of pale shallow aqua water, a small stepped cream-white foam edge that wobbles gently left and right in broad waves, a band of slightly darker damp wet sand, then dry pale-gold sand. Keep the foam sparse and simple, with a few short 2-6-pixel-equivalent foam dashes just above the waterline and generous gaps. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained palette, calm and low in detail. Keep the foam cream rather than pure white. Opaque rectangle. No dark outline or dark line at the waterline, gradient, glow, spray, large breaking waves, rocks, seaweed, shells larger than a pixel or two, people, footprints, boats, birds, sky, text, UI, border, watermark, blur, antialiasing or dithering.

### 2. Sand source
Use case: stylized-concept. Asset type: seamless-style sand texture source plate for a 2D side-scrolling game. Use the supplied pale-gold sand colours only as a palette reference. Create one extremely wide, flat, top-lit beach sand texture in pale gold with a slightly lighter cream shade and a slightly darker tan shade. Add sparse, tiny, quiet details with generous empty space between them: a few single-pixel-equivalent pebbles, a few 1-3-pixel cream shell flecks, a few faint short ripple-mark dashes, and a few small soft-edged footprint dimples that are only simple paired dark-tan marks. Keep every mark low contrast so the sand reads as almost flat colour. Keep the marks evenly scattered, with no large clusters. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained palette. Opaque rectangle. No horizon, water, foam, wet patch, seaweed, crabs, footprints that look like feet, bottles, litter, large rocks, strong shadows, gradient, glow, vignette, dense noise, grain, uniform rows, blur, antialiasing, dithering, text, border or watermark.

### 3. Promenade boardwalk source
Use case: stylized-concept. Asset type: source plate for a wooden promenade boardwalk strip in a 2D side-scrolling game. Create one extremely wide, thin, straight-on strip of warm medium-brown wooden boardwalk planks. Each plank is the same width, a little wider than the strip is tall, with a thin darker vertical joint between planks and a slightly lighter top lip along the upper edge and a darker lower edge. Add quiet detail: two to five short horizontal wood-grain dashes per plank, and one tiny nail head near each end of each plank. Vary a few planks very slightly lighter or darker. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained warm palette. Keep detail subtle and below sprite contrast. Opaque rectangle. No dark outline, black, knots larger than a pixel or two, cracks, rust, puddles, leaves, litter, railings, people, gradient, glow, perspective, blur, antialiasing, dithering, text, border or watermark.

### 4. Pier deck source
Use case: stylized-concept. Asset type: source plate for the front face of a wooden pier deck with support posts, for a 2D side-scrolling game. Create one extremely wide strip, seen straight on. Along the top, a narrow pale warm-gold deck lip with a small notch where each plank joint falls. Beneath it, a taller warm reddish-brown fascia beam with one slightly lighter highlight line and a tiny nail head at regular intervals. Below the fascia, evenly spaced round wooden support posts, each lit on its left half in a lighter brown and shaded on its right half in a darker brown, with a stepped cap where it meets the deck and a small flat dark-tan contact shadow at its foot. Use a plain flat pale-gold sand colour behind the posts so it can be removed. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat colour clusters and a restrained palette. Keep detail quiet. No dark outline, black, water, barnacles, seaweed, ropes, lamps, railings, boats, people, birds, gradient, glow, blur, antialiasing, dithering, text, border or watermark.

## Requirements
1. Generate the four source plates with the image generator (plus a second try of any plate that fails the checks) and store them unchanged in `assets/reference/beach-ground-v1/` as `shoreline-source.png`, `sand-source.png`, `promenade-source.png`, `pier-source.png`, with a `PROMPTS.md` in the background-v2 style that lists the four prompts and any runtime preparation adjustments.
2. Write `tools/prepare_beach_ground_v1.py`, modelled on `tools/prepare_background_v2.py`:
   - crop the plate to the target aspect and shrink to the native size with nearest-neighbour; quantise to the fixed `PALETTE` without dither; binarise alpha;
   - for sand and wood, build the base (bands, joints, lips) from the plate's colours, then collect the plate's small marks as stamps and re-place them with a seeded, wrap-aware scatter (minimum spacing, wrap at x = 320, quiet zone rows 152-168 on sand); for wood use 4 plank variants (promenade) and post spacing every 64 px (pier) in a sequence that wraps;
   - make every file tile seamlessly: column 0 and column 319 must be neighbours with the same band colours per row, and no mark may be cut at the seam;
   - measure palette count, detail density, alpha values and the quiet-zone density, print them, and exit non-zero on any breach;
   - write runtime PNGs to `assets/sprites/beach-ground-v1/` and previews to `assets/previews/`. Do not touch `data/*.json`, `scripts/*`, `tests/*` or the Art Lab. Keep the original plates unmodified.
3. Previews (all nearest-neighbour, opaque, composited over the real `background-v2` sky-clouds, sun and sea frame 1 at their game positions: sky y 14, sea y 94, sun x 233 y 26):
   - `beach-ground-v1-composite-320x180.png` plus a 1280x720 4x copy: the beach scene at the left of a level, sea to sand to y 180, with two or three real existing cast sprites (a shopper, a vendor or the herring gull from `assets/sprites/`) standing at ground y 160 for scale. Do not code-draw characters.
   - `beach-ground-v1-promenade-320x180.png` and `beach-ground-v1-pier-320x180.png` (4x copies too): a screen where the promenade ends and the pier begins (world x 920 in levels 3-6, so the join at the screen centre), with a sprite at y 160, a food stand sprite, and a bin for clutter.
   - `beach-ground-v1-tile-check.png`: the sand and shoreline repeated three times side by side (960 x 180) to prove the seam.
   - If the animated shoreline is delivered, a looping `beach-ground-v1-shoreline.gif`.
   - A mirrored set of the three scene previews with the old flat ground for before/after, named `...-before-...`.
4. Update `docs/RETRO_ENVIRONMENT_STYLE.md` with one short "Beach ground v1" section (files, sizes, rows, palette, caps).
5. Run `./tools/validate.ps1`. This task adds no game code, so it should add no failures; record the check count.

## Art Lab review (not live)
Codex stops after assets, prep script and previews. The ground must be **viewed in the Art Lab first, never in the live game**. The pattern is the one the background-v2 sky uses: a `BeachBackdrop.use_background_art` flag that the Art Lab sets from its `G` key, with the game left on the old drawing until David approves. The follow-up task (Assignee: Claude Sonnet, to be written after David has seen the previews, suggested name `056-beach-ground-art-lab`) will:
- add a `use_ground_art` flag to `BeachBackdrop` (default off), draw the four textures in `_draw()` in place of the flat rectangles when it is on (shoreline y 120, sand y 140, promenade y 151 and pier y 157 anchored at their start x, tiled and cropped to the world width), keeping the draw order so signs, props and sprites stay in front;
- bind an unused Art Lab key (suggested `H`; `G`, `D`, `B`, `F`, `I`, `P`, `C` are taken), include the toggle in the lab capture, and apply the dusk tint to the ground under `D`;
- leave `use_ground_art` off in the game until David approves; then a second small change turns it on.

## Out of scope
- Any edit to `scripts/`, `data/`, `tests/` or the Art Lab (that is the Sonnet follow-up).
- Characters, props, signs, palms, water animation changes, and the sky/sun/sea assets (do not regenerate or edit background-v2).
- Dusk-specific ground variants, a sand-to-pier left end cap, bench, railing, lamp or crab art.
- Any new colour outside the fixed palette, gradients, glow, translucent alpha, shadows under characters.

## Done when (acceptance)
- [ ] Four source plates preserved unchanged in `assets/reference/beach-ground-v1/` with `PROMPTS.md`; four runtime PNGs at exactly 320x20, 320x40, 320x14 and 320x22 in `assets/sprites/beach-ground-v1/` (plus `shoreline-anim-01..04` only if animated)
- [ ] Each file tiles seamlessly: the tile-check preview shows no visible seam, and a script check confirms column 0/319 continuity and no cut marks
- [ ] Alpha is strictly 0 or 255 in every file; no dither; 20 or fewer unique colours across all four, and per-file counts within the specs above; pure white `ffffff` is absent
- [ ] Detail-density caps met (sand 8% or fewer, wood 10% or fewer, shoreline foam lacing 25% or fewer) and printed by the prep script; sand rows 152-168 at 3% or less
- [ ] No dark outline at the shoreline or any seam between sea, shoreline and sand; the sand tile starts exactly in the shoreline's base sand colour
- [ ] The ground line at y 160 reads in the composites: sprites standing at 160 stay clearly more contrasty than any mark in the sand, promenade or pier
- [ ] Composites over the real background-v2 sky, sun and sea exist at 1x and 4x for the beach, the promenade-to-pier join and the before/after, and all pass the style check by eye: calm, no busier than the sea, no mark competing with a sprite
- [ ] `tools/prepare_beach_ground_v1.py` regenerates every runtime file and preview from the preserved plates; exit code 0
- [ ] `./tools/validate.ps1` passes with no new failures; no file under `scripts/`, `data/` or `tests/` is changed
- [ ] Status set to `done (awaiting David)`: nothing is wired into the game until David approves the previews

## Report

## Review notes
