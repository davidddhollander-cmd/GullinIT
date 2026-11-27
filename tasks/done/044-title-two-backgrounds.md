# 044 — Trim the title rotation to two backgrounds (A original + D) with strong tagline contrast

Status: done
Author: Claude
Assignee: Codex
Depends on: 042, 043 (neither merged to main: base on branch `codex/043-title-background-varieties`)
Created: 2026-11-27

## Base branch (overrides the usual "branch from main")
Clone the caller repo, check out `codex/043-title-background-varieties` (local branch, includes 042), and create `codex/044-title-two-backgrounds` from it. State the base commit in the Report. Do not merge into main.

## Goal
David picked the final two title backgrounds. The title alternates between exactly these:
- **A (unchanged):** the original sunset beach with ALL its existing props, sunbathers, towels and flyby. Do not change it.
- **D (from 043, extended):** clear day, `island-lighthouse` horizon, moved sun and cloud layout, flyby, PLUS the background birds (the distant flocks, `background_art.birds`, currently hidden on D) visible and live, PLUS one palm tree and one beach ball placed next to each other in the open strip beside the menu panel (x >= ~207, clear of the lighthouse and of the menu), using the existing `beach_palm` and `beach_ball` sprites at their normal scale/style as in-game.

## Requirements
1. Rotation is A, D, A, D...; first show is A; in-memory only. Remove variants B, C and E from `scripts/main.gd` (the 042/043 code) and from the tests; leave no dead code. Keep the Practice menu hide/restore working on both (D's palm, ball and birds must hide and restore too, via `_scenery`).
2. D's birds must be visible and animated, and must hide under the Practice "bare beach" mode like A's.
3. **Strong tagline contrast on both A and D.** Today the tagline "THE NO. 1 SEAGULL SIMULATOR" renders dark brown on the day variants and is weak on dusk. Make it clearly legible on both: sample the pixels behind the tagline in a capture of each variant and compute the WCAG contrast ratio of the tagline colour against them; target >= 7:1 (at least 4.5:1 on the worst sample), e.g. gold/cream fill with a dark navy outline or a soft dark backing, whichever keeps the style. Find out WHY it turns brown on day (theme, shader, tint?) and fix the cause rather than hard-coding two colours if possible. Do not change the logo, buttons or menu layout. Text uses the GullPixel font on its 8 px grid.
4. Update the integration checks: two-step rotation, A unchanged composition, D has horizon `island-lighthouse`, exactly one palm and one ball, birds visible and animated, tagline contrast check (>= the chosen threshold) on both.

## Out of scope
- Level backdrops, gameplay, new art, menu layout. Do not stash, reset or discard uncommitted changes. Do not touch the sweeper/bin art tasks.

## Done when (acceptance)
- [x] Title alternates A, D, A, D; Practice hide/restore works on both
- [x] D shows birds, a palm and a ball next to each other, no other props
- [x] Measured tagline contrast on A and D meets the target; numbers in the Report
- [x] Headless `tests/integration.tscn` passes, no new failures; counts in the Report
- [x] Screenshots `test-output/title-background-a.png` and `title-background-d.png` refreshed, viewed and mentioned in the Report
- [x] Committed on `codex/044-title-two-backgrounds`, task moved to `tasks/done/`, LOCK removed, not pushed, bundle left for the caller

## Report

- Files changed: `scripts/main.gd`, `scripts/menus.gd`, `tests/integration.gd`, and this task report. Reused existing art only. No level backdrops, gameplay, logo, buttons, menu layout, other task files, sweeper or bin art changes.
- Base: `codex/043-title-background-varieties` at **d4fcd2f53c599d6f1175f09821ae9101e76801a0**, which includes 042. Cloned the caller repo into `.tools/task-044`, checked out that local branch and created `codex/044-title-two-backgrounds` directly from it, as required by the Base branch section. Did not pull/branch from or merge into main; the caller's dirty worktree and current branch were left in place.
- Title rotation is exactly A/D/A/D in memory, starting with A. Removed the B/C/E branches and their obsolete title checks. A's setup, hut/castle/palm, castle adjustment, sunbathers/towels and flyby are unchanged. D retains `island-lighthouse`, horizon_x -12, clear sky, sun (276,18), and all three cloud placements from 043. Its distant birds are visible and updated by the existing beach clock. D adds exactly one normal-scale palm at (238,156) and one normal-scale ball at (265,156); their complete frames fit in the open strip and below the lighthouse horizon. Both variants track birds, flyby and all props/characters in `_scenery` for Practice hide/restore.
- Brown-text cause confirmed with the actual base-commit `menus.gd` in an isolated diagnostic probe: first title colour **#ffc65c**, then **#a8581c** after `options(false)` immediately followed by `title()`. Material was null and modulate remained white in both cases. `clear()` had queued `_ink_labels()` over the entire menu; when the title was rebuilt before the deferred call, the cream-board gold-to-brown mapping recoloured the new floating tagline. Fixed the cause by binding that pass to its own board panel, with a validity guard. Regression checks exercise the immediate options/title return on both A and D.
- Strong tagline contrast uses one shared cream fill **#fff4da** on an opaque ink/navy **#183b4e** Label backing. GullPixel remains exactly 8 px. A zero-content-margin StyleBoxFlat with 2 px visual expansion adds a snug backing without changing the row height or logo/button/menu placement. Replaced the previous one-pixel shadow treatment; no per-variant colours or new art.
- Contrast measured from real 1280x720 rendered captures, using WCAG linear-sRGB relative luminance and `(Llighter + 0.05)/(Ldarker + 0.05)`. Temporarily made only the glyph fill transparent, leaving backing, layout and beach clock fixed; sampled the underlying rendered pixels at every cream glyph pixel. **A: 5,312 samples, worst 10.82297:1; D: 5,312 samples, worst 10.82297:1**. All sampled backgrounds were #183b4e. Both exceed the selected **7:1** threshold (and 4.5:1 worst-sample floor). Numeric artifacts: `test-output/title-contrast-a.json` and `title-contrast-d.json`, in both clone and caller.
- Integration coverage checks two complete A/D rotations; unchanged original-A composition; exact D prop types/count/normal scale/placement; D horizon, sun and clouds; sea/cloud clocks; actual changing flock pixels through `beach.tick`; Practice hide/restore including birds/palm/ball; deferred recolour regression; backdrop release; UI bounds and native font grid. Headless checks assert the shared palette contrast, and rendered checks additionally measure real glyph/background pixels.
- Validation: focused headless title checks **200 checks, 0 failures**; rendered title/capture run **204 checks, 0 failures**. Full headless `tests/integration.tscn`: **19,454 checks, 0 failures**, exit 0. Direct editor import succeeded. `git diff --check` passed. Reviewed using GodotPrompter UI, 2D, debugging, testing and code-review skills.
- Refreshed and viewed `test-output/title-background-a.png` and `test-output/title-background-d.png`; both copied to the caller's `test-output/`. Confirmed A's original scenery, D's visible live flock and adjacent palm/ball clear of the lighthouse, and readable cream tagline on both. Captures/JSON are outside Git under the existing test-output ignore rule.
- Logs and diagnostic runners retained in clone `.tools/`: `import{,-errors}.log`, `title-headless.log`, `integration-headless.log`, `tagline-cause-fixed-probe.log`, and `test-output/title-capture{,-errors}.log`. Existing sandbox root-certificate and suite image/resource/shutdown diagnostics remain; no title check failures. Godot's unrelated font `.import` change and generated `tests/backup_snack_checks.gd.uid` / `tests/signpost_checks.gd.uid` remain uncommitted only in the clone; they were not discarded or bundled.
- Branch: `codex/044-title-two-backgrounds`. Last implementation commit: **ccdabee2c06e282ce9086845ac001b990ff83f25**; this completion report is committed afterward on the same branch.
- Handoff: local commits in `.tools/task-044`, task moved to `tasks/done/` in clone and caller, both queue locks removed after committing. **Not pushed**, per the user's sandbox instruction. Incremental bundle `.tools/task-044.bundle` requires the base commit above, already in the caller repo. Import with `git fetch .tools/task-044.bundle codex/044-title-two-backgrounds:codex/044-title-two-backgrounds`. Shared-repo Git metadata remains read-only in this sandbox; branch commits are in the writable clone/bundle.
- All pre-existing caller changes and every other task were preserved. No stash, reset or discard was used. Anything not done: no push, as requested; no acceptance work left outstanding.
