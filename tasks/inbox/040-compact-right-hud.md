# 040 — Compact, higher right-side score panel

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-26

## Goal
Playnotes: "UI scores on right hand need to be higher on the screen, taking up too much space." Free up the play area on the right.

## Context
- `scripts/overlay.gd`: `rival_score_panel`, `rival_score_list`, `you_score_label`, quest strip (`QUEST_STRIP_HEIGHT`). Task 018 put the rival panel top right.
- CLAUDE.md: GullPixel font on the 8 px grid only (8 or 16 px).

## Requirements
1. Move the rival score panel up so its top sits directly under the top bar (sharing the quest-strip row if it fits).
2. Shrink it: one tight row per gull (`NAME SCORE`), minimal padding, no header; at most ~25% of screen width and the shortest height that fits the level's rivals.
3. Nothing overlaps the pause button, timer or quest strip at 320x180.

## Done when (acceptance)
- [ ] Capture of L5 (most rivals) shows the smaller panel high on the right, nothing overlapping
- [ ] HUD layout tests updated; `./tools/validate.ps1 -Capture`: 0 failures

## Report

## Review notes
