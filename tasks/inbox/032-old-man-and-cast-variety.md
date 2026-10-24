# 032 — Old man joins the cast (replacing, not adding); maximise variety per level

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-24

## Goal
Codex delivered the old man with a walking stick (art only: `scripts/old_man_art.gd`, `data/old_man_art.json`, `assets/sprites/retro-old-man-stick-32bit.png`; 22 clips including walk, idle, eat, alert, swat, kick, chase, run, pickup, carry, handover and stick_hit). David wants to:
- see him in play, **replacing** some of the older woman in the floral sundress (`shopper_sundress`), never adding to a level's head count;
- **maximise character variety in each level and minimise duplication**.

## Context
- Current casts: L2 sundress; L3 mullet, sundress, kiosk_customer, diner; L4 3 sunbathers (male_blue, male_red, female_blue), mullet, sundress; L5 mullet, sundress, 2 diners; L6 female_blue sunbather, mullet, sundress, **mullet again**, 2 diners.
- Appearances: shoppers via `ShopperArt.APPEARANCES` (`kiosk_customer`, `shopper_mullet`, `shopper_sundress`) in `scripts/shopper_art.gd`. Missing appearances are auto-assigned by cycling (`spawner.gd:76-77`), and replacements and station refills also create shoppers. Sunbathers have `male/female` × `red/blue`. Pier diners and families have their own art.
- Benches need a shopper whose art has seated clips (`ShopperArt.supports_bench`); the old man has no seated clips, so every bench level (3–6) must keep a bench-capable shopper, and the seat starter must not pick him.
- `data/levels/level_03.json` has a trailing comma after the last spawn (line 30). Godot accepts it, but other JSON tools don't; remove it.

## Requirements
1. Add `old_man` as a shopper appearance. He walks, idles, eats, reacts (alert/swat/chase) and carries using his own clips, at the normal adult scale (`DISPLAY_SCALE` 0.5). Use `stick_hit` as his swat when a gull is close. Code only selects and positions his generated frames; no drawn art (AGENTS.md).
2. **Replace, don't add:** in levels 3–6, swap a `shopper_sundress` for `old_man` wherever the swap still leaves a bench-capable shopper in the level. Head counts per level stay the same.
3. **Variety rule:** within a level, no two people share the same look (shopper appearance, or sunbather gender+colour) while an unused one exists. Apply it to authored spawns (fix L6's duplicate mullet) **and** to code-chosen appearances (auto-assign, replacements, station refills): pick the least-used look among those not currently on the beach.
4. Remove the trailing comma in `level_03.json`.

## Out of scope
- New art (bench clips for him, if wanted, would be a Codex task), café furniture, head-count changes.

## Done when (acceptance)
- [ ] Check: the old man appears in at least two levels and plays walk, eat and stick_hit
- [ ] Check: no level's starting cast repeats a look while an unused one exists; a 120 s sim with replacements keeps duplicates at the minimum possible
- [ ] Check: head counts per level unchanged vs main; every bench level still starts with a seated shopper
- [ ] One capture run at the end: 0 failures. A screenshot of the old man on the beach, path in the Report.

## Report

## Review notes
