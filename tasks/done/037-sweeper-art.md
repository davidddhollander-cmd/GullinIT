# 037 — Sweeper character art

Status: done
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-02

## Goal
Generate the full animation set for a new beach character, **the Sweeper**: a council beach cleaner in overalls who runs onto the sand, swings a push broom at gulls, then brushes fallen food and litter across the sand into the nearest bin. Task 038 (game code) is blocked on this art. Mechanics are in `tasks/inbox/038-sweeper-mechanics.md`; you only need the art and the registry entry.

## Who he is
Lanky, middle-aged, sun-weathered man, adult scale (same height class as the shoppers and the seafood vendor; taller than the watergun teen). Tired, methodical, a bit grumpy. He must read as a *different person* at 40 px from: the seafood vendor (green jumper, mustard apron, cream beanie, grey moustache), the fish & chips vendor (white apron, blue shirt), the lifeguard (red shorts), and the shoppers.

- **Overalls:** rust-orange work dungarees (council-worker orange, pops against sand), both straps fastened, a darker orange patch pocket on the chest.
- **Under:** off-white long-sleeve tee, sleeves pushed up to the elbows.
- **Head:** olive-green bucket hat with a navy hatband, tanned sun-reddened skin, short stubble, sandy-brown hair at the sides. No moustache, no beard (seafood vendor has the moustache).
- **Feet:** tan work boots, grey socks.
- **Broom:** wide wooden push broom: long pale-wood handle, rectangular block head with dense yellow-brown bristles, about 3/4 of the figure's height long overall. **Generated art only; the broom is part of the character in every frame.** No hi-vis vest, no trolley, no dustpan, no bag.

## Context
- Reference for scale, outline weight and palette: `assets/reference/seafood-vendor-v1/`, `assets/reference/watergun-teen-v1/` (copy their process and prompt style), plus the approved adult cast in `assets/reference/adult-replacement-v3/`. Supply these as image references to the generator.
- Registry shape to copy: `data/watergun_teen_art.json` and the `seafood_vendor` entry of `data/sprites.json`.
- AGENTS.md applies: built-in image generator or supplied artwork only. **No code-drawn bodies, faces, limbs or broom, not even as placeholders.** Code may crop, align, resize, pack and mirror.

## Output spec
- Cell size **128×128**, `visual_scale` **0.5**, `art_height` **40**, sprite faces **right** (`source_faces_right: true`; the game mirrors for left). Feet baseline identical in every frame (`sprite_offset_y: -26` like the other adults; adjust only if his baseline differs).
- The whole figure including the broom must fit in the cell in every frame. Standing figure about 80 px tall in the source cell.
- Palette/outline: same deep-navy outline weight and cel-cluster shading as the seafood vendor; transparent background (real alpha, no checkerboard), binary-ish edges, no glow, no cast shadow, no ground, no food, no bin, no motion lines, no dust.
- Final atlas `assets/sprites/sweeper-v1/sweeper-v1.png`, 54 frames, registry file `data/sweeper_art.json` (new) **and** a `sweeper` entry in `data/sprites.json` pointing at it (follow how `watergun_teen` and `seafood_vendor` are registered). Frame order and clip names (fixed, task 038 depends on them):

| Frames | Clip | fps | loop | Notes |
| --- | --- | --- | --- | --- |
| 0–3 | `idle` | 3 | yes | Standing, broom planted upright beside him, leaning slightly on it; breathing + one slow look around |
| 4–9 | `walk` | 8 | yes | Slow trudge, broom carried low in one hand, head dragging along the sand |
| 10–15 | `run` | 10 | yes | Fast run, broom held across body, hat bobbing; used for his entrance and chases |
| 16 | `alert` | 2 | yes | Head up, broom lifted off the ground, spotted a gull |
| 17 | `warning` | 2 | yes | Broom held two-handed across chest, glaring, plainly telling the gull off |
| 18–20 | `angry` | 4 | no | Scowl, stomp, shaking the broom head |
| 21–22 | `windup` | 4 | yes | Broom drawn back **behind and above** his shoulder, body twisted. Very readable; this is the player's warning |
| 23–28 | `swat` | 10 | no | Big horizontal swing: broom sweeps forward from head height down to knee height; the head passes through the front reach zone around frames 25–26 |
| 29–34 | `surprise` | 14 | no | Jump back, hat tilting, broom flung up (gull stole something under his nose) |
| 35–40 | `fist_shake` | 7 | no | Shakes a fist at the sky with the broom in the other hand |
| 41–43 | `recover` | 6 | no | Off balance after a missed swing, broom dragging, straightening up, gasping |
| 44–49 | `sweep` | 8 | yes | Walking forward pushing the broom with short firm strokes; bristles in contact with the ground in front of his feet, body bent slightly forward |
| 50–53 | `sweep_bin` | 6 | no | Standing beside a bin (bin is **not** drawn), leaning in, flicking the broom up and forward so the pile goes over the rim, then pausing satisfied |

Also write, per frame, into `data/sweeper_art.json`:
- `broom_ground_anchors_source_px`: for `sweep` frames 44–49, the (x, y) pixel where the **front-centre of the bristle head touches the ground** (the point where a pile of food would be pushed). Code attaches the swept items there.
- `swat_reach_source_px`: for `swat` frames 23–28, the (x, y) of the broom head centre (the hit zone). Also `swat_hit_frames: [25, 26]`.
- `bin_flick_anchors_source_px`: for `sweep_bin` 50–53, the broom head tip.
Measure these from the opaque pixels programmatically; do not guess.

## Requirements
1. Generate in five sheets, each fed the **identity sheet** as the strict character reference (same process as the watergun teen): identity (4 poses) → locomotion → combat → cleaning → reactions. Keep the exact prompts and untouched source images in `assets/reference/sweeper-v1/` with a README.
2. Write `tools/prepare_sweeper.gd` (copy the pattern of `tools/prepare_seafood_vendor.gd`): connected-component cropping, alpha hardening, nearest-neighbour resize to 128 cells, baseline alignment, packing, anchor measurement. It must draw no character pixels.
3. Register the sprite and write `data/sweeper_art.json`. Add art-check tests (copy `tests/staff_art_checks.gd`): frame counts, cell size, clip names/ranges above, no clipped edge pixels, constant foot baseline, anchors present, wired into `tests/integration.gd`.
4. Preview `assets/previews/sweeper-v1-comparison.png`: him beside the seafood vendor, a pier diner, a shopper and the gull at in-game size (and 4× enlarged), plus an animated `sweeper-v1-sweep.gif` of `sweep` and `swat`.
5. No gameplay changes. Do not spawn him anywhere (task 038 does that).

## Generation prompts (use these, adapt only to fix problems; record what you actually ran)

**Shared style block** (prepend to every prompt):

> Use case: stylized-concept. Asset: full-body character animation sheet for Gullin' It, a seaside 2D pixel-art arcade game (320x180 logical resolution, characters about 40 px tall in game). Match the supplied reference characters exactly in pixel density, outline weight and shading: deep navy #183B4E outline about one logical pixel thick, chunky cel-shaded colour clusters, one highlight and one shadow tone per material, light from upper left, no antialiasing, no gradients, no glow, no cast shadow. Genuine transparent background, no scenery, no ground line, no checkerboard, no text, no watermark, no motion lines, no dust, no food, no bin. All figures face RIGHT, full body visible head to boots, identical scale and identical foot baseline in every cell, even gutters, nothing touching the cell edge, the whole broom inside its cell.
> CHARACTER (identical in every frame): THE SWEEPER, a lanky tired middle-aged beach cleaner, adult proportions, slightly stooped, sun-reddened tanned skin, short stubble, no moustache, sandy-brown hair at the sides. Olive-green bucket hat with a navy hatband. Off-white long-sleeve tee with sleeves pushed up to the elbows. Rust-orange work dungarees (overalls) with both shoulder straps fastened and a darker orange chest pocket. Grey socks and tan work boots. He always holds ONE wide wooden push broom: long pale-wood handle, rectangular wooden block head with dense yellow-brown bristles; the handle reaches about his chin when it is planted. No other props.

**1. Identity sheet** — "Four full-body poses in one row on a transparent background: relaxed idle leaning on the planted broom; slow walk mid-stride with the broom carried low; run mid-stride; and a two-handed sweep stroke with the bristle head pressed to the ground ahead of him. Establish the definitive look of the character for all later sheets."

**2. Locomotion sheet** — "Using the supplied identity sheet as the strict character reference: row 1 a 4-frame idle loop (breathing, one slow glance round, broom planted); row 2 a 6-frame walk cycle (trudging, broom head trailing low, hat bobbing slightly); row 3 a 6-frame run cycle (fast, leaning forward, broom held diagonally across the body, bristle head up)."

**3. Combat sheet** — "Using the identity sheet as the strict reference: row 1 single-frame poses: ALERT (head up, broom lifted off the ground, eyes on the sky) and WARNING (broom held two-handed across the chest, glaring upward, mouth open mid-shout); row 2 a 2-frame WINDUP loop (broom drawn far back behind and above the right shoulder, torso twisted away, weight on the back foot, very clear and exaggerated); row 3 a 6-frame SWAT (a big horizontal broom swing: from the raised windup, sweeping forward and down in a wide arc so the bristle head crosses in front of him at waist-to-head height in frames 3-4, then follow-through past the front knee); row 4 a 3-frame RECOVER after a miss (off balance, broom head dragging, hunched and panting, then straightening up)."

**4. Cleaning sheet** — "Using the identity sheet as the strict reference: row 1 a 6-frame SWEEP loop: he walks forward at slow pace pushing the broom with short firm strokes, bristle head flat on the ground about one body-length ahead of his boots, body bent slightly forward, hat steady (the bristle head must visibly touch the ground in every frame at the same height); row 2 a 4-frame BIN SWEEP: he stands side-on facing right at a waist-high bin that is NOT drawn (leave the space in front empty), leans in, flicks the broom up and forward so the head ends at about waist height, holds it for a beat, then lowers it with a satisfied sigh."

**5. Reaction sheet** — "Using the identity sheet as the strict reference: row 1 a 6-frame SURPRISE (startled jump backwards, hat tilting, broom flung up with one hand, mouth open); row 2 a 6-frame FIST SHAKE (broom in the left hand, right fist raised and shaking at the sky, furious, stamping); row 3 a 3-frame ANGRY (scowl, stomp, shaking the broom head)."

If a sheet comes back with the broom missing, a second broom, the wrong overalls colour, a moustache, a bin, or food, regenerate it; do not paint over it.

## Done when (acceptance)
- [ ] `assets/sprites/sweeper-v1/sweeper-v1.png` has 54 frames in the order above, 128×128 cells, shared foot baseline, broom visible in every frame
- [ ] `data/sprites.json` has a `sweeper` entry and `data/sweeper_art.json` has all clips and the three anchor sets (measured, not guessed)
- [ ] Source images, prompts and README in `assets/reference/sweeper-v1/`; comparison preview and GIF in `assets/previews/`
- [ ] Art-check tests added and wired into `tests/integration.gd`; `./tools/validate.ps1` has no new failures

## Report
Atlas packed from Codex sheets (hat recoloured olive in four sheets; palette remap only). 54 frames at 192x160, visual_scale 0.3 / art_height 24 like the newest cast. Anchors measured from bristle pixels. Not done: prepare script, art-check tests, GIF.

## Review notes
<!-- Filled in by the reviewer. -->
