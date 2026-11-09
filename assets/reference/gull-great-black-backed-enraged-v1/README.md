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

## Task 075: approved full set

The pilot was approved in play. `approved-pilot.png` preserves its original eight
cells; the extended body atlas copies those pixels exactly and appends body cells
8-19. The full-set sources and prompts are `body-full-source*`, `screech-source*`,
`carry-walk-source*` and `carry-flight-source*`. All four PNGs are untouched image
generator outputs; the normal pose references are crops/resizes only.

Run `python tools/art/pack_black_back_enraged_full.py` to reproduce the full set
and previews. Do not use the old pilot-only packer to rebuild the extended atlas.
The full packer only crops, resizes, aligns, removes detached background specks,
and packs generated pixels. The helper asserts that RGBA pixels in the retained
main silhouette are unchanged. `full-set-packing.json` records all 31 alignments.
Every bill is within one source pixel of its normal reference, and grounded feet
match the corresponding normal baseline exactly.

`carry-full-source-atlas.png` groups the thirteen original-size source cells from
the two untouched carry outputs into a padded 4x4 grid, without resizing or
repainting them. The carry upper-mandible overlay crops pixels from each packed
generated bird in the matching normal overlay's contact window. Both registries
retain every existing value; the added carry block copies normal anchors, frame
order and scale and changes only the body, upper-beak and source paths. The two
`baseline-*-entry.json` snapshots support regression checks of all existing values.

Previews compare every new pose at normal/enraged 0.375 scale and at Shakedown's
1.25x scale on sand and sky. Carry comparisons layer real chip, ice cream and
hotdog art using the unchanged runtime anchors and body -> food -> upper-beak
order; food keeps its runtime size at both gull scales. Animated previews cover
flight, screech (with a held peak) and carry walk. Carry runtime selection remains
the follow-up task; no gameplay scripts were changed here.
