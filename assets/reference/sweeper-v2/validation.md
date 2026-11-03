# Sweeper v2 verification

- Runtime atlas: 58 active frames in 211x176 native cells, six columns. Two final unused slots are transparent.
- The runtime entry and art metadata use the requested clip order, eight-frame walk/run, walk 11 fps, run 16 fps, sweep 12 fps, scale 0.5 and offset -33.
- All 25 explicitly supplied colours are used; every opaque pixel belongs to that palette. Alpha is only 0 or 255 and transparent RGB is zero.
- All bodies are registered to x=79 and ground edge y=154. Airborne run/surprise frames retain the same ground registration with an intentional lift.
- Walk contact feet separate by 56.4 and 59.7 native pixels. Passing swing-boot bounds end at y=141 versus ground y=154; both legs are visible. Eight distinct walk frames are included.
- Run local frame 3 is airborne: both boot bounds end above ground y=154.
- Bristle anchors are actual opaque pixels in the specified bristle colours. All six sweep contacts are on y=152, inside the one-pixel contour at ground edge y=154. Swat head travel is 108.3 native pixels. Hit frames are local indices [2, 3, 4, 5].
- Focused unchanged `tests/sweeper_checks.gd`: **26 checks, 0 failures**.
- Full integration baseline before art changes: **16666 checks, 8 failures**.
- Final full integration: **16670 checks, 9 failures**. The original eight failures remain. One additional failure is `every strip line fits 2 lines (worst 3)` in `tests/trainer_checks.gd:72`; this evaluates trainer text and fonts. Game/UI/font files changed concurrently during the task. No Sweeper failures were reported.
- An intermediate run encountered a transient BeachGame parser error during concurrent game script edits; the fresh focused and final runs loaded successfully.
- No gameplay scripts, integration tests, `tests/sweeper_checks.gd`, or `tools/bake_sweeper.py` were changed by this art task.

Exact logs and measurement JSON are stored beside this report. Untouched ImageGen sources and exact prompts are in the parent folder. The native 320x180 comparison and walk GIFs are in `assets/previews/`.
