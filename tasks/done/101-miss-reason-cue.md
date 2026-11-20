# 101 — Miss cue that says why a dive missed

Status: done
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
**Files:** `scripts/game.gd` (`_dive_tick`, `_miss_cue`, `dive_peck_reach`, peck_started handler, `miss_stats` merged into `_run_stats`), `data/trainer.json` (`miss_cues` callouts, `live.miss_early/far/aim` for training), `data/tuning.json` (`juice.miss_cue_cooldown` 4.0 s), `tests/analytics_checks.gd`.

**Tests:** 18526 checks, 0 failures (task 100 left 18521; 5 new checks, plus the existing level_end dive checks updated for the extra dives).

**Reason rules** (checked when a dive ends without a snatch; priority order):
- aim: no snatchable target on the aim line when the dive began (`dive_target == null`).
- early: a peck was pressed while the snack was still ahead and farther than the real peck reach (same formula the lesson peck-freeze uses, now shared as `dive_peck_reach()`).
- far: the gull passed the snack (existing overshoot test), or a peck was pressed in reach and still missed.
- otherwise nothing (e.g. pulled up before reaching it with no peck).
Peck window opens at the press in this game, so "window not open yet" is modelled as "pressed out of reach".

**Behaviour:** counts always go up (`miss_early`, `miss_far`, `miss_aim` on `level_end`, kept in a separate dict so `dive_stats` and lesson stats are unchanged). The callout uses the tip-style floating text at screen top, at most once per 4 s, and is skipped while a trainer card is open or queued. In training the reason shows on the lesson strip through the existing training-hint path, and only when the first-miss hint is not already showing.

**Not done / unverified:** the training strip route has no automated test; the callout look in game is unseen. Dive aim assist, peck window and physics are untouched.

**Branch:** sonnet/101-miss-reason-cue

## Review notes
Review fix (follow-up commit on the 102 branch): an aim miss now counts only when snatchable food was within the touch assist range at dive start but outside the cone (`dive_food_near`, found with `assist_target` at a 180 degree angle). Dives with no food nearby (rival, dog, bin, ground) show nothing and add no `miss_aim`. The game does not record non-food dive intent, so that case is covered by the no-food-nearby rule only. Tests added for both cases; full run 18534 checks, 0 failures.
