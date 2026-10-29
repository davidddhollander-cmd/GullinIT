# 050 — Build beach direction signs from the approved pieces

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 049 item 9, approved by David in the Art Lab
Created: 2026-10-27

## What David will see in game
The wooden direction signs keep their text, size and position. Today their wood is one picture squashed to fit each board, so wider boards stretch the grain and the arrow tip. After this change every board, whatever its width, has the same crisp wood pixels and arrow tip, matching the stands and benches around it.

## Requirements
1. In `scripts/beach_sign_art.gd`, build each board row from left end + repeated middle + arrow end at 1:1, for any width; draw the post at its native 3 px width.
2. Labels, widths and positions stay exactly as they are. Update `docs/BEACH_SIGNS.md`.

## Done when (acceptance)
- [ ] Before/after captures of a one-arrow and a three-arrow sign at 1× and 4×
- [ ] **David has approved the captures**
- [ ] `./tools/validate.ps1`: 0 new failures

## Report

## Review notes
