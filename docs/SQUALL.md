# Level 6: Squall

Squall slots in before the boss; **Sunset Showdown is now level 7** (`data/levels/level_07.json`).

## Phases (`level.twist`, driven by `scripts/squall.gd`)
Initial tuning, all in `data/levels/level_06.json` and expected to change after playtests.

| Phase | Time | What happens |
| --- | --- | --- |
| Calm | 0–45 s | Light steady wind (0.3), no gusts. |
| Warning | 42 s | `SQUALL INCOMING!` toast and the gust sound, 3 s before the storm. |
| Squall | 45–85 s | Wind ramps to 0.85 over 3 s with gusts every ≤5 s and one direction flip in the second half. Rain overlay (`scripts/squall_rain.gd`) and a dark/wet `modulate` on the beach (full) and the actors (half). Everyone runs for cover; Gary and Chip (Chip's `after_snatch` hold is lifted) get a 0.95 ground-scraps taste to mob loose food. |
| Clearing | 85 s on | Wind eases back over 8 s, rain stops, shelterers walk home. |

## Sheltering
`CrowdPanic` has a `SHELTER` state (run with the existing `panic_run` clips, then stand in the look-up pose; `release_shelter` hands over to the normal walk-home `RETURN`). Shelter spots are the promenade `beach_hut`, `umbrella` and `beach_bench` props, spread so nobody stacks. Sheltering **adults** swap their target twist to `umbrella` (restored on clearing), so `BeachCollisions` rejects dives steeper than `dive.umbrella_angle` (45°).

## Abandoned food
People caught on the sand (x < promenade) drop what they hold; sunbathers drop up to `bag_items` from their bag and the picnic mum `picnic_items` from the basket. They are `stash_raids.items` entries with `source: "abandoned"` and a `snack` (so the player's pickup scores like any snatch, full combo). Anyone already on the promenade keeps their food under cover, which is what the umbrella quest targets.

## Quests
- `LOOT 3 PICNICS`: event `abandoned_looted`, fired when the player picks up abandoned food.
- `SNATCH UNDER AN UMBRELLA`: event `umbrella_snatch`, fired by any player snatch from an `umbrella`-twist target (so the pier diner counts too).

Stars 600 / 950 / 1250 are an initial guess.

## Save migration
Save version 2 inserts Squall as level 6. `GameState.migrate_progress` moves an old version-1 level 6 record (the boss: best, stars, quests; `l6_random` becomes `l7_random`) to level 7 and drops key `6`. `GameState.unlocked` also opens any level that already has stars or a casual time, so a beaten boss stays open even though Squall is unplayed; level 6 itself opens from level 5 as before. `stage1_complete` and feathers are untouched. The demo `last_level` default is now 7; `data/demo.json` is unchanged.

## Art requests (for Codex)
Squall reuses walk/run/`panic_run`/`look_up`. Nothing is faked in code. Wanted later: a hunched "running for cover" pose with a coat or towel over the head, and a held-umbrella sprite for the sheltering adults (currently shown under the prop umbrellas, huts and benches).
