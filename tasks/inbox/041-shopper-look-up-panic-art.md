# 041 — Shopper look_up + panic_run art

Status: inbox
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-27

## Goal
Gang Call (the herring gull's power) needs two new crowd reactions. First, beachgoers **look up at the sky in surprise** just before the gang gulls dive. Then, after the hit, they **run away in a panic**. Start with the three shoppers, the most common characters. Task 040 adds the behaviour and picks up these animation names automatically when they exist.

## Characters (existing sheets, 128x128 frames, `visual_scale` 0.5)
- `kiosk_customer`: `assets/sprites/shopper-diner-style-v2-bite-v1.png` (`data/shopper_art.json`)
- `shopper_mullet`: `assets/sprites/shopper-mullet-walk-v2-bite-v1.png` (`data/shopper_variants_art.json`)
- `shopper_sundress`: `assets/sprites/shopper-sundress-walk-v2-bite-v1.png` (`data/shopper_variants_art.json`)

## Requirements
1. Generate the animations below for each of the three shoppers with the built-in image generator. Match their current pixel density, outline weight, palette and proportions exactly; they must read as the same people.
   - `look_up`: 2 frames. The head is tilted back so the face points at the sky, eyes wide, mouth open. One hand may still hold food at the existing food anchor. The feet stay planted on the same sole baseline.
   - `panic_run`: 6–8 frames, a looping run cycle, clearly different from the existing angry `run`. Arms flailing or hands up by the head, leaning forward, and a scared face (not angry). Draw it facing the same way as the sheets' current `run`, so the code can flip it.
2. Add the frames to each character's sheet or a companion sheet, and register `look_up` (about 6 fps, no loop) and `panic_run` (about 12 fps, loop) in the same art JSON, including food anchors where the existing clips have them. Keep every existing animation working unchanged.
3. Keep the untouched source artwork and prompts in `assets/reference/shopper-panic-v1/`. Put a preview in `assets/previews/` showing all three shoppers in both new poses at in-game size, next to their current `idle`.
4. No gameplay changes. AGENTS.md applies: generated art only. Code may crop, align and pack, but must not draw bodies, faces or limbs, not even as placeholders.

## Out of scope
- Other characters (sunbather, mum/parent, pier diners, lifeguard, market cleaner, old man). These follow as separate tasks once these look right.
- The panic behaviour itself (task 040).

## Done when (acceptance)
- [ ] All three shoppers have `look_up` and `panic_run` registered, with feet on the existing baseline and food anchors aligned
- [ ] The preview image is in `assets/previews/`; the source and prompts are in `assets/reference/shopper-panic-v1/`
- [ ] Art-check tests cover the new clips (frame counts, baseline)
- [ ] `./tools/validate.ps1`: 0 new failures

## Report

## Review notes
