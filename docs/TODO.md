# TODO

Parked work that is agreed but not yet scheduled. When an item is ready, Opus turns it into a task in `tasks/inbox/`.

## Features

- **High score entry and online leaderboard** (parked 2026-10-25). Today the result sign shows made-up starter names from `data/leaderboards.json` plus "YOU" with this device's best; there is no name entry and nothing is shared between players. Options:
  1. Local name entry (3-8 letters at level end, saved in the player's browser). Small Sonnet task, no backend.
  2. Online leaderboard. itch.io has none for HTML games, so it needs a service (Talo, SilentWolf, LootLocker or a Supabase table) with a name filter, basic score sanity checks against faked browser scores, and a privacy note on the itch page.
  Decision needed: which option, and which service for 2.

## Audio

- **Second sounds pass: people voices first** (medium priority, parked 2026-11-11). David reviewed everything except the gulls in the SFX Lab (`SFX Lab.bat`). The verdicts are in `data/sfx_approvals.json`: 16 approved, 46 rejected. Rejected sounds never play, so the game runs on the approved set for now.
  - **People voices** (most work): only 10 of 46 synthesised takes survived: `aah_kid`, `hey_kid`, `oi_kid`, `wah_kid`, `no_no` ×3, `huh_man`, `oi_woman`. The kid takes are the best, and men borrow them for now (task 085). The swat lines (`hah`, `gotcha`) and give-up lines (`aww`, `ugh`, `hmph`) have no approved take, so those reactions are silent. `whoa`, `eek`, `shoo`, `get_off` and `my_chips` have none either. Woman `aah` needs a higher pitch. Options: real recorded voice lines (Pixabay/CC0 shouts, which David downloads), or build every register from the kid synthesis recipe. Re-review in the lab, which flags regenerated files as "changed".
  - **UI and results:** `ui_confirm`, `ui_back`, `ui_error`, `score`, `level_end` and `level_end_fail` are rejected, so menu clicks, the combo tick and the result stings are silent. These need replacements.
  - **Other rejected:** `gust` (wind turns), `whistle` (the lifeguard), and the generated `dog_bark` (unused now that the real barks are approved).
  - **Menu waves:** approved, but David's note says "make it less sharp sounding" (gentle low-pass or high-shelf cut in `tools/make_menu_waves.py`).
  - **Gulls:** not reviewed yet, fine for now.

## From player feedback (`docs/PLAYER_FEEDBACK.md`)

- Suggestion 2: ease the gull's speed after releasing flap so dives can be lined up (data-first: `flight.coast_drag`).
- Suggestion 3: an aim marker on the snack while a dive is possible. Needs a design decision.
- Suggestion 5: ask the player for a follow-up once suggestion 2 lands.

## Open decisions

- Pixel grid for art consistency (2x grid recommended; see `docs/superpowers/plans/2026-10-24-playnotes-fixes.md`).
- Dive feel (parked "discuss later" on 2026-10-24).
