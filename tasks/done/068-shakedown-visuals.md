# 068 — Shakedown visuals: rear up, slam, rampage, deflate

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 067
Created: 2026-11-09

## Goal
Shakedown works mechanically but doesn't look like a power. Give it four clear beats, have the gull change into its enraged sprites (art from task 069), and stop the gull bursting feathers as if it had been hit. Code and tuning only. The code must work with or without the art: any clip with no enraged version plays as normal.

## Context
- `scripts/shakedown.gd`: `start()`, `_slam()`, `_knock_around()`, `_panic()`, `_shake()`, `_pulse()`, `peck()`, `end(snap)`. `scripts/brashness.gd`: `fire()`, `hit_fx()`.
- `scripts/effects.gd`: `ground_slam(at, facing)` already does heavy landing, sand puff, stripes both ways and shake. The `ring` particle (`grow`, `delay`), `pixelfx()`, `_texture_particle()`, `DUST_PUFF_TEXTURE`, `shout()`, `sand_puff()`, `feather_burst()`.
- `scripts/gull.gd`: `squash(x, y)`, `squash_scale()`, `walk_phase`, the `screech` clip (peak wings on frame 4), `power_scale`, `power_tint`. The clip is chosen in several places in `tick()`, and the `frame_beaks` lookup reads `art_entry.animations[String(sprite.animation)]`.
- Task 069 registers `idle_enraged` and `walk_enraged` with the same frame numbers as `idle` and `walk`. A later task adds the other clips under the same `<clip>_enraged` naming.
- `game.gd:237`: the `stun_ignored` handler shows "NOPE!", rate-limited.
- `scripts/overlay.gd`: `score_announcement` and the game overlay drawing.
- Check `godot-prompter:shader-basics` and `tween-animation` first. Every number goes in the `shakedown` block of `data/tuning.json`. AGENTS.md: tinting and scaling existing sprites is allowed; do not draw any part of a character. Text stays on the 8 or 16 px grid.

## Requirements
**1. Rear up**
1. On firing, hold the action for `rear_time` (0.3 s) before the slam. During it the screen dims by `rear_dim` (behind the HUD if practical). "SHAKEDOWN!" appears at 16 px, reusing `score_announcement` if it fits. This replaces the small plated name for Shakedown only; Gang Call is unchanged.
2. A grounded gull holds the screech clip's peak frame during the hold. An airborne gull keeps its pose. Find out whether `effects.freeze` skips the gull's `tick()`, and set the pose so the hold actually shows.
3. The 8 s power time starts after the hold. The gull is invulnerable during the hold. Pause, level end and `clear()` during the hold must leave a clean state: no stuck dim, freeze or pose, and no slam firing afterwards.

**2. Slam**

4. At the end of the hold, a shockwave ring grows from the gull to exactly `slam_radius` in `slam_ring_time` (0.18 s), `slam_ring_width` px thick. Add an optional width to the ring particle, default 1. On the first frame of the slam, draw one white screen frame.
5. If the gull is on or near the ground, call `ground_slam` beneath it.
6. Victims flash when the slam lands, using `target.hit_flash()` as now. No per-victim delay: the ring is too fast for one to be visible.

**Feathers in the wrong place (slam and every shake knock)**

7. The gull must no longer burst its own feathers. `hit_fx` draws no feathers when passed 0, including the per-hit extra. Shakedown passes 0. A rival made to drop food gets a `feather_burst` at the rival. People lose food, not feathers. Gang Call is unchanged.

**3. Rampage**

8. Enraged sprites: add one `enraged` flag on `BeachGull`. While it is on, the gull plays `<clip>_enraged` wherever that clip exists, and the normal clip otherwise, keeping the frame position when the clip swaps. Do this in one place rather than at every `play` call. Beak and foot positions must keep working on the enraged clips. The flag turns on when the slam lands, so the bird transforms on the impact, and off on every end path. Carry sprites are unchanged for now.
9. Keep the existing tint pulse and end-warning tick unchanged for now. They cover clips that don't have art yet, and the full-art task can retire them.
10. Stomp: while grounded and walking, every `stomp_steps` of `walk_phase`, a sand puff and `stomp_shake`.
11. Panic pulse: each repeat `_panic()` also draws a faint thin ring from the gull.
12. Blocked hit: when "NOPE!" actually shows during the power, also play the crit-hit effect on the gull.
13. Cleaned out: the peck that reaches `raid_cap` plays the crit-hit effect at the window and shouts "CLEANED OUT!".

**4. Deflate**

14. On natural expiry only (not `snap`), the gull switches back to its normal clips and shrinks from `bully_scale` to normal over `deflate_time` (0.25 s) with a small feather puff and a low-pitched `gust`. Reuse `squash()` with an optional duration rather than adding a second animation path.

**Reduced effects:** the white frame and dim are skipped when `GameState.options.shake` is off.

## Out of scope
- New art, sound or pixelfx sheets (the rage aura was tested and dropped); glow and steam effects (replaced by the enraged sprites); enraged carry sprites; Gang Call or kittiwake visuals; balance changes; perks.

## Done when (acceptance)
- [ ] The power runs for its full duration after the hold, and the slam fires once, at the end of the hold
- [ ] Pausing, ending the level or `clear()` during the hold leaves no dim, freeze, stuck pose or later slam
- [ ] The ring reaches `slam_radius`
- [ ] No feather particles at the gull from the slam or shake knocks; a rival drop still bursts feathers; Gang Call's feathers are unchanged
- [ ] With an `_enraged` clip present (use a fixture clip in the test), the gull plays it after the slam and not before; a clip with no enraged version plays normally with no errors
- [ ] Beak and foot positions match the normal clip's while enraged
- [ ] The enraged flag is off at expiry, level end and `clear()`, and the normal clip plays afterwards
- [ ] Stomps appear only during the power, and only when grounded and moving
- [ ] Crit effect shows only when "NOPE!" shows; "CLEANED OUT!" shows once, on the capping peck
- [ ] Deflate returns the sprite to normal on expiry; a level-end `snap` returns it at once
- [ ] With the shake option off: no white frame and no dim, and the power still works
- [ ] Checks added to `tests/shakedown_checks.gd`; `./tools/validate.ps1` has no new failures. No screenshots needed; David will judge the look in game

## Report
Branch `sonnet/068-shakedown-visuals` (not pushed, not merged). Tests: 16,838 checks, 2 failures, both the known ones ("nobody teleports across the beach while running off", "data/demo.json enables the four-level demo"); main had 16,790 checks, same 2 failures. +48 checks.

Files changed: `scripts/shakedown.gd`, `scripts/brashness.gd`, `scripts/gull.gd`, `scripts/effects.gd`, `scripts/overlay.gd`, `scripts/game.gd`, `data/tuning.json` (shakedown block), `tests/shakedown_checks.gd`, `tests/impact_pass_checks.gd`.

How it works
- Hold: `start()` no longer slams. It sets `rear_left = rear_time`, `player.rearing`, the dim and the "SHAKEDOWN!" banner (`overlay.show_callout`, 16 px, no scale pop; the small plated name is skipped for Shakedown only). `brash.tick` runs `shakedown.rear_tick()` instead of the power clock while `rear_left > 0`, so the 8 s starts after the hold. The slam is the only caller path out of the hold, so it fires once.
- `effects.freeze` DOES skip the gull's `tick()` and `brash.tick()` (`game.gd` returns right after `effects.tick`). So the hold does not use freeze: it runs on the power's own clock, and a hit-stop (or pause) just delays it. The pose is set in `tick()` (grounded + `rearing`: screech clip, frame 4, horizontal velocity zeroed). Airborne keeps its pose.
- Slam: `set_enraged(true)`, `power_scale = bully_scale` (moved here from `start()` so the bird grows on impact), `effects.ring()` (new helper, uses the ring particle with new optional `width`/`points`, `grow = (R-4)/time` so it ends exactly at `slam_radius`), white frame, `ground_slam` when the feet are within `slam_ground_reach` of the sand, knock + `hit_fx(.., feathers = 0, ..)`.
- Feathers: `hit_fx` skips `feather_burst` when `feathers <= 0` (including the per-hit extra). Shakedown passes 0 for slam and shakes. A rival that drops food in `_knock_around` gets a `feather_burst` at the rival (`hit_feathers` from the shakedown block). Gang Call untouched (a test confirms it still bursts).
- Enraged clips: `BeachGull.enraged` + `set_enraged()`; `_swap_clip()` is the single place. At the start of `tick()` an enraged gull is put back on plain clip names (so all existing `play()`/frame logic is unchanged), and at the end of `tick()` the current clip is swapped to `<clip>_enraged` if that exists, keeping frame and progress. Clips without a twin play normally. Beak and foot placement use fixed source anchors keyed by frame size, so they are identical on enraged clips (tested). `sync_carry`'s climb check now strips the `_enraged` suffix. Carry sprites unchanged.
- Rampage: stomp every `stomp_steps` of `walk_phase` (radians; PI = one footfall at 8 frames per cycle) while grounded and moving; panic repeat ring (faint, 1 px); crit effect (`pixelfx_crit_hit`) in the `stun_ignored` handler only when "NOPE!" shows during the power; the peck that reaches `raid_cap` plays crit and shouts "CLEANED OUT!".
- Deflate (natural expiry only): `end(snap=false)` calls `squash(bully-1, bully-1, deflate_time)` (new optional duration; `squash_span` replaces the fixed `squash_time` in `squash_scale`), a small feather puff and a low `gust`. `end()` always clears `rearing`, `rear_left`, the dim and `enraged` (immediate clip swap-back, so a level-end snap returns at once).
- Overlay: `dim` ColorRect is the first child of the overlay (over the world and effects, behind the HUD), faded with one killable tween (`set_dim`); `flash` ColorRect shown by `white_frame()` for one rendered frame (`tick_flash()` in `_process`). Both are skipped when `juice.shake` or `options.shake` is off.
- Tuning added to `shakedown`: rear_time 0.3, rear_dim 0.45, dim_fade 0.15, callout_hold 1.2, slam_ring_time 0.18, slam_ring_width 3, slam_ground_reach 24, stomp_steps 3.1416, stomp_shake 0.8, panic_ring_radius 90, panic_ring_time 0.5, panic_ring_alpha 0.3, deflate_time 0.25, deflate_feathers 8, deflate_pitch 0.6.

Decisions
- Gorge capacity/digestion still start at fire (invisible); only the bully scale moves to the slam.
- The invulnerability top-up also runs during the hold (otherwise it would decay below `active_left`).
- `ring` particle default behaviour (width 1, 20 points) is unchanged for existing rings.
- `show_score_announcement` now builds its text and calls the new `show_callout`.

Existing tests changed (behaviour the spec deliberately changes: the slam now lands at the end of the hold, and the power clock starts after it)
- `tests/shakedown_checks.gd`: added `land_slam()` helper; "overlay data: ready label and time left" now sims through the hold first; "people flee around the gull's current position" sims `1.05 + rear_time`; the punch check now asserts nothing is knocked during the hold and calls `land_slam` before the slam assertions.
- `tests/impact_pass_checks.gd`: "Shakedown's slam flashes the people it hits" calls `Shakedown.land_slam` after `fire()`.

Not done / not verified
- No enraged art exists, so everything was tested with a fixture `idle_enraged`/`walk_enraged` built from the normal frames. Not looked at in game: the dim strength, ring look, banner position/timing and the stomp feel are untuned guesses. The existing tint pulse and end warning are unchanged, as specified.
- The "!is_inside_tree()" stderr line during import appears on this branch's runs; I did not run main to confirm it is pre-existing (it is printed before any test runs, during the editor import step).

## Review notes
<!-- Filled in by the reviewer. -->
