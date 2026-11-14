# 086 — Kittiwake power: Lightning Strike (rough playtest build)

Status: inbox
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
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
