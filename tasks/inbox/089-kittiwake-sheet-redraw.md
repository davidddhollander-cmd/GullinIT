# 089: Kittiwake sprite sheet redraw (clean outline)

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-14

## What David should see if this works
In game the kittiwake looks as clean and crisp as the herring and the great black-backed. It has a dark outline all the way round, flat readable colour clusters, and no grainy speckle on its white body against the sky or sand. It's still clearly the same slender kittiwake: smaller than the herring, dark eye, black legs, solid black wingtips and a plain yellow bill.

## Why
At real size the kittiwake looks grainy, and the cause is the art, not the rendering. All three gulls use the same pipeline: 256 px cells, `visual_scale` 0.375 and nearest filtering. Compared with the herring, the kittiwake source (`assets/sprites/gull-kittiwake-diner-style.png`):
- has **no dark outline** on its back and belly, so the white body blurs into the background
- has **fine, noisy shading**: about 1% of horizontally adjacent pixels are identical, against 4% for the herring
- is drawn smaller in the cell (idle bounds about 47×34 against 61×44 for the herring), so it's about 18×13 px on screen and the noise has nowhere to hide

## Context
- The pipeline is documented in `assets/reference/gull-production-v1/README.md` and `docs/GULL_SPECIES_PRODUCTION_V1.md`:
  - the generated 4×5 source sheet
  - `tools/prepare_gull_species.py`, which isolates, scales, aligns and packs the 256 px cells and updates `data/gull_art.json` and the sprite registry
  - `tools/gull_species_production_review.tscn` plus `tools/package_gull_preview.py` for review previews
- The previous prompt is `assets/reference/gull-production-v1/kittiwake-prompt.txt`, with the approved identity `assets/reference/gull-species-v1/kittiwake-c-source.png` (Sea Dart). The herring's results (`herring-source.png`) are the style target.
- The carry sheet `gull-kittiwake-carry-v1.png`, with its source in `assets/reference/gull-carry-v1/`, very likely has the same problem.

## Requirements
1. Use the **built-in image generator**. No code-drawn, recoloured or programmatically painted bird art (AGENTS.md). Give it the approved Sea Dart concept **and** the herring production source as inputs. Ask for the same 20 poses in the same order, keeping the kittiwake's identity and adopting the herring's rendering style. A starting prompt is below; adjust it as needed and save the final prompt beside the source.
2. Save it as `assets/reference/gull-production-v2/kittiwake-source.png` plus `kittiwake-prompt.txt`, keeping the v1 files. Run `tools/prepare_gull_species.py` for the kittiwake only. That produces `assets/sprites/gull-kittiwake-diner-style.png`, the clips and anchors in `data/gull_art.json`, and the mirrored entry in `data/sprites.json`.
3. Keep the kittiwake's in-game size class, smaller than the herring with an idle height of about 17 game px. Draw the bird **larger in the cell** and lower the scale in the prepare step if that keeps the outline and clusters intact after downscaling.
4. Keep the 20-frame layout, the animation map and the frame order, so no game code changes. Check that `frame_beaks`, `ground_beak_y` and `art_height` come out sensible, with feet on the ground line and the beak at the snatch point.
5. If the redrawn walk sheet is approved, do the carry sheet the same way, from the same prompt base plus `assets/reference/gull-carry-v1/PROMPTS.md`. If time is short, list it as not done in the Report.

### Starting prompt (adapt it)
> Use case: stylized-concept. Asset type: production animation sprite sheet for a side-view seaside game. Input image 1 is the APPROVED kittiwake identity (Sea Dart). Input image 2 is the APPROVED RENDERING STYLE (herring gull sheet). Keep image 1's species, proportions, head, small bill and plumage, but render it exactly like image 2: a continuous dark fine outline around the whole silhouette including back, belly and wings; flat cel shading in a few large clean clusters (2 to 3 greys on the mantle, 1 to 2 off-white shadow tones on the body); no speckle, dither, noise or soft gradients; strong contrast between the white body and the outline so it reads at 18 px tall. Draw the bird large, filling most of each cell. Generate the SAME character in twenty sequential poses, not redesigns; all face RIGHT. True transparent background; no text, grid, ground, shadows or effects. Layout and POSE ORDER: identical to the v1 kittiwake prompt (EXACTLY 4 columns × 5 rows; idle, seven walk poses, four wingbeat poses, glide, dive preparation, streamlined dive, pull-up, airborne snatch, ground peck, landing, stunned). Species invariants: adult BLACK-LEGGED KITTIWAKE, slender angular silhouette, solid DARK eye, grey mantle, solid BLACK wingtip ends with NO white spots, white head, body and flight tail, BLACK legs and feet, plain yellow bill with NO red spot, no hood, no juvenile markings.

## Out of scope
- Herring and great black-backed art, which are already clean.
- Any gameplay or code change.

## Done when (acceptance)
- [ ] The new source, prompt and processed sheet are in place, with v1 kept for reference.
- [ ] The Report has a side-by-side capture of herring, old kittiwake and new kittiwake at real size and at 4×, on sky and on sand.
- [ ] The Report has the review GIF from `tools/package_gull_preview.py`.
- [ ] `./tools/validate.ps1` shows no new failures. Main has 12 environmental ones: flash, name field and PostHog.
- [ ] Status is `done (awaiting David)`.

## Report

## Review notes
