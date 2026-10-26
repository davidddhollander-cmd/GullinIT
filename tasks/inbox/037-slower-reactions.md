# 037 — Slower beachgoer reactions; slower elderly walkers

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-26

## Goal
Playnotes 25 Oct: "Old man too fast, reaction times slower. Same for old lady in dress. Overall characters too quick on reaction as well." Give the player a fairer window after a snatch.

## Context
- `scripts/adult_reaction.gd` (`THEFT_SURPRISE_TIME`, `FAILED_CHASE_ANGER_TIME`, notice/chase timers), `scripts/target.gd`, `data/targets.json`, `data/tuning.json`.
- CLAUDE.md: prefer data over code. If timings are constants in code, move them into one `adult_reaction` block in `data/tuning.json`.

## Requirements
1. Global: lengthen the notice/surprise delay before an adult reacts to a nearby gull or a theft by ~40% (e.g. surprise 0.32 -> 0.45), and delay chase/swat start by a similar amount. Swat range unchanged.
2. Old man and the old lady in the sundress (find their kinds/appearances in `data/targets.json` / `data/levels/*.json`): walk ~25% slower than other adults and react ~1.5x slower. Add per-target `speed_mult` / `reaction_mult` data, default 1.0.

## Out of scope
- Dog, rivals, vendors, lifeguard.

## Done when (acceptance)
- [ ] Adults react noticeably later; old man / sundress lady walk and react slower than others
- [ ] Test asserts the multipliers are read (old man reaction delay > default, speed < default)
- [ ] `./tools/validate.ps1`: 0 failures

## Report

## Review notes
