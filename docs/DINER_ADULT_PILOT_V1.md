# Diner-led adult pilot v1 — 19 October 2026

The user approved this pilot. It has now been carried through the five production atlases; see `DINER_ADULT_PRODUCTION_V1.md`. The remainder of this document records the isolated pilot checkpoint.

Status: five poses prepared and rendered for visual review. Production atlases, runtime loaders and gameplay settings are unchanged. The approved pier diner remains the style reference and is displayed using its production textures, scale, animation regions and material.

## Deliverables

The built-in image generation tool created three source images using the approved diner as the style master and the existing adults as identity references. Full prompts and sources are retained in `assets/reference/adult-diner-pilot-v1/`.

Five separate pilot frames are saved in `assets/pilots/adult-diner-v1/`: `mum-idle.png`, `mum-walk.png`, `mum-swat.png`, `male-idle.png` and `female-idle.png`.

Each frame is 128 × 128 with an approximately 80-pixel figure, sole baseline y=116 and a 0.5 presentation scale. That retains the current 40-logical-pixel apparent standing height. Outline, skin, hair and clothing colours come from the generated source; the old 14-colour reduction is not applied. Alpha is fully transparent or opaque and final sampling is nearest. These are five style/pose samples, not complete animation clips or replacements for production assets.

## Review images

`assets/previews/adult-diner-pilot-v1/` contains:

| Image | Purpose |
| --- | --- |
| `comparison.png` | 1280 × 1080. Top: current mum/man/woman and approved diner. Middle: new adult pilots with the identical diner. Bottom: mum walk/swat beside the diner's walk/swat. All figures use their actual presentation sizes. |
| `comparison-phone.png` | 720 × 607. Same comparison at a narrower display size. |
| `gameplay.png` | 1280 × 720. Staged pilot figures and the unchanged diner inside the actual gameplay backdrop and interface. Original level actors are hidden for the comparison. It is explicitly labeled as a pilot preview, not a changed playable roster. |
| `gameplay-phone.png` | 693 × 390 content capture from an 844 × 390 window with aspect preservation. The window's side bars are outside the captured content viewport. |

## Assessment

At the tested presentation sizes, the pilot retains clearer sunglasses, eyes, hair contours, blouse knot, trunks piping and sandal details than the current coarse adult sheets. The result is materially closer to the diner's dark outline and compact arcade shading. The diner's head/body proportions remain more exaggerated; the pilot preserves the existing adult identities and is not intended to copy the diner's anatomy. Whether this exact detail level is the desired finish is the next user review decision.

The three mum poses are consistent enough for a style pilot, but they are not a walk or swat animation sequence. A full animation pass still needs independently authored transitions, pose-to-pose head checks, stable foot contacts and new hand anchors for the final art.

## Validation and reproduction

`tools/prepare_diner_adult_pilot.gd` prepares only the five pilot images and writes `manifest.json`. Its checks confirm all five frames are nonempty 128 × 128 images, have the shared foot baseline, fit the cell and have binary alpha. It retains source crop metadata and colour counts for inspection.

`tools/diner_adult_pilot_preview.tscn` / `.gd` render the comparison and staged gameplay views with Godot. The preview run completed successfully and its error log was empty. Outputs were visually inspected at desktop and phone display sizes. No gameplay integration tests were run because the production art and gameplay code were not changed.

Next: review the five-pose pilot against the diner, then use the selected detail level for the full adult animation sheets. Preserve the current production sheets until that visual direction is settled.
