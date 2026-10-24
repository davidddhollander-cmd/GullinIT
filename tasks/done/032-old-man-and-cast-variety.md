# 032 — Old man joins the cast (replacing, not adding); maximise variety per level

Status: done
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
Branch `sonnet/032-old-man-and-cast-variety`. Tests: `INTEGRATION: 13594 checks, 0 failures` (capture run, no SCRIPT ERROR). Screenshot: `test-output/old-man-on-beach.png` (worktree).

Shopper casts (before -> after; looks: K=kiosk_customer, M=mullet, S=sundress, O=old man):
- L2: S -> S (unchanged; task scope is L3-6)
- L3: M, S, K (+diner) -> M, O, K (+diner)
- L4: sunbathers male_blue/male_red/female_blue; M, S -> same sunbathers; M, O
- L5: M, S (+2 diners) -> M, O (+2 diners)
- L6: female_blue sunbather; M, S, M (+2 diners) -> same sunbather; M, O, S (+2 diners), duplicate mullet fixed
Head counts unchanged; every bench level keeps a bench-capable shopper (seated starter verified in test).

Changes: `old_man` added to `ShopperArt.APPEARANCES`, `data/sprites.json` entry (adult scale 0.5, art height 40, food anchors), `Config.frames("old_man")` returns `OldManArt.frames()`, `ShopperArt._update_old_man` (walk/idle/eat/alert/run, stick_hit for windup and swat, uses the drawn `_left` clips instead of mirroring). `BeachSpawner.create` now picks the least-used look (shoppers and sunbathers gender+colour) for any spawn without an authored appearance, covering auto-assign, replacements and station refills. Trailing comma removed from level_03.json. New `tests/cast_variety_checks.gd` (120 s-style sim per level); patrol check updated for left clips.

Decisions: the old man has no seated clips so `supports_bench` excludes him automatically. Windup uses stick_hit frames 0-1; swat maps the 0.28 s action time across all 6 stick_hit frames. Carry/handover/kick/pickup clips unused (no matching gameplay hook). Food hand anchor is an approximate shared point (11,-22), eat clip (11,-26); not tuned per frame. Ties in least-used look take list order (deterministic).

## Review notes
