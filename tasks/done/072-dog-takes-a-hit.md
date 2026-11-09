# 072 — A bumped dog takes a hit like a gull

Status: merged
Author: Claude
Assignee: Claude Haiku
Depends on: 070
Created: 2026-11-09

## Goal
When a black-back bumps the dog, it should take a proper hit: thrown away in an arc, spinning, landing dazed with stars circling its head, the way a bumped gull does. Today it only slides back 18 px.

## Context
- `scripts/off_lead_dog.gd`: `bump()` calls `_bounce()` (an instant 18 px recoil, then `_cooldown`). `air` already lifts the sprite. `_animate()` sets `sprite.position.y` and plays clips; the sheet has `idle`, `run`, `sniff`, `leap`, `catch`.
- `scripts/effects.gd` `pixelfx("pixelfx_stunned", Vector2(0,-14), Vector2.RIGHT, parent)` makes the looping stars. `pixelfx_stunned(gull)` shows how they are parented and timed; it takes a gull, so call `pixelfx` directly or widen it. Effects live in `Config.tuning.juice`.
- `scripts/gull.gd` `begin_tumble()` for how a gull's launch feels; `Config.tuning.tumble` (`launch_speed` 110, `launch_up` 115, `gravity` 520, `duration` 0.9).
- `game.gd` `_dog_bumped` handles the BONK and brash. Rotating and moving the existing sprite is allowed; do not draw a dog.

## Requirements
1. Add a dog state `TUMBLE` entered by `bump()` only. `_bounce()` stays as it is for Shakedown blocks.
2. In `TUMBLE`: the dog launches away from the gull with its own `off_lead_dog` tunables (`tumble_speed`, `tumble_up`, `tumble_gravity`), using `air` for height and spinning the sprite (`leap` clip). It stays inside the world bounds.
3. On landing: sand puff, rotation back to 0, then `tumble_daze` seconds lying still (`sniff` or `idle` clip) with the stars over its head, then the normal `_cooldown`. It can't catch, chase or be bumped again during `TUMBLE` or the daze.
4. Rotation, `air` and stars are reset or freed on every exit, including the dog being freed at level end and a squall or Shakedown setting `flee_to` during the tumble. The tumble finishes before `flee_to` takes over.

## Done when (acceptance)
- [x] A bump throws the dog further than the old 18 px, in the air, and it lands back at ground level with rotation 0
- [x] Stars appear on the dog during the daze and are gone afterwards
- [x] The dog can't catch or be re-bumped until the daze and cooldown are over
- [x] Shakedown's bounce-off and other species are unchanged
- [x] Checks added on simulated ticks; `./tools/validate.ps1` has no new failures

## Report

**Branch and commit:** `haiku/072-dog-hit` (worktree `GullinIt-haiku-072`), commit recorded in the git log of that branch. Not pushed, not merged.

**Files changed**
- `scripts/off_lead_dog.gd`: new `TUMBLE` state, `landed` and `dazed` signals, tumble vars, `_start_tumble`, `_tick_tumble`, `_land`, `_end_tumble`, `_clear_tumble_visuals`. `bump()` now starts a tumble (guarded against COOLDOWN, TUMBLE and `flee_to`). `tick()` runs the tumble before the `flee_to` branch. `_bounce()` is unchanged and still used by the power-immunity path in `_try_catch`.
- `scripts/game.gd`: connects `landed` to `effects.sand_puff` and `dazed` to `effects.pixelfx("pixelfx_stunned", (0,-40), ..., dog)`, storing the result in `dog.stars`.
- `data/tuning.json`: `off_lead_dog` gains `tumble_speed` 80, `tumble_up` 120, `tumble_gravity` 420, `tumble_spin` 12, `tumble_daze` 1.2.
- `tests/dog_hit_checks.gd` (new, plus `.uid`): 19 checks on simulated ticks.
- `tests/integration.gd`: registers `dog_hit_checks.gd` after `off_lead_dog_checks.gd`.
- `tests/shakedown_checks.gd`: 2 assertions updated. A black-back dive now leaves the dog in TUMBLE, not COOLDOWN with the old recoil (the spec changes this on purpose).
- `tasks/done/072-dog-takes-a-hit.md`: this file. The inbox copy was left alone.

**Test results (`tools/validate.ps1`)**
- Run: `INTEGRATION: 16976 checks, 2 failures`.
- Failures: "nobody teleports across the beach while running off (1 jumps)" and "data/demo.json enables the four-level demo". Both are the known failures.
- No new failures. Check count is up 19 from main's 16,957, which is the new dog checks.

**Decisions**
- One TUMBLE state with a `tumble_landed` flag for the daze, not a separate DAZE state.
- The tumble ticks before the `flee_to` branch, so a squall or Shakedown flee that is set mid-tumble waits until the daze is over.
- Stars are parented to the dog node, not the sprite, so they don't spin with it. They are freed in `_clear_tumble_visuals`. The dog's children are also freed when the dog is freed at level end.
- Landing snaps rotation to 0 with no ease-back. The dog holds still during the daze with the `idle` clip.
- Stars are created via the game's `dazed` handler, not in the dog, because the dog has no reference to effects. The dog stores the returned sprite and owns its lifetime.
- Stars use a `pixelfx` call directly, as the spec allowed, so `pixelfx_stunned` is unchanged.

**Not done / caveats**
- Visual feel is not playtested. The numbers are first guesses in `tuning.json`.
- Dog art `sprite_offset_y` is -18 and the star anchor at -40 was estimated from the 96 px frame at scale 0.5. Worth a look in game.

**Last commit:** see `git log -1` on `haiku/072-dog-hit`.
