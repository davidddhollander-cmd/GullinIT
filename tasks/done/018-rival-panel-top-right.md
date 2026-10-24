# 018 — Rival score panel: higher and smaller

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playtest note: "UI scores on right hand need to be higher on the screen, taking up too much space." Move the in-level rival score panel into the top-right corner and make it compact, so it stops covering the play area.

## Context
- `scripts/overlay.gd:88-105` builds `rival_score_panel` (PRESET_TOP_RIGHT, `offset_left -56`, `offset_top 76`), filled around line 230–262. `overlay.gd:420-421` moves the right-side food/threat edge markers left while the panel is visible.
- HUD face `gull_hud.fnt` is native 6 px. `BeachUI.label` forces sizes under 8 back to 8, so set `add_theme_font_size_override` afterwards (as the quest panel does). GullPixel stays on 8/16.
- Plan: `docs/superpowers/plans/2026-10-24-playnotes-fixes.md`.

## Requirements
1. Panel sits directly under the top bar, flush top-right (4 px margin), at about 40 px wide or less.
2. Rows are compact: a short name or initial plus the score, HUD 6 px face, one line per gull including YOU. Keep the current leader highlight, if there is one.
3. The panel must not overlap the top bar, the quest panel, or the training panel, at 320x180 or in the phone capture.
4. Since the panel no longer covers the right edge, put the edge markers back at their normal x (or only shift them by the new, smaller width).

## Out of scope
- The result board, the quest panel and the top bar contents.

## Done when (acceptance)
- [ ] Panel at the top right, ≤ 40 px wide, rows readable
- [ ] Existing overlay/menu font-grid checks pass, and a check asserts the panel's rect lies inside the top-right corner and doesn't intersect the quest panel
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures. Screenshot paths of levels 5 and 6 with the panel visible in the Report.

## Report
- Files: scripts/overlay.gd, tests/rival_ai_checks.gd.
- Tests: validate.ps1 -Capture: INTEGRATION 15407 checks, 0 failures.
- Panel now x 276..316 (40 px), y 17..44 (directly under top bar), no title, no per-row frames, one 6 px HUD line per gull: tinted initial + 3-digit score; extra gold "Y" row for YOU (game.score.points). No leader highlight existed, none added.
- Decisions: panel ends at y=44 so it sits above the (out of scope) star-goal panel at Rect2(232,44,84,29) instead of overlapping it. Edge markers restored to x 280/302. You-marker obstacle now uses the panel rect.
- Test: replaced the old safe-area check with one asserting right edge <=316, width <=40, y>=17, bottom <=44, no intersection with the quest panel (levels 3,4,6). Level 5 gets a capture-only 6 s sim.
- Screenshots (worktree test-output/): rival-score-meter-l5.png, rival-score-meter.png (level 6).

## Review notes
