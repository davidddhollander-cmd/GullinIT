# 046 — Herring gull pilot: one candidate, judged in the Art Lab

Status: inbox
Author: Claude
Assignee: Codex
Depends on: 044
Created: 2026-10-27

## What David should see if this works
The player's herring gull **looks the same size and shape as now**, but its pixels line up with the people's pixels. Today the gull is drawn at an in-between scale, so (per the numbers) some of its pixels are dropped unevenly as it moves. That may show as feather edges, the eye or the beak flickering during flight and dives. If David can't see any difference between the two gulls in the lab, **this work stops here** and the other species are not touched.

Second, smaller change: today the gull has much less dark outline than the people (about half of its edge vs about 90%). The candidate adds a thin dark outline on the back, wing and tail, keeping the white belly. Make **two candidates**: (a) re-export only, and (b) re-export plus outline. David picks a, b or neither.

## Requirements
1. Herring gull only: `gull-herring-diner-style.png`, `gull-herring-carry-v1.png` with its `-upper-beak` overlay, and `gull-herring-screech-v1.png`. Other species are out of scope until David approves.
2. Rebuild from the untouched sources in `assets/reference/` at 192×192 frames (256 × 0.375 ÷ 0.5) so they draw at `visual_scale` 0.5 at the same on-screen size. Don't resample the current 256 px sheets.
3. Save as new files (`...-v2a.png`, `...-v2b.png`) and register them **only** in `data/art_lab.json` as two comparisons against the current herring gull, with motions `fly_across`, `dive` and `in_beak`. Do not edit `data/sprites.json` or `data/gull_art.json`.
4. Source-pixel values (frame size, `frame_beaks`, `frame_bounds`) scale by 0.75; screen-pixel values (`art_height`, `ground_beak_y`) stay the same.

## Done when (acceptance)
- [ ] Both candidates show in the Art Lab next to the current gull; Report includes lab captures at real size and 4×
- [ ] Status set to `done (awaiting David)`. **Nothing ships until David picks a, b or neither.** If he approves, a follow-up task swaps the gull in and repeats for the other species.

## Report

## Review notes
