# 091 — Level 2: two quests, Gary quest to level 3, clearer start card with a LET'S GULL IT! button

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-10 (renumbered from 079-081 on 2026-11-15)

> Written against main on 10 Nov. Main has moved since (practice rework, demo lock at level 3, task 087 mouse role, kittiwake Lightning Strike); re-check line numbers and current code before editing. 15 Nov playtest reviews back these tasks: dive timing and miss feedback, level 2 overload, mobile timing.

## Goal
Level 2 ("Family Picnic") stops overwhelming players straight after training. Real data (26 Oct to 10 Nov): 20 level 2 runs, 2 cleared, 7 failed, 11 quit or closed; one star earned in all data; only 8 of 34 players reach arcade levels. A player said level 2 stacks three quests right after training. Level 2 drops the Gary quest (ice cream and toddler quests stay), and the level start card makes clear what you need to pass and that quests are optional bonus points. The card stays up until the player presses a real button.

## Context
- `data/levels/level_02.json` → `quests`: `l2_ice` (3 CLEAN ICE CREAMS, +50), `l2_cry` (MAKE A TODDLER CRY, +30), `l2_bump_gary` (BUMP GARY TWICE, +40). `stars` [150, 400, 550]. Level 2 also runs the screech/Gang Call lesson on first herring play (task 043) and Gary's fly-in intro (`twist.gary_intro`), so a first visit is already busy. Training Day now teaches the toddler peck (lesson 3), so the toddler quest fits level 2.
- Gary is a rival in levels 2 to 7. Level 3 quests: `l3_outrun`, `l3_crab` + `random_quest` (`BeachQuests.setup` in `scripts/quests.gd` appends it).
- Tests that pin quest lists: `tests/off_lead_dog_checks.gd:47` (level 3), `tests/quest_checks.gd`, `tests/screech_lesson_checks.gd` (level 2). Saved quest completion lives in `GameState` (`previous.quests`, ~line 153); check that a save holding `l2_bump_gary` from an old run still loads without errors.
- **Start card today** (`scripts/overlay.gd` ~line 215-241): "SCORE %d IN %d:%02d / TO PASS TO THE NEXT LEVEL", then "QUESTS" and the list, then "ANY BUTTON TO GO". On levels 2+ it also **closes by itself** after `world.intro_time` (2 s) (`game.gd` ~563), or on any key press or click (`game.gd` ~793). Only level 1 has a real button: `BeachUI.button(intro,"LET'S GULL IT",game.dismiss_intro)` with `MOUSE_FILTER_STOP` and `grab_focus()`.
- Quest bonuses are already added to the score (`game.gd` ~1207 `result.quest_bonus`).
- Rules: UI text in GullPixel on its 8 px grid (8 or 16 px). Prefer data changes.

## Requirements
1. **Level 2 quests: `l2_ice` and `l2_cry`.** Remove `l2_bump_gary` from `level_02.json`. Do not add a `random_quest`.
2. **Move BUMP GARY TWICE to level 3** (data only), replacing level 3's `random_quest`, so level 3 keeps 3 quests. New id `l3_bump_gary`, same event/filter/count/bonus. Keep `random_foods` in level 3 if anything else still reads it; remove it only if nothing does.
3. **Clearer start card** (every arcade level). Two clearly separate blocks, goal first:
   ```
   02 / FAMILY PICNIC
   TO PASS:  SCORE 150 IN 2:00            <- "TO PASS:" in gold, 8 px main font
                                          <- a few px gap
   BONUS QUESTS - OPTIONAL                <- gold heading, small HUD font
   - 3 CLEAN ICE CREAMS  +50
   - MAKE A TODDLER CRY  +30
   QUEST POINTS COUNT TOWARD YOUR SCORE   <- small, muted
          [ LET'S GULL IT! ]              <- real button
   ```
   - No line about further stars.
   - Numbers come from `level.stars[0]` and `time_limit`, never hard-coded.
   - If the player has already passed the level, the first line says "PASSED. BEAT YOUR BEST: <best>" instead (best score from `GameState`); skip this if the saved best is not easy to read here and say so.
   - Boss level (`objective`) keeps its objective line above the pass line. Practice mode keeps "15 SNATCHES. NO TIMER." in place of the pass line and shows quests the same way.
   - Everything fits on the 320x180 canvas without clipping, in the 8 px main font or the small HUD font only.
4. **LET'S GULL IT! button on every level's start card.** Replace "ANY BUTTON TO GO" with the same `BeachUI.button` level 1 uses, labelled "LET'S GULL IT!" (level 1's label changes to match). Click or tap starts the level; it has focus, so Enter/Space and pad A start it too. Remove the 2 s auto-close and the any-key dismiss for levels 2+, so the card stays until the button is pressed. Remove `world.intro_time` from `tuning.json` if nothing else reads it. Make sure the click that presses the button does not also flap or dive the gull, and that the touch overlay does not swallow the tap.
5. If the result board on a fail shows quests, make sure it also shows the pass mark ("NEED 150 TO PASS"), so a player sees the target was points, not quests. Skip if the board already does this; say so in the Report.
6. Update the tests that pin quest lists or the intro auto-close, and add checks for level 2.

## Out of scope
- Star thresholds, time limit, layout or spawns of level 2 (if the analytics after this change still show few clears, a follow-up can lower `stars[0]`).
- The screech lesson and Gary's intro.
- Training Day (task 090) and touch controls (task 092).

## Done when (acceptance)
- [ ] Level 2 has exactly `l2_ice` and `l2_cry`; level 3 has `l3_bump_gary` and no random quest.
- [ ] Arcade start cards show "TO PASS: SCORE N IN M:SS", a gap, "BONUS QUESTS - OPTIONAL", the list, "QUEST POINTS COUNT TOWARD YOUR SCORE" and a LET'S GULL IT! button; no stars line; values come from level data; nothing clips. Captures of the level 2 and level 7 cards are in `test-output/` (`./tools/validate.ps1 -Capture`).
- [ ] The level 2 card stays up past 2 s and ignores random keys; the button (click, tap, Enter, pad A) starts the level, and that press does not move the gull.
- [ ] A check reads the level 2 intro labels and finds "TO PASS:", "150", "2:00", "OPTIONAL" and the button text "LET'S GULL IT!".
- [ ] An old save containing `l2_bump_gary` loads and plays level 2 without errors.
- [ ] Checks updated (`off_lead_dog_checks`, `quest_checks`, `screech_lesson_checks` and any intro-timer checks as needed).
- [ ] Headless `tests/integration.tscn` passes with no new failures (report check counts before and after).
- [ ] README/docs updated if they list level quests or `intro_time`.
- [ ] **Analytics (after release, not blocking merge):** `level_end` for level 2 (`mode` arcade): share with `outcome` `completed` rises from 2 of 20, and `quit` + `abandoned` falls from 11 of 20, over the next ~20 runs; more players send `level_start` for level 3.

## Report
Files: data/levels/level_02.json (bump Gary removed), data/levels/level_03.json (`l3_bump_gary` replaces random_quest; its now-unused random_foods removed), data/tuning.json (`world.intro_time` removed), scripts/overlay.gd (new start card + button), scripts/game.gd (card waits for the button; timer/any-key dismiss only for VS), tests: quest_checks (level 2/3/5 quest pins, new `_start_card_checks` with captures), off_lead_dog_checks, shakedown_checks (3-quest board case now uses level 3), touch_stick_checks (hide the card panel in the synthetic-touch fixture), integration/training_checks (no `intro_time`, button label).
Tests: before (090 tip) 17745 checks, 0 failures; after 17741 checks, 0 failures (quest-pin checks removed/rewritten, 4 card checks added). One `-Capture` run showed 11 touch_stick_checks failures that passed in the plain run with no code change between (the plain run printed 0 failures); probably capture-mode only, not investigated.
Captures (worktree, not committed): C:/Users/david/Documents/ChatGPT/GullinIt-main/.claude/worktrees/p1/test-output/level-2-start-card.png and .../level-7-start-card.png. Both fit with no clipping.
Decisions:
- Card: "TO PASS:" gold + "SCORE n IN m:ss" side by side, 4 px gap, "BONUS QUESTS - OPTIONAL" gold small, muted quest rows, "QUEST POINTS COUNT TOWARD YOUR SCORE", then the LET'S GULL IT! button (level 1 label changed too). Boss objective line stays above the pass line; Practice shows "15 SNATCHES. NO TIMER." plus the same quest block.
- Already-passed levels show "PASSED. BEAT YOUR BEST: n" (saved `best`, when saved `stars` > 0).
- VS keeps its 2 s auto-close and "ANY BUTTON TO GO" (it is not an arcade level). All other levels wait for the button; `intro` is just a nonzero flag (1.0) for them. Panel mouse_filter is STOP so clicks hit the button; main.gd already forwards taps to the GUI while the card is up, so touch works.
- `world.intro_time` removed (only VS uses `vs.intro_time`). Level 3 random_foods removed (nothing reads it without random_quest); quest_checks' random-quest cases now use level 5.
- Requirement 5: result board already shows "N MORE TO PASS" in its subtitle on a fail (result_board.gd `_target_text`), so nothing changed.
- Old saves: quest ids are plain strings in `GameState`; a check starts level 2 with a save containing `l2_bump_gary` and it loads and plays.
Not done: analytics criteria (post-release); did not touch docs (nothing listed intro_time or level quests).
Branch sonnet/091-level-2-quests-and-start-card.

## Review notes
<!-- Filled in by the reviewer. -->
