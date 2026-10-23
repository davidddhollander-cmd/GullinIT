# 004 — Quest checklist, level card and result board

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 003
Created: 2026-10-22

## Goal
Players see their 3 quests in-run, on the level card and on the result board, plus their Feathers total.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 3**. Its Files, Interfaces, data values and test steps are the requirements for this task.
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`
- AGENTS.md: no code-drawn character bodies/faces/limbs; GullPixel 8/16 px only; tuning in `data/`.

## Requirements
1. Do everything in the plan section named above, in its step order (tests first for code tasks).
2. Record any value or choice the plan left open in the Report.

## Out of scope
- Other plan tasks and later phases (levels 4+, shop, diving).

## Done when (acceptance)
- [ ] Every step of the plan section is checked off
- [ ] `./tools/validate.ps1` passes with no new failures (report check count)
- [ ] `-Capture` screenshots of the checklist, level card and result board inspected

## Report
Files: scripts/overlay.gd (quest_box/quest_labels, sync_quests), scripts/menus.gd (card "Q n/N", Feathers label), scripts/result_board.gd (quest panel), tests/quest_checks.gd.
Tests: validate.ps1 -Capture: 16083 checks, 1 failure (known: level 6 rival leaves the scene of a theft). Count differs from baseline 16061 only because new checks leave the menus in level-select state for later layout checks.
Screenshots: test-output/quest-checklist.png, quest-level-select.png, quest-result-board.png (not committed).
Decisions: checklist top-left under HUD, "- text" / gold "* text", n/N for counted quests; during training replays it sits below the lesson panel. Level card shows "Q n/N" beside the stars (L1 only once trained); Feathers total top-right of level select. Result board: when the run had quests, the right panel shows QUESTS (+N FEATHERS in header) instead of high scores, since quest names do not fit beside 5 score rows; wrapped to two lines when long. Runs without quests keep high scores.
Gaps: training-day completion screen does not list quests/Feathers; no result-board progress counts (result only carries text/done).

## Review notes
