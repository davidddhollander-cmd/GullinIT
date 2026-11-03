# 039 — Sweeper art v2: crisp colours, real walk and run

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 037
Created: 2026-11-03

## Goal
Regenerate the whole Sweeper animation set (replaces the v1 sheets in `assets/sprites/sweeper-*-v1.png`). v1 problems seen in play: (1) colours look soft and muddy next to the rest of the cast (only 28 flat colours, several close together, orange/skin/brown blur together, outline too faint); (2) the walk reads as a shuffle: both legs stay under the body, feet barely separate, no lifted back leg.

## What stays
Same character, same names and clips as 037/`docs/SWEEPER.md`: lanky tired middle-aged beach cleaner, olive bucket hat with navy band, off-white long-sleeve tee with sleeves pushed up, rust-orange dungarees with both straps fastened and a darker chest pocket, grey socks, tan work boots, full brown beard (kept by David), one wide wooden push broom with pale handle and yellow-brown bristle head, visible in every frame. Use `assets/sprites/sweeper-identity-v5.png` and the v1 sheets as the identity reference, plus `assets/sprites/retro-mum-32bit.png` as the **quality/density bar** for outline and colour.

## Output spec (new, so no resampling is needed)
- Native cells **211×176**, figure about **88 px tall** (feet on the same baseline row in every frame, 154 px from the top of the cell), drawn at the game's `visual_scale` 0.5. Body anchor x about 79 px from the left of the cell (the figure's centre of mass); keep it identical across frames so nothing slides. Whole figure including broom inside the cell.
- Faces right. Transparent background (real alpha).
- Crisp: hard pixel edges, no antialiasing, no gradients, no dither, no blended pixels, no glow. **Near-black outline #0A0A18, one pixel thick**, uniform around the whole figure and broom (like the mum sprite). Flat colour clusters with 3 distinct steps per material (highlight, base, shadow) and strong contrast between steps:
  - dungarees: #FF8A2A, #E5601A, #A8400F
  - skin: #FFC08A, #E8956A, #B9654A
  - tee: #FFF4DA, #E3D3B0, #B9A98A
  - hat: #8E9A3E, #66742C, #46501F; band #1D3347
  - beard/hair: #8A5A38, #5E3A24, #3A2314
  - boots: #6B7076, #474C52, #2B2F34
  - broom wood: #E3B26A, #C28E48; bristles: #F2C94C, #D4A232, #986E29
  Use these exact colours (about 28-32 total). Keep orange, skin and brown clearly distinguishable from each other.

## Clips (frame counts changed: walk and run are now 8)
| Clip | Frames | fps | loop | Notes |
| --- | --- | --- | --- | --- |
| `idle` | 4 | 3 | yes | as v1 |
| `walk` | **8** | 11 | yes | exaggerated, readable two-legged gait: contact, down, passing, up for each leg. Feet about one body-width apart at contact. The back leg visibly lifts and swings forward with a bent knee. Arms swing a little, torso bobs a few pixels, broom trails low behind in one hand. |
| `run` | **8** | 16 | yes | long stride, leaning forward, one airborne frame with both feet off the ground, broom held across the body, hat bobbing |
| `alert`, `warning` | 1 each | 2 | yes | as v1 |
| `angry` | 3 | 4 | no | as v1 |
| `windup` | 2 | 4 | yes | broom drawn back behind and above the shoulder, very clear |
| `swat` | 6 | 10 | no | big horizontal swing: broom passes in front of him at waist height, long follow-through; make the arc long (broom head travels at least 60 px) |
| `surprise` | 6 | 14 | no | same scale as the other clips (v1's first frame was about 20% small) |
| `fist_shake` | 6 | 7 | no | as v1 |
| `recover` | 3 | 6 | no | as v1 |
| `sweep` | 6 | 12 | yes | bristles on the ground in front of his feet, same ground contact height every frame, steady stride |
| `sweep_bin` | 4 | 6 | no | as v1 |

Total 58 frames. Deliver five sheets in the v1 layout (locomotion, combat, cleaning, reactions, identity), 6 columns, rows per clip, plus `assets/sprites/sweeper-animation-layout-v2.json` (cell size, per-clip frame indexes).

## Process
1. Regenerate with the built-in generator, identity first, then each sheet fed the identity as the strict reference. Keep the prompts and untouched sources in `assets/reference/sweeper-v2/`. No code-drawn pixels; code may crop, align, pack, harden alpha and snap to the palette above.
2. Pack the atlas as `assets/sprites/sweeper-v1/sweeper-v2-game.png` (6 columns, 211×176 cells, clips in the same order as `data/sprites.json` -> `sweeper`, walk and run now 8 frames, so later indexes shift). Update `data/sweeper_art.json` (`body_anchor_x`, `broom_ground_anchors_source_px`, `swat_reach_source_px`, `swat_hit_frames`, `bin_flick_anchors_source_px`; measured from the bristle pixels, in baked-cell pixels) and the `sweeper` entry in `data/sprites.json` (`frame_w` 211, `frame_h` 176, `visual_scale` 0.5, `sprite_offset_y` -33, new frame indexes). `tools/bake_sweeper.py` is no longer needed after this; leave it.
3. Preview: sweeper beside mum at in-game size, and a walk GIF. The walk must be judged as moving on two legs.

## Done when
- [ ] 58-frame atlas in place, clips as above, outline near-black 1 px everywhere, ~30 flat colours, no blended pixels
- [ ] Walk has a clear lifted back leg and separated feet; run has an airborne frame
- [ ] `./tools/validate.ps1` (or headless `tests/integration.tscn`) has no new failures (`tests/sweeper_checks.gd` must still pass)

## Report

## Review notes
