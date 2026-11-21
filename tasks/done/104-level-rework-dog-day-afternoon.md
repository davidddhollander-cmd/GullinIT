# 104 Level rework: Gary in level 3, new level 5 "Dog Day Afternoon"

Assignee: sonnet
Status: done
Depends on: none

## Goal
Take the off-lead dogs out of level 3 and make Gary (great black-back) its twist. Add a new level 5 "Dog Day Afternoon", after Feeding Time, that is all about dogs, with two new breeds plus two small dogs. That makes 9 levels.

## Requirements

### Level order (9 levels)
1 Training Day · 2 Family Picnic · 3 Boardwalk Bustle · 4 Feeding Time · **5 Dog Day Afternoon (new)** · 6 Water Fight · 7 Three's a Crowd · 8 Thunderstorm · 9 Sunset Showdown.
- Renumber `data/levels/level_05..08.json` to `06..09` (update `id`, quest id prefixes `l5_`→`l6_` etc. only if ids are not referenced by saved data or analytics; otherwise keep them and note it in the Report).
- Find every hard-coded level count, last-level check or boss check (level 8 = boss/sunset) in scripts, tests and data (leaderboards.json, analytics, level select, unlocks), and make it work with 9.
- **Save remap:** existing saves keep their progress. Stars/unlocks for old levels 5–8 move to 6–9. New level 5 unlocks once level 4 is cleared; a save that already unlocked old level 5 also unlocks the new one. Do this as a one-time, versioned migration in the save code.
- `data/demo.json`: `last_level` 3 → 4.

### Level 3 – Boardwalk Bustle
- Remove both `off_lead_dog` spawns.
- Twist: `{"id": "gary_intro", "tip": {"id": "gary", "text": "GARY: THE BEACH BULLY"}}`. Check how twist ids are consumed and reuse the existing tip path. Add a twist id only if one is needed.
- Gary arrives from the start (drop `rivals_after_snatch` or set it to false) and is a bit tougher: speed 0.65 → 0.75, still `loose_only`.
- Quest: replace `OUTRUN A DOG` with `MUG GARY` (use the existing rival-mug event, filter name Gary, bonus 60). Keep EAT A CRAB. BUMP GARY can stay, or be swapped if it is now redundant with MUG GARY; record the choice.
- Re-check star thresholds still look sane. Note the reasoning; don't playtest-tune.

### New level 5 – Dog Day Afternoon (`data/levels/level_05.json`, authored)
- Dog walk beach: wide quiet beach, mostly sand, picnic/sunbather food, one or two `dog_owner`s, few stalls. Model it on the existing authored levels (level_04 for structure). Thumbnail: a golden-retriever frame.
- Twist tip along the lines of "DOGS OFF THE LEAD: MIND THE SHEPHERD!".
- Dogs: one golden retriever, one German shepherd and two small dogs, each with its own home range.
- Quests e.g. OUTRUN THE SHEPHERD (existing `dog_outrun` event, filtered by breed), EAT A CRAB, plus one more fitting goal.
- Wind/time/awareness between level 4 and Water Fight.

### Dog breeds
- Copy art into the repo (assets/sprites/), keep full source sheets:
  - `C:/Users/david/Documents/ChatGPT/GullinIt 2/output/imagegen/dog-breeds-v1/assets/sprites/golden-retriever-pixel-v1.png`
  - `C:/Users/david/Documents/ChatGPT/GullinIt 2/output/imagegen/dog-breeds-v1/assets/sprites/german-shepherd-pixel-v1.png`
  Both are 768x480, 6x5 frames, same row layout as `off-lead-dog-pixel-v1.png` (run, leap, catch, idle, sniff). Check the README/data in `dog-breeds-v1/` for anchors.
- Add `golden_retriever` and `german_shepherd` entries to `data/dog_art.json` next to `off_lead_dog`. Spawn entries choose a breed (e.g. `"breed": "german_shepherd"`). Missing breed = current `off_lead_dog`, so levels 6–9 keep their old dog unchanged.
- Behaviour per breed is set in data (tuning.json or dog_art.json, whichever already holds dog tuning), not with code branches per breed:
  - **Golden:** slower, playful, sniffs/idles more, lower chase commitment.
  - **Shepherd:** faster, higher leap, chases harder and longer.
  - **Small (×2):** old `off_lead_dog` sheet at a smaller draw scale. Yappy and quick: short fast dashes, low leap (only a threat when the gull flies very low), barks to alert nearby humans (reuse an existing alert/bark hook if there is one).
- Depth rule (AGENTS.md): dogs already go through the Spawner depth logic. Make sure the new breeds and the small scale do too. Small dogs' feet must still sit on the sand (adjust `sprite_offset_y` for scale).

## Done when
- Level 3 has no dogs; Gary tip shows; Gary is present from the start; MUG GARY quest works.
- Level select shows 9 levels in the order above; level 9 is still the boss/sunset level.
- Level 5 loads with golden, shepherd and 2 small dogs, each visibly different in speed and leap.
- An old save with stars on Water Fight shows them on level 6 after migration (add a test).
- Demo `last_level` is 4.
- Depth check per AGENTS.md rule 6 for one new breed and one small dog.
- `./tools/validate.ps1` passes with no new failures; report check counts.

## Report
Branch `sonnet/104-level-rework-dog-day-afternoon`.

**Tests:** baseline (before changes) `INTEGRATION: 17899 checks, 0 failures`; after `INTEGRATION: 19996 checks, 0 failures` (`tools/validate.ps1`, headless).

**Files changed**
- Levels: `level_05..08.json` renamed to `06..09` (ids updated); new authored `level_05.json` "Dog Day Afternoon"; `level_03.json` reworked; `demo.json` last_level 4; `leaderboards.json` shifted (new level 5 seeded from level 4 scaled x1.15).
- Code: `config.gd` (LEVEL_COUNT 9), `game_state.gd` (SAVE_VERSION 5 migration, `unlocked` flag), `online_scores.gd` (`board` field), `off_lead_dog.gd` (breed support), `game.gd` (breed spawn, bark alert, per-dog bump box, `dog_outrun` carries breed, Gary fly-in at run start), `level_generator.gd`, `main.gd` (music mapping), tuning/sprites/dog_art json, two new sprite sheets plus `.import` files.
- Tests: all renumbered; new checks in `off_lead_dog_checks.gd` (breeds, depth, bark alert, 4 dogs on level 5, no dogs on level 3), `squall_checks.gd` (v4 to v5 save migration, v1 chain), `quest_checks.gd` (MUG GARY).
- Tools previews: indices shifted.

**Decisions**
- Breeds live in `tuning.json` `off_lead_dog_breeds` (sprite, optional draw scale/offset, tuning overrides merged over `off_lead_dog`; `bark_alert_radius` is a generic key). No breed = terrier reads the live base block, so levels 7-9 are unchanged. Small dogs = breed `small_dog`, terrier sheet at scale 0.375 (offset -13.5 = -36 x scale).
- Quest ids kept (`l5_counter` etc.; saved data references them); only `lN_random` ids follow the level, migrated in the save step. Migration is versioned (v5): records for 5-8 move to 6-9, new level 5 opens when level 4 is cleared, or via `{"unlocked": true}` for saves that had Water Fight.
- Online leaderboards: levels carry `board` (old level number) so live Talo boards keep their scores; new level 5 uses `level-9`.
- Level 3: MUG GARY uses the `swallowed` + `mugged_from: Gary` pattern (same as MUG CHIP); BUMP GARY kept (different action). Gary speed 0.75, `rivals_after_snatch` dropped; to keep his fly-in debut, the run-start fly-in now applies to any released rival with `entry: fly_in` (was VS only). Star thresholds unchanged (dogs gone, Gary harder: about neutral).
- Level 5: width 1280, all sand, 2 dog_owners (relaxed the "dog owner never spawns" test to allow level 5), hotdog stand + kiosk, one palm (palms must be 70 px apart across all levels), quests OUTRUN THE SHEPHERD (60), EAT A CRAB (40), OUTRUN 3 DOGS (50); stars 230/440/620.
- `level_generator`: `id <= 7` stays on the authored-jitter branch (Three's a Crowd is not flagged authored).
- Music: levels 6-9 keep their old tracks; level 5 plays "beach".
- Level select already pages 3 per page, so 9 cards fit in 3 pages.

**Not done / notes**
- No rendered/visual playtest of level 5 or the new sprites in game (headless only); breed tuning numbers are first-pass.
- Docs under `docs/` still mention old level numbers.

