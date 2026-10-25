# Pier diner B — generated source

These four PNG files are the untouched outputs from the built-in image generator:

- `pier-diner-b-base-source.png` — 12 base/action poses
- `pier-diner-b-locomotion-source.png` — six walk and four run poses
- `pier-diner-b-eat-source.png` — four eating poses
- `pier-diner-b-reactions-source.png` — six surprise and six fist-shake poses

`PROMPTS.md` preserves the exact generation and cleanup prompts. The production atlases are prepared by `tools/prepare_pier_diner_b.gd`, which only crops, isolates connected generated figures, hardens alpha, nearest-resizes, aligns to a shared baseline, and packs frames. It does not paint character bodies, faces, clothing, or limbs.

The game renders fried fish as a separate sprite. The generated diner therefore presents an empty supporting palm; `data/sprites.json` supplies the matching food anchor for each relevant frame.
