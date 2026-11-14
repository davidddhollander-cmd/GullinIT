# 086 — Kittiwake power: Lightning Strike (rough playtest build)

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 064 (merged)
Created: 2026-11-14

## Goal
The kittiwake gets its special. On a full brashness meter the player fires Lightning Strike: time slows, the player aims to mark up to 3 foods, then the gull becomes a lightning streak that snatches each mark in turn and lands mid-air. This is a **rough playtest build with no new art or pixelfx**. David decides after playing whether it stays or gets swapped for Feeding Frenzy, so keep it contained and easy to remove.

## Context
- Design: `docs/SPECIAL_POWERS_BRIEF.md`, Shared rules and Kittiwake sections. This task covers those only.
- `scripts/brashness.gd`: the Shakedown plumbing from 064 is in place: `power()`, `earn()`, `active_id`/`active_left`, `powers_fired`, `fire()` branching on `power.id`, `end_power()`, `clear()`. Shakedown's logic lives in `scripts/shakedown.gd` (`BeachShakedown`). Follow that pattern with a new `BeachLightning`.
- `data/species.json`: the kittiwake has no `power` block and is `coming_soon`.
- `scripts/game.gd`:
  - `assist_target(origin, dir, range, angle)` is the aim-cone pick.
  - `start_slowmo()`/`end_slowmo()` belong to Bullet Time. **Do not call them.**
  - `_snatched()` handles direct snatches, the counter (`handover`) bonus and `brash.earn("snatch")`. `_award()` scores.
  - `set_paused()` and `finish()` are the pause and level-end paths.
- `scripts/target.gd`: `take(gull)` checks `gull.can_collect_food()` (the stomach) before stealing.
- `scripts/digestion.gd`: `collect()` refuses when 4 units are used (small 1, medium 2, large 4). `swallowed` is the signal that leads to scoring.
- `scripts/gull.gd`:
  - `enum State { GLIDE, WINDUP, STRIKE, GROUNDED, STUNNED }`. A STRIKE near the sand can sand-crash.
  - `invulnerable` and the `steady_invulnerable` flag (no flicker) come from 064.
  - `control_mode` is "realistic", "normal" or "casual".
- Stall portions: find how a stall's counter food sets `last_theft_handover`. A strike that takes a counter portion must still pay the counter bonus.
- AGENTS.md: no code-drawn characters. Hiding the gull sprite during the streak is fine. A jagged bolt line and reticles drawn with `_draw()` are FX, not characters, so they're allowed.
- Check `godot-prompter:ability-system` and `godot-prompter:state-machine` first.
- Line numbers are omitted on purpose; find code by function name.

## Requirements
**Data**
1. Give the kittiwake a `power` block in `data/species.json`: `id: "lightning_strike"`, `name: "LIGHTNING STRIKE"`, `ready_label: "STRIKE!"`, `sound: "gang_call"` (placeholder; `pitch` about 1.3), and `fill: {"snatch": 1.4, "handover": 1.4}`.
2. Put the tunables in a `lightning_strike` block in `data/tuning.json`: `windup_time` (2.5 s, real time), `windup_time_scale` (0.35), `max_marks` (3), `mark_range` and `mark_angle` (start from the assist values), `dash_speed` (fast enough that 3 marks across the screen take under about 1 s), `land_invulnerable` (0.5), and `fizzle_pause` (0.1).

**Windup**
3. `fire()` branches to the new power. It sets `Engine.time_scale` to `windup_time_scale` and runs its own clock on real time (unscaled delta or a `Time` tick), so slow motion doesn't stretch the windup.
4. Realistic and normal modes: every tick, `assist_target` with the player's aim direction and the mark range and angle. A new food in the cone becomes the next mark. Casual mode and touch input: on fire, mark the nearest `max_marks` foods the gull can see.
5. Each mark gets a numbered reticle (1, 2, 3) drawn in Godot at the food, using the GullPixel font on its 8 px grid.
6. The windup ends at `max_marks`, at `windup_time`, or on a second press of Q or the touch power button. With no marks, refund the meter (back to 1.0), restore the time scale and end the power with no dash.

**Dash**
7. Restore `Engine.time_scale` to 1, then hide the gull sprite. A new `dashing` flag on `BeachGull` keeps the gull out of its normal state machine: no STRIKE, no sand crash, no stun, and rivals, people and the dog ignore it. Move it in straight lines to each mark at `dash_speed`. Draw a jagged bolt along the path behind it with `_draw()`, fading over about 0.2 s.
8. On reaching a mark that still has its food, snatch it as a direct snatch: `brash`, quest and analytics hooks as now, with the counter bonus on stall portions. **Swallowed whole:** strike snatches skip the stomach. They score at once through the same path a swallowed snack takes, even when the stomach is full, and leave the stomach as it was.
9. A mark whose food has gone (eaten, stolen, portion withdrawn, person left) is skipped with a small fizzle (an existing spark or poof effect) and a `fizzle_pause`.
10. After the last mark the sprite comes back mid-air in GLIDE with `land_invulnerable` immunity and no flicker, keeping the speed it had on the last leg, capped to normal flight speed.

**Shared**
11. `clear()`, `finish()` and pause are all safe mid-windup and mid-dash. Level end restores the time scale, shows the gull, clears `dashing`, invulnerability and reticles. Pause freezes the windup clock and the dash, and resuming carries on.
12. `active_id` is set for the whole power, so `add()` and `earn()` stay blocked while it runs. Strike snatches don't refill the meter. The power can't fire while stunned (already in `fire()`). The `power_fired` event and the results-board count work as for Shakedown.
13. Leave `coming_soon` as it is. In the Report, say how David can play a kittiwake for the playtest: an existing debug or unlock path, or, if there isn't one, the smallest dev-only switch.

## Out of scope
- New art, pixelfx sheets or sounds. The FX table in the brief comes after the playtest.
- Any perk change, including the Bullet Time Q conflict (a known gap, don't work around it).
- Feeding Frenzy, screeching for the kittiwake, shop or price changes, or removing `coming_soon`.

## Done when (acceptance)
- [ ] A kittiwake with a full meter fires Lightning Strike from Q and the touch button. The meter shows "STRIKE!".
- [ ] During the windup the beach runs slowed, but the windup lasts `windup_time` of real seconds. Sweeping the aim marks foods 1–3 with reticles.
- [ ] The windup ends at 3 marks, at the timeout, or on a second press. Firing with no marks refunds the meter and leaves no slow motion.
- [ ] Casual mode marks the nearest 3 by itself.
- [ ] The dash snatches each live mark in order and scores it at once, with a full stomach as well as an empty one. A stall portion pays the counter bonus.
- [ ] A lost mark fizzles and the dash carries on.
- [ ] A mark near the sand causes no sand crash. The gull comes back mid-air with brief immunity and no flicker.
- [ ] Herring Gang Call and black-back Shakedown behave as before.
- [ ] Level end and pause/resume, both mid-windup and mid-dash, leave no leftover state (`Engine.time_scale` is 1, the gull is visible, no reticles).
- [ ] Automated checks in a new `tests/lightning_strike_checks.gd`, wired into `tests/integration.gd`, cover each item above.
- [ ] `./tools/validate.ps1` (or headless `tests/integration.tscn`) passes with no new failures.
- [ ] `docs/BRASHNESS_BACKLOG.md` and `docs/SPECIAL_POWERS_BRIEF.md` note Lightning Strike as built (rough, awaiting playtest).

## Report
**Branch:** `sonnet/086-lightning-strike-rough` (from main c252ead). Last commit: see `git log -1` on the branch.

**Files changed**
- New: `scripts/lightning_strike.gd` (`BeachLightning`: WINDUP, DASH, LAND phases; reticles and bolt drawn with `_draw()`), `tests/lightning_strike_checks.gd`.
- Hooks: `scripts/brashness.gd` (`lightning` instance, `fire()` branch, `tick()` branch, `end_power()` branch, `active_fraction()`/`active_label()` for the HUD), `scripts/gull.gd` (`dashing` flag: tick early-return, stun/swat/dive guards, `untargetable()`, `can_collect_food()` returns true), `scripts/game.gd` (`assist_target` gets an optional `exclude` array; `start_slowmo` second press ends the windup; `set_paused` calls `lightning.set_paused`; `_snatched` swallows whole when dashing and counts the counter bonus), `scripts/overlay.gd` (meter fill and label via brash), `data/species.json`, `data/tuning.json`, `tests/integration.gd`, `docs/BRASHNESS_BACKLOG.md`, `docs/SPECIAL_POWERS_BRIEF.md`.

**Tests**
- Baseline (main, before changes): `INTEGRATION: 17612 checks, 0 failures`.
- After: `INTEGRATION: 17669 checks, 0 failures` (+57 checks, all in `lightning_strike_checks.gd`).
- Ran with the Godot 4.7.2 console exe from the other checkout's `.tools` (this worktree has no `.tools`).

**Decisions**
- Windup clock: `delta / Engine.time_scale` (real seconds), so no `Time` tick and it freezes with the physics process on pause. `set_paused` drops the slow motion for the menu and restores it on resume. `start_slowmo`/`end_slowmo` (Bullet Time) are never called.
- Windup marking in realistic and normal modes uses `assist_target` with the gull's aim direction; I added an optional `exclude` argument so a second food in the cone can be picked once the best one is already marked.
- Casual mode and touch (`input.touch_active`) auto-mark the nearest 3 foods on screen, then hold a short beat (`auto_hold`, 0.6 real s, extra tunable) so the reticles are visible before the dash.
- Swallowed whole: while `dashing`, `can_collect_food` is true (so `take()` works with a full stomach) and `_snatched` passes the snack straight to `_swallowed()` instead of `digestion.collect()`. Stomach contents are untouched; scoring, quests and the counter bonus go through the normal path. The counter bonus uses `player.dashing` in the `handover` test.
- Dash: the gull is `visible = false`, state GLIDE, `dashing = true`; `BeachGull.tick` returns at once so there is no STRIKE, sand crash or stun. Immunity is 999 during the dash (`untargetable()` is true while dashing, which dogs, sweeper, teens and stash raids already check). Landing sets `land_invulnerable` with `steady_invulnerable` (no flicker), velocity = last leg direction at normal flight speed. The power ends when that immunity runs out, so `active_id` stays set through the landing.
- A stun during the windup (it is not made immune) cancels the power and refunds the meter. A cancelled or empty windup also decrements `powers_fired`; the `power_fired` analytics event for the press was already sent.
- Lost mark: fizzle uses the existing hit-spark pixelfx and a click, then `fizzle_pause`, then the next leg.
- HUD: during the windup the meter bar drains with the remaining windup time and reads "AIM"; during the dash and landing it reads "ZAP".
- Extra tunables beyond the task: `auto_hold` and `bolt_fade` (0.2 s) in `lightning_strike`.

**Not done / caveats**
- Not played in a window; verified by the automated checks only. Dash timing, bolt look and the reticle layout need David's eyes.
- The Bullet Time Q conflict is untouched (known gap): the kittiwake cannot fire with that perk equipped.
- `coming_soon` left as is. The gang_call sound is the placeholder fire sound.

**How David plays a kittiwake**
- There is an existing testing switch: `"unlock_all": false` at the top of `data/species.json`. Set it to `true` locally (do not commit it); the kittiwake card then becomes pickable on the gull select screen. Pick Kittiwake, play without the Bullet Time perk. Each direct snatch fills 0.15 x 1.4 of the meter (about 5 snatches), then press Q (or the touch power button). Sweep the aim over up to 3 foods, press Q again to go early, and the gull streaks through them.

## Review notes
<!-- Filled in by the reviewer. -->
