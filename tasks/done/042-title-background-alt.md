# 042 — Second live background for the title menu (alternates with the current one)

Status: done
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-27

## Goal
The title menu currently always shows the same live sunset beach. Add a second, simple live background and alternate between the two so the title feels fresher on repeat visits. Keep it simple: reuse existing backgrounds, sky and props only.

## Context
- The title scene is built in `scripts/main.gd` `_ready()` (a `BeachBackdrop` with `sunset = true`, `strength = 0.12`, props hut/castle/palm, two `SunbatherTowel` + sunbather sprites, a `TitleFlyby`), and re-shown from `_navigate("title")` (~line 113).
- Sky, sun, sea, clouds and horizon come from `scripts/beach_background_art.gd` (assets in `assets/sprites/background-v2/`, optional `assets/sprites/horizon-v1/`, `overcast` preset, dusk tint) via `BeachBackdrop`.
- Only x >= ~207 is visible beside the menu panel. Logo and buttons must stay readable over both versions.
- `_scenery` (what the Practice menu hides to show the bare beach) must keep working for both versions.

## Requirements
1. Variant A is the current scene, unchanged.
2. Variant B: a daytime or overcast take using the existing sky/sun/sea/cloud art (day sky, not sunset, or the overcast preset), a different existing horizon strip if one fits, and a different small set of EXISTING props from `BACKDROP_PROPS`/`data/sprites.json` placed only in the visible x range. Reuse existing characters/flyby only as they already exist; no new art, no code-drawn characters.
3. Alternate on every time the title is shown (including returning from other screens): first show is A, next B, next A. Keep the toggle in memory; no save-file change.
4. No change to level backdrops, gameplay or menu layout. Do not use `beach_bucket` (unwired, see task 041).
5. Add a check to `tests/integration.gd` that the title builds both variants without errors and alternates.

## Out of scope
- New sprites, new music, changes to the logo or buttons. Do not stash, reset or discard uncommitted changes.

## Done when (acceptance)
- [x] Title alternates A/B across repeated visits; menu text and buttons stay readable on both
- [x] Practice menu still hides/shows scenery on both variants
- [x] `./tools/validate.ps1 -Capture` (or headless `tests/integration.tscn`) passes, no new failures; capture a screenshot of each variant in `test-output/` and mention it in the Report
- [x] Committed on `codex/042-title-background-alt`, task moved to `tasks/done/`, LOCK removed, not pushed

## Report
- Files changed: `scripts/main.gd`, `tests/integration.gd`, and this completion report. No art, level data, gameplay, logo, button, or menu-layout files were changed.
- The first title show remains variant A: the original sunset, hut/castle/palm, two sunbathers and towels, and existing flyby. Every later title show alternates B/A in memory, including returns from other screens; no save-file fields were added.
- Variant B uses the existing daytime sky/sun/sea/clouds, `headland-lighthouse` horizon (start x 248), and four existing backdrop props: jet ski (244,154), palm (292,144), ball (222,173), shells (286,171). Their complete displayed widths fit within x 207-320. B reuses the unchanged flyby and omits the sunbathers. No bucket is used. These are the task's discretionary art/composition choices; no new artwork was needed.
- Each title return releases the old backdrop, rebuilds `_scenery` for the active variant, and preserves Practice's hide/restore behavior. The gentle 0.12 breeze and live sea/cloud animation remain on both variants.
- Added 213 integration checks (including menu bounds/native-font checks) covering five alternating visits, original-A composition, daytime-B construction, prop bounds, live sea/cloud updates, Practice hiding/restoring every tracked item, and release of old backdrops without accumulation. Focused regression before implementation: 207 checks, 21 expected failures; after implementation: **213 checks, 0 failures**.
- Validation: direct full headless `tests/integration.tscn`: **19,467 checks, 0 failures**, exit 0. `git diff --check` passed. Reviewed using the GodotPrompter UI, testing and code-review skills.
- `tools/validate.ps1 -Capture` stopped during import because PowerShell treats Godot's sandbox root-certificate stderr as terminating. Direct editor import succeeded (exit 0). The directly launched hidden-window rendered integration run completed with 19,467 checks and 14 mouse/touch input-coordinate failures; the same full suite passed headlessly. Capture-window input behavior was not changed as part of this title-only task. Certificate, resource/image and shutdown-leak diagnostics remain in the logs.
- Captured and visually reviewed both variants: `test-output/title-background-a.png` and `test-output/title-background-b.png`, available in both the isolated checkout and caller workspace. Logo/tagline and menu buttons are readable in both. Logs in the isolated checkout: `.tools/title-red.log`, `.tools/title-green.log`, `.tools/integration-headless.log`, `.tools/validation.log`, and `test-output/task-042-capture{,-errors}.log`.
- Checkout: `.tools/task-042`. Branch: `codex/042-title-background-alt`. Last implementation commit: `f348104b78f61657562638acee62acbb8f43a54d`; this completion report is committed immediately afterward on the same branch.
- Sandbox adaptation: the shared repository denied creation of the task branch because its `.git` is read-only, and local `main` is already checked out in a separate worktree. Cloned local `main` at `623277f5e6d192e300d98a5e00ec82545eaa210c`, pulled that local main successfully, and created the task branch there. The GitHub pull failed with `SEC_E_NO_CREDENTIALS`; remote freshness beyond available local main could not be verified. Set a Codex author identity only in the isolated clone to enable committing.
- Handoff: implementation and report committed locally; task moved to `tasks/done/` in both checkouts; both queue locks removed after committing; **not pushed**. Incremental bundle: `.tools/task-042.bundle` in the caller workspace. Import with `git fetch .tools/task-042.bundle codex/042-title-background-alt:codex/042-title-background-alt`, then push the imported branch. The bundle requires the local-main base commit named above, already present in the caller repository.
- All pre-existing caller changes and every other task, including the sweeper/bin art tasks, were preserved. Godot's unrelated font `.import` change and two generated test `.gd.uid` files remain uncommitted only in the isolated clone; they were not reset, discarded or bundled.
- Anything not done: no push, as instructed; GitHub pull could not authenticate; the rendered input failures and validation-wrapper certificate restriction are recorded above. All task-specific checks and the full headless acceptance suite passed.
