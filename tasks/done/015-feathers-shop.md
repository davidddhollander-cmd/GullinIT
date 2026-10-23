# 015 — Feathers shop and perk equip (UI)

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-23

## Goal
A **SHOP** where players spend Feathers on gull species and perks, open once the Stage 1 boss (level 6) is beaten, and a perk slot on the gull picker so one owned perk can be equipped before a run.

## Context
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` → "Feathers shop" (species 6 Feathers; perks: Bigger stomach 3, Keen eye 3, Dive speed 4, Strong skull 4, Bullet time 5; buy once, equip 1).
- Already on main (use, don't rewrite): `data/perks.json` (`slots`, `perks{id:{name,blurb,price,…}}`), `Config.perks`; `GameState.feathers()`, `owns(id)`, `buy(id, price) -> bool`, `perk_owned(id)`, `equipped_perk()`, `equip_perk(id)`, `shop_open()` (true after `stage1_complete`), `gull_owned(id)` (now also true for bought species); `data/species.json` (`unlock_all`, prices).
- Menus: `scripts/menus.gd` (`title()`, `level_select()`, `gull_picker()` with SPEED/DIVE/TOUGH pips), `scripts/main.gd` `_navigate`. UI rules: GullPixel 8/16 px (HUD face 6 px allowed), 320x180, keyboard/controller/touch.
- A parallel task (016) implements what each perk does in play; don't touch gameplay scripts (`gull.gd`, `game.gd`, `digestion.gd`, `overlay.gd` HUD).

## Requirements
1. **Turn the species testing switch off:** `data/species.json` `"unlock_all": false`. Herring stays free; other gulls show `UNLOCK: 6 FEATHERS` in the picker until bought. (Testers can flip it back.)
2. **Title screen SHOP button:** always visible. Before `shop_open()` it is disabled and reads `SHOP - BEAT SUNSET SHOWDOWN` (or a short equivalent that fits). After, it opens the shop.
3. **Shop screen** `FEATHER SHOP` with the Feathers total; two sections, **GULLS** (priced species) and **PERKS** (all five). Each item: name, blurb, price; states `BUY  n` (affordable), greyed `n FEATHERS` (too poor), `OWNED`. Buying calls `GameState.buy`, updates the total, shows a short `BOUGHT!` confirmation. Must fit 320x180 (two compact columns or pages — your call, note it). BACK returns to the title.
4. **Perk slot on the gull picker:** a row under the cards: `PERK:  < BULLET TIME >` cycling through `NONE` and owned perks (left/right, click/tap). Selecting calls `GameState.equip_perk`. Hidden if no perk is owned.
5. **Result board / level select:** no change needed beyond the Feathers total already shown.

## Done when (acceptance)
- [ ] SHOP disabled before `stage1_complete`, enabled after (checks)
- [ ] Buying a species: Feathers drop by its price, it becomes pickable in the picker; buying with too few Feathers does nothing (checks)
- [ ] Buying a perk then equipping it in the picker persists through save/load (check)
- [ ] `owns`/`buy` never double-charge (check)
- [ ] Layout + font-grid checks on the shop and the picker perk row; `-Capture` screenshots of the shop (some owned, some too expensive) and the picker with a perk equipped, paths in the Report
- [ ] One `tools/validate.ps1 -Capture` run (two at most): **0 failures**

## Report
Files: `data/species.json` (unlock_all false), `scripts/menus.gd` (title SHOP button, `shop()`, `_shop_item`, `_perk_picker`, picker bottom row, bird stage 30->22 px so cards fit), `scripts/main.gd` (`shop`, `buy` actions), `tests/shop_checks.gd` (new), `tests/gull_picker_checks.gd` (unlock_all on for the open-picker part, off at the end), `tests/integration.gd` (one wiring line).
Tests: `tools/validate.ps1 -Capture` run twice: INTEGRATION 14827 checks, 0 failures (baseline 14577).
Screenshots: `test-output/shop.png` (Keen Eye + Kittiwake owned, rest too expensive, BOUGHT!), `test-output/gull-picker-perk.png` (BULLET TIME equipped, locked Great Black-back), `test-output/title.png`.
Decisions: shop is two columns (PERKS left, GULLS right with BACK below). Title row is OPTIONS / SHOP / QUIT; disabled caption is `SHOP - LVL 6`. Perk row shares a line with BACK as one button: click cycles forward, left/right keys cycle, NONE then owned perks; hidden if none owned. The `shop` action only opens when `shop_open()`. Picker card content overflowed before (2-line name + status), so the bird stage was shortened; a new check guards card fit.
Not done / notes: stderr shows one `grab_focus !is_inside_tree` engine error at exit with all checks passing; not traced (may predate this task). Not merged.
Branch: sonnet/015-feathers-shop.

## Review notes
