# Mum artwork — 8 October 2026

Replaced the 16 × 32 placeholder parent sheet with `assets/sprites/mum-polished.png`, created using the built-in ChatGPT image generator. The original placeholder remains available. One brunette mum appearance currently serves all families.

The new transparent 1279 × 1230 source contains 16 poses. `tools/map_mum_sheet.py` reads alpha bounds and writes atlas regions into `data/sprites.json`; it does not modify source pixels. Frames use a shared 400 × 320 canvas and 0.13 display scale. Linear filtering with mipmaps and the existing alpha-cutout shader preserve detail at game size. Generated frames still have slight natural proportion variation; this is a first art pass, not a hand-cleaned animation master.

## Animation behaviour

- Four-frame walking and carrying cycles follow actual family movement. Buying and gathering pauses stop the walk.
- The handover bends down toward the child. Food stays separate, follows the hand in both directions, and uses its visible position for theft.
- Shielding, alert and brief swat poses follow existing defenses. Swatting has priority over shielding, then returns to the appropriate pose.
- Family supplies, shopping, handover timing and attack rules remain governed by existing mechanics.

Rendered validation: **981 checks, zero failures**. Added checks cover atlas bounds, shared canvas, mipmaps, directional carrying, stopped walking, animation continuity, lowered handover food and defense transitions. Existing family and theft tests also pass. Captures: `test-output/mum-walking.png`, `mum-carrying.png`, `mum-handover.png`, `mum-shielding.png`, `mum-swat.png`. Carrying and handover captures visually reviewed at 1280 × 720.

## Generation prompt

Create production 2D game sprite sheet on genuinely transparent background: one beach mum, cheerful adult brunette ponytail, coral sleeveless blouse, teal knee-length shorts, sandals, warm skin, crisp detailed pixel-art/cartoon hybrid matching polished seaside arcade characters. EXACT uniform 4 columns x 4 rows =16 separate full-body frames, generous transparent gutters, no text, no labels, no gridlines, no ground shadows. All face RIGHT in consistent side/three-quarter side view. Identical head size/body proportions every frame. Each cell same dimensions; feet at identical baseline within each cell, whole figure fits, no overlap. Row1: four sequential WALK frames empty hands, complete natural step cycle. Row2: four sequential CARRY-WALK frames carrying plain canvas grocery tote in back hand, front hand held forward waist-height EMPTY to receive separate in-game food overlay. Row3: four HANDOVER frames: standing, bending knees gently, extending empty front hand down toward child-height, returning upright. No child in image. Row4: SHIELD pose with front forearm across chest protecting empty space, WINDUP pose raised empty hand, SWAT pose palm extending forward and down, RECOVERY pose hand lowered. No actual food or snacks painted anywhere. No extra people or props except plain tote in row2. Clean alpha edges, no black background, no checkerboard baked in. Art must remain readable scaled to about40 logical pixels tall but retain fine detail at a1280x720 display.
