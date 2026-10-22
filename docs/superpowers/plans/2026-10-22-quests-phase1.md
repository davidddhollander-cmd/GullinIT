# Quests Phase 1 (demo levels 1–3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Each task below is also an inbox file in `tasks/inbox/` with an `Assignee`.

**Goal:** Levels 1–3 get mini-quests (2 fixed + random "Eat N <food>"), bonus points, Feathers, the L2 wind-intro twist and the L3 Gary intro, ready for the itch.io demo.

**Architecture:** A `BeachQuests` RefCounted (like `BeachScore`) is built from level JSON, fed named events by `BeachGame`, and adds bonus points through `score`. `GameState` stores completed quest ids per level and a Feathers wallet. Twists are level-JSON flags read by existing systems; no per-level code.

**Tech Stack:** Godot 4.7.2 GDScript, JSON data in `data/levels/`, integration tests in `tests/`.

**Spec:** `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`

## Global Constraints

- UI text uses GullPixel at 8 or 16 px only; Godot-drawn UI/scenery only — no code-drawn character bodies, faces or limbs (AGENTS.md).
- Tuning values (bonus points, counts, feather pay) live in `data/`, not code.
- Quest bonus points pay every run; each quest pays **1 Feather** the first time; the random slot pays 1 Feather once per level.
- Training Day: 2 fixed quests, no random slot, quests active only when `training_complete` was already true at level start.
- Existing saves (stars, best, casual_time, training_step) must load unchanged.
- Tests: `./tools/validate.ps1` must pass with no new failures; report the check count.

## Review Focus

- Old save without `quests`/`wallet` keys → loads, 0 Feathers, no crash (Task 1 test).
- Replaying a level after completing a quest → bonus points again, no second Feather (Task 1 test).
- Random slot rolls a food not present in the level → impossible; it only picks from the level's `random_foods` (Task 1 test).
- Quest completes in the final second / after the timer → counts if recorded before `finish()`, ignored after (Task 2 test).
- Casual (Practice) mode → quests still track and pay Feathers; bonus points added (Task 2 test).

---

### Task 1: Quest tracker, level data and Feathers save — Assignee: Claude Sonnet

**Files:**
- Create: `scripts/quests.gd` (`class_name BeachQuests extends RefCounted`)
- Modify: `scripts/autoload/game_state.gd` (wallet + quest records)
- Modify: `data/levels/level_01.json`, `level_02.json`, `level_03.json` (add quest data below)
- Create: `tests/quest_checks.gd`; wire into `tests/integration.gd` `run()` next to `score_rules_checks`

**Interfaces — produces:**
- `BeachQuests.setup(level: Dictionary, rng: RandomNumberGenerator) -> void` — builds `quests: Array[Dictionary]`, each `{id, text, event, filter, count, bonus, progress:int, done:bool}`.
- `BeachQuests.record(event: String, data: Dictionary = {}) -> Array[Dictionary]` — increments every not-done quest whose `event` matches and whose every `filter` key equals `data[key]`; returns quests completed by this call.
- `signal quest_completed(quest: Dictionary)`
- `BeachQuests.bonus_points() -> int` (sum of done quests' bonus)
- `GameState.complete_quest(level_id: int, quest_id: String) -> bool` — true and +1 Feather only on first completion; saves.
- `GameState.feathers() -> int`; save JSON gains top-level `"wallet": {"feathers": int}`; per-level entry gains `"quests": Array[String]`.

**Level data** (exact):
- `level_01.json`: `"quests_on_replay_only": true`, `"quests": [{"id":"l1_bin","text":"EMPTY THE BIN","event":"bin_emptied","filter":{},"count":1,"bonus":30},{"id":"l1_bite","text":"SNATCH A MID-AIR BITE","event":"mid_air_bite","filter":{},"count":1,"bonus":40}]`
- `level_02.json`: `"quests": [{"id":"l2_ice","text":"3 CLEAN ICE CREAMS","event":"swallowed","filter":{"food":"ice_cream","direct":true},"count":3,"bonus":50},{"id":"l2_cry","text":"MAKE A TODDLER CRY","event":"toddler_cried","filter":{},"count":1,"bonus":30}]`, `"random_quest": {"count":[3,5],"bonus":40}`, `"random_foods": ["ice_cream","crisps_bag","crisps_box","half_eaten_doughnut","half_eaten_sandwich"]`
- `level_03.json`: `"quests": [{"id":"l3_mug_gary","text":"MUG GARY","event":"swallowed","filter":{"mugged_from":"Gary"},"count":1,"bonus":50},{"id":"l3_crab","text":"EAT A CRAB","event":"swallowed","filter":{"food":"crab"},"count":1,"bonus":40}]`, `"random_quest": {"count":[3,5],"bonus":40}`, `"random_foods": ["hotdog","fried_fish","ice_cream","half_eaten_doughnut","half_eaten_pizza"]`

Random slot: id `l<level id>_random`, event `swallowed`, filter `{"food": <rolled id>}`, count rolled from the range, text `"EAT %d %s" % [n, Config.foods[food].name.to_upper()]`. Verify each `random_foods` entry actually appears in that level (spawn food or bin leftover); drop any that don't and note it in the Report.

- [ ] **Step 1: Write failing tests** in `tests/quest_checks.gd` (`static func run(check: Callable)`):
  - setup with level_02 → 3 quests; quest 3 id `l2_random`, its food in `random_foods`, count in 3..5.
  - setup with level_01 → 2 quests, no random.
  - `record("swallowed", {"food":"ice_cream","direct":true})` ×3 → `l2_ice` done, returned once on the 3rd call only; `{"food":"ice_cream","direct":false}` does not count.
  - `bonus_points()` == 50 after that.
  - `GameState.complete_quest(2,"l2_ice")` true then false; `feathers()` +1 total.
  - `GameState.load_progress()` on a save JSON without `wallet` → `feathers() == 0`, existing `progress` intact.
- [ ] **Step 2:** Run `./tools/validate.ps1` → new checks fail (missing class).
- [ ] **Step 3:** Implement `scripts/quests.gd`, GameState additions, level JSON.
- [ ] **Step 4:** Run `./tools/validate.ps1` → all pass.
- [ ] **Step 5:** Commit.

### Task 2: Wire game events and pay out — Assignee: Claude Sonnet

**Files:**
- Modify: `scripts/game.gd` (`setup`, `_swallowed`, `_mugging`, `_cry`, `finish`)
- Modify: `scripts/stash_raids.gd` (emit when a bin's `remaining` reaches 0)
- Test: extend `tests/quest_checks.gd` with an in-game section (`static func run_game(suite: Node, check: Callable)`), awaited from `integration.gd`

**Interfaces — consumes:** Task 1. **Produces:** `BeachGame.quests: BeachQuests`; `result.quests: Array[Dictionary]` (`{text, done}`), `result.feathers_earned: int`; `signal BeachStashRaids.bin_emptied(bin_type: String)`.

Events to record (only for the player gull, only while `running`):
- `swallowed` from `_swallowed`: `{"food": snack.id, "direct": not scrap and not mugged, "mugged_from": snack.get("mugged_from",""), "handover": snack.handover}`. In `_mugging`, add `"mugged_from": pilot.gull.rival_name` to the collected snack.
- `toddler_cried` from `_cry` when `source.kind == "toddler"`.
- `bin_emptied` from the new stash signal.
- `mid_air_bite` is recorded in Task 5; leave the quest unreachable until then.

On completion: `score.points += quest.bonus`, `effects.message(... "QUEST! +%d" ...)`, `Audio.play("snatch")`, and `GameState.complete_quest()` (count Feathers newly earned for the result). Level 1: create quests only when `GameState.entry(1).training_complete` was true before setup.

- [ ] **Step 1: Failing tests:** start level 2 via `main.start_level(2)`; call `game._swallowed({"id":"ice_cream"})` ×3 → `game.quests` `l2_ice` done, score raised by 50 plus snack points; `finish()` result has 3 quests and `feathers_earned == 1`; a second identical run → `feathers_earned == 0`, bonus still added; `_swallowed` after `finish()` does not change quests; casual start pays too; level 1 first-run (training incomplete) has `game.quests.quests.is_empty()`.
- [ ] **Step 2:** Run validate → fails.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run validate → passes.
- [ ] **Step 5:** Commit.

### Task 3: Quest UI — Assignee: Claude Sonnet

**Files:** Modify `scripts/overlay.gd` (in-run checklist), `scripts/menus.gd` (level card + Feathers total), `scripts/result_board.gd` (quest ticks, "+N FEATHERS"). Test: extend `tests/quest_checks.gd`.

- In-run: 3 rows, 8 px GullPixel, top-left below the existing HUD; done rows show a tick/colour change (`BeachUI.GOLD`). Hidden during training lessons.
- Level card caption gains a quest line `Q n/3` (n = saved completed ids for that level; L1 `n/2`). Level select header shows total Feathers.
- Result board lists each quest with done state and `+N FEATHERS` when > 0.
- Use `suite.layout()` and `suite.menu_font_grid()` checks so nothing overflows the 320×180 canvas.

- [ ] Step 1 failing tests (labels present, font grid, layout) → Step 2 run fails → Step 3 implement → Step 4 `./tools/validate.ps1 -Capture`, inspect `test-output/` screenshots → Step 5 commit.

### Task 4: L2 wind intro and L3 Gary intro — Assignee: Claude Sonnet

**Files:** `data/levels/level_02.json` (`"twist": {"id":"wind_intro"}`), `data/levels/level_03.json` (`"twist": {"id":"gary_intro"}`, Gary profile `"loose_only": true`), `scripts/beach.gd` or backdrop (wind flags), `scripts/game.gd` (tip/taunt), `scripts/rival_gull.gd` (loose-only targeting). Test: extend `tests/quest_checks.gd` or `tests/rival_ai_checks.gd`.

- Wind intro: two flag props on L2 drawn with Godot primitives (scenery only; pole + cloth flapping toward `wind.direction`, speed from `wind.strength`). First time per save the player is airborne in L2, show `"FLY INTO THE WIND = UPWIND +%d%%"` from `Config.tuning.score.upwind`; remember in `GameState.options.tips`.
- Gary intro: at `_release_rivals()` in a level with `gary_intro`, show a 2 s taunt line `"GARY: OI! THAT'S MY LUNCH!"` above Gary (existing rival sprite; text only) instead of the current message. With `loose_only`, `RivalPilot` only targets dropped/knocked/ground food, never food held by a person.

- [ ] Step 1 failing tests (flags exist only in L2; tip shown once across two runs; loose-only Gary never calls `take()` on a held target over N simulated seconds) → Step 2 fails → Step 3 implement → Step 4 validate (+ `-Capture` look at L2 flags) → Step 5 commit.

### Task 5: Mid-air bite (art first) — Assignees: Codex (5a), Claude Sonnet (5b)

**5a — Codex, asset:** add a "bite" pose to the kiosk/customer shopper sprites (`shopper_mullet`, `shopper_sundress`, see `data/shopper_art.json`, `docs/SHOPPER_VARIANTS_V1.md`): 2–3 frames raising the held snack to the mouth and back, same scale/palette, generated with the image generator. Register frames in the art JSON. No code changes beyond registration.

**5b — Sonnet, code:** customers enter a `biting` window (~0.6 s, every 4–7 s while holding food, values in `data/tuning.json`) playing the bite pose; a direct STRIKE snatch during the window records `mid_air_bite`. Test: force the window, snatch, quest `l1_bite` completes; snatch outside the window does not.

### Task 6 (parallel, Phase 2 prep): Off-lead dog sprites — Assignee: Codex

Generate the fast off-lead dog for Level 4 (Dog Day Afternoon): run, leap (for low-flight chases), catch/bite, idle, sniff. Match the existing `dog` sprite style in `data/sprites.json` / `docs/BEACHGOER_ART.md`; register in a new `data/dog_art.json`. Asset only.
