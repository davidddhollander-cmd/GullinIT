# 077 — Enraged carry sprites

Status: done
Author: Claude
Assignee: Sonnet
Depends on: 075 (merged)
Created: 2026-11-09

## Goal
While Shakedown is active, a black-back carrying food uses the enraged carry art.

## Context
- `gull_art.json` has `carry_enraged` beside `carry` on `gull_great_black_backed`: same layout, beak anchors and frames, only `file`, `overlay_file` and `source` differ. Check how `BeachGull.carry_for()` reads the entry; `data/gull_carry_art.json` may also matter.
- `BeachGull.carry_frames()` caches by art id and overlay flag. `sync_carry()` assigns the frames only when `art_id` meta changes, so it will not notice `enraged` flipping mid-carry.

## Requirements
1. When `enraged` is true and the art has a `carry_enraged` block, `sync_carry()` uses its body and upper-beak sheets. Otherwise it uses the normal carry, so every other gull is unchanged.
2. Flipping `enraged` during a carry swaps immediately in both directions and keeps the current clip and frame. Normal and enraged frames are cached separately.
3. Keep the change in the existing carry functions. Add no new data or tunables.

## Done when (acceptance)
- [ ] Checks with simulated ticks cover: enraged black-back carry uses the enraged sheets for body and beak; ending the power restores the normal sheets; frame kept across the swap; a herring is unaffected
- [ ] `tools/validate.ps1` shows only the 2 standing failures

## Report
- Files: `scripts/gull.gd` (`carry_for`, `carry_frames`, `sync_carry`), `tests/shakedown_checks.gd` (new `_carry_art_checks`, 6 checks).
- Change: `carry_for(id, on)` returns the `carry_enraged` block when `on` and one exists, else the normal `carry`. `carry_frames(..., on)` caches normal and enraged frames under separate keys. `sync_carry()` keys its `art_id` meta by art id plus `/enraged`, so flipping `enraged` mid-carry reassigns frames in both directions; clip and frame are set right after, so they are kept. Beak anchors still come from the normal block (same layout). No new data or tunables.
- Tests: `validate.ps1` gave INTEGRATION: 17226 checks, 2 failures, exactly the standing ones ("nobody teleports across the beach while running off", "data/demo.json enables the four-level demo"). The art checks merged with task 076 all pass (no art-check failure).
- Decisions: herring check forces `enraged` on a herring (no `carry_enraged`) and asserts normal sheets.
- Not done: nothing.

## Review notes
<!-- Filled in by the reviewer. -->
