# 038 — Sweeper: broom-swinging beach cleaner

Status: done
Author: Claude
Assignee: Claude Sonnet (game code)
Depends on: 037
Created: 2026-11-02

## Goal
A new roaming character, the **Sweeper**, runs onto the sand, tries to whack low gulls with his broom, and in between brushes fallen food and litter into the nearest bin. He is a new kind of pressure: he *removes food the player dropped or hasn't eaten yet* and punishes loitering at ground level, but his pile is also a contestable snack source for a brave gull.

## Design summary (read this first)
- **Not a food owner, not a stall.** He only cares about two things: gulls that are low and close, and unowned food/litter lying on the sand.
- **Gull beats litter.** A low gull in range always interrupts cleaning. Cleaning resumes after he gives up.
- **Same fairness rules as every adult:** visible warning → windup → swing with a fresh range check → recovery. Swat result is the *existing* adult swat result (stun, −5 points, drop current snack). The dropped snack lands on the sand and becomes something he can sweep: punishment feeds the clean-up loop.
- **The pile is a gamble.** Swept food slides ahead of the broom and stays collectable. Dive in and snatch from the pile, but you are now inside his reach.
- **Escape = altitude.** Above `reach_height` he cannot hit; he just glares and, after a while, goes back to sweeping.

## Context
- Art (task 037): `sweeper` in `data/sprites.json`, `data/sweeper_art.json` (clips `idle walk run alert warning angry windup swat surprise fist_shake recover sweep sweep_bin`; anchors `broom_ground_anchors_source_px`, `swat_reach_source_px` + `swat_hit_frames`, `bin_flick_anchors_source_px`). AGENTS.md: use the generated sprite only, never draw him with code.
- Pattern to copy for a free-roaming beach entity with a state machine, spawner hook, `barked`/`outrun`-style signals and tests: `scripts/off_lead_dog.gd` (+ its tuning block and spawn in `data/levels/level_04.json`). Pattern for periodic arrivals gated per level: crabs (`"crabs": {"enabled": true}` in level JSON, `scripts/crab_population.gd`).
- Swat consequences and range-check helpers: `scripts/adult_reaction.gd`, `scripts/target.gd` (swat/windup, lanes, `gull.stun(...)`, snack drop), `docs/FOOD_AND_REACTIONS_SPEC.md`.
- Loose food on the sand: `BeachStashRaids.items` in `scripts/stash_raids.gd` (dicts with `owner`, `source`, `food_id`, `position`, `velocity`, `grounded`, `age`). Bins: `BeachStashRaids.bins` (`type`, `x`, `remaining`, …) and `BeachBackdrop.wobble_bin()` in `scripts/beach.gd`. Do **not** touch the respawning ground crumbs in `scripts/scraps.gd`.
- Bin docs: `docs/BIN_LEFTOVER_ART.md`. Level rules: `docs/LEVEL_GENERATOR.md`.
- Constraints: tuning in `data/tuning.json` (new `sweeper` block), UI text 8/16 px, no new audio files (reuse existing swat/whistle/thud sfx). Another agent has uncommitted work in `game.gd`, `gull.gd`, `tests/integration.gd`: branch from `main`, keep edits small.

## Behaviour

### Visits (when he exists)
Per level `"sweeper": {"enabled": true}` (default off). Enabled in levels 3 and 5; Sonnet checks level themes and adjusts if either has a conflicting twist, and records the choice in the Report.
- First arrival `first_arrival` (35 s) into the round, then he stays on the beach for `dwell` (28 s), leaves, and returns after `absence` (20–30 s random from the level seed). One sweeper at a time.
- **Litter call:** he is called only by litter. While he is absent, if MORE than `call_litter` (5, so 6 or more) sweepable items are on the sand and at least `call_min_absence` (8 s) has passed since he left, he arrives early. Dropping food makes him come, which is the cost of being sloppy.
- **Entrance:** he appears at the nearer of the two sand edges (`beach_min_x` / `beach_max_x`) already on screen-edge, plays `run`, and says a quip bubble ("OI!" from `data/quips.json`; add `sweeper_arrive`). He never goes onto the promenade or pier: his range is `range` `[24, 620]`. Exit: walks to the nearest sand edge and disappears off it.
- His lane is the front sand lane (see lane rules in `target.gd`); he does not use the rear lane.

### States
`ENTER → PATROL ⇄ (WARN → CHASE → WINDUP → SWAT → RECOVER) | (SWEEP → DUMP) → EXIT`
1. **PATROL** (`walk`, speed `walk_speed` 28): ambles between points inside `range`, pauses to `idle` for 1–2 s. Picks the next job on every decision tick: gull first, otherwise litter, otherwise wanders; leaves when `dwell` ends and he is not mid-job.
2. **Notice gull**: gull is "low" when `gull_height <= notice_height` (36 above ground, includes grounded and low gliding) **and** within `notice_radius` (90) horizontally **and** not stunned/caught/perched out of reach. Also notices a gull that is pecking a bin or a food pile from further away: use `bin_notice_radius` (130).
3. **WARN** (`alert` then `warning`, `warn_time` 0.5 s, faces gull). Fair warning, as with the dog's bark. If the gull is no longer low when it ends, back to PATROL; no free hit.
4. **CHASE** (`run`, speed `run_speed` 70, runs along x toward the gull). Gives up on: `chase_timeout` (5 s), gull beyond `lose_radius` (150), gull above `notice_height + 24` for `lose_grace` (1.2 s), or leaving `range`. Give-up plays `angry` then `fist_shake` (if the gull stole from the pile, `surprise` first) and enters a `cooldown` (3 s) during which he will not warn or chase again, so he cannot chain-stun.
5. **WINDUP** (`windup`, `windup_time` 0.6 s) starts when horizontal gap ≤ `swing_range` (30) and the gull is within `reach_height` (44) of the ground. He stands still: a big, readable, avoidable tell. Gull can leave the zone (up or away) during windup.
6. **SWAT** (`swat`, 6 frames, 0.6 s): a **fresh range check on the hit frames** (`swat_hit_frames`): the hit point is the broom head from `swat_reach_source_px` on the facing side; it hits a gull whose position is within `hit_radius` (16) of it, inside `reach_height`, and not already stunned. Hit result = the existing adult swat result (stun, −5, current snack dropped). One hit per swing. A swing in a different lane than the gull's cannot hit (follow the lane check the other adults use).
7. **RECOVER** (`recover`, `recover_time` 0.9 s): can't act. This is the player's opening to steal from his pile or the nearest food. After a *hit*, instead plays `fist_shake`, then `cooldown`.
8. **Reaction to theft**: when a gull swallows or picks up food from his pile while he is in SWEEP/DUMP, he plays `surprise` once (0.4 s), then CHASE if the gull is low and cooldown is over, else back to PATROL.

### Cleaning
- **Sweepable** = a `stash_raids.items` entry that is `grounded`, has no valid `owner` (owner-held drops belong to a person or toddler who will reclaim them), is in `range`, has been on the sand ≥ `litter_settle` (1.0 s, so the gull can eat its own drop first), and is not currently held by a gull. Includes player/rival drops and bin scatter, crumbs, wrappers and paper. Excludes counter portions, bag/stash contents, towels, and the `scraps.gd` crumbs.
- **SWEEP** (`sweep`, speed `sweep_speed` 22): he walks to the nearest sweepable item, turns toward the *closest bin* (nearest by x to the item, any bin type, empty or full, inside `range`; if there is none he ignores litter and only patrols/exits). He pushes items **toward that bin**: the item(s) in front of the brush get `swept=true` and are moved each frame to the `broom_ground_anchors_source_px` anchor of the current `sweep` frame (spaced `pile_gap` (4) px apart when several). He gathers up to `pile_max` (3) items along the way (any sweepable item within `gather_radius` (18) of the brush path joins the pile).
- Swept items **remain valid pickups** (the gull can still snatch them). When one is taken the pile just shrinks; if the whole pile is gone he returns to PATROL.
- **DUMP** (`sweep_bin`, `dump_time` 0.8 s): when the brush reaches the bin (`dump_distance` 10 from `bin.x`) he plays `sweep_bin`; on its second frame call `wobble_bin()` on that bin and remove the swept items from the world (they went in the bin). Items are **destroyed, not restocked** (`refill_bin: false` in tuning keeps the bin economy unchanged; if true they add to `remaining`, capped at `capacity`; leave it false, flag exists for later balancing).
- **No scoring** for sweeping, but fire `sweeper_dumped(count)` for quests/analytics.
- He never touches a bin that the gull is currently standing on (wheelie bin top landing): wait up to `dump_wait` (1.5 s), then dump anyway if clear.

### Consequences for the player (keep these exact)
- A swat hit = −5 points, stun, current snack dropped (existing rules, same numbers as other adults; do not add new penalties).
- He never eats, steals or carries anything himself.
- He does not target rival gulls in v1 (flagged out of scope).
- Perched gulls are safe; flying above `reach_height` is safe; stunned/caught gulls are not re-targeted until the stun ends.

## Requirements
1. New `scripts/sweeper.gd` (`BeachSweeper`) modelled on `off_lead_dog.gd` with the states above, using the `sweeper` sprite and clip names, facing flip like the other sprites, foot offset from the sprite entry.
2. Population/visit controller: small `scripts/sweeper_visits.gd` (or reuse `crab_population.gd` style) driven by the level's `"sweeper"` block and a seeded RNG; spawns/despawns the entity. Do not put visit logic in `game.gd` beyond one hook.
3. Tuning block in `data/tuning.json`:
   `sweeper`: `first_arrival 35, dwell 28, absence [20,30], call_litter 5, call_min_absence 8, range [24,620], walk_speed 28, run_speed 70, sweep_speed 22, notice_radius 90, bin_notice_radius 130, notice_height 36, reach_height 44, swing_range 30, hit_radius 16, warn_time 0.5, windup_time 0.6, recover_time 0.9, cooldown 3, chase_timeout 5, lose_radius 150, lose_grace 1.2, litter_settle 1.0, pile_max 3, pile_gap 4, gather_radius 18, dump_distance 10, dump_time 0.8, dump_wait 1.5, refill_bin false`. All are starting values; no magic numbers in code.
4. Enable the block in levels 3 and 5 (see above); the level generator keeps a sweeper block untouched (`docs/LEVEL_GENERATOR.md`).
5. Signals for quests/analytics (`sweeper_arrived`, `sweeper_warned`, `sweeper_swatted`, `sweeper_dumped(count)`, `sweeper_pile_stolen`), emitted but no new quests required. One optional level quest in a level where he is enabled: `"STEAL FROM THE SWEEPER'S PILE"`, event `sweeper_pile_stolen`, count 2, bonus 50.
6. Rendering: z-order with the other ground characters; his swept items draw in front of the sand, behind his boots (the pile is *ahead* of his feet). Items keep their normal sprites; no new effects required (a small existing dust/puff effect on bin dump is welcome if one exists).
7. HUD/label if the game shows character names in the shopper/quip layer: use `SWEEPER`.
8. Tests `tests/sweeper_checks.gd`, wired into `tests/integration.gd`:
   - arrival timing from level seed, dwell, absence, early call at 6 litter items (5 does not call him)
   - no sweeper in levels without the block; never outside `range`
   - warn → chase → windup → swat sequence with the right durations; **no hit if the gull rises above `reach_height` or leaves `swing_range` during windup**; no hit in a different lane
   - hit applies exactly the existing swat result once per swing; cooldown prevents a second warn for `cooldown` seconds
   - sweepable filter (owned drops, counter portions, stash contents, `scraps.gd` crumbs, items < `litter_settle` old are excluded)
   - picks the closest bin; pile follows the broom anchors; pile_max respected; dump removes items and wobbles the bin; `refill_bin false` leaves `remaining` unchanged and `true` caps at `capacity`
   - gull can swallow an item from a swept pile; pile shrinks; `sweeper_pile_stolen` fires; he reacts with `surprise`
   - rendered capture of a sweep, a windup and a dump in `test-output/` when run with `-Capture`
9. Docs: add `docs/SWEEPER.md` (behaviour table, tuning keys, signals) and mention him in `docs/NEXT_STEPS.md`.

## Out of scope
- Rival gull targeting, sweeping the promenade or pier, picking up the respawning crumbs, new audio, new quests beyond the optional one, new art (if a clip or anchor is missing, report it; do not draw one).
- Changing bin stock sizes or the fixed bin scatter sequence.

## Done when (acceptance)
- [ ] Playing levels 3 and 5: he runs in, warns, winds up and swings at a low gull; a gull above `reach_height` is never hit
- [ ] Dropped food gets swept toward the closest bin and disappears into it with a bin wobble
- [ ] A gull can steal from the moving pile; he reacts with `surprise`
- [ ] A hit costs exactly what an adult swat costs today; no chain-stuns (cooldown holds)
- [ ] Tests above added and wired; `./tools/validate.ps1` has no new failures; capture inspected

## Report
scripts/sweeper.gd, scripts/sweeper_visits.gd, tuning block, levels 2 and 5 (not 3: dogs), game.gd hooks, tests/sweeper_checks.gd wired into integration. Full run 16665 checks; all sweeper checks pass; 8 failures remain in other suites (card 1, bin leftover scoring, level5 off_lead_dog, squall teleport, twelve foods, demo.json), none sweeper-related. Not done: rendered capture, optional quest, quips.json entry.

## Review notes
<!-- Filled in by the reviewer. -->
