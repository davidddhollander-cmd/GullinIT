# 019 — Off-lead dog stays near its patch

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Playtest note: "Dog chasing across all." Once the level 4 dog starts a chase it follows the gull across the whole beach, because chase only ends at `lose_radius`. Give it a leash: past a set distance from its home patch it gives up and trots back, so the danger zone stays local and readable.

## Context
- `scripts/off_lead_dog.gd`: `home` (x range from the level spawn, `home: [235, 330]` in `data/levels/level_04.json`), chase/leap/return states, `lose_radius`, wander inside home ±20.
- Dog tuning: find where `_t()` reads from (`data/tuning.json` or `data/dog_art.json`); add the key there.
- L4 quest "OUTRUN THE DOG" counts `dog_outrun` events (`game.gd`). Keep that working; a leash give-up counts as an outrun.
- Plan: `docs/superpowers/plans/2026-10-24-playnotes-fixes.md`.

## Requirements
1. New tuning key `leash` (px past each edge of `home`, start at 120).
2. If the dog (or its target) is more than `leash` past its home range, it stops chasing, plays a short give-up/bark beat using the existing art, and returns home at trot speed. It won't start a new chase on a gull outside the leash zone.
3. A give-up emits the same outrun event the quest uses (exactly once per chase).
4. The dog never leaves `home ± leash` (allow a few px for a leap in progress).

## Out of scope
- New dog art, adding the dog to other levels.

## Done when (acceptance)
- [x] Check: a gull flies 600 px away from home during a chase → the dog stops within `home ± leash`, returns inside home, and one outrun event fires
- [x] Check: a gull hovering outside the leash zone doesn't trigger a chase
- [x] Existing dog checks still pass
- [x] One `tools/validate.ps1` run at the end: 0 failures (`-Capture` not needed)

## Report
Files: scripts/off_lead_dog.gd, data/tuning.json (off_lead_dog.leash = 120), tests/off_lead_dog_checks.gd.
Tests: headless integration run, 15410 checks, 0 failures (ran the integration scene directly with the Dummy audio driver; same as validate.ps1 without -Capture).
Decisions:
- Zone = home.x - leash .. home.y + leash. Gulls outside it are never noticed/chased (`_can_chase`); dog movement is clamped to the zone.
- Leash give-up in CHASE (gull or dog outside zone) emits `barked` (the WOOF beat) and `outrun` once, regardless of min_chase, then enters COOLDOWN with `returning` set: trots back at run_speed*0.5 until inside home, then the cooldown ends.
- Existing checks relocate the dog to x=800 outside the real home, so `_reset` now sets a wide test home; new checks use the real level 4 home.
New checks: 600 px flight -> dog stays within home+leash, one outrun, returns inside home; gull outside leash does not trigger chase.
Branch: sonnet/019-dog-leash

## Review notes
