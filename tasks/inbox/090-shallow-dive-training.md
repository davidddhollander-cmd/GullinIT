# 090 — Training: teach a shallow dive, approach-angle cue, fix the dummy lesson copy

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-10 (renumbered from 079-081 on 2026-11-15)

> Written against main on 10 Nov. Main has moved since (practice rework, demo lock at level 3, task 087 mouse role, kittiwake Lightning Strike); re-check line numbers and current code before editing. 15 Nov playtest reviews back these tasks: dive timing and miss feedback, level 2 overload, mobile timing.

## Goal
More players pass the first dive lesson and finish Training Day. Real players (PostHog, 26 Oct to 10 Nov) thought dives had to be vertical and kept crashing: the first dive lesson lost 4 of 11 players, those who passed took 37 s with 10 overshoots and 7 crashes, and only 4 of 15 finished training. Players also got stuck on the final dummy dive, whose copy says to fly "straight through" him, which reads as "dive straight down".

## Context
- Lesson numbering: the live build had 5 lessons; main has 6 (`TRAINING_LESSONS`). On main, the dive snatch is `DIVE_LESSON` = index 4 (analytics `lesson` 5) and the dummy mug is `MUG_LESSON` = index 5 (analytics `lesson` 6). `lesson_start.lesson` is the 1-based lesson being started; `lesson_complete.lesson` is the 1-based number of the lesson just finished (`scripts/game.gd` `_training_advance`, line ~1244).
- Copy: `data/trainer.json` → `training.lessons[4]` (dive snatch) and `training.lessons[5]` (dummy), plus `live.mug_miss`, `live.mug_rescue`, `live.dive_nudge`, `live.aim_freeze`, `live.missed` and `tips.mug_miss` ("MISSED THE MUG! DIVE STRAIGHT THROUGH HIM"). Every variant (`default`, `casual`, `touch`, `touch_casual`) must be updated together.
- Dive physics (`scripts/gull.gd` `State.STRIKE`, `crash_risk()`, `crash_warning()`): a crash is nose-down ground contact with vertical speed ≥ `dive.crash_vertical_speed` (170). Dive speed builds with `dive.acceleration` (260) times `direction.y`, so steep dives from high up crash and shallow ones turn into a swoop. `dive.pull_up_turn_boost` (1.5) already makes pulling up easier (merged, not yet released; do not change it).
- Dive lesson aim freeze: `game.gd` `_aim_pause_check` / `_aim_pause_tick` (`AIM_PAUSES` 2), `aim_lines_up()`; the overlay draws the frozen dive line in `scripts/overlay.gd` `_draw_aim_line()` (gold when lined up, cream otherwise).
- The dummy flies at `training_dummy.cruise_y` 92 in `data/levels/level_01.json`.
- Bug spotted in passing: the Training Day intro panel in `overlay.gd` (~line 217) still says "FIVE SHORT LESSONS"; there are six.
- Crash cost (`score.crash_keep` 0.75) and the -5 rival bump penalty are already on main; nothing to do here.
- Rules: UI text in GullPixel on its 8 px grid (8 or 16 px). No new art.

## Requirements
1. **Teach the shallow dive in the dive snatch lesson** (`training.lessons[4]`). Rewrite `lay`, `how` and `strip` (all variants) so the player learns: start the dive from a little above and to the side of the target, not from straight overhead, and dive at a shallow angle into the snack, then aim up. Suggested `how.default`: "Fly in from the side, a little above him. Press {dive} and aim at a shallow slant, not straight down. Tap {peck} as your beak reaches the cone." Suggested strip: "Dive at a slant, not straight down, then tap {peck}". Keep Screeches' voice; keep it short.
2. **Dummy lesson copy is already done** (David's wording, merged on 10 Nov: "Fly up and dive ({dive}) against the rival..."; strip, `live.mug_miss`, `live.mug_rescue` and `tips.mug_miss` no longer say "straight through"). Do not rewrite it; only check that nothing in the dummy lesson still says "straight through", "straight down" or "climb above him".
3. **Approach-angle cue.** In the two dive lessons (`DIVE_LESSON`, `MUG_LESSON`), while the player is in WINDUP or STRIKE, draw the dive line (reuse `_draw_aim_line`, not only during the aim freeze). Colour it by angle: gold when lined up with the target (as now), cream when shallow enough, and coral/red when steeper than new tuning key `dive.safe_angle` (degrees below horizontal; start at 35 and tune so a dive from the lesson's usual height at that angle does not crash). When too steep, the strip shows a new `live.too_steep` line ("Too steep! Level out a bit") ahead of the normal strip, but after `crash` (which already wins). Put the threshold check in one helper (e.g. `BeachGull.dive_too_steep()`), not in the overlay and game separately.
4. **Aim freeze copy** (`live.aim_freeze`, both variants): mention the slant, e.g. "Steer with {steer}. Aim at a slant, not straight down.\nPress {dive} to go."
5. Fix the Training Day intro to say "SIX SHORT LESSONS" (or derive the count from `TRAINING_LESSONS` and spell it).
6. Do not change dive physics or crash tuning in this task; this is teaching only (touch physics is task 092).

## Out of scope
- Changing `crash_vertical_speed`, `pull_up_turn_boost`, `crash_keep` or other dive tuning.
- The cue outside Training Day (arcade levels). Note in the Report how easy it would be to switch on.
- New art or sounds; lesson order or the number of lessons.

## Done when (acceptance)
- [ ] Lessons 5 and 6 (main numbering) and their live lines, tips and aim-freeze line no longer say "straight through", "straight down" as an instruction, or "climb above him"; every input variant is updated and placeholders still resolve (`TrainerScript.line`).
- [ ] During both dive lessons the dive line shows in WINDUP and STRIKE; it is red above `dive.safe_angle`, gold when lined up, cream otherwise; the "too steep" strip line shows only when steep and no crash warning is up.
- [ ] Intro says six lessons.
- [ ] Checks in `tests/` (extend the trainer checks): a steep dive (e.g. 70°) reports `dive_too_steep()` true and a 25° dive false; a dive at `dive.safe_angle` from the lesson's typical start height (about 40 px above the kiosk customer's food) does not crash; trainer copy for lessons 5 and 6 has no "straight through".
- [ ] Headless `tests/integration.tscn` passes with no new failures (report check counts before and after).
- [ ] README updated for `dive.safe_angle`.
- [ ] **Analytics (after release, not blocking merge):** over the first ~15 new players who `lesson_start` lesson 5, at least 75% send `lesson_complete` lesson 5 (live: 7 of 11), with median `lesson_crashes` ≤ 1 and `lesson_overshoots` ≤ 2; at least half of training starters send `lesson_complete` lesson 6 (live: 4 of 15).

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
