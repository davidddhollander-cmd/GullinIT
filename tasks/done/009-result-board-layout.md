# 009 — Result board: one scoreboard with quests, high scores right, Feathers line

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
Simplify the end-of-level sign (David's direction). The left panel is one scoreboard that includes the quests. The right panel always shows high scores. The bottom line shows Feathers instead of BEST / NEXT STAR.

## Context
- Files: `scripts/result_board.gd` (layout consts `LEFT_PANEL`, `RIGHT_PANEL`, `_build`, `_build_quests_panel`, `_build_scores_panel`, tally `_process`/`finish_tally`, `_record_text`), `scripts/game.gd` (`finish()` result), `scripts/overlay.gd` (quest checklist), `tests/quest_checks.gd`, `tests/integration.gd` result board checks.
- Current problems (seen in renders): on quest levels the high scores are replaced by quests; the quest bonus is hidden inside EARNED POINTS; the in-run checklist shows through above the sign.
- Rules: GullPixel 8/16 px only; everything inside the 320x180 canvas; run tests with `tools/validate.ps1` (silent, isolated save).

## Requirements
1. **Left panel = THIS RUN scoreboard**, top to bottom:
   - `EARNED POINTS` — points excluding quest bonuses.
   - `CLEAN BONUS` — as now.
   - One row per quest: `* NAME  +50` when done (gold, value is that quest's bonus), `- NAME  1/4` when a counted quest is unfinished, `- NAME` otherwise. Truncate a name that would collide with the value; never wrap.
   - `SNATCHES n  STUNS n` on a single row.
   - `TOTAL` — unchanged total, and it must equal earned + clean + done quest bonuses.
   - Remove the RISKY / UPWIND / MUGGED / COUNTER line. Move the `?` score-rules link next to the TOTAL row (keep the link working; the pause menu still has SCORE RULES).
   - Runs without quests (first-time training) simply have no quest rows.
   - Quest rows take part in the tally count-up like the other rows.
2. **Right panel = HIGH SCORES always** (as before task 004), on every level, quests or not. Delete the quests-panel variant.
3. **Bottom line** (where `BEST n  NEXT STAR n` sits) shows Feathers: `+1 FEATHER  /  FEATHERS 8` when Feathers were earned this run (singular/plural correct), otherwise `FEATHERS 8`. The tally hint (`CLICK / TAP / CONFIRM TO TALLY`) still uses that line until the tally finishes.
4. **Result data:** `game.gd` `finish()` adds `result.quest_bonus` (sum of done quest bonuses) and each `result.quests` entry gains `progress`, `count` and `bonus`. `result.base` must not include quest bonus (subtract it, or track it separately), so TOTAL stays correct.
5. **Hide the in-run quest checklist** (and other HUD text drawn over the sign) while the result board is shown.

## Out of scope
- Level select, in-run checklist content, quest logic, star rules.

## Done when (acceptance)
- [ ] Left panel rows as specified; TOTAL = EARNED + CLEAN + done quest bonuses (checked in tests for a level 2 run with one done quest)
- [ ] Right panel shows HIGH SCORES on levels 1–6
- [ ] Bottom line shows Feathers text exactly as specified, after the tally
- [ ] Checklist not visible behind the result board
- [ ] `suite.layout()` / `suite.menu_font_grid()` pass for the board; nothing clipped or overlapping in `-Capture` renders of a level 2 (quests) and level 6 (no quests) result board; screenshot paths in the Report
- [ ] `tools/validate.ps1` passes with no new failures (baseline: 1 known failure `level 6 rival leaves the scene of a theft`)

## Report
Files: scripts/result_board.gd, scripts/game.gd (finish: quest_bonus, quest progress/count/bonus, base minus quest bonus), scripts/main.gd (hide game overlay when results show), tests/quest_checks.gd, tests/integration.gd, tests/demo_polish_checks.gd.
Tests: `INTEGRATION: 16220 checks, 1 failures` (only the known `level 6 rival leaves the scene of a theft`), run with -Capture.
Screenshots (worktree test-output/): quest-result-board.png (level 2, quests; scores panel mid-fade in this capture), result-5.png (no quests, failed run).
Decisions: quest value is right-aligned, name trimmed (not wrapped) to leave room, so `* NAME  +50` is two labels; unfinished single quest shows no value. `?` badge sits right of TOTAL caption (whole-line link removed). Casual runs keep their TIME/BEST SEC bottom line (Feathers line applies to arcade runs). Left panel fits 3 quests; a 4th would overlap the TOTAL rule. Hiding is done by hiding the whole game overlay in Main._finished.
Not done: no separate level 6 capture inspected (no quests there, same layout as result-5).
Branch: sonnet/009-result-board-layout.

## Review notes
