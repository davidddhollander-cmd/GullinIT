# Codex to-do — 21 October 2026

Status, 22 October: all three changes are implemented. Smaller signs were approved; vendor turn/preparation poses and order bubbles are complete; catchable red/blue crabs now use the supplied sheet. See `docs/CRABS.md` and `assets/previews/crab-cycle-v1.gif`. Crab checks: 73/73 pass. Full integration: 15,910 checks with only the previously reproduced level-6 rival escape-distance failure.

Three tasks, in this order. Follow `AGENTS.md` throughout: characters (vendors, crabs) must use image-generator or user-supplied artwork, never code-drawn bodies; check for a matching `godot-prompter:*` skill before implementing a system. After each task, run `tests/integration.tscn` headless and review the relevant preview captures.

User clarification: changes 1 and 2 MUST use ChatGPT image generation through the built-in `image_gen` tool. Change 3 uses the supplied `assets/sprites/crabs-transparent.png`; preserve the original. Crabs emerge from the sea or enter from the sides of the screen, can be pecked or dive-snatched, and award the highest catch score. Detailed implementation plan: `docs/godot-prompter/plans/2026-10-21-signs-vendor-poses-crabs.md`.

Known baseline failures, unrelated to these tasks: `practice result distinguishes run time from saved best time` (61.25 formats as "61.2"). The two "vendor preserves untouched generated full-body source" checks pass only when `assets/reference/` is present.

Recently changed by Claude (leave intact): `scripts/result_board.gd` (two-panel result sign, star plank, seeded leaderboard from `data/leaderboards.json`), `scripts/autoload/audio.gd` + `scripts/main.gd` (music: `Audio.play_music("title"|"beach")`, `stop_music()`, `duck_music()`; tracks in `assets/audio/music/`).

---

## 1. Redo the beach direction signs (snacks / promenade)

**Now:** `scripts/beach.gd` draws the zone signs in code — a plain cream rectangle on a brown post with the zone name ("SUNBATHERS", "FAMILY BAY", "PROMENADE", "THE PIER") — see `_draw()` around the `sign_layouts()` loop and the constants `SIGN_TOP = 84`, `SIGN_HEIGHT = 11`. The stall name boards ("HOT DOGS" / "ICE CREAM") come from `scripts/stand_sign.gd`.

**Goal:** new generated sprite signs with real shapes — wooden arrow/finger-post boards that point towards the snacks (food stalls) and the promenade/pier, so a player reads "food is this way" at a glance.

- Generate a small sign sprite set with the image generator, matching `docs/RETRO_ENVIRONMENT_STYLE.md` and the existing navy/cream/coral/teal palette: left-pointing arrow board, right-pointing arrow board, a two-finger post variant, and a post. Keep boards blank (no baked-in text); keep source sheets and prompts under `assets/reference/beach-signs-v1/` like the vendor sources.
- Keep labels as GullPixel bitmap text (8 px native grid) drawn over the board so they stay crisp; consider a small snack icon (hot dog / ice cream cone) on the snack sign.
- Point each sign in the right direction relative to its target: snack signs towards the nearest `kiosk`/`hotdog_stand` prop in the level, promenade/pier signs towards `promenade_start` / `pier_start`.
- Keep the existing placement logic (`sign_layouts()` / `_sign_hits_prop()`): signs must not overlap props, and the existing check "hint sits above every zone sign board" in `tests/demo_polish_checks.gd` must still pass. Update `Config.sprites` / `data/sprites.json` if the new art goes through the sprite table.
- Check levels 1–3 (authored) and 4–6 (generated) in-game at desktop and phone size; save before/after captures to `assets/previews/`.

## 2. Shopkeeper "turn away" animation (hot dog + ice-cream stands)

**Now:** both vendors are generated full-body characters, 8 frames each (idle, blink, preparation, placing food, withdrawal…) in `assets/sprites/vendor-hotdog-full-body-v2.png` and `vendor-ice-cream-full-body-v2.png` (128×128 frames, 0.5 scale, sole at 116). Metadata in `data/vendor_art.json`, frames built by `scripts/vendor_art.gd`, service phases in `scripts/stall_service.gd`, masking in `scripts/food_stall.gd`. Full docs: `docs/STALL_VENDORS.md`; sources/prompts in `assets/reference/stall-vendors-v2/`.

**Goal:** after an order is taken, the vendor visibly turns away (back/three-quarter-back view) to fetch/make the snack, then turns back to the counter to place it. This shows the snack being prepared before it appears.

- Generate new poses with the image generator from the existing v2 designs (same uniform, hair, cap, proportions): turn-away (3/4 back), back view working, turn-back. Add them to the existing sheets (or v3 sheets) via `tools/prepare_stall_vendors.gd` — it only crops/aligns/scales, never draws. Keep shoes on baseline 116 so the serving-window mask still works.
- Sequence: order → turn away → work (back view, short loop) → turn back → existing placing gesture → snack on shelf for the unchanged 0.85 s counter window → withdraw.
- Don't change counter-snatch rules or timing: the 0.85 s shelf window, COUNTER +50% bonus and theft/cancel behaviour stay as documented. Any new prep duration goes in `data/tuning.json`.
- The snack sprite must not be visible on the shelf or in hand while the vendor faces away.
- Update `docs/STALL_VENDORS.md`, regenerate `tools/stall_vendor_preview.tscn` captures, and extend `tests/stall_service_checks.tscn` to cover the new phases (including pause/freeze advancing correctly).

## 3. Integrate the crab visuals

**Artwork supplied:** `C:\Users\david\Documents\ChatGPT\GullinIt\assets\sprites\crabs-transparent.png` (file presence verified). Inspect and use this artwork; no new crab artwork is requested. Gameplay role is confirmed: moving, catchable, highest-value prey.

- Treat crabs as characters under `AGENTS.md`: generated or supplied sprites only, with sources and prompts kept under `assets/reference/crabs-v1/`.
- Inspect available frames for emergence, scuttling and capture; size them for the 320×180 view next to the ~40 px adult cast. Report any missing required poses before generating additional artwork.
- Support sea emergence and left/right screen-edge arrivals, with configurable spawning, movement and lifetime. Crabs are catchable by ordinary peck and timed dive-snatch; reuse existing collision, digestion and score rules, including capacity limits and once-only capture. Do not add attack or damage mechanics.
- Add them through `data/sprites.json`, food/score configuration and level JSON. Set crab base points above every other catchable item; verify ranking under equivalent combo/bonus conditions. Keep them clear of sign boards and props. Test both entry modes, both capture methods, duplicate/failed catches, pause/freeze and cleanup. Document in a new `docs/CRABS.md`.
