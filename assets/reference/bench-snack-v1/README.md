# Bench snack source artwork

Generated with the built-in image generator on 2026-10-23. Complete original transparent 1774x887 outputs are preserved here. `PROMPTS.md` records the prompts and reference roles. No new anatomy was painted, rigged or assembled in code.

- `yellow-source.png`: original yellow open-shirt shopper.
- `mullet-source.png`: stocky red-shirt shopper with teal cap and mullet.
- `sundress-source.png`: older woman with grey bun, glasses and yellow floral dress.

Each sheet has eight full-body right-facing figures in two rows. The first row lowers the actor into a seated pose. The second row supplies rest and bite gestures. Horizontal mirroring supplies the opposite orientation. Runtime sit uses source figures 0,1,2,4; stand reverses them. Figure 3 remains preserved in the source and atlas; figure 4 keeps the serving palm continuous with the separate snack.

`tools/prepare_bench_snacks.gd` crops whole figures, scales every figure in a sheet by one shared factor determined from its standing figure, aligns hips horizontally and soles at atlas y=116, thresholds alpha fringes and removes disconnected reduction specks. It retains the complete prior atlas above a new row, keeping all walking/reaction cells exact. The preparation script records measured source hip x and palm x/y coordinates; food anchors use those coordinates and the same crop, scaling and sole adjustments. It edits only the three shopper entries in shared `data/sprites.json`.

Run preparation with Godot headless, then editor import. Source preservation and atlas versioning allow re-preparation without modifying earlier assets. Generated sources remain unchanged; alpha cleanup applies only to runtime derivatives.

Production atlases: `assets/sprites/shopper-{yellow,mullet,sundress}-bench-v1.png`. Production animation time is manually sampled from `BenchVisit`, including eating and both transitions; AnimatedSprite playback is paused for these clips.

Visual review: `assets/previews/bench-snack-v1.gif` is 640x280 at actual game scale; `bench-snack-v1.png` is a 2x rendered view; `bench-snack-contact-sheet-v1.png` shows approach, sit, rest, theft/stand, chase and departure. The yellow-only proof has its own PNG/GIF. Captures use production target, registry, visit, crowd-spacing and art paths.
