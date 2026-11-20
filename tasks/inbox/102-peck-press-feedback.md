# 102 — Every peck press gives feedback, and ground eating stops dropping presses

Status: inbox
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
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
