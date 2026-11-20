# 101 — Miss cue that says why a dive missed

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 100
Created: 2026-11-20

## Goal
When a dive ends without a snatch, tell the player in a few words why: pecked too early, pecked too late or too far away, or the dive was aimed off the target. Players currently cannot tell whether they missed because of aim or timing, and say so.

## Context
- Player feedback gp-04 (14 Nov, paid playtester): "Sometimes it's hard to tell whether you missed because of your aim or because you pressed the button too early... clearer feedback when you miss a steal." gp-12 also asks for clearer snatch timing. PostHog: lesson 3 loses 9 of 34 players, with 10 overshoots in the lesson.
- Relevant files: `scripts/game.gd` (`_dive_tick`, `dive_stats`, `dive_hit`, `dive_target`, `training_miss_hint`, `training_miss_line`, `show_callout`), `scripts/gull.gd` (`peck_window_open`, `peck_used`, `consume_peck`, `beak()`), `scripts/overlay.gd` (`show_callout`, beak ring around line 866), `data/trainer.json` ("live" lines such as `first_miss`).
- Reuse the existing overshoot detection and the callout; do not add a new HUD element.
- CLAUDE.md: UI text on the 8 px grid; copy lives in data, not code.

## Requirements
1. When a dive ends without a snatch, pick one reason from what the game already knows:
   - **too early**: a peck was pressed while the peck window was not open yet;
   - **too late or too far**: the gull passed the food or the beak was out of range when the window was open;
   - **off target**: the aim line was not on any snatchable target (including dives with no `dive_target`).
   If none fits, show nothing rather than a vague message.
2. Show the reason as a short callout (max about 24 characters per line, 8 px font), for example "TOO EARLY", "TOO FAR", "AIM AT THE FOOD". Strings live in `data/` with the other callouts.
3. Show it at most once every few seconds so a run of misses does not spam the screen, and never over the lesson card.
4. In training, reuse the existing first-miss hint instead of showing two messages.
5. Add the chosen reason to the existing `level_end` analytics as a count per reason (for example `miss_early`, `miss_far`, `miss_aim`), using the project's existing analytics path, so PostHog can show which reason is most common.

## Out of scope
- Changing the peck window, dive physics, or aim assist.
- The lesson 3 ring (task 100) and peck press feedback (task 102).

## Done when (acceptance)
- [ ] Each of the three reasons can be triggered in a headless test and shows the right line.
- [ ] A successful snatch shows no miss cue; a run of misses does not repeat the cue faster than the cooldown.
- [ ] Analytics counts are present on `level_end` and covered in `tests/analytics_checks.gd`.
- [ ] `./tools/validate.ps1` passes with no new failures.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
