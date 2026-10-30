# Shopper walk reassessment

Implementation update: both generated walk replacements are now integrated; see `MULLET_WALK_V2.md`, `SUNDRESS_WALK_V2.md` and their animated comparisons under `assets/previews/`. The older woman's update also corrects repeated direction reversals outside the patrol span.

20 October 2026. User review rejects the cutout pilot and identifies the original yellow-shirt shopper as having a good walking animation. That existing walk is the reference; the two newer appearances are the problem to address. The rejected pilot was isolated and has not replaced gameplay animation.

## Corrected diagnosis

All three appearances use `kiosk_customer`, `ShopperArt.update`, six sequential walk frames `[1,2,3,4,5,6]`, 8 fps, a 128 x 128 source cell displayed at 0.5 scale, a 40-pixel adult height and the same vertical sprite offset. They select walking through the same movement code. The prior playback probe visited all six frames for each appearance. Neither a general animation restart nor a different animation rate explains the difference between these three shoppers.

The same source-preparation helper extracts all three walks. The original's dedicated locomotion sheet has two rows; the variants' 24-pose sheets have four, and their preparation correctly extracts the first of those four rows for walking. The walk indices are sequential in each prepared atlas. No frame-order or wrong-row mapping fault was found.

The shortcomings are already visible in the variants' generated source sheets, before import:

- **Original shopper:** readable transitions between extended stride, bent trailing leg and passing foot. Clear space around the legs and larger changes below the shorts make the cycle work at gameplay size.
- **Stocky mullet man:** the belly and shorts leave less visible leg length. Several walking poses keep similar foot spacing/height, with a weaker passing position and less knee articulation. Body/arm changes contribute more to frame differences than the feet do. The cycle reads as a small shuffle.
- **Older woman:** the dress obscures the upper legs, while the visible sandals remain in similar positions through several frames. The passing pose does not pull the feet together and lift the swing foot clearly enough. Dress and arm changes do not establish a convincing step below the hem.

The shorter visible leg area is a contributing silhouette constraint, not a reason to change either character's identity or body type. Their feet and hem need a more deliberate pose sequence within the existing proportions.

## Controlled comparison

`assets/archive/previews/shopper-walk-reassessment.gif` displays only the three current production characters, synchronised to the same six frame indices at 8 fps. It includes enlarged lower-leg crops. No new character artwork, movement driver or pilot rig is used in this comparison. The diagnostic scene is retained under ignored `test-output/shopper_reassessment.tscn`.

As a supporting diagnostic, mean adjacent-frame alpha-silhouette change in the same lower-body region (source y=94..115, x=20..107) was 0.554 for the original, 0.272 for the man and 0.200 for the woman. This measures changed occupancy divided by the union of occupied pixels, including loop closure. It is not a biomechanical score or a direct foot-travel measurement; it quantifies how much less their visible lower silhouettes change. Source-sheet inspection and the animation comparison are the decisive evidence.

The earlier checks accepted any whole-frame pixel difference as evidence of moving limbs. A face, flower pattern or arm can change while the feet barely move. The reassessed review needs to inspect the lower-body poses themselves.

## Narrow replacement plan

1. Preserve the original shopper's artwork and walking playback as the approved benchmark.
2. Replace only the two newer characters' drawn six-frame walk cycles. Use each of the original's six actual walk poses as a motion reference, alongside the relevant character's identity sheet. Generate complete character drawings with ImageGen; preserve their faces, clothes, body types and established game size.
3. For the man, retain the stocky silhouette while making planted, bent-knee, passing and opposing-contact positions visibly different. For the woman, coordinate the dress hem with distinct exposed-foot positions, heel lift and a clear passing foot. Do not require every pose to have the original's exact limb proportions.
4. Keep six frames, 8 fps and the existing sprite animation method during the replacement comparison. Verify foot baseline, body stability, mirrored food anchors and both directions. Adjust import alignment only if the replacement exposes a specific alignment defect.
5. Review all three side by side at gameplay size and at the same travel speed before integrating the replacements. Separate review of run/other characters can follow if requested; they are not automatically part of this walk correction.

The rejected pilot's segmented limbs and different cadence introduced a new appearance and gait instead of fixing the weaker drawings. Its analytical checks did not establish visual quality. A new skeleton, a cast-wide gait driver or an increase to eight frames is not the proposed solution for these two shoppers.
