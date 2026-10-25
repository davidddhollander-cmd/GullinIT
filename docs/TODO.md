# TODO

Parked work that is agreed but not yet scheduled. When an item is ready, Opus turns it into a task in `tasks/inbox/`.

## Features

- **High score entry and online leaderboard** (parked 2026-10-25). Today the result sign shows made-up starter names from `data/leaderboards.json` plus "YOU" with this device's best; there is no name entry and nothing is shared between players. Options:
  1. Local name entry (3-8 letters at level end, saved in the player's browser). Small Sonnet task, no backend.
  2. Online leaderboard. itch.io has none for HTML games, so it needs a service (Talo, SilentWolf, LootLocker or a Supabase table) with a name filter, basic score sanity checks against faked browser scores, and a privacy note on the itch page.
  Decision needed: which option, and which service for 2.

## From player feedback (`docs/PLAYER_FEEDBACK.md`)

- Suggestion 2: ease the gull's speed after releasing flap so dives can be lined up (data-first: `flight.coast_drag`).
- Suggestion 3: an aim marker on the snack while a dive is possible. Needs a design decision.
- Suggestion 5: ask the player for a follow-up once suggestion 2 lands.

## Open decisions

- Pixel grid for art consistency (2x grid recommended; see `docs/superpowers/plans/2026-10-24-playnotes-fixes.md`).
- Dive feel (parked "discuss later" on 2026-10-24).
