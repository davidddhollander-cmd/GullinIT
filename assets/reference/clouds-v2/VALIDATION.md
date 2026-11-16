# Task 094 validation — 2026-11-16

Godot 4.7.2, Windows; `tools/validate.ps1` with explicit Godot executable.
Baseline and final both complete **17,883 checks with 6 failures**, exit 1.
There are **no new failures** after normalizing generated Button instance IDs.

Existing failures in both runs:

- completed Training Day card clearly offers the lessons
- the freeze says how to steer: Aim with the mouse/WASD and line up the snack.
- level card shows stars only, no quest count or best score
- trained level 1 card has no quest count
- UI bounds: Button at `(0,-7)`, size `(48,13)`
- UI bounds: Button at `(52,-7)`, size `(39,13)`

Both runs also contain the same `food_checks` out-of-bounds script error at
`tests/integration.gd:2477`, one occurrence, and pre-existing tree/resource
cleanup warnings. These were left outside task 094's art-only scope.

The test harness persists `test-output/mouse-role-save.json`; repeated runs
can add two mouse-role failures. The clean final run started without that
generated fixture, matching the initial baseline. Its previous contents were
preserved at `../task-094-mouse-role-save-before-final.json` locally.

Asset QA passed:

- 12 unique IDs and distinct sprites: 8 fair and 4 windy.
- All 12 JSON regions cover exactly their cloud; no opaque pixels outside them.
- Regular 192x112 cells, minimum 8 px padding, transparent gutters.
- Atlas 768x336; alpha only 0/255; opaque palette only #fff4da / #8e9b9e.
- Unscaled generated detail retained; all recommended display scales 0.5.
- Complete original sources byte-compared to generation outputs, identical.
- Actual Godot dusk-shader rendering: `CLOUD PREVIEW: OK`.
- Final day/dusk board visually inspected for all 12 sprites.
- No game scripts, level/tuning data, shaders, existing sky plate or sea changed.

Full local logs are outside the worktree: `../task-094-baseline.log` and
`../task-094-final-clean-validation.log`.
