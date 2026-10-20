# Approved gull production sources

Created with the **built-in image-generation tool**, 19 October 2026. The approved references are Herring B (Chip Thief), Kittiwake C (Sea Dart), Great black-backed C (Breakwater Bruiser), in `../gull-species-v1/`. Source research and photo attribution remain in that collection's `SOURCES.md`.

Each `*-source.png` is a unique generated 4-column, 5-row sheet with twenty poses. The complete prompt used for that sheet is saved beside it as `*-prompt.txt`. Reference inputs were the corresponding approved two-view concept sheet; no API/CLI fallback was used.

Frame order: idle; seven walking poses; four wingbeat poses; glide; dive preparation; horizontal dive; pull-up; airborne snatch; ground peck; landing/perch; grounded stun. These are drawn key poses, not twenty frames for every animation. Idle and glide hold one drawing, walking uses an eight-frame loop (seven walking poses plus idle), and a full wingbeat uses four drawings. Landing, peck and pull-up use brief dedicated pose holds.

`tools/prepare_gull_species.py` isolates each full connected actor, thresholds alpha, preserves source RGB, scales all poses from a species' common standing scale, aligns standing feet and airborne bill positions, and packs individual padded 256-pixel cells. It does not draw, recolour or manufacture character poses. The atlas scale is 0.5; visible idle heights are 22, 17 and 28 game pixels. The larger canvas preserves generous margins for extended wings and bills.

Final files: `assets/sprites/gull-herring-diner-style.png`, `gull-kittiwake-diner-style.png`, `gull-great-black-backed-diner-style.png`. `data/gull_art.json` records their clips and anchors and is mirrored into the main sprite registry by the preparation tool. Original painted gull images remain archived in their existing locations.

Run `tools/gull_species_production_review.tscn`, then `tools/package_gull_preview.py`, to reproduce the PNG/GIF review previews. Production and validation notes are in `docs/GULL_SPECIES_PRODUCTION_V1.md`.
