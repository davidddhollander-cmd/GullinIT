# 093 Lesson 3 peck freeze

Status: merged
Assignee: Claude Sonnet

## Goal
Players stall in Training Day lesson 3: the toddler freeze waits for E / middle click, which mouse-only players cannot find.

## Requirements
1. During a peck freeze (toddler and dive-lesson peck pause), any mouse button press ends the freeze and pecks; the left click must not also flap or dive.
2. Replace "MOUSE 3" with "MIDDLE CLICK" and "MOUSE 2" with "RIGHT CLICK" in labels; the big keyboard/mouse freeze prompt reads "PRESS E OR CLICK".
3. Toddler freeze start clears the lesson toast and score popups.
4. Checks for the above.

## Report
- Files: scripts/game.gd, scripts/overlay.gd, data/trainer.json, tests/trainer_checks.gd, tests/screech_lesson_checks.gd, this file.
- Tests: INTEGRATION 17757 checks, 1 failure. The failure ("level 2 start card shows the pass mark...") is unrelated: the card text now has an extra "WIN FEATHERS TO UNLOCK GULLS/UPGRADES" line from main's latest start-card commit (9c08582); not touched here.
- Decisions: mouse click handled at the top of the peck_pause block in _unhandled_input (consumes the event, clears input.flap_tap, calls _peck_pressed). Item 3: clear effects.texts at freeze start (simpler than holding the freeze). Dive prompt now "DIVE! SHIFT/RIGHT CLICK" (fits). Gamepad and touch prompts unchanged.
- Not done: a held left button still polls as climb until released (polled action, cannot be consumed); harmless on the ground in lesson 3.
- Branch: sonnet/093-lesson3-peck-freeze
