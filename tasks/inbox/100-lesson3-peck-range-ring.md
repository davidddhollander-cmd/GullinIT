# 100 — Lesson 3 ring shows when the cone is in peck range

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-20

## Goal
In training lesson 3 (the first peck), the gold ring around the target should visibly change when the gull's beak is close enough to peck it. Today a player pecks too far away and only learns to move closer after a failed try. The final dive lesson already gets this help from the ring and the "Now!" prompt, so lesson 3 should too.

## Context
- Player feedback nw-05 (20 Nov): "In lesson 3 my first peck was too far away... Having the ring change color when the cone is in peck range would give that earlier lesson the same helpful timing cue as the final dive." Also gp-04 (miss cue).
- Relevant files: `scripts/overlay.gd` (training target ring, around line 809: `draw_arc(training_target,12,...)`), `scripts/game.gd` (`training_target()`, `prompt_action == "peck"`, lesson 3 peck freeze from task 093), `scripts/gull.gd` (`attempt_peck`, `beak()`), `data/trainer.json`.
- Use the same range test the real peck uses, so the ring never says "in range" when a peck would miss. Do not write a second copy of that rule.
- CLAUDE.md: gameplay tuning in `data/*.json`; UI text on the 8 px grid.

## Requirements
1. While lesson 3 is active and the peck is the next action, the ring turns a second colour (suggest green, with a thicker or pulsing outer ring so it does not depend on colour alone) whenever the beak is within real peck range of the target. Out of range it stays gold.
2. The change applies to the ground peck of lesson 3 only. Other lessons keep their current ring behaviour.
3. Update the lesson 3 text in `data/trainer.json` to mention it, for example "The ring lights up when you are close enough." Keep all control modes and touch variants of the text in step.
4. Any colour or radius values go in data or a named constant, not inline numbers.

## Out of scope
- Peck range tuning, dive physics, the final dive lesson, or any other lesson.
- Miss reasons (task 101) and peck press feedback (task 102).

## Done when (acceptance)
- [ ] In lesson 3 the ring changes colour exactly when a peck would reach the target, and changes back when the gull moves away.
- [ ] Lesson 3 card text mentions the ring change in every control variant.
- [ ] A test in `tests/training_checks.gd` (or a new check wired into `tests/integration.gd`) covers in-range and out-of-range.
- [ ] `./tools/validate.ps1` passes with no new failures.

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
