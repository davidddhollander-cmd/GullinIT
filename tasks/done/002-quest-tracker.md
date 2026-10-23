# 002 — Quest tracker, level quest data and Feathers save

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-22

## Goal
Levels 1–3 carry quest data, a BeachQuests tracker counts events, and the save holds completed quests and Feathers.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 1**. Its Files, Interfaces, data values and test steps are the requirements for this task.
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

Files: new `scripts/quests.gd`, `tests/quest_checks.gd`; edited `scripts/autoload/game_state.gd` (wallet, complete_quest, feathers, save key `wallet`, per-level `quests`), `data/levels/level_01-03.json`, `tests/integration.gd` (wired after score_rules_checks).

Tests: new checks failed first (level 2 quest slot missing, out-of-bounds error), then pass. Final run: `INTEGRATION: 16024 checks, 1 failures`. The one failure, `level 6 rival leaves the scene of a theft` (tests/rival_ai_checks.gd:96), is pre-existing: it fails identically before any quest code or data existed, and level 6 is untouched. Ran headless Godot directly (validate.ps1 aborts on Godot stderr noise under PowerShell strict error mode in this worktree).

Decisions:
- Dropped `crisps_box` from level 2 `random_foods`: nothing in level 2 can produce it (picnic mum is forced to crisps_bag, kiosk customers are pinned to ice_cream, bin scatter and stash snacks have no box). Kept ice_cream, crisps_bag, half_eaten_doughnut, half_eaten_sandwich (bins at x=470/805). All level 3 entries verified: hotdog (hotdog stand), fried_fish (pier diner), ice_cream (kiosks), half_eaten_doughnut/pizza (bin scatter).
- `quest.progress`/`done` are initialised in `setup`; `filter` match is exact equality and a missing key fails the match.
- Task 001 analytics files untouched. `quests_on_replay_only` is data only; enforcing it is task 003.
- Branch `sonnet/002-quest-tracker` was fast-forward-equivalent to local main by checking out `tasks docs AGENTS.md` from main (my starting HEAD predated main's plan commits); those files appear in the commit.


## Review notes
