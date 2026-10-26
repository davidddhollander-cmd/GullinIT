# 038 — Off-lead dog also chases rival gulls

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-26

## Goal
Playnotes 25 Oct: "Dog doesn't catch rival gulls?" The dog should threaten every low gull, not only the player, so the player can lure it onto rivals.

## Context
- `scripts/off_lead_dog.gd` (line 4 comment: it "only ever interacts with the player gull"). Tuning: `off_lead_dog` in `data/tuning.json`.
- Rivals: `scripts/rival_gull.gd` (carry state, existing stun path, `mug_stun`).

## Requirements
1. When picking a chase target, consider the player and rival gulls within `notice_radius`; prefer the nearest low gull. Player behaviour unchanged when no rival is closer.
2. Catching a rival: same catch timing as the player; the rival drops any carried food as a ground scrap and is stunned/flees via its existing stun path. No score change.
3. Add `chase_rivals: true` to the `off_lead_dog` tuning block.
4. Update the line-4 comment.

## Out of scope
- Dog art, leash, chase range (task 024).

## Done when (acceptance)
- [ ] A rival on the sand near the dog gets chased and caught and drops its food
- [ ] Test: dog targets a nearer rival, catch drops food; with `chase_rivals: false` it ignores rivals
- [ ] `./tools/validate.ps1`: 0 failures

## Report

## Review notes
