# Shopper walking pilot

**Rejected by the user, 20 October 2026.** The original yellow-shirt shopper's existing walk is preferred and is the approved motion reference. Do not promote this cutout pilot into gameplay. See `SHOPPER_WALK_REASSESSMENT.md` for the corrected scope: the older woman and stocky mullet shopper need improved drawn walk frames. The remainder of this document records the rejected experiment.

20 October 2026. Review pilot for the original yellow-shirt shopper. The comparison is isolated from the regular game and its character animation registry.

## Review

Open `assets/archive/previews/shopper-walk-pilot-v1.gif`: current animation on the left, the selected cutout pilot on the right. The three rows demonstrate a cycle in place, patrol at 9 pixels/second and a kiosk trip at 20 pixels/second. Both columns move at the same speeds and turn left. Food remains separate and follows the generated hand.

Run `tools/walk_cycle_pilot.tscn` in Godot for the live version. Space pauses and R replays. The top row demonstrates one cycle per second. The moving pilot rows follow distance travelled, with a 28-pixel full stride: about 3.11 seconds per patrol cycle and 1.4 seconds per kiosk-trip cycle.

The eight key positions are also baked into `assets/archive/pilots/shopper-walk-v1/rig-poses.png` for pose review. These are renders of animated generated artwork, not characters drawn with primitives.

## Why the approach changed

Several whole-body ImageGen sheets repeated the same leading leg despite explicit pose instructions and correction attempts. Those candidates are preserved for comparison. Their increased knee lift alone was insufficient to establish a dependable full gait.

The selected pilot uses a generated upper body and six separately generated limb pieces: near/far thighs, calves and sandals. Godot moves and rotates those image assets so each leg genuinely exchanges support. Knee position follows two fixed seven-pixel segments; the swing foot lifts four pixels while the supporting ankle remains fixed against the ground during travel. There is no code-drawn character anatomy. All faces, clothes, skin, limbs and shoes originate in ImageGen artwork.

The upper body is cropped from the generated complete character; its complete source remains intact. The limb source was refined with ImageGen to match the body's flat warm skin and navy outlines. Technical preparation only crops, removes translucent edge fringes, aligns pivots and resizes the artwork. Dense sampling during rotation retains source detail. Body height stays approximately 40 game pixels.

## Assets and reproduction

- Complete sources, rejected attempts and exact built-in-tool prompts: `assets/reference/shopper-walk-pilot-v1/`.
- Selected limb source: `leg-parts-flat.png`; upper-body source: `source.png`.
- Prepared body and six parts, pivot/dimension metadata: `assets/archive/pilots/shopper-walk-v1/rig.json` and sibling PNGs.
- Earlier whole-body frame candidate: `walk.png` / `walk.json`; retained as experimental reference, not the selected moving pilot.
- Preparation: `tools/prepare_walk_pilot.gd`, then `tools/prepare_walk_rig.gd`.
- Joint animation and distance phase: `tools/walk_pilot_rig.gd`, `tools/walk_pilot_motion.gd`.

Render `tools/walk_cycle_pilot.tscn -- --record-pilot` for 128 deterministic frames at 20 fps under `test-output/walk-pilot-frames`, three comparison stills, and the eight-pose sheet. Encode the PNG sequence with FFmpeg using a shared palette and no dithering. The GIF lasts 6.4 seconds and replays the demonstration.

## Validation and remaining review

The focused suite passes 1,113 checks. It covers generated-frame bounds/alpha/hand anchors, frame-rate independence, reversed travel, pause/stopping, fixed thigh/calf lengths, foot lift, opposing contacts and supporting-foot world position at both travel speeds and 30/60/120 Hz. The joint-space support foot stays fixed within 0.001 logical pixels in those checks. Raster sampling and the turn itself still need visual judgement; that analytical result is not a certification of every rendered pixel.

Run:

```powershell
& ./.tools/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/walk_pilot_checks.gd
```

The rendered comparison exits with an empty error log. The headless asset/check scripts produce the project's existing autoload-music shutdown warning after completing their work; this is separate from the checks and the review scene.

This is a locomotion pilot, not a finished cast replacement. The joints and shorts-to-thigh seams need an art review, and the free arm still lacks a natural counter-swing. Left-facing motion mirrors the same generated pieces. The very slow patrol may benefit from a shorter-stride stroll. Keep the pilot isolated until the look and cadence have been reviewed, then decide whether to use the rig or bake its poses for production. Service counters, rear-lane draw order, scoring and normal AI are unchanged.
