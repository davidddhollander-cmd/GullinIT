# Kittiwake screech source

Generated with the built-in image generator for task 089. No character pixels were programmatically painted or recoloured.

- `source-first.png`: initial generation, using the live retouched kittiwake sheet for identity and herring screech for poses; `prompt.txt`.
- `source-refined.png`: first refinement of that source; `refinement-prompt.txt`.
- `source.png`: final untouched generation with visible small wing lifts in frames 3 and 4; `wing-lift-prompt.txt`. References were `source-refined.png` and `identity-detail.png`.
- `identity-detail.png`: nearest-neighbour enlargement of the production idle crop `(90,90,160,145)`, used only as an identity reference.
- `packing.json`: generated source crops, common scale, destinations, sole baseline and foot centers.

Rebuild the atlas and comparison preview with `tools/art/pack_kittiwake_screech.py` (Pillow). Packing only crops, nearest-samples and translates the generated RGBA pixels. It starts from one common scale for all six birds and adjusts sampling sizes by at most three pixels to keep thin toes/feathers connected, following task 065. It derives horizontal alignment from the planted feet and sets every sole to the production idle baseline. The source background has faint low-alpha generation artefacts outside the bird crops; these are excluded by rectangular crop bounds, without painting or masking character pixels.

Preview: top row uses the actual game scale 0.375; bottom row enlarges atlas pixels 2x for inspection. Frame indices are zero based: 4 is held while screeching; 5 recovers.
