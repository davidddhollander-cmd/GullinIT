# Adult artwork replacement — 19 October 2026

Replaced the five `retro-mum-32bit.png` / `retro-sunbather-*-32bit.png` production atlases. The previous code-drawn rectangles did not preserve the faces, ponytail/bun, anatomy, trunks piping or action silhouettes shown in the supplied review art. The runtime filenames, 64 × 64 cell grid, clip order, counts and timing remain compatible with the existing registry and sunbather loader.

## Assessment of the supplied images

| Existing image in assets/previews | Assessment and use |
| --- | --- |
| sunbather-male-retro-review-v1.png | Useful reclining, seated, eating, warning, block, swat and kick key poses. Retained as the main male action source. Not a complete animation atlas. |
| mum-retro-review-v1.png | Useful identity, idle, eating, warning, palm block, swat, running and kick key poses. Retained as the main mum action source. Detached yellow reaction effects are excluded from the actor extraction. |
| beach-buildings-32bit-concept-v1.png | Good palette/outline/shape reference. Contains no reusable character frames; no building changes needed for this request. |
| adult-cast-32bit-style-review-v2.png | Best clear shared standing proportions and identity reference. Supplies neutral male/female standing poses. |
| sunbather-male-walk-review-v1.png | Six right and six left walking poses, reused directly as the male locomotion source. |
| mum-walk-review-v1.png | Six right and six left walking poses, reused directly as mum's empty-hand locomotion source. |
| sunbather-female-retro-review-v1.png | Useful matching female action key poses. Only three broad stride poses; lacks a full walk cycle and continuous get-up/pickup sequences. |

These are large reference images with fine shading and some blended edge alpha. They are not drop-in 64-pixel animation sheets. Offline preparation extracts the main connected actor in each region, samples it onto the native grid, resolves colours into the shared palette and produces binary alpha. No source review image is overwritten.

## New artwork that was needed

Three supplemental sheets were generated with the built-in image generation tool, using the existing review art as identity/style references:

- `assets/reference/adult-replacement-v3/female-motion.png`: six walking frames each direction, six get-up poses and six pickup poses.
- `assets/reference/adult-replacement-v3/male-transitions.png`: six get-up poses and six pickup poses.
- `assets/reference/adult-replacement-v3/mum-carry-handover.png`: six carry-walk poses each direction and six handover poses; hands and the moving actor remain free of baked-in bags or food.

The exact prompts are saved beside those sources in `PROMPTS.md`. Blue swimwear is a deterministic garment-only palette swap of each red atlas; hair and skin keep the same colours and pixel positions.

## Preparation and limitations

`tools/adult_atlas_source.gd` records source regions, native heights, shared palette and clip mappings. `tools/generate_retro_adults.gd` rebuilds all five runtime images and `assets/previews/adult-replacement-review-v3.png`. Runtime `scripts/adult_pixel_art.gd` now defines layout/loading only, so regenerating no longer restores the old geometric people. Review columns are idle, walk 0, walk 1, left walk 2, swat contact, kick contact, handover/rest, and carry-left/pickup. Rows are mum, male red, male blue, female red, female blue.

Adults remain about 40 native pixels tall with the soles at y=58, no mipmaps and nearest sampling. Each appearance uses at most 14 opaque palette colours and fully transparent remaining pixels. The contact sheet has transparent gutters for inspecting edge contamination.

This pass prioritizes reuse of the requested artwork. Rest/idle and reaction anticipation/contact poses use held keyframes; chase/run combine the walk source with the existing running key pose. These are not newly authored, fully independent run cycles. Left kicks mirror the right kick sequence, whereas left walk/carry use dedicated source poses. Further generation would be useful for independent sprint cycles, more fluid reaction in-betweens and independently drawn left kicks, but is not necessary to load or play the replacement atlases.

Food remains a separate gameplay layer. `MumArt.FOOD_ANCHORS` aligns it to the new palms per frame, including the separately drawn left walk/carry poses and the lower held handover pose. The snack's visible position remains its theft position. No character behavior, food supply, attack timing or scoring rules were changed.

## Validation

Final rendered integration run: **10,774 checks, zero failures**. The suite checks loading, all clip counts, changing adjacent locomotion/kick frames, binary alpha, palette limits, carrying, handover, food visibility and sunbather reactions. Visually reviewed the final contact sheet plus in-game carrying, handover and female pickup captures in `test-output`. `test-output/adult-replacement-validation.log` records the run.
