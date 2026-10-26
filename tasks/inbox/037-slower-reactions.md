# 037 — Slower old man and old lady

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-26

## Goal
Playnotes 25 Oct: "Old man too fast, reaction times slower. Same for old lady in dress." Make these two elderly characters walk and react slower. All other characters stay as they are for now.

## Context
- `scripts/adult_reaction.gd` (`THEFT_SURPRISE_TIME`, `FAILED_CHASE_ANGER_TIME`, notice/chase timers), `scripts/target.gd`, `data/targets.json`, `data/levels/*.json`.
- CLAUDE.md: prefer data over code.

## Requirements
1. Old man and the old lady in the sundress (find their kinds/appearances in `data/targets.json` / `data/levels/*.json`): walk ~25% slower than other adults and react ~1.5x slower (notice/surprise delay and chase/swat start). Swat range unchanged.
2. Add these as per-target data (`speed_mult`, `reaction_mult`, default 1.0) so other characters can be tuned later without code changes.

## Out of scope
- Global reaction timings and every other character (unchanged), dog, rivals, vendors, lifeguard.

## Done when (acceptance)
- [ ] Old man and sundress lady walk and react noticeably slower; other characters unchanged
- [ ] Test asserts the multipliers are read (old man reaction delay > default, speed < default; a regular adult still uses 1.0)
- [ ] `./tools/validate.ps1`: 0 failures

## Report

## Review notes
