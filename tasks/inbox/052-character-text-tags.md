# 052 — Readable text tags over characters (rival names stay panel-free)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-28

## Goal
Playnotes 28 Oct: "Improve blocks of text with names" (the tags over characters). The small words that float over people and gulls (WATCH, CHASE, ALERT, SEEN, GONE!, BLOCK, CALM, Zzz, YOU, DIVE and the rival gull names) are bare 8 px text on busy sand and sea, and pile on top of each other when people cluster. Make them readable and keep them from overlapping, without making the beach look cluttered.

## Context
- Tags are drawn in `scripts/target.gd` (~lines 905–990: awareness cues, "Zzz", order/cue text), `scripts/gull.gd` (`rival_label`, ~line 267), `scripts/overlay.gd` (`YOU` ~408, `DIVE` ~413).
- The quest checklist already sits on a dark backing panel (commit e38f4df) and the YOU tag has a dark tag; reuse that look (`BeachUI.INK` backing, `BeachUI.CREAM` text).
- 8 px GullPixel font on its native grid only (CLAUDE.md). Texts stay at integer positions.

## Requirements
1. **Person cues** (the awareness words and "Zzz") get a small dark backing panel (`BeachUI.INK`, 1 px padding, drawn pixel-aligned) behind the existing coloured text, so they read over sand, sea and sky. Keep each cue's current colour.
2. **Rival gull names get NO black panel.** Keep them as plain text, but give them a 1 px dark outline (`draw_string_outline` / label outline, as "Zzz" already does) in the rival's tint colour so they read without a box. Do the same for the `DIVE` tag if it has no panel today.
3. **No stacking:** when two tags would overlap (people clustered, a person next to a rival), the lower-priority one is nudged up by a tag height or hidden. Priority: GONE!/CHASE/ALERT > WATCH/SEEN/BLOCK > CALM > Zzz > rival name. One small helper, not a new system.
4. Tags never leave the screen edges and never sit on the top HUD rows.
5. No change to when cues appear, their words, or their timings.

## Out of scope
- New fonts or art, the scoreboard/rival panel (already reworked), signs, order bubbles.

## Done when (acceptance)
- [ ] Every person cue sits on a dark panel; rival names have an outline and no panel
- [ ] Check: two people 10 px apart showing cues do not overlap (tag rects are disjoint)
- [ ] Check: a rival name tag has no backing rect
- [ ] One `tools/validate.ps1 -Capture` run at the end: 0 failures, capture of a crowded scene in the Report
- [ ] Small visual task: no repeated test runs, David eyeballs it in game

## Report

## Review notes
