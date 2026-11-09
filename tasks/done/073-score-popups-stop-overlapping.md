# 073 — Floating text stops covering itself

Status: merged
Author: Claude
Assignee: Claude Haiku
Depends on: none
Created: 2026-11-09

## Goal
Scoring pop-ups pile up on top of each other and become unreadable (a "+70 MINE ACTUALLY." plate drawn straight over an earlier one). Keep every visible message readable.

## Cause
`scripts/effects.gd`: score messages last 4.5 s (`SCORE_MESSAGE_HOLD` 3.0 + `SCORE_MESSAGE_FADE` 1.5), rise only 4 px/s, and each starts at the gull. Fast snatches therefore land on the same spot. Nothing in `_draw()` checks text against other text.

## Requirements
1. In `_draw()`, work out all text positions first, then draw. Keep the current hop and the existing move-below-the-banner logic. Then resolve overlaps newest first: each text's rect (`at-Vector2(2,8)`, size `width+4` by 11) that overlaps an already placed rect moves up until clear. Texts with `rise_speed` 0 (tips and taunts) never move and are placed first. Positions are whole pixels. A pushed text stays on screen; if it can't, skip drawing it.
2. Keep at most `score_popups_max` (2) score messages alive. A new one removes the oldest.
3. Shorten the score hold to `score_popup_hold` (1.6 s) in `juice`, replacing the constant. Fade stays as is, moved to tuning if convenient.
4. Do not scale text. Font stays 8 px. No changes to banner art or wording.

## Done when (acceptance)
- [ ] Two score messages in the same frame at the same position draw without overlapping rects
- [ ] A score message, a shout and a plated message at one spot do not overlap, and fixed tips do not move
- [ ] A third score message removes the oldest
- [ ] Text near the top of the screen is not pushed off it
- [ ] Separate the layout into a function that tests can call without drawing; checks added; `./tools/validate.ps1` has no new failures

## Report
- Branch `haiku/073-popups`, commit: see `git log -1` (commit message ends with Co-Authored-By line).
- Files changed: `scripts/effects.gd` (new static `text_layout` and `_text_box`/`_hits_any` helpers, instance `layout_texts(screen_top)`, `_draw` now draws the laid-out origins; `score_message` keeps at most `score_popups_max` score messages and uses `score_popup_hold`; removed `SCORE_MESSAGE_HOLD`), `scripts/overlay.gd` (banner hold kept at its old 3.0 s literal, since the constant was removed), `data/tuning.json` (`juice.score_popup_hold` 1.6, `juice.score_popups_max` 2), `tests/integration.gd` (registers the new file; the existing score-cue timing check now expects the 1.6 s hold), `tests/popup_layout_checks.gd` (new, 10 checks).
- Tests: `tools/validate.ps1` gives 16967 checks, 2 failures: "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo" (both known on main). No new failures.
- Decisions: the banner's own hold stays at 3.0 s (the spec only names the popup hold); fade stays a constant; screen top is taken as local y of canvas y=0; a pushed text that would leave the top is skipped; tips and taunts (rise_speed 0) are placed first and never move.
- Not done: no visual screenshot check (not requested); fade not moved to tuning.


## Review notes
<!-- Filled in by the reviewer. -->
