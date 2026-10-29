# Art audit tools

Pixel-art consistency checks for Gullin' It. Background, standard and latest results: `docs/ART_AUDIT_2026-10-27.md`.

| File | What it does |
| --- | --- |
| `build_manifest.py` | Lists every runtime sprite with its first-frame rect and in-game scale, read from `data/*.json` and the few scales set in code. Re-run after adding sprites or changing a `visual_scale`. |
| `art_manifest.json` | Output of the above (committed so diffs show scale changes). |
| `gullinit_audit.py` | The audit: source checks (soft alpha, import settings), on-screen checks (pixel density vs the 0.5 cast standard, palette, colours, outline, peer outliers), project settings and linear-filter overrides. Writes `report.md`, `findings.json` and two lineup PNGs. Exit code 1 while S1 findings remain. |
| `pixel_audit.py` | Generic 1:1 pixel-art checker (palette, alpha, scale, orphans, frame baselines, import). Useful for new props and VFX. |
| `palette.hex` | Reference palette, outline colour first. |

```
pip install pillow numpy
python tools/art_audit/build_manifest.py > tools/art_audit/art_manifest.json
python tools/art_audit/gullinit_audit.py --project . --manifest tools/art_audit/art_manifest.json --palette tools/art_audit/palette.hex --out test-output/art_audit
```

Severity: S1 blocks a commit (uneven pixels, soft alpha, linear filtering, lossy import). S2 blocks an itch.io build. S3 next weekly pass. S4 housekeeping.
