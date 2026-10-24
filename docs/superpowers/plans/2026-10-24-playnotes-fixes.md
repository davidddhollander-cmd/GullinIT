# Playnotes fixes: pixel consistency, rival panel, dog, level variety

Source: `Gullin'it playnotes.txt` (2026-10-23). Four notes, in the user's priority order.

## What the code says

| Note | Cause found |
|---|---|
| Rival scores on the right sit too low and take too much space | `overlay.gd:88-105`: `rival_score_panel` is 56 px wide at `offset_top = 76` and pushes the right-side food/threat markers left (`overlay.gd:420`). |
| Every level has the same population and setup | L3–L6 share one prop layout (3 palms, 2 parasols, 3 bins, 2 lamps, kiosk, grill, 2 benches) and nearly the same cast (2 sunbathers, 3 shoppers, 1–2 diners). L1–L2 are just smaller versions of it. |
| The dog chases everywhere | `off_lead_dog.gd` keeps a `home` range for wandering only. A chase stops at `lose_radius` and never checks home, so the dog follows the gull across the whole 1280 px beach. (The dog only spawns in L4, so this assumes the note means "across the whole beach", not "in every level".) |
| Pixel art is inconsistent | **Mixed pixel densities.** The game renders 320x180 with `canvas_items` stretch at 4x. Props, sky, sea and sand are on the 1x grid (1 art pixel = 4 screen px). Characters are scaled down from big generated sheets: shoppers, vendors, sunbather, mum, lifeguard and dogs at 0.5; gulls at 0.375; the pier diner at 0.11; the toddler at 0.075; food at about 0.02 (huge `food_bites.png` regions); the cookie is an SVG. Each ends up with its own pixel size, often non-integer, so outlines shimmer and detail clashes with the chunky backdrop. Stall signs and vendors look high-res next to 1x clouds and sand. |

## Decision needed: one pixel grid

- **A. 2x grid (recommended).** One art pixel = 0.5 game px = 2 screen px. Most characters are already close to this, so the faces and poses you approved survive. Props, the backdrop and food move up to 2x detail.
- **B. 1x grid.** Everything as chunky as the clouds. Characters shrink to roughly 32 px of detail and lose their faces. That means redoing most character art, so it isn't recommended.

The tasks below assume **A**.

## Tasks

| # | Task | Who | Sonnet difficulty | Depends on |
|---|---|---|---|---|
| 018 | **Rival score panel.** Move it to the top-right corner, just under the top bar, at about 40 px wide (initial + score only, HUD 6 px face). Restore the right-side marker positions. | Sonnet | Easy: one file, layout only. One `-Capture` run at the end. | none |
| 019 | **Dog leash.** Add `leash` to the dog tuning (about 120 px past each `home` edge). Past the leash the dog gives up, barks, and trots home. The OUTRUN quest counts these give-ups. Add a test: the gull flies 600 px away and the dog stays within its leash. | Sonnet | Easy: data plus about 10 lines and a test. | none |
| 020 | **Pixel audit tool.** `tools/pixel_audit.gd` measures each sprite's effective art-pixel size (source run length × visual scale × 4) and writes `test-output/pixel-audit.md` plus a contact sheet of every sprite at true in-game size, flagging anything off the 2x grid. No art changes. | Sonnet | Easy to medium: offline tool, no gameplay risk. | none |
| 021 | **Snap characters to the 2x grid.** For each flagged character sheet, detect its native art grid, re-sample with nearest-neighbour so 1 art pixel = exactly 2 source px at `visual_scale` 0.5, and save it as `*-grid2.png`. Point the art JSON at the new file and keep the originals (AGENTS rule). Start with one character for approval, then do the rest. | Sonnet (tool), Codex reviews | Medium: mechanical, but needs visual judgement. Any sheet that looks bad goes to C2. | 020, decision A |
| 022 | **Backdrop on the 2x grid.** Redraw the code-drawn sky, clouds, sun, sea foam and sand speckle in `beach.gd` at half-pixel steps so they match the characters. Level elements only, no characters. | Sonnet | Medium: `beach.gd` has 18 draw calls. Capture each level. | decision A |
| 023 | **Level variety.** Give each level its own cast and layout from the table below. JSON only: counts, positions, props. | Sonnet | Easy to medium: data only, but quests and tests reference spawn counts. | none |
| C1 | **Props at 2x density.** Regenerate palms, bins, wheelie bin, parasols, chairs, bench, hut, lamp, rocks, castle, sign, kiosk and grill bodies at the 2x grid and the same footprint. | Codex | n/a (image generation) | 020 |
| C2 | **Food and outliers.** Replace the `food_bites.png` regions and `cookie.svg` with small native pixel food on the 2x grid, wire up crumbs v3 (generated but unused), and fix any character task 021 couldn't snap cleanly (likely the toddler and the pier diner). | Codex | n/a | 020, 021 |

**Sonnet can safely take 018, 019, 020 and 023 now, in parallel** (no shared files). 021 and 022 wait for the audit and your grid decision. Codex takes C1 once the audit lists the props.

## 023 level identity (proposal)

| Level | Feel | Cast change | Layout change |
|---|---|---|---|
| L1 Training Day | Quiet morning | Keep it sparse: 1 of each | Unchanged |
| L2 Family Picnic | Families | 3 families, 1 shopper, 1 sunbather | Picnic blankets cluster mid-beach, hut at the far end |
| L3 Boardwalk Bustle | Busy promenade | 4 shoppers, 2 diners, 0 families | Benches and lamps in a row along the promenade, stalls close together |
| L4 Dog Day Afternoon | Sunbathers' strip | 4 sunbathers, 1 family, 2 shoppers | Rocks and parasols, dog home in the open middle |
| L5 Three's a Crowd | Lunch rush | 2 diners and 3 shoppers queueing at a single grill | Grill centre stage, fewer covers, bins spread wide |
| L6 Sunset Showdown | Everyone's out | Full mix, seafood vendor | Widest spread, both stalls at the edges |

## Order

1. In parallel: 018, 019, 020, 023 (Sonnet).
2. Review the audit together and confirm grid A, then run C1 (Codex) alongside 021 and 022 (Sonnet).
3. C2 last, for whatever 021 couldn't snap.
