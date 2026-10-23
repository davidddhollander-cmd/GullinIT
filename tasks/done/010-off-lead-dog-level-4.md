# 010 — Off-lead dog and Level 4 "Dog Day Afternoon"

Status: merged
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
- [x] Dog wanders, warns, chases, leaps and catches per the rules; a gull above `chase_ceiling` is never caught; tests drive each state
- [x] Catch stuns the player and drops held food; cooldown prevents an instant second catch
- [x] `dog_outrun` fires once per escaped chase; three escapes complete `l4_outrun`; `l4_counter` completes on a stall handover snatch
- [x] The dog exists only in level 4; levels 1–3, 5–6 unchanged
- [x] Level 4 is hand-built, named Dog Day Afternoon, and passes the existing layout/zone/sign checks
- [x] `tools/validate.ps1 -Capture` run once at the end: no new failures (baseline 1 known: `level 6 rival leaves the scene of a theft`); screenshots of the dog chasing and leaping, paths in the Report

## Report
Branch `sonnet/010-off-lead-dog-level-4` (from `main` 429b217). Not merged.

**Files changed**
- New `scripts/off_lead_dog.gd` (`OffLeadDog`: enum WANDER/SNIFF/WARN/CHASE/LEAP/CATCH/COOLDOWN; sprite from `Config.frames("off_lead_dog")`; signals `barked`, `caught`, `outrun`).
- `scripts/game.gd`: spawns the dog only for twist `off_lead_dog` (into `actors`), ticks it after `player.tick`, wires WOOF! / GOTCHA! / OUTRUN! messages and `_quest_event("dog_caught" / "dog_outrun")`, pause support. A catch calls `BeachGull.stun(-1, dog.position)`, so the existing `_stunned` path drops food and costs points.
- `scripts/spawner.gd`: skips `off_lead_dog` spawn entries (not a BeachTarget). `scripts/level_generator.gd`: levels 1-4 are authored (was 1-3).
- `data/tuning.json`: new `off_lead_dog` section. `data/levels/level_04.json`: hand-built Dog Day Afternoon.
- `tests/off_lead_dog_checks.gd` (new, wired into `tests/integration.gd`); `tests/level_generator_checks.gd` and two lines in `tests/integration.gd` (spawn count ignores the dog; level 4 gets level-3 style overview views).
- Docs: `README.md`, `docs/OPENING_LEVELS.md`, `docs/LEVEL_GENERATOR.md`.

**Tests**: `tools/validate.ps1 -Capture`: `INTEGRATION: 15888 checks, 1 failures` (the known `level 6 rival leaves the scene of a theft`). The first full run exposed level-4 dependencies (family test, wheelie-bin count, scenery distinctness), fixed in the second. Own suite: 40 checks (wander stays in home zone and sniffs; high gull ignored and never caught; bark, 0.4 s hold, then chase; notice radius; run speed 95 between walk 28 and flight 140; leap only when low and in range; leap arc; ground catch stuns and drops held food and records dog_caught; cooldown blocks a second catch; mid-leap catch; outrun by climbing and by distance; short chase records nothing; stunned gull ignored; three outruns complete l4_outrun; handover swallow completes l4_counter; no dog in levels 1-3, 5, 6). The total is below the 16,281 baseline because level 4 is now authored and no longer runs the 20-variation generated-layout checks.

**Screenshots**: `test-output/off-lead-dog-chase.png`, `test-output/off-lead-dog-leap.png` (in the worktree, gitignored).

**Tuning (`off_lead_dog`)**: notice_radius 70, chase_ceiling 40, windup 0.4, run_speed 95, wander_speed 28, leap_range 26, leap_height 28, leap_time 0.6 (matches the clip), leap_speed 100, leap_lift 22, leap_cooldown 0.8, catch_radius 9 (mouth offset 9,-7), catch_time 0.5, cooldown 4, min_chase 1.5, lose_radius 120, sniff 1.5-3, rest 0.5-1.2.

**Decisions**
- Gull height = `world.ground - gull.position.y` (grounded gull = 6); "airborne" for leaps means above feet_offset + 2.
- The dog stays on the sand line, x clamped to the world; wandering is limited to the spawn's `home` range [235,330]; chasing can go anywhere along x.
- A catch only counts if `stun()` succeeds, so invulnerable or already stunned gulls are ignored and never chased.
- Level 4 keeps the old wind (dir 1, 0.5, gusts), awareness 1.24, time 135, stars 450/700/950 and Gary (normal, from the start). Layout is Boardwalk's promenade/pier base, but the quiet beach now holds sunbather, picnic family (toddler 295, mum 339) and sunbather, because existing family-trip tests use level 4's `family_1`; one wheelie bin (existing test expects 1 outside level 3), a rock at the right end, and nudged parasols/bin so the scenery differs from level 3. `random_foods` copied from level 3 (same cast).
- Level select shows names from data, no code change.

**Not done / gaps**: no new audio (reuses click/snatch); no dog shadow; dog not shown on the HUD map; no human playtest (numbers are the spec defaults).

## Review notes
