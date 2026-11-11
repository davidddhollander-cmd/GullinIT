# 080 — VS round on Scrap Sands

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-11

## Goal
A playable VS round: the player against Gary on a new compact arena, Scrap Sands, won by out-scoring him in 75 seconds, with the winning margin posted to its own online board. Task 081 adds the menu; this task makes the round itself work and startable from code.

## Context
- Spec: `docs/superpowers/specs/2026-11-11-vs-mode-design.md` (read it first; it is the source of truth).
- Relevant files: `scripts/main.gd` (`start_level`, `_navigate`, `_finished`), `scripts/game.gd` (`setup`, `finish`, boss branches near `level.has("boss")`), `scripts/boss.gd` (`best_rival`), `scripts/overlay.gd` (rival meter), `scripts/result_board.gd` (title, score panel, `OnlineScores.submit` call sites), `scripts/autoload/online_scores.gd`, `scripts/autoload/config.gd`, `data/levels/level_03.json` and `level_04.json` (schema examples: world, spawns, props, off-lead dog).
- Before writing code, use the matching `godot-prompter:*` skills (`hud-system`, `godot-testing`, `gdscript-patterns`).
- Constraints: no code-drawn characters (the intro card may only import/scale existing gull sprites); GullPixel at 8 or 16 px only; tuning in `data/*.json`.

## Requirements
1. **`data/vs.json`** as in the spec (`round_time` 75, `board_prefix` "vs-", `opponents.gary` with his level 5 profile plus `"entry": "fly_in"`, `seed_scores`). Load it in `Config` as `Config.vs`.
2. **`data/arenas/scrap_sands.json`**, same schema as a level file, with `"id": "scrap_sands"`, `"name": "Scrap Sands"`. World 640 wide, `promenade_start` 240, `pier_start` 640. Contents: one sunbather (with parasol), one off-lead dog on the sand, ice-cream kiosk and hot-dog stand, three `kiosk_customer` shoppers (one at the kiosk, two at the hot-dog stand; if a stand cannot hold two, put the third at the kiosk and say so in the Report), three bins (one a wheelie bin), a palm, a bench, two lamps. Light steady wind, no gusts. No quests, stars, twist or rivals in the file. Use the spec's position table as the starting point and adjust to satisfy the existing spacing rules.
3. `Config` loads every file in `data/arenas/` into `Config.arenas` keyed by id. Arenas must not appear in `Config.levels` or the Arcade level select. If the level generator or any code assumes an integer id or `Config.levels[id-1]`, handle the arena path without changing Arcade behaviour.
4. **`main.gd`: `start_vs(arena_id, opponent_id)`** builds a deep copy of the arena with `rivals = [opponent profile]`, `time_limit = round_time`, `vs = {"opponent": opponent_id}`, and starts a `BeachGame` on it. Add `_navigate("vs_start", {"arena": ..., "opponent": ...})` calling it. The source arena dictionary is never modified.
5. **In a VS round `BeachGame`:**
   - shows a VS intro card for about two seconds: `<SPECIES NAME> VS GARY` over the arena name, with the two existing gull sprites;
   - shows the rival meter the boss level uses;
   - runs no quests, awards no stars or Feathers, writes no level progress, sets no flags, shows no trainer or lesson cards.
6. **Verdict:** `result.vs = true`, `result.rival_best`, `result.margin = points - rival_best`, `result.won = margin > 0` (a tie is a loss). Do not call `BeachBoss.verdict` (it sets the stage flag); reuse `best_rival`.
7. **Result sign:** title `YOU WIN!` / `OUT-EATEN!`, both scores and the margin. Buttons REMATCH (`vs_start` with the same payload) and a second button sending action `vs` (task 081 gives it a screen; until then route `vs` to the title).
8. **Leaderboard:** change `OnlineScores.submit` to take the board name; level call sites pass `level-<id>` so Arcade boards are unchanged. VS posts `margin` to `vs-<arena id>-<opponent id>` (`vs-scrap_sands-gary`) only on a win; on a loss it only fetches the board. Offline, the sign shows `seed_scores`.
9. **Analytics:** VS start and end events carry `mode: "vs"`, `arena`, `opponent`, and on end `won` and `margin`.
10. **Dev entry:** until 081 lands, a `--vs` command-line argument (or equivalent already-used dev hook) starts a Scrap Sands round against Gary so David can playtest.

## Out of scope
- The VS menu and title button (task 081).
- New art, new opponents, more arenas, ladder, multiplayer.
- Any change to Arcade levels, their boards or balance.

## Done when (acceptance)
- [ ] `--vs` starts a 75-second round on Scrap Sands with Gary flying in, the rival meter showing, and the intro card first
- [ ] Scrap Sands has two shops, three shoppers, one sunbather, three bins, one dog, and is absent from the Arcade level select
- [ ] Win, loss and tie give the right `won` and `margin`; the sign shows the right title and REMATCH works
- [ ] A finished VS round changes no stars, Feathers, quests, flags or level records
- [ ] Board name is `vs-scrap_sands-gary`; a loss posts nothing; Arcade still posts to `level-<id>`
- [ ] New `tests/vs_checks.gd` covers the above and is wired into `tests/integration.gd`; the arena passes the existing layout spacing checks
- [ ] `./tools/validate.ps1` passes with no new failures
- [ ] README/docs note the new `data/vs.json` and `data/arenas/` keys

## Report
**Files:** `data/vs.json`, `data/arenas/scrap_sands.json` (new); `scripts/autoload/config.gd` (loads `Config.vs`, `Config.arenas`); `scripts/main.gd` (`start_vs`, `vs_start`/`vs` actions, `--vs`, shared `_start_game`, R restarts a VS round); `scripts/game.gd` (`is_vs()`, intro length, Gary fly-in at round start, verdict, no `GameState.record`, analytics); `scripts/overlay.gd` (VS intro card, no pass-mark bar); `scripts/result_board.gd` (VS sign, REMATCH / VS MENU, board name); `scripts/autoload/online_scores.gd` (`submit(board, ...)`, `level_board`, `vs_board`); `scripts/score.gd` (`level.get("stars", [])`); `tests/vs_checks.gd` (new), `tests/integration.gd`; `README.md`.

**Tests:** see the final reply for exact numbers (baseline 17218 checks / 2 failures; after the change 17280 checks, same 2 failures, none new; 62 new checks).

**Decisions:**
- Two shoppers at the hot-dog stand work (level 5 already does it), so no fallback to the kiosk was needed: kiosk customer at 345, hot-dog customers at 540 and 590.
- Id handling: the arena id is the string `scrap_sands`. `int("scrap_sands")` is 0, so `int(level.id)` call sites degrade harmlessly (entry 0 is empty, level-id gates for levels 1 to 5 treat it as an authored opening level). The arena also sets `"authored": true` so the generator never rewrites it. The only `Config.levels[id-1]` use that could break is `BeachGame._reload`, which now returns early in a VS round. `Score.result` reads `level.get("stars", [])`. Side effect: the id-gated kiosk arrivals (`level.id >= 4`) do not run on Scrap Sands, so food comes only from the starting shoppers, scraps and bins; flag for playtest.
- Gary fly-in: triggered when the intro card ends (`dismiss_intro`), reusing `_start_fly_in`. `vs.json` carries `entry_text` because the fly-in popup needs it.
- VS boards: loss calls the same `submit` path with score 0 (the existing `score > 0` guard posts nothing, it only fetches). The sign shows the seed scores offline; YOU is merged in only after a win. Name entry still prompts on the first ranked sign.
- The touch-controls explainer card is skipped in VS (spec: no trainer cards). `GameState.options.tips` (e.g. bin hints) can still be written by `_learned`; no level, star, Feather or flag data is.
- `vs` action routes to the title until task 081.
- Result sign hides the star plank and the rules badge in VS; left panel shows YOU / GARY / WON BY or LOST BY.

**Not done / not verified:** no visual check (no screenshots; the intro card sprite offsets and the sign layout are unseen in the rendered game); Talo board `vs-scrap_sands-gary` must be created by David; no live online post tested (tests are offline).

## Review notes
<!-- Filled in by the reviewer. -->
