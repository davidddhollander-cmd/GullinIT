# 043 — Level 2: screech, brashness and Gang Call lesson + layout rework

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-27

## Goal
Players don't know screeching, the brashness meter or Gang Call exist. Teach them in a short lesson at the start of level 2 ("Family Picnic"), the first time it is played. Rework level 2's layout so the lesson's ingredients (an ice-cream stand to perch on, people holding food) sit right by the left-side start.

## Context
- **Training today:** `scripts/game.gd` runs 7 lessons in level 1 (`TRAINING_LESSONS`, `FINAL_LESSON`, `lesson`, `_training_tick`, `_training_advance`, `training_text()`, `training_target()`). Progress is saved via `GameState.entry(1).training_step` / `training_complete`. The lesson panel is drawn in `scripts/overlay.gd`. Copy its style: short two-line prompts, the key names switch for gamepad and touch, and a golden ring marks the target.
- **Mechanics:**
  - Hold E (0.24 s, grounded, standing still) to screech: `_advance_screech_hold`, `_can_screech`, `BeachGull.start_screech`.
  - The brashness meter is `scripts/brashness.gd` (`meter`, `add`, `screech_tick`, `vantage_mult`, `fire`). It fills faster from high perches, shown as a "HIGH PERCH xN" message.
  - A screech, Q or the touch CALL button on a full meter fires Gang Call. The crowd panic is `scripts/crowd_panic.gd`.
  - The BRASH bar is in the top HUD bar.
- **Screeching is herring-only** (`_can_screech` checks `player.species == "herring"`), and only the herring has a `power` in `data/species.json`.
- **Screeching is keyboard-only today:** `_unhandled_input` only starts a hold for an `InputEventKey`. Touch and gamepad players can't screech at all.
- **Level 2:** `data/levels/level_02.json`. The start is at x 40. Current props: palm 70, parasol 182, bins 470/780, castle 650, wheelie bin 950, kiosks at 600 and 905, hut 1000. Current spawns: a sunbather at 155, two picnic families (each a mum plus one toddler) at 326–370 and 440–484, and ice-cream customers at 545 and 865.

## Requirements

### A. Make the screech work on every input
1. Holding the peck input works the same way for gamepad (X) and the touch PECK button as for E: a tap pecks, a hold of `SCREECH_HOLD_TIME` while grounded and still screeches, and releasing stops it. Keep the existing E behaviour and its tests unchanged.

### B. Rework level 2's layout (data only where possible)
2. Move the ice-cream stand (kiosk) to the left side, near the start, about x 220–260. It must be close enough for the first lesson step and must not overlap the palm or parasol. Keep the second kiosk on the right.
3. Put 2 ice-cream customers holding food on the left, near that stand: in the stand's queue or patrolling just to the right of it.
4. Move the sunbather(s) to the right side of the beach.
5. Remove the second picnic family. Keep **one mum with two toddlers** (both toddlers share the mum's `family_id`/station). Check that the family and toddler code handles two toddlers per mum: crying, seeking the parent, the "make a toddler cry" quest. Fix it if it doesn't.
6. Keep the quests (3 clean ice creams, make a toddler cry) achievable. Run the existing layout and prop-overlap checks (`tests/level_layout_checks`, sign placement, bin/bench rules) and fix anything that breaks.

### C. The lesson (first play of level 2, herring only)
7. **When it runs:** the first time level 2 starts with the herring, unless it's saved as done. Add `GameState.entry(2).screech_lesson_complete`, or an equivalent saved flag. It is skippable: any pause-menu "skip" path the level 1 training offers should work the same way. Replays and other species get the normal level. Pause the level timer while the lesson runs.
8. **Steps.** Use the same lesson panel, golden ring and key-name switching as level 1. Suggested copy (keep it short):
   1. **Perch high:** "LAND ON THE ICE CREAM SIGN" (ring on the stand's roof sign). Done when grounded on that stand's perch.
   2. **Screech:** "HOLD %s TO SCREECH\nHIGH PERCHES FILL BRASH FASTER" (peck key name). Point at the BRASH bar, e.g. a pulsing outline or arrow on it. Done when the meter is full. Start the meter at about 60% for this step so it takes a few seconds, not 16.
   3. **Gang Call:** "BRASH FULL! SCREECH AGAIN\nTO CALL THE GANG" (also mention Q or CALL as the alternative). Done when Gang Call fires.
   4. **Grab:** "GRAB THE DROPPED FOOD!\nTHEY'LL BE BACK SOON". Done when the player collects any knocked or dropped food, or after about 8 s.
   5. Then a short "LESSON DONE" message; the timer starts and the level plays normally. Reset the brashness meter to 0 for the real run.
9. During the lesson the beachgoers must not leave the area before the gang arrives. Use the existing training patterns, for example spawning or holding the left-side customers until step 3. Make sure Gang Call has at least one person holding food in range when the player fires it.
10. Put any lesson tunables in data: the starting meter fill and the grab timeout.

## Out of scope
- Powers for other species, and their screech animations.
- New art or sounds.
- Changes to the level 1 training.

## Done when (acceptance)
- [ ] Level 2 layout: an ice-cream stand and 2 people holding food on the left near the start; sunbathers on the right; one mum with two toddlers; no overlaps; quests still achievable
- [ ] Hold-to-screech works on keyboard, gamepad and touch; tap still pecks
- [ ] First herring play of level 2 runs the 4-step lesson with correct key names per input; it's saved as done and skippable; the timer is paused during it
- [ ] Tests: a lesson step-by-step walkthrough (perch → meter full → fire → grab → done); the saved flag skips it on replay; a non-herring species skips it; touch/gamepad hold starts a screech; a family with two toddlers works
- [ ] `./tools/validate.ps1 -Capture`: 0 new failures (known: pier-diner fish check in rendered mode, play copy's demo lock), plus captures of the new level 2 start and one lesson step in `test-output/`

## Report

**Files changed:** `data/levels/level_02.json` (layout, zones, `screech_lesson` tunables), `scripts/game.gd` (lesson state machine, hold-to-screech for gamepad/touch, clock pause), `scripts/overlay.gd` (lesson panel/ring/BRASH pulse reuse), `scripts/input_controller.gd` (`peck_held`), `scripts/beach_routine.gd` (optional spawn `bounds`), `scripts/menus.gd` + `scripts/main.gd` (pause-menu SKIP LESSON), `scripts/autoload/game_state.gd` (`complete_screech_lesson`), tests (`tests/screech_lesson_checks.gd` new; `integration.gd`, `cast_variety_checks.gd`, `level_generator_checks.gd`, `demo_polish_checks.gd` adapted to the new layout).

**Tests:** rendered `tests/integration.tscn` (`--capture`) and headless: 14438 checks, 0 failures. The pre-existing level5 `off_lead_dog` SCRIPT ERROR still prints. Captures: `test-output/level2-start-lesson-1.png`, `test-output/level2-lesson-2-screech.png`.

**Decisions:**
- Layout: near ice-cream stand at x 240 (queue side right, customer_x 290); two holding customers at 290/335 (new optional spawn field `bounds` [270,350] keeps them by the stand); family = mum 455 with toddlers 410/500; sunbather at x 700; far kiosk unchanged at 905 with one shopper (mullet look, so every look stays unique). Dropped the mid shopper and the second family. Zones renamed ICE CREAM / FAMILY BAY / SUNBATHERS / SNACK KIOSK. Parasol 182 -> 150, bin 470 -> 560.
- The mum's stand trip now goes to the near stand (first kiosk in props). The family/toddler code already handled two toddlers (gather/follow slots, cry, help); fixtures that assumed the stand on the family's right now relocate the family left of the stand.
- Lesson: runs when level data has `screech_lesson`, species is herring and `GameState.entry(2).screech_lesson_complete` is unset. Four steps as specified; `start_meter` 0.6 and `grab_timeout` 8 live in level_02.json. The level clock is frozen while it runs. Customers by the stand are re-handed food through step 3 so Gang Call always has holders; if the meter drops below full in step 3 the lesson steps back to step 2. Skip: level 1 training has no skip path, so I added a "SKIP LESSON" pause-menu button while the lesson is active (saves the flag).
- Hold-to-screech: gamepad X reuses the peck action; touch uses a new `GullInput.peck_held`; `_peck_pressed/_peck_released` are shared by all inputs. A moving touch stick cancels a touch screech.
- Existing tests that start level 2 set `progress["2"].screech_lesson_complete` so ordinary runs are unaffected.

**Not done:** no arrow on the BRASH bar (pulsing gold outline only; the lesson panel overlaps the space below it). Real gamepad/touch hardware untested (simulated events only).

**Branch:** `sonnet/043-level-2-screech-lesson`

## Review notes

Reviewer (Claude Opus): approved. Fixed one exploit: steps 1-3 refill the shoppers' ice creams on a frozen clock, so quest events are now ignored during the lesson (no farming l2_ice and its Feather) and ending the lesson resets practice points. Added checks for both; quest_checks skip the lesson for ordinary runs. Headless: 14441 checks, 0 failures. Follow-up noted: the left signpost shows ICE CREAM on both arrows.
