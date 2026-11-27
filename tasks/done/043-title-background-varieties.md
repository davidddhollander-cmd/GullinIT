# 043 — Three more title backgrounds: sky, sea and land/island horizons only

Status: done
Author: Claude
Assignee: Codex
Depends on: 042 (NOT merged to main: base this task on branch `codex/042-title-background-alt`, see below)
Created: 2026-11-27

## Base branch (overrides the usual "branch from main")
Task 042 is committed on `codex/042-title-background-alt` (bundle `.tools/task-042.bundle`, already imported into the caller repo as that local branch) but is not on `main`. Clone the caller repo, check out `codex/042-title-background-alt`, and create `codex/043-title-background-varieties` from it. Your report must state the base commit. Do not merge anything into main.

## Goal
Add THREE more live title backgrounds to the rotation from 042 (currently A sunset, B day with lighthouse + props). New rotation: A, B, C, D, E, then repeat. Each new one must look clearly different at a glance, with a quiet "just the view" feel.

## Rules for the new varieties (C, D, E)
- Use ONLY the sky, sun, sea, clouds and the land/island horizon strips: `assets/sprites/background-v2/*`, `assets/sprites/horizon-v1/*` (`headland-hills`, `headland-lighthouse`, `headland-lighthouse-blue`, `island-lighthouse`, `islands-ferry`, `windfarm`, `cliffs-cottage`), plus the existing overcast preset, dusk tint and cloud layouts.
- NO props: do not place anything from `BACKDROP_PROPS`/`data/sprites.json` (no palm, ball, hut, castle, jet ski, shells, bucket, lifebuoys, towels, sunbathers). The existing `TitleFlyby` may stay on every variant as the live element.
- No new art, nothing code-drawn.
- Suggested set (change if something reads better, record the choice): C = overcast sky + `islands-ferry`; D = clear day with the sun in a different spot/cloud layout + `island-lighthouse`; E = sunset/dusk (different from A: other horizon, e.g. `windfarm` or `cliffs-cottage`). Each needs the horizon aligned so its land/islands show in the strip beside the menu panel (x >= ~207) and nothing important hides behind the menu.

## Requirements
1. Implement C, D, E in the 042 code (`scripts/main.gd` `_show_title_background()`); rotation order A, B, C, D, E, repeat; in-memory only; first show stays A.
2. Logo/tagline and buttons stay readable on all five (check text contrast on the overcast one in particular; adjust nothing in the menu itself if avoidable).
3. Practice menu hide/restore of scenery still works on every variant.
4. Extend the 042 integration checks: five-step rotation, no prop sprites on C/D/E, correct horizon ids, old backdrops released.

## Out of scope
- Level backdrops, gameplay, menu layout, new art. Do not stash, reset or discard uncommitted changes. Do not touch the sweeper/bin art tasks.

## Done when (acceptance)
- [x] Rotation A,B,C,D,E,A... works across repeated title visits
- [x] No wired-in props on C, D, E (test enforces it)
- [x] Headless `tests/integration.tscn` passes with no new failures; report check counts
- [x] A screenshot per new variant in `test-output/` (title-background-c/d/e.png), viewed and mentioned in the Report
- [x] Committed on `codex/043-title-background-varieties`, task moved to `tasks/done/`, LOCK removed, not pushed, bundle left for the caller

## Report
- Files changed: `scripts/main.gd`, `tests/integration.gd`, and this task report. Existing A/B compositions are preserved. No art, gameplay, level, menu-layout, logo, button, save-file, sweeper or bin-task changes.
- Base branch: `codex/042-title-background-alt`, base commit **f9af2bb61b960c38463a1d3a3ded1bdeccb209fd**. Created `codex/043-title-background-varieties` directly from that commit in `.tools/task-043`, a local clone of the caller repo. Followed this task's Base branch section rather than pulling or branching from main. Nothing merged into main.
- Rotation is now A/B/C/D/E/A in memory, beginning with the original A on startup. C uses the existing overcast preset and `islands-ferry`, horizon_x 40 (islands and ferry visible beside the menu). D uses clear day and `island-lighthouse`, horizon_x -12, a high sun at (276,18), and three existing plate-cloud placements. E uses the existing dusk sky/sea tint and `windfarm`, horizon_x 0. These match the suggested variety choices.
- C/D/E call setup with no props and contain only BeachBackgroundArt plus the existing TitleFlyby. Existing code-drawn distant bird flocks are hidden on C/D/E and excluded from Practice restoration; no new art or drawing code was added. Live sea/cloud animation and the gentle 0.12 breeze remain.
- Extended title checks cover two full five-step rotations, exact horizon ids/textures, prop absence, horizon visibility in x 207-319, sky presets, D's sun/cloud layout, live sea/cloud clocks, Practice hide/restore on every variant, hidden flocks after restoring C/D/E, and release of old backdrops without accumulation. The title coverage now runs **422 checks**, up from 213 (+209).
- Validation: full direct headless `tests/integration.tscn`: **19,676 checks, 0 failures**, exit 0. Focused rendered title run: **422 checks, 0 failures**. Direct editor import succeeded; `git diff --check` passed. Reviewed with GodotPrompter 2D, UI, testing and code-review skills; no outstanding title-specific issues. Regression checks initially failed against the A/B-only implementation before the new variants were implemented.
- Captured and viewed all five variants. New screenshots: `test-output/title-background-c.png`, `test-output/title-background-d.png`, `test-output/title-background-e.png`, present in both `.tools/task-043/test-output/` and the caller's `test-output/`. Confirmed clearly different views, visible horizon landmarks, readable logo/tagline/buttons (including overcast C), and no beach props on C/D/E. The menu itself required no adjustment. Screenshots are outside Git under the existing test-output ignore rule.
- Logs retained in the clone: `.tools/import.log`, `.tools/title-red.log`, `.tools/title-green.log` (intermediate run before the thin-turbine visibility threshold was corrected), `.tools/integration-headless.log`, and `test-output/title-capture{,-errors}.log` (final passing rendered run). Existing root-certificate, image-resource and shutdown-leak diagnostics still appear; the complete headless suite reports zero failed checks and exits 0.
- Branch: `codex/043-title-background-varieties`. Last implementation commit: **706746e7bf0f87ddb813fe835aa940936a637344**; this completion report is committed immediately afterward on the same branch.
- Handoff: committed locally in `.tools/task-043`; task moved to `tasks/done/` in the clone and caller; both `tasks/LOCK` files removed after committing. **Not pushed**, as instructed. Incremental bundle: `.tools/task-043.bundle`, requiring the base commit above, already present in the caller repo. Import with `git fetch .tools/task-043.bundle codex/043-title-background-varieties:codex/043-title-background-varieties`. The shared repo's Git metadata is read-only in this sandbox, so the branch commits live in the clone/bundle.
- All pre-existing caller changes and every other task, especially the sweeper/bin art tasks, were preserved. No stash, reset or discard was used. Godot's unrelated font `.import` change and two generated test `.gd.uid` files remain uncommitted only in the clone; they were not discarded or bundled.
- Anything not done: no push, as requested. All acceptance items are complete.
