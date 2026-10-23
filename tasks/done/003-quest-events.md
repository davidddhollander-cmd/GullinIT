# 003 — Wire quest events, bonus points and Feathers payout

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 002
Created: 2026-10-22

## Goal
Playing levels 1–3 completes quests from real gameplay, adds bonus points every run and pays a Feather the first time.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 2**. Its Files, Interfaces, data values and test steps are the requirements for this task.
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`
- AGENTS.md: no code-drawn character bodies/faces/limbs; GullPixel 8/16 px only; tuning in `data/`.

## Requirements
1. Do everything in the plan section named above, in its step order (tests first for code tasks).
2. Record any value or choice the plan left open in the Report.

## Out of scope
- Other plan tasks and later phases (levels 4+, shop, diving).

## Done when (acceptance)
- [x] Every step of the plan section is checked off
- [x] `./tools/validate.ps1` passes with no new failures (report check count)

## Report
Files: `scripts/game.gd`, `scripts/stash_raids.gd`, `tests/quest_checks.gd` (new `run_game`), `tests/integration.gd`.
Tests: headless integration 16061 checks, 1 failure (known pre-existing `level 6 rival leaves the scene of a theft`); +15 new checks. Test fix: the random quest slot is dropped in game tests (a rolled 3x ice cream quest made them flaky). Note: my first red run raced with the implementation edits and was discarded, so the fail-first run was not captured.
Decisions:
- Events are recorded via `_quest_event`, gated on `running`; `bin_emptied` emitted from `_peck_bin` when `remaining` hits 0 after a scatter.
- `direct` = not scrap and not mugged. Scrap swallows still count for the random "EAT N" quest.
- Quests are set up when not training, or when the level has `quests_on_replay_only` and `training_complete` was already true (the menu always passes force_training for L1, so replays are training runs). First-time trainees get none. Events record during replay lessons. The quest RNG is `randomize()`d per run.
- Bonus and Feather paid on completion; `result.quests` and `result.feathers_earned` added to non-training and training results alike (training has all quests undone).
- Random-food reachability audit from Task 1 not revisited.
Not done: `mid_air_bite` unreachable (Task 5).
Branch: sonnet/003-quest-events

## Review notes
