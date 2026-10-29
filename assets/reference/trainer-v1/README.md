# Screeches McCrumbs trainer art — concept and production

This folder contains the generated concept board, preserved generated sources, and the exact prompts supplied to the built-in image generator.

Reference inputs:

- `../../sprites/gull-herring-diner-style.png` — authoritative in-game anatomy and rendering reference.
- `../../previews/gull-herring-frames-v1.png` — enlarged approved frame review.

Round 1 presents three alternatives, each with a full-body idle and a head-and-shoulders bust:

- A: feather beard and scar only.
- B: feather beard, scar, and battered faded captain's hat.
- C: feather beard, scar, and thin frayed neckerchief.

Variant B was approved with three user-directed changes: a larger feather beard,
a short cigar, and a left-facing profile. Those directions override the initial
right-facing production brief.

Files:

- `concept-board-source-v1.png` — untouched first generation.
- `concept-board-source-v2.png` — untouched transparency-correction generation.
- `concept-board-source-v3-chroma.png` — untouched flat-green extraction generation.
- `trainer-screeches-concepts-v1.png` — binary-alpha Round 1 review board extracted from source v3.
- `concept-board-prompt.txt` — exact initial generation prompt.
- `concept-board-transparency-edit-prompt.txt` — exact focused correction prompt.
- `concept-board-chroma-edit-prompt.txt` — exact flat-background extraction prompt used after the generator returned hidden RGB beneath zero alpha.

Production sources and exact prompts:

- `portrait-01-neutral-source.png` and `portrait-01-neutral-prompt.txt`
- `portrait-02-talking-source.png` and `portrait-02-talking-prompt.txt`
- `portrait-03-amused-source.png` and `portrait-03-amused-prompt.txt`
- `portrait-04-proud-source.png` and `portrait-04-proud-prompt.txt`
- `portrait-05-wince-source.png` and `portrait-05-wince-prompt.txt`

`../../../tools/prepare_trainer_v1.py` removes the generated flat-green
background, creates binary alpha, scales all portraits from their shared source
canvas with nearest-neighbour, limits the talk-loop difference to the generated
lower-bill/cigar region, and packs the atlas plus the 56px/4x review preview. It
does not draw or recolour character pixels.
