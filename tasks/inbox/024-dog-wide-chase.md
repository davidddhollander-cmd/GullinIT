# 024 — Dog: wide chase territory, keeps chasing high gulls

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playnotes, 24 Oct: "the dog should have a wider chase territory and keep chasing even if gull goes higher, he should be a continuous threat but avoidable." Task 019 misread the earlier note and leashed the dog to about 120 px past its patch. Reverse that: the dog covers about half the beach, keeps tracking a gull that flies higher, and leaps higher. You can still avoid it by staying high or leaving its half.

## Context
- `scripts/off_lead_dog.gd` (leash from 019: `_in_leash`, `_give_up(leashed)`, `returning`), tuning `off_lead_dog` in `data/tuning.json` (`leash`, `chase_ceiling`, `lose_radius`, `leap_height`, `leap_range`, `leap_lift`). Level 4 dog home `[250, 330]`, world width 1280. Checks in `tests/off_lead_dog_checks.gd`.
- Interview decisions: territory = roughly half the beach (~600 px zone around the patch); a high gull = the dog runs underneath barking and **higher leaps** make mid-height risky.

## Requirements
1. Territory: set `leash` so the zone spans ~600 px (e.g. 260 each side of home, clamped to the world). Keep the leash give-up from 019 (bark, one outrun, trot home) at the zone edge.
2. Height: `chase_ceiling` no longer ends a chase or blocks noticing. Above leap reach, the dog shadows the gull's x underneath (run speed, bark every few seconds) and can't catch it. The chase still ends on the leash edge, a stun, `lose_radius` (re-tune it so a high gull directly above isn't "lost"; measure horizontal distance), or a timeout so it isn't endless (start at 8 s, then cooldown).
3. Higher leaps: raise the leap so a gull at mid-height is at risk (start `leap_height` around 1.5x the current value; tune `leap_lift`/`leap_time` to match). A gull flying high (above about 2x the old ceiling) must stay safe.
4. OUTRUN THE DOG quest keeps working (outrun on a give-up after `min_chase`, or a leash/timeout give-up).

## Out of scope
- New dog art; the dog in other levels.

## Done when (acceptance)
- [ ] Checks: a high gull is shadowed (dog under it ±20 px) and never caught; a mid-height gull can be caught by a leap; a gull leaving the ~600 px zone ends the chase with one outrun; the chase times out
- [ ] Existing dog checks updated (not deleted) to the new rules
- [ ] One `tools/validate.ps1` run at the end: 0 failures

## Report

## Review notes
