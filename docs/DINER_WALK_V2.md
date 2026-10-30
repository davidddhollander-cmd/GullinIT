# Pier diner walk v2

The original pier diner now uses a six-phase carrying walk generated from her approved artwork. The cycle reads contact, weight-down, passing, opposite contact, opposite weight-down and opposite passing. Her free arm counter-swings while the forward serving palm remains steady for the separate stealable food sprite. The six complete generated figures share a 398-pixel sole baseline, a stable 338-pixel body height and the existing 0.11 gameplay scale.

Runtime uses `assets/sprites/pier-diner-motion-v2.png`. `tools/prepare_diner_walk_v2.gd` crops, nearest-neighbour scales, aligns and packs the complete generated figures. It then copies the approved four-frame run and four-frame eating animation pixel-for-pixel from `assets/sprites/pier-diner-motion-clean.png`; that original atlas remains untouched. The selected generated sheet and exact prompt are preserved under `assets/reference/diner-walk-v2/`.

Normal routine walking remains 9 pixels per second and plays at 7 fps. The faster leaving state still moves at 27 pixels per second and now plays the same walk at a 3× cadence, preventing foot skating. Pursuit continues to use the existing 10 fps run. Both directions use sprite mirroring, and all six walk frames keep the separate food anchor at `(10, -22)` before facing mirroring.

Review assets:

- `assets/archive/previews/diner-walk-v2.png` compares the old and new walks, shows both directions with food at actual gameplay scale, and enlarges all six new poses.
- `assets/archive/previews/diner-walk-v2-live.png` is a captured actual-scale live sample.
- Run `tools/diner_walk_v2_live_preview.tscn` for the moving normal/fast comparison; Space pauses it.

Focused validation is in `tests/diner_walk_v2_checks.tscn`. It checks clip timing, complete isolated figures, sole alignment and height, mirrored food anchors, pause behavior, normal/fast cadence and pixel-identical preservation of run/eat art.

Visual review found planted contacts, clear passing feet, stable body volume and a steady food hand at gameplay scale. The new generated walk has slightly cleaner facial and outline detail than the older run/eat drawings, so the walk-to-run transition still exposes a small style-age difference; the approved run was intentionally not regenerated in this diner-only walk pass.
