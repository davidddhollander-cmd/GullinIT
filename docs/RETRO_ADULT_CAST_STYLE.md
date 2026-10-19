# Retro adult cast style and animation specification

**19 October 2026 replacement:** the user selected the existing review artwork for replacing the geometric production cast. See `ADULT_ASSET_REPLACEMENT_V3.md` for the active source mapping, three supplemental generated sheets, preparation workflow and motion limitations. The historical direct-drawing source description and strict independent-cycle requirements below describe the earlier pass; they are not claims about the current reused keyframe set.

Status: implemented native-pixel pass, 15 October 2026. Applies to the beach mums and male/female sunbathers. The target is a chunky 32-bit-era handheld/arcade sprite, with the visible pixels and restrained palette of a native low-resolution game asset. “32-bit” describes the period and visual character, not the PNG colour depth. The first review sheets were too finely shaded and are rejected as production art.

## Visual rules

- Author at the game's 320 × 180 logical scale. Standing adults are 36–40 native pixels tall from sole to hair, with heads about one third of standing height. Keep the same foot baseline and eye line across the cast. Mum is medium width with a clear ponytail; male sunbather is slightly broader; female sunbather has a distinct bun and swimsuit silhouette. Change body shapes without changing perceived height.
- Every native pixel must remain a visible square after enlargement. Build silhouettes from stair-step edges and broad, coherent colour clusters, usually 2–4 native pixels wide. Reserve isolated single pixels for eyes, mouths and fastenings. Render only with integer nearest-neighbour scaling. No antialiasing, semitransparent edge pixels, gradients, blur, rim light, micro-dither, painted texture, tiny fabric folds or subpixel detail.
- Use one navy outline colour and no more than 16 opaque colours per appearance, including outline and facial details. Use at most two skin tones, two hair tones and two tones per garment. Shared anchors: ink `#183B4E`, cream `#FFF4DA`, coral `#EF725C`, teal `#408FA8`, gold `#FFC65C`. Keep red/blue sunbather variants as palette swaps of one silhouette and animation, with identical anatomy and timing.
- Preserve character identities: brunette ponytail, coral sleeveless blouse, teal knee shorts and sandals for mum; sunglasses, short dark hair and swim trunks for male sunbather; sunglasses, brown bun and one-piece swimsuit for female sunbather. Keep faces and hands large enough to read alert, block and impact at game size.
- Use genuine alpha. Towels, picnic bags, groceries and stealable food remain separate layers. Do not bake a towel, bag, snack, shadow or ground into moving frames. Mum's separately drawn food follows a per-frame hand anchor, including left-facing poses.
- Production frames use equal 64 × 64 transparent cells with a common sole baseline at y=58; the 36–40-pixel figure occupies only the needed area within each cell. Reclining poses may use two adjacent cells as one 128 × 64 frame but retain the same world-space hip/ground anchor. Put each action in its own evenly spaced atlas row or sheet. Source art must have only fully opaque or fully transparent pixels. Final runtime sampling is nearest-neighbour with mipmaps off; any generated large render is a reference until rebuilt on this native grid.

## Direction and motion

- Draw left and right locomotion poses separately. A horizontal flip is acceptable only for a temporary review mockup; production left poses must preserve mum's visible food hand, the sunbather swimsuit details, and kick/swipe silhouettes. Both directions have the same timing and foot contact order.
- A walk cycle has six distinct frames per direction: left contact, down/passing, right takeoff, right contact, down/passing, left takeoff. Two contacts and two passing frames must visibly differ. Play at 9–10 fps, with 1–2 authored pixels of vertical bounce and no sliding planted foot.
- Chase has six distinct frames per direction, forward lean and longer stride, at 11–12 fps. It can transition through a two-frame acceleration into chase and a two-frame deceleration back to walk/idle. Animation speed follows movement so a stopped character holds a planted frame.
- One-shots hold the last readable anticipation frame until the gameplay event resolves, then show contact and recovery. They never restart every physics tick. A change of direction changes at a planted/contact frame to avoid a foot pop.

## Required clips for each mum and sunbather variant

| Clip | Frames | Timing and readable poses |
| --- | ---: | --- |
| Idle / breathing | 4 | Planted stance, small head/shoulder shift, blink; 5–6 fps. |
| Eat | 4 | Empty hand to mouth, chew, lower hand; 6–8 fps. Food is a separate overlay if the actor actually holds one. |
| Walk right / left | 6 + 6 | Opposed arm and leg swings with clear contact/passing poses; 9–10 fps. |
| Alerted | 4 | Notice, turn/raise gaze, braced warning, hold; 8 fps then hold. |
| Block | 4 | Forearm/shoulder rises across food space, full shield, impact recoil, reset; 8–10 fps. |
| Swat | 6 | Notice, draw arm back, windup hold, open-palm contact, follow-through, recovery; contact frame tied to the current range check. |
| Chase right / left | 6 + 6 | Clear running contacts and airborne passing frames; 11–12 fps. |
| Kick right / left | 6 + 6 | Plant, draw knee, held telegraph, foot extension/contact, recoil, return to planted idle; contact frame tied to a range check. |

The minimum common set is 58 frames per appearance, including explicit left and right locomotion and kicks. Mum additionally needs five handover poses and six carry-walk poses per direction, with the visible food anchor following the hand. Sunbathers additionally need four reclining/rest poses, six get-up/settle poses, and five bend/pickup poses, with towel and bag fixed at home while the person moves.

## Gameplay mapping and review gate

- Mum's existing walk/carry, handover, alert, shield, chase and swat states map to the new clips. A visible snack stays stealable throughout eating and handover. Swat has priority over block; both recover into the current alert or locomotion state.
- Sunbather's wake, retrieve, return, warning and swat phases map to rise, chase/walk, alert and swat clips. Rest and towel are separate. Sunbather eat, block and kick are animation-only poses: they do not move food out of the bag or add defense, damage, or a new attack. The existing bag and swat rules remain authoritative.
- Review one right-facing and one left-facing contact frame, a full walk loop, chase loop, alert-to-block, swat and kick sequence, and the reclining/rise/pickup transitions at both 1× logical size and 4× display size. Reject a sheet if feet drift, adjacent walk frames repeat, the hand/food anchor jumps, the character changes size, colours exceed the palette limit, edge alpha is blended, or contours smooth out when rendered.
- Retain the old sheets as references. Production frames are mapped into gameplay after the approved style checkpoint, then checked at native size and in rendered scenes. Confirm DDH1 activity before running integration checks.

## Production source

The approved render is a style reference. `scripts/adult_pixel_art.gd` authors every production frame directly on a 64 × 64 native grid with a limited opaque palette. `tools/generate_retro_adults.gd` saves the five atlas variants, and `tools/map_retro_adults.ps1` keeps `data/sprites.json` aligned with those clip indices. The runtime uses native atlases for mum and both sunbather appearances, including separately generated left-facing travel and kick frames. The first large rendered concept sheets remain in `assets/previews` for visual comparison.
