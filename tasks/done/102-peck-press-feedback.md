# 102 — Every peck press gives feedback, and ground eating stops dropping presses

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 101
Created: 2026-11-20

## Goal
Pressing the peck/eat button always does something visible or audible, even when there is nothing to eat, and spamming it on the ground eats reliably. Right now a player spamming E to eat items on the ground reports that the gull hardly eats and gives no sign that the presses registered.

## Context
- Player feedback gp-13 (15 Nov, paid playtester): "I was spamming E to eat all the items on the ground, but the bird hardly ate. There should be an animation (or at least some audio) for each input, even if there is nothing to eat." gp-12 adds that spamming eat near the ground was the best strategy, which suggests an exploit worth knowing about.
- Relevant files: `scripts/game.gd` (`_peck_pressed`, `_peck_released`, `_peck`, `peck_hold_pending`, `peck_hold_touch`), `scripts/gull.gd` (`attempt_peck`, `show_ground_peck`, `art_event == &"peck"`, `consume_peck`, `cooldown`), `scripts/effects.gd` (`peck_contact`), `scripts/autoload/audio.gd`, `scripts/input_controller.gd`.
- Web audio rules in CLAUDE.md: buses come from `default_bus_layout.tres` and every AudioStreamPlayer must use Stream playback.
- Peck sprites already exist (`art_event == &"peck"`), so this needs no new character art.

## Requirements
1. **Find why presses are dropped.** Reproduce spamming the peck key on the ground next to food. Identify whether a cooldown, the `peck_hold_pending` hold logic, or the peck animation timer swallows presses, and write the cause in the Report.
2. **Fix it** so rapid presses eat reliably up to a sensible rate, without changing the dive peck window or its tuning.
3. **Always give feedback.** A peck press that finds nothing to eat plays the short ground-peck animation and a quiet whiff sound. A press that eats keeps its current effect.
4. **Check the exploit.** Report whether holding left/right at ground level while spamming peck is now a stronger strategy than diving (gp-12). If it clearly is, note the numbers and suggest tuning, but do not change balance in this task.
5. Sound: reuse an existing sound if one fits, otherwise add the whiff to the existing SFX path with the correct bus and Stream playback. Volume stays quiet so spamming does not get loud.

## Out of scope
- Dive peck window, snatch rules, scoring and bin or food drop balance.
- New character art.
- Naming the mouse buttons on screen (separate small task).

## Done when (acceptance)
- [ ] Headless test: N rapid peck presses next to ground food eat the expected items, with no dropped presses beyond the documented rate.
- [ ] A press with nothing in range triggers the ground-peck animation and the whiff sound (assert the sound is requested).
- [ ] No change to dive peck outcomes in existing tests.
- [ ] `./tools/validate.ps1` passes with no new failures.

## Report
**Files:** `scripts/game.gd` (`_ground_peck_miss`, `peck_buffered`, `PECK_WHIFF_DB`, buffered-press fire in `_physics_process`), `scripts/stash_raids.gd` (`has_peck_target`), new `tests/peck_spam_checks.gd` wired into `tests/integration.gd`.

**Tests:** 18533 checks, 0 failures (task 101 left 18526; 7 new checks).

**Root cause (reproduced headless with E key events, gull standing beside a bin, 3 s of tapping):**
1. Every grounded peck (bin, bag, toddler) shares `world.peck_cooldown` = 0.18 s in `stash_raids.peck()`. A press inside it returned false and was dropped with no pose, no sound. Before the fix: tapping at 5/s landed 15 of 15; at 6.7/s only 10 of 20; at 10/s 15 of 30. So anyone mashing faster than about 5.5/s lost roughly half of presses, silently.
2. A press with nothing in reach also gave no feedback (only the near-bin tip text).
3. Not a cause: the `peck_hold_pending` screech-hold deferral (the press fires on release; quick taps are well under the 0.24 s hold) and the peck animation timer swallowed nothing in the repro. Side finding: in mouse-aim the gull walks toward the cursor on the ground, so a player whose cursor is off the gull drifts out of reach mid-spam and every press then misses; my first repro lost all but one press this way. That is control design, left alone.

**Fix:** cooldown and rate cap unchanged. (a) A press during the cooldown with food in reach is held (one deep) and fires when the cooldown ends, so near-cap tapping loses nothing. (b) Any grounded press that eats nothing plays the ground-peck pose and a quiet whiff (reused `empty_tap` cue, -12 dB, SFX bus via the existing `Audio.play` Stream playback path, so no new sound or bus work). Held presses show the pose now and land with the normal effect. Dive pecks (`attempt_peck`, peck window) untouched.

**Exploit check (gp-12):** not changed, not measured against dives in play. From tuning: a bin holds 9 snacks and gives 3 per 4 pecks, so at the 5.5/s cap a bin empties in about 2.2 s (roughly 4 snacks/s); a sunbather bag gives 2 per 3 pecks but holds 3. Supply is finite, the stomach digests slowly and sunbathers wake and swat, so it is not unlimited, but ground raiding is clearly fast next to a dive cycle. The fix does not raise the ceiling (5.5 pecks/s before and after); it only stops losing presses below it. Holding left/right while spamming makes the press fire at once instead of on release and does not change the rate. If the ground route proves too strong, tune `world.peck_cooldown`, `bin_pecks` or `bin_burst`, not done here.

**Not done / unverified:** no audio listened to in the real game; the feel of the held press is untested by hand.

**Branch:** sonnet/102-peck-press-feedback

## Review notes
<!-- Filled in by the reviewer. -->
