# 078 — Signature food in raids; gull card names lower

Status: merged
Author: Claude
Assignee: Sonnet
Depends on: none
Created: 2026-11-09

## Goal
A raided stall visibly gives what it sells, and gull names no longer cover the bird on the selection screen.

## Requirements
1. In `data/tuning.json` `shakedown`, add `"raid_signature": {"kiosk": "ice_cream", "hotdog_stand": "hotdog", "fish_chips_stand": "fried_fish"}` and `"raid_signature_count": 2`.
2. In `BeachShakedown.peck()`, the first `raid_signature_count` items from a stall are that stall's signature food, looked up by `stall.stall_type`. Later items still come at random from `raid_foods`, which may roll a signature too only if it is in that list. An unmapped stall type uses `raid_foods` for every item. `raid_cap` stays 4 and raid items still score flat.
3. On the gull selection cards (`scripts/menus.gd`, the `stage` control above the name label), raise the stage's minimum height from 14 to 22 and move the bird's y to suit, so the name sits below the whole bird and the bird is not clipped. The blurb row's expand-fill should absorb the height; make sure the stat rows, SPECIAL and status lines still fit inside the card. UI text stays on the 8 px grid and is not scaled.
4. Update the existing test "raided food is never large": the rule now applies to the `raid_foods` pool, since a signature hotdog or fish may be large. Add checks: the first two items from a kiosk are `ice_cream`, the first two from a hotdog stand are `hotdog`, and the third comes from `raid_foods`.

## Done when (acceptance)
- [ ] Every stall gives two signature items first, then pool items, 4 in all
- [ ] Gull names sit below the bird and all card rows fit
- [ ] `tools/validate.ps1` shows only the 2 standing failures

## Report
- Files: data/tuning.json (raid_signature, raid_signature_count), scripts/shakedown.gd (peck), scripts/menus.gd (stage min height 14 to 22, bird y 8 to 12), tests/shakedown_checks.gd.
- Tests: 17230 checks, 2 failures, both standing ("nobody teleports across the beach while running off", "data/demo.json enables the four-level demo"). New checks: kiosk first two ice_cream then pool item, each other stall type's first two are its signature then pool, a raided large food is picked up while gorging and swallowed (digestion stepped with simulated ticks).
- Large foods: no blocker. Pickup goes through can_collect_food; a large costs 4 stomach units and gorge capacity is base 4 + 4, so one fits when the stomach is empty. Two larges in a row need the first digested (and the 2 s post-large rest) before the second can be picked up; they stay on the sand meanwhile. Not changed.
- Card layout: not rendered or screenshotted; the existing shop_checks check that picker card content fits inside the card (with the perk row) still passes with the taller stage, and the blurb row's expand-fill absorbs the extra 8 px.
- Decision: "raided food is never large" now checks the raid_foods pool.
- Branch sonnet/078-signature-raids-card-names.

## Review notes
<!-- Filled in by the reviewer. -->
