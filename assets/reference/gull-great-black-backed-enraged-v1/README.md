# Enraged black-back pilot

The built-in image generator drew the idle and seven walk poses using the normal
black-back sheet for identity and the enlarged eight-pose crop for footfalls.
`initial-source.png` and `source.png` preserve the untouched generation and cleanup
outputs; `prompt.txt` contains both prompts.

The atlas uses source indices 0-7 in a 4x2 layout of 256x256 cells, with the same
idle and walk timing as the normal bird. Feet end at y=140. Bill tips are measured
from the rightmost yellow bill pixels and aligned within two source pixels of
their corresponding normal cells. Existing metadata and clips are preserved.

Run `python tools/art/pack_black_back_enraged.py` (Pillow required) to reproduce
the atlas, comparison and walk GIF. `packing.json` records source crops, resize
sizes, detached-speck counts, destinations and measured anchors. Comparison rows show
normal/enraged idle and the Shakedown 1.25x size, then every normal/enraged walk
cell on sky and sand. The GIF uses the production eight-frame order at 8 fps.

David explicitly approved removing detached background specks during packing.
After nearest-neighbour resizing the packer retains the largest connected
silhouette and removes only detached components. It asserts that every RGBA
pixel in the main bird is unchanged. No character pixels are drawn or recoloured.
The horizontal footprint is the matching normal frame width plus four pixels;
extra height comes from the puffed chest and raised hackles. Sole alignment is
exact and all measured bill differences are at most one source pixel.

Gameplay switching remains task 068. Other animations and carry sheets remain
outside this pilot, pending David's judgement of the look.
