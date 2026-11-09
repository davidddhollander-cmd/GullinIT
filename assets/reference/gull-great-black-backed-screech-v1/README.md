# Great black-backed gull screech v1

Created with the built-in image generator using the black-back production sheet
as the identity/style reference and the herring screech sheet as the pose reference.
`initial-source.png` and `source.png` are the untouched first and cleanup outputs.
`prompt.txt` preserves both prompts.

Repack from the repository root with `python tools/art/pack_black_back_screech.py`
(Pillow required). The packer only crops, resizes with nearest-neighbour sampling,
aligns and packs generated artwork; it does not draw or recolour character pixels.
The alpha >= 200 mask locates the crop rectangle only; the generated RGBA pixels
inside that rectangle are preserved. Nearby sampling sizes keep feather tips
connected at the production pixel density. `packing.json` records each crop and
destination bound. All six soles end at source-space y=140, matching idle.

The game atlas is 768x512, three columns by two rows of 256x256 cells. Frame 4 is
the held peak; frame 5 recovers. The comparison preview uses the production 0.375
scale and shows idle followed by frames 0 through 5.

No base-sheet frame_beaks or frame_bounds entries are changed: their indices
describe the existing base-sheet clips. Grounded sprite positioning uses a fixed
sole offset. Separate screech bounds are recorded in packing.json. Gameplay
enabling remains task 066.
