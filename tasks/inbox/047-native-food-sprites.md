# 047 — Food candidates drawn at real size

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 044
Created: 2026-10-27

## What David should see if this works
The seven snacks (crumbs, single chip, crisps box, ice cream, crisps bag, hot dog, fried fish) are tiny on screen: 2 to 7 pixels tall. Today they're shrunk from big illustrations (about 50× smaller), so their shapes come out as accidental blobs and their edges are soft. The candidates are drawn pixel by pixel at their actual size, in the same style as the half-eaten doughnut, sandwich and pizza already in the game. **The test:** can David tell which snack is which, on the sand and in the gull's beak, at real size? If the current blobs read better, keep them.

## Requirements
1. One candidate per food, drawn at twice its on-screen size (e.g. hot dog 16×8) and shown at 0.5, like the half-eaten food. Sizes from `data/foods.json`: crumbs 5×3 shown, chip 4×2, crisps box 6×6, ice cream 4×7, crisps bag 6×7, hot dog 8×4, fried fish 9×5.
2. Sharp edges (no semi-transparent pixels) and only colours from `tools/art_audit/palette.hex`.
3. Register them **only** in `data/art_lab.json`: one comparison showing all seven current foods against all seven candidates, with motions `on_sand` and `in_beak`.

## Done when (acceptance)
- [ ] Comparison visible in the Art Lab; captures at real size and 4× in the Report
- [ ] Status `done (awaiting David)`; David decides per food which version ships

## Report

## Review notes
