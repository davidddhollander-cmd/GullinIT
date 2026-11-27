# 041 — Unwire the beach bucket prop from the main build

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-11-27

## Goal
The bucket-and-spade backdrop prop (`beach_bucket`) is not right and must not appear anywhere in the main build. Unwire it; keep the art assets so it can be redone later.

## Context (found on main)
- `scripts/beach.gd` line ~16: `BACKDROP_PROPS` lists `"beach_bucket"`.
- `data/levels/level_01.json`: `"thumb": "beach_bucket"` and a placement `{"type": "beach_bucket", "x": 194, "y": 138}`.
- `data/levels/level_02.json`: placement `{"type": "beach_bucket", "x": 110, "y": 146}`.
- `data/sprites.json` entry `beach_bucket`, `data/art_lab.json` bucket entries, `tools/prepare_beach_props_v*.py`, `tools/art_audit/prop_candidates.py`, the PNGs in `assets/sprites/beach-props-v1/` and `assets/reference/` are art/pipeline files.
- Do NOT touch food items named "bucket" (onion ring / nugget / popcorn buckets) or the lime bucket HAT on the second pier diner.

## Requirements
1. Remove `beach_bucket` from `BACKDROP_PROPS` and from every level placement and level thumbnail. Grep all of `scripts/`, `data/`, `scenes/`, `tests/` for `beach_bucket` and handle every runtime reference (also any other level file that uses it).
2. level_01's thumb needs a replacement: use another existing beach prop (suggest `beach_ball`); record the choice in the Report.
3. Leave the sprite files, `data/sprites.json` entry, `art_lab.json` entries and `tools/` scripts untouched so the prop can come back later.
4. If a test references `beach_bucket`, update it. Add a check to `tests/integration.gd` that no level placement or thumb uses `beach_bucket` and that `BACKDROP_PROPS` does not contain it.

## Out of scope
- Deleting art, redrawing the prop, any other prop or gameplay change.
- Do not stash, reset or discard uncommitted changes.

## Done when (acceptance)
- [x] `grep -r beach_bucket scripts data/levels scenes` returns nothing
- [x] Levels 1 and 2 load; the new test passes
- [x] `./tools/validate.ps1` (or headless `tests/integration.tscn`) passes with no new failures; report check counts
- [x] Committed on `codex/041-remove-bucket-prop`, task moved to `tasks/done/`, LOCK removed, not pushed

## Report
- Files changed: `scripts/beach.gd`, `data/levels/level_01.json`, `data/levels/level_02.json`, `tests/integration.gd`, and this task report.
- Removed the bucket from `BACKDROP_PROPS` and the two authored placements. Level 1 now uses the existing `beach_ball` thumbnail.
- Added 37 integration assertions covering every level JSON file, all loaded/generated levels, and `BACKDROP_PROPS`. Thumbnail checks support both a single sprite ID and arrays of IDs.
- Validation: focused regression before removal: 37 checks, 7 expected failures; after removal: 37 checks, 0 failures. Full headless `tests/integration.tscn`: **19,272 checks, 0 failures**, exit 0; includes loading and exercising levels 1 and 2. `git diff --check` passed. `git grep -n beach_bucket -- scripts data/levels scenes` returned no matches.
- `tools/validate.ps1` stopped on Godot's sandbox root-certificate stderr. Ran the equivalent editor import (exit 0) and headless integration scene directly; full log is `.tools/task-041-green.log` in the caller workspace. Non-assertion certificate/resource/image warnings remain in the test log.
- Preserved all bucket art, `data/sprites.json`, `data/art_lab.json`, and `tools/` scripts. Food buckets, the pier diner's hat, sweeper/bin art tasks, and all pre-existing uncommitted changes were left alone. Godot import produced an unrelated `.import` modification and two `.gd.uid` files only in the isolated clone; these remain uncommitted.
- Checkout: `.tools/task-041` (isolated clone inside the caller workspace). Branch: `codex/041-remove-bucket-prop`. Last implementation commit: `11b25ff9c151ec738160d5ebd7c6718853b2783e`; this completion report is committed immediately afterward on the same branch.
- Sandbox adaptation: the original repository's `.git` is read-only, so creating its branch and pulling in the existing main worktree were denied. Cloned local `main` at `4a16d897d400aab2afb353577fae3a6fcf7a2a6f`, pulled that local main successfully, then created the task branch. A GitHub pull was attempted but credentials were unavailable (`SEC_E_NO_CREDENTIALS`). Remote freshness beyond the available local main could not be verified.
- Handoff: branch committed locally, task moved to `tasks/done/`, queue locks removed after committing, **not pushed**. A bundle is provided at `.tools/task-041.bundle` in the caller workspace. The caller can import the branch with `git fetch .tools/task-041.bundle codex/041-remove-bucket-prop:codex/041-remove-bucket-prop`, then push it. The isolated clone's origin also points at the GitHub repository for direct caller push if preferred.
- Anything not done: remote pull could not authenticate; original shared Git metadata could not be written. All implementation and acceptance checks passed in the isolated branch.
