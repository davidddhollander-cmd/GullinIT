# Generated beach direction signs — approval preview

The arrow plank and wooden stake were created with ChatGPT's built-in image generation. Intact source PNGs and exact prompts live in `assets/reference/beach-signs-v1/`. `tools/prepare_beach_signs.gd` crops transparent margins, thresholds edge alpha and reduces with nearest sampling to native sprites; it also mirrors the arrow for the left-facing variant. No text is baked into the generated art.

`scripts/beach_sign_art.gd` composes the generated post and one or two arrow boards with the compact GullHud bitmap font. `scripts/beach.gd` finds a clear position within each level zone, points snack arrows to the nearest actual stall from the final sign position and points promenade/pier arrows to their level boundaries. Beach-only levels retain local zone names. Crowded zones use a single arrow; densely furnished generated promenades use a compact SNACKS arrow. Both board and post placement account for scenery, and existing hint/marker avoidance uses the complete board group.

Run `tools/beach_sign_preview.tscn -- --check-only` headless for focused placement checks across all six levels; run the scene with rendering enabled for captures. `assets/previews/beach-signs-review-v1.png` shows three actual Boardwalk Bustle views plus Training Day's single-arrow variant. `beach-signs-phone-v1.png` captures at 640×360. These are actual Godot renders, not image-generator scene mockups.

All six levels also have 1280×720 desktop and 640×360 phone captures. `beach-signs-all-levels-v1.png` shows levels 1–3 across the first row and 4–6 across the second. Focused sign checks pass with zero failures; the full headless integration suite passes 15,797 checks with zero failures. The standing-character clearance fixture now measures the visible image bounds, excluding transparent atlas padding. Existing hint-clearance and prop-clearance checks still pass.

Status: the smaller v2 signs were approved when the user instructed work to proceed to step 2. Vendor animation follows that approval; catchable crabs remain step 3. The sign pass did not change vendor service timing or bonus rules.

## Smaller signs — revision 2

Following user feedback, boards now start at 38 pixels wide instead of 76; longer labels expand only enough to fit the compact 3×5-pixel GullHud glyphs at their native size. Boards are 12 pixels tall instead of 16, finger spacing is 13 instead of 17, and posts are 3 pixels wide instead of 4. Source artwork is unchanged and preserved. The smaller type remains a crisp bitmap font rather than a blurred reduction of the original letters.

The approved review is `assets/previews/beach-signs-review-v2.png`, with phone and all-six-level variants using the same v2 suffix. The v1 captures remain available for comparison. All six levels pass focused placement/direction checks, and desktop/phone v2 renders have been reviewed. The later vendor-v3 full integration run also covers the smaller signs: 15,824 checks, zero failures.
