# 007 — Customer bite window and mid-air bite quest

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 003, 006
Created: 2026-10-22

## Goal
Customers periodically take a bite; snatching during it completes Training Day's 'Snatch a mid-air bite' quest.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 5, part 5b**. Its Files, Interfaces, data values and test steps are the requirements for this task.
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

## Report
Files: `data/tuning.json` (new `bite` block: duration 0.6, interval 4-7 s), `scripts/target.gd` (`biting`, `bite_wait`, `was_moving`, `last_theft_biting`, `_tick_bite`; `take()` records the window), `scripts/shopper_art.gd` (bite pose), `scripts/game.gd` (`_snatched` records `mid_air_bite`), `tests/quest_checks.gd` (+8 checks, `customer-mid-bite` capture).
Tests: `INTEGRATION: 16279 checks, 1 failures` (only the known `level 6 rival leaves the scene of a theft`); baseline was 16271.
Decisions: a bite starts only when the customer holds food, is idle (did not move the previous tick), not leaving, not recovering, no reaction mode and no pending drop; it is cancelled if any of those change. The customer stands still during the bite. Only `kiosk_customer` kind (all three shopper appearances) bites. Quest needs `take()` while `biting > 0` plus the existing STRIKE direct check. Stall counter handover untouched.
Not done: bite frame timing is tied to the 0.6 s window via the clip's 5 fps; no sound.

## Review notes
