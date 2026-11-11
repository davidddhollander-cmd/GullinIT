# Sunbather sunglasses check, v2 — 11 November 2026

Replaces the rejected arm wave with David's approved action: rest, briefly lift
sunglasses, open both eyes and glance left then right, lower the glasses and rest.
Gameplay retains the existing `lie_shoo` name and 0.7-second second-peck reaction.

All character anatomy was generated with the built-in image generator. Code
only extracts alpha, crops, nearest-resizes, aligns, packs and applies the existing
garment palette conversion. No eyes, pupils, fingers, faces or bodies were painted
programmatically. Original generated PNGs and exact prompts are kept here.

- `male-red-source.png`, `female-red-source.png`: original five-pose source strips.
  Frames 1, 2 and 5 provide rest, lift and lower.
- `*-glance-reference.png`: untouched crops used as generation references.
- `*-left-source.png`, `*-right-source.png`: final independently generated full-body
  glance poses. These supply frames 3 and 4, making horizontal pupil movement
  clearer than the original strip at game resolution.
- `male-gaze-strip-rejected.png`: preserved intermediate that did not separate
  the two gaze directions clearly enough.
- `*-generated-packed.png`, `*-packed.png`: aligned generated red frames and
  production strips. Blue variants share the generated red geometry and use the
  established `blue_variant` garment conversion, preserving skin and hair.
- `*-rest.png`: unchanged original rest references.
- `measurements.json`, `atlas-audit.json`: frame bounds and original-cell audit.

Five frames, 128×128 cells, indices 88–92, 0.5 display scale, sprite Y -26.
All frames use the resting envelope: male 88×34 source pixels, female 98×36,
bottom boundary 116. A 2-source-pixel grid gives 1-screen-pixel colour blocks.
Alpha is exclusively 0/255. The existing separate towel stays stationary.
All original 88 cells per atlas remain unchanged.

Rebuild using `tools/prepare_sunbather_shoo.py --godot PATH_TO_GODOT_CONSOLE`.
The retained script name reflects the existing gameplay animation API.
`diner_adult_atlas_source.gd` resolves the new v2 packed sources too.

Previews: `assets/previews/sunbather-sunglasses-v2-1x.png`, `*-4x.png`, `*.gif`.
The GIF includes extra resting time for review; game playback remains 0.7 s.
Art Lab uses the four SUNGLASSES comparisons beside a standing shopper.
