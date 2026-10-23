# 010 — Off-lead dog and Level 4 "Dog Day Afternoon"

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 008
Created: 2026-10-23

## Goal
Level 4 becomes **Dog Day Afternoon**: a hand-built beach where a fast off-lead terrier chases the gull on the ground and in low flight. Escaping it is the skill; getting caught means a stun. This replaces "Ice cream rush".

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` (Stage 1, level 4).
- Art (task 008, merged): `data/dog_art.json` → sprite id `off_lead_dog` (run / leap / catch = bite / idle / sniff, both facings), README `assets/reference/off-lead-dog-v1/README.md`. 16 px tall dog, 40 px adults.
- Existing pieces to reuse: `BeachGull.stun(duration, attacker)` (stun + food drop path in `game.gd` `_stunned`), `BeachGame._quest_event`, effects messages, `Config.tuning`, hand-built level JSON format of `data/levels/level_01..03.json` (`world`, `zones`, `spawns`, `props`, `map_version`), `docs/OPENING_LEVELS.md`.
- The existing leashed `dog_owner` (twist `dog`) stays as it is; the off-lead dog is a new, separate actor.
- AGENTS.md: no code-drawn characters (use the generated sprite only).

## Gameplay rules (defaults; every number goes in `data/tuning.json` under `off_lead_dog`)
1. **Wander:** the dog roams its home zone on the sand: trots, stops to `sniff` 1.5–3 s, `idle` between. Never enters water or leaves the world bounds.
2. **Notice:** if the player gull is within `notice_radius` 70 px horizontally and lower than `chase_ceiling` (40 px above the sand line), the dog barks — `"WOOF!"` message over it — and after a `windup` of 0.4 s starts chasing. The windup is the fair warning.
3. **Chase:** runs (`run` clip) toward the gull at `run_speed` 95 px/s — faster than the gull walking on the sand, a bit slower than the gull flying, so climbing or flying away is how you escape.
4. **Leap:** when within `leap_range` 26 px and the gull is airborne but below `leap_height` 28 px above the sand, the dog plays `leap` and jumps on an arc towards it.
5. **Catch:** if the dog's mouth box touches the gull (on the ground or mid-leap), it plays `catch`, the gull is stunned through `BeachGull.stun(...)` (normal stun: food dropped, points lost), message `"GOTCHA!"`, quest event `dog_caught`. The dog then ignores the gull for `cooldown` 4 s (sniffs).
6. **Escape (outrun):** a chase that lasts at least `min_chase` 1.5 s and ends without a catch — gull rose above `chase_ceiling` or got more than `lose_radius` 120 px away — records quest event `dog_outrun` and shows `"OUTRUN!"`. Then the dog gives up for `cooldown` and wanders back.
7. The dog never steals food and never attacks rival gulls.

## Level 4 data
- Rename to `Dog Day Afternoon` (id 4); make it hand-built like levels 1–3 (own `world`, `zones`, `spawns`, `props`, `map_version`), using level 3's promenade/stall layout as the base. Keep Gary as the rival (normal, not `loose_only`), keep wind/gusts and time/star targets unless the layout needs a change (note it in the Report).
- `"twist": {"id": "off_lead_dog"}` and one `off_lead_dog` spawn with its home zone on open sand away from the start position.
- Quests: `{"id":"l4_counter","text":"PULL OFF A COUNTER","event":"swallowed","filter":{"handover":true},"count":1,"bonus":50}`, `{"id":"l4_outrun","text":"OUTRUN THE DOG","event":"dog_outrun","filter":{},"count":3,"bonus":60}`, plus `"random_quest": {"count":[3,5],"bonus":40}` and `random_foods` that really appear in level 4.
- Update anything that shows the old name (level select, docs).

## Out of scope
- Levels 5–6 (Chip, Bev, boss), the shop, sounds beyond reusing existing ones (`Audio.play("stun")` etc.).

## Done when (acceptance)
- [ ] Dog wanders, warns, chases, leaps and catches per the rules; a gull above `chase_ceiling` is never caught; tests drive each state
- [ ] Catch stuns the player and drops held food; cooldown prevents an instant second catch
- [ ] `dog_outrun` fires once per escaped chase; three escapes complete `l4_outrun`; `l4_counter` completes on a stall handover snatch
- [ ] The dog exists only in level 4; levels 1–3, 5–6 unchanged
- [ ] Level 4 is hand-built, named Dog Day Afternoon, and passes the existing layout/zone/sign checks
- [ ] `tools/validate.ps1 -Capture` run once at the end: no new failures (baseline 1 known: `level 6 rival leaves the scene of a theft`); screenshots of the dog chasing and leaping, paths in the Report

## Report

## Review notes
