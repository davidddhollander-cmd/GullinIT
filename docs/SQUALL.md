# Level 6: Squall

Squall slots in before the boss; **Sunset Showdown is now level 7** (`data/levels/level_07.json`).

## Phases (`level.twist`, driven by `scripts/squall.gd`)
Initial tuning, all in `data/levels/level_06.json` and expected to change after playtests.

| Phase | Time | What happens |
| --- | --- | --- |
| Calm | 0–45 s | Light steady wind (0.3), no gusts. |
| Warning | 42 s | `SQUALL INCOMING!` toast and the gust sound, 3 s before the storm. |
| Squall | 45–85 s | Wind ramps to 0.85 over 3 s with gusts every ≤5 s and one direction flip in the second half. Rain overlay (`scripts/squall_rain.gd`) and a dark/wet `modulate` on the beach (full) and the actors (half). Everyone runs off the map; Gary and Chip (Chip's `after_snatch` hold is lifted) get a 0.95 ground-scraps taste to mob loose food. |
| Clearing | 85 s on | Wind eases back over 8 s, rain stops, people and the dog walk home. |

## Everyone leaves
`CrowdPanic` has a `SHELTER` state (run with the existing `panic_run` clips; `release_shelter` hands over to the normal walk-home `RETURN`). In the squall **every** beachgoer, on the sand or the promenade or the pier, runs to the nearest edge of the map (40 px past it) and stays gone until it clears. The off-lead dog runs off too (`OffLeadDog.flee_to`, back via `come_home`). While it rages `Spawner.arrivals_blocked` stops new customers and replacements walking on. People running from a squall or Gang Call ignore bag-retrieval raids (`stash_raids`) and keep their depth offset (`Spawner._family_offset`), so nobody is pulled back or snapped across the beach.

## Abandoned food
Everyone drops what they hold; sunbathers also drop up to `bag_items` from their bag and the picnic mum `picnic_items` from the basket. They are `stash_raids.items` entries with `source: "abandoned"` and a `snack` (so the player's pickup scores like any snatch, full combo).

## Quests
- `LOOT 3 PICNICS`: event `abandoned_looted`, fired when the player picks up abandoned food.
- `SNATCH UNDER AN UMBRELLA`: event `umbrella_snatch`, fired by any player snatch from an `umbrella`-twist target (pier diners hold fish under one, so they count; they leave once the squall starts, so snatch one during the calm).

Stars 600 / 950 / 1250 are an initial guess.

## Save migration
Save version 2 inserts Squall as level 6. `GameState.migrate_progress` moves an old version-1 level 6 record (the boss: best, stars, quests; `l6_random` becomes `l7_random`) to level 7 and drops key `6`. `GameState.unlocked` also opens any level that already has stars or a casual time, so a beaten boss stays open even though Squall is unplayed; level 6 itself opens from level 5 as before. `stage1_complete` and feathers are untouched. The demo `last_level` default is now 7; `data/demo.json` is unchanged.

## Rain, lightning and sound
`BeachRain` draws two layers of streaks (far: short/dim/slow, near: long/bright with a 1 px head) with per-drop speed, length and brightness, and half-scale `water_splash` crowns where near drops land on the sand. Lightning strikes when the squall begins and every `lightning_every` seconds after: a double flash, a 0.3 s bolt, and `thunder_1`/`thunder_2` alternating on the flash. `BeachSquall` fades the looping `rain_loop.ogg` with the squall's intensity on the SFX bus (Stream playback). The three sounds are Pixabay downloads (Pixabay Content License, not CC0): see `assets/audio/pixabay_SOURCES.txt`.

## Art requests (for Codex)
Squall reuses walk/run/`panic_run`/`look_up`. Nothing is faked in code. Wanted later: a hunched "running for cover" pose with a coat or towel over the head, and a held-umbrella sprite for adults caught in the rain (currently none, huts and benches).
