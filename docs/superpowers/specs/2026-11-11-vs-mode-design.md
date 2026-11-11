# VS mode (demo slice) — design

Date: 2026-11-11. Status: draft for David's review.

## Goal

A quick-play VS mode in the Street Fighter mould: pick a beach, pick a rival gull, and out-score them in one short round. Each matchup has a global leaderboard. The demo ships one opponent (Gary) behind a VS sub-menu that already shows where Ladder and Multiplayer will go.

What David asked for: VS against a rival gull in a particular beach/setting, won on points, linked to a global leaderboard, small slice for the demo, multiplayer parked. A sub-menu with a mode list on the left (Match-up live; Ladder and Multiplayer as placeholders) and beach + opponent selection on the right.

Assumptions of mine (correct any of these):

- The leaderboard value is the winning margin (your points minus the rival's), posted only on a win.
- VS is open from the start; it needs no Arcade progress.
- The arena is two screens wide (640), so the gulls keep meeting.
- "Three beachgoers" are shoppers who buy from the two shops.

David's correction (11 Nov): arenas are not the arcade levels. VS gets its own purpose-built arena: two shops, three beachgoers, one sunbather, several bins, one dog.

## What is reused

- `RivalPilot` (`scripts/rival_gull.gd`): rivals already score, mug and get mugged.
- `BeachBoss.best_rival` and the level 6 rival meter on the HUD.
- `OnlineScores` (Talo) and the result sign's score panel and name entry.
- `Menus.gull_picker`, `BeachUI` buttons and wood panels.

## Flow

Title → **VS >** → gull picker → VS menu → FIGHT! → VS intro card → round → result sign → REMATCH or VS MENU.

- The title's disabled `VS / COOP - LATER` button becomes a live `VS  >` button (action `vs`).
- `main.gd` gains a `vs` flag beside `casual`. With it set, picking a gull opens the VS menu instead of the level select.

## VS menu (`Menus.vs_menu`)

320x180, GullPixel at 8 px, built from containers like the other menus.

```
+--------------------------------------------------------------+
| VS                                                           |
| +-------------+  +-----------------------------------------+ |
| | MATCH-UP  > |  | ARENA                                   | |
| | LADDER      |  | [SCRAP SANDS]                           | |
| |   LATER     |  |                                         | |
| | MULTIPLAYER |  | OPPONENT                                | |
| |   LATER     |  | [GARY / BLACK BACK]                     | |
| +-------------+  |                                         | |
|                  | [< BACK]                    [FIGHT!]    | |
|                  +-----------------------------------------+ |
+--------------------------------------------------------------+
```

- **Left panel (about 96 px):** three buttons. MATCH-UP is selected and is the only one enabled. LADDER and MULTIPLAYER are disabled with a LATER caption. They are named nodes so tests can find them.
- **Right panel:** an ARENA row of toggle cards (one per file in `data/arenas/`; Scrap Sands only), an OPPONENT row of toggle cards (one per entry in `opponents`; Gary only), then `< BACK` (to title) and `FIGHT!`.
- Below the rows is a `YOUR NAME` field for the leaderboard, prefilled with the saved name or the default `HERRING` (board names are capped at 8 characters, so "HERRING GULL" does not fit). FIGHT! saves it, so the result sign never has to ask.
- Scrap Sands and Gary are preselected, so FIGHT! works straight away.
- FIGHT! sends action `vs_start` with `{arena, opponent}`.

## Data: `data/vs.json`

```json
{
  "round_time": 75,
  "board_prefix": "vs-",
  "opponents": {
    "gary": {"name": "Gary", "blurb": "BLACK BACK", "species": "great-black-backed",
             "speed": 0.8, "accuracy_px": 16, "mug_chance": 0.3,
             "ground": {"scraps": 0.9, "bins": 0.9, "bags": 0.6, "catch": 0.7}}
  },
  "seed_scores": [{"name": "TIDES", "score": 180}, {"name": "SPRAT", "score": 120}, {"name": "BEAKY", "score": 60}]
}
```

Gary's profile is his level 5 one. `Config` loads the file like the other data files. `seed_scores` fill the result sign when offline, as `leaderboards.json` does for levels.

## The arena: Scrap Sands (`data/arenas/scrap_sands.json`)

Same schema as a level file, kept out of `data/levels/` so it never shows in the Arcade level select. The world width is already per-level data (Training Day is 800), so a compact arena needs no engine change.

- **World:** 640 wide (two screens). Sand from 0 to 240, promenade from 240 to 640. Light steady wind, no gusts.
- **Sand (left):** one sunbather with a picnic bag under a parasol, and one off-lead dog roaming the sand.
- **Promenade (right):** the ice-cream kiosk and the hot-dog stand, with three shoppers between them (one at the kiosk, two at the hot-dog stand; if a stand cannot seat two, the third uses the kiosk).
- **Bins:** three, at the sand edge, between the shops and at the far end; one is a wheelie bin.
- **Scenery:** a palm, a bench and two lamps, kept sparse so food stays readable.
- **Starts:** the player starts over the sand on the left; Gary flies in from the right (his existing `fly_in` entry).

First-pass positions (tune in playtest):

| x | What |
| --- | --- |
| 30 | palm |
| 90 | sunbather + parasol |
| 60–220 | off-lead dog's home range |
| 250 | bin |
| 300 / 345 | ice-cream kiosk / its customer |
| 400 | bench |
| 440 | wheelie bin |
| 500 / 540 | hot-dog stand / its customers |
| 600 | bin |

Other names considered: Squabble Bay, Pecking Order.

## The round

`main.gd` builds the VS level as a deep copy of the chosen arena (the source is never modified) with:

- `rivals` set to the one opponent profile;
- `time_limit` set to `round_time`;
- `vs: {"opponent": "gary"}` added.

In a VS round `BeachGame`:

- shows a VS intro card for about two seconds, `<YOUR GULL> VS GARY` over the arena name, using the existing gull sprites;
- shows the rival meter the boss level uses;
- runs no quests and awards no stars or Feathers;
- writes nothing to level progress and sets no stage flag.

## Verdict and result sign

- `result.vs = true`, `result.rival_best`, `result.margin = points - rival_best`, `result.won = margin > 0`. A tie is a loss, as on the boss level.
- Title: `YOU WIN!` or `OUT-EATEN!`. The sign shows both scores and the margin.
- Buttons: REMATCH (same arena and opponent) and VS MENU.

## Leaderboard

- One Talo board per arena and opponent: `vs-<arena id>-<opponent id>`, so `vs-scrap_sands-gary`.
- The value is the margin, posted only on a win. Talo keeps each player's best.
- `OnlineScores.submit` currently builds the board name from a level id; it takes the board name instead, and the level call sites pass `level-<id>`.
- **David creates the board in the Talo dashboard** (descending, unique entries), the same way as the level boards.
- Scores are client-submitted and can be faked, the same as the level boards today.

## Analytics

The existing level start and end events gain `mode: "vs"`, `opponent`, `won` and `margin`, so VS rounds can be separated from Arcade in PostHog.

## Tests

A new `tests/vs_checks.gd`, wired into `tests/integration.gd`:

- the VS menu has MATCH-UP enabled and LADDER and MULTIPLAYER disabled;
- Scrap Sands loads with two shops, three shoppers, one sunbather, three bins and one dog, and passes the existing layout spacing checks;
- the arena does not appear in the Arcade level select;
- the VS level has exactly one rival, the VS round time, and leaves the source arena untouched;
- verdict: win, loss and tie give the right `won` and `margin`;
- a finished VS round changes no stars, Feathers, quests or flags;
- the board name for Gary on Scrap Sands is `vs-scrap_sands-gary`, and a loss posts nothing.

## Out of scope

- Ladder and Multiplayer beyond their disabled buttons.
- More opponents, more arenas, new arena scenery art, portrait art for the intro card (a later Codex task).
- Ratings, win streaks, anti-cheat.

## Open for playtest

- Round length (75 s is a first guess) and arena width (640).
- Whether the food on Scrap Sands lasts the round, and whether the dog is a fair hazard for both gulls.
- A Black Back player against Gary: both shove, so the matchup may need its own tuning.
- Whether margin reads well as the board value, or raw score should replace it.

## Build order

Two Sonnet tasks, in sequence because both touch `main.gd`:

1. **VS round:** `data/vs.json`, the Scrap Sands arena file and its loading, the VS level copy, intro card, meter, verdict, result sign, board posting, analytics, tests.
2. **VS menu:** title button, `vs` flow through the gull picker, `Menus.vs_menu`, REMATCH and VS MENU, tests.
