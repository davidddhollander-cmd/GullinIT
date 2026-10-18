# Label layout verification — 2026-10-18

Snapshot: `5f5a5d3` (`Snapshot before label overlap fix`).

## Layout decisions

Boards occupy logical y=84–95, with posts ending at y=134. This is deliberately higher than the preferred y=124–134: the existing 64 px adult frames occupy the requested conservative standing band starting at y=96, so a shoreline-height board cannot pass that clearance requirement. The board remains in the backdrop, its text stays at integer positions and font size 8, and the shoreline stripe stays unobstructed by lettering. Posts can pass behind scenery; only the readable board requires clearance.

Board width is measured text width plus 4 px. Placement starts at zone.from+28, searches right, then left, inside a 4 px zone/world inset. Collision uses the full scaled prop sprite rectangle and the decorative flag envelope. The only board moved more than 40 px in the six tested layouts was **level 3 PROMENADE: +74 px, x=532 instead of 458**.

YOU is shown throughout active training. Outside training it holds for four seconds after the intro is dismissed, then fades for 0.5 seconds. Its dark tag is pixel-aligned, stays below y=30 and inside the screen, and seeks a clear row above the gull around signs and HUD panels. A top-corner fallback keeps it readable when there is no clear row directly above the gull.

The training title/prompt gap is 2 px. The panel fits two prompt lines, remains left of the NEXT LEVEL footprint, and the contextual hint/FOOD rows are placed below the panel and sign boards.

Gameplay rules, tuning, rosters, level JSON and art assets were not changed. Overview camera adjustments exist only in screenshot fixtures. Legacy layout filenames are refreshed using the current authored maps (the level-1 pier/promenade aliases therefore show its east beach, not a nonexistent pier).

## Automated validation

- `./tools/validate.ps1`: 10,562 checks, 0 failures.
- `./tools/validate.ps1 -Capture`: 10,562 checks, 0 failures (log: `test-output/label-capture-validation.log`).
- Sign checks use actual instantiated prop texture sizes and actor frame sizes independently of placement collision helpers, across all six layouts.
- Checks cover zone/world containment, prop and adult-band clearance, training title/prompt separation, NEXT LEVEL footprint clearance, expired YOU visibility, marker screen bounds, and complete-board overview framing.

## Visual review

Opened and inspected all 35 requested images in six labeled contact sheets, with full-size spot checks of training lesson 3, the level-3 Promenade and the family view. All visible zone boards are readable and clear of actor, prop and HUD occlusion. YOU is absent in all layout overview captures (timer 4.5 s), readable in every training capture, and readable in the active family capture (timer 1 s). The screenshots are static checks; the fade is implemented by alpha interpolation and expiry is checked automatically.

| Capture in test-output/ | What was checked |
|---|---|
| game-family.png | FAMILY BAY board clear of mum/kiosk; early-run YOU tag above gull, below HUD; goal panel clear. |
| training-lesson-0.png | Title and two prompt lines separated; OPEN SAND/SNACKS readable; YOU clear of board; hint/FOOD below panel. |
| training-lesson-1.png | Landing lesson text spacing; target rings do not cover board text or YOU; both boards readable. |
| training-lesson-2.png | Dive/peck prompt spacing; customer remains below SNACKS; YOU separate from OPEN SAND. |
| training-lesson-3.png | Bag lesson title/prompt spacing; grounded YOU no longer overlaps OPEN SAND; customer below SNACKS. |
| training-lesson-4.png | Two-line final lesson fits; both boards and YOU readable; hint/FOOD clear. |
| training-touch.png | Training text, boards and YOU readable; touch controls stay at bottom and clear of those labels. |
| layout-1-open-sand.png | OPEN SAND and SNACKS clear of player/customer and goal HUD; YOU absent. |
| layout-1-snack-and-bag.png | SNACKS and SUNBATHERS clear of bin, parasol, customer and gull; YOU absent. |
| layout-1-family-bay.png | FAMILY BAY clear of mum, kiosk and palm; YOU absent. |
| layout-1-sunbathers.png | Legacy west view: OPEN SAND/SNACKS readable; YOU absent. |
| layout-1-families.png | SUNBATHERS and FAMILY BAY readable above parasol/mum; YOU absent. |
| layout-1-promenade.png | Legacy east view: FAMILY BAY clear of kiosk/palm and HUD; YOU absent. |
| layout-1-pier.png | Legacy east view: FAMILY BAY clear of kiosk/palm and HUD; YOU absent. |
| layout-2-sunbathers.png | FAMILY BAY board fully framed, clear of parasols and family; YOU absent. |
| layout-2-first-family.png | No board inside this reframed view; no clipped board fragment; FOOD/HUD clear; YOU absent. |
| layout-2-second-family.png | SNACK KIOSK board clear of hut/customer and goal panel; YOU absent. |
| layout-2-snack-kiosk.png | SNACK KIOSK clear of kiosk flag, hut and palm; YOU absent. |
| layout-2-families.png | No board inside this legacy family view; no clipped fragment; FOOD/HUD clear; YOU absent. |
| layout-2-promenade.png | SNACK KIOSK readable above hut/customer, left of kiosk; YOU absent. |
| layout-2-pier.png | Legacy east view: SNACK KIOSK clear of hut/kiosk/palm; YOU absent. |
| layout-3-quiet-beach.png | QUIET BEACH clear of bag/parasol; goal panel and gull clear; YOU absent. |
| layout-3-promenade-snacks.png | Shifted PROMENADE clear of lamp, kiosk, flags, hotdog stand and customers; YOU absent. |
| layout-3-dog-walk.png | No board inside reframed dog-walk view; no clipped fragment; HUD/FOOD clear; YOU absent. |
| layout-3-pier-dining.png | PIER DINING clear of diner and bench; goal panel clear; YOU absent. |
| layout-3-sunbathers.png | Legacy west view: QUIET BEACH clear of parasol and gull; YOU absent. |
| layout-3-families.png | Legacy middle view: PROMENADE clear of kiosk flag/customer and HUD; YOU absent. |
| layout-3-promenade.png | No board inside reframed legacy dog-walk view; HUD/FOOD clear; YOU absent. |
| layout-3-pier.png | PIER DINING fully framed at left, clear of diner/bench; YOU absent. |
| layout-4-promenade.png | PROMENADE clear of hotdog stand, kiosk, lamp and adults; YOU absent. |
| layout-4-pier.png | PIER DINING clear of diner, tower/flag and vendor; YOU absent. |
| layout-5-promenade.png | PROMENADE clear of reversed kiosk/hotdog arrangement and adults; YOU absent. |
| layout-5-pier.png | PIER DINING clear of parasol, diner, tower and vendors; YOU absent. |
| layout-6-promenade.png | PROMENADE readable against sunset, clear of stands/flags and FINAL GOAL; YOU absent. |
| layout-6-pier.png | PIER DINING readable at sunset, clear of parasol/tower/vendors and FINAL GOAL; YOU absent. |

## Files changed

- `scripts/beach.gd`: measured boards, shared zone/board layouts, prop/flag avoidance.
- `scripts/game.gd`: presentation-only elapsed time after intro dismissal.
- `scripts/overlay.gd`: marker visibility/fade/tag placement and training/hint layout.
- `tests/integration.gd`: independent geometry checks and refreshed capture fixtures.
- `docs/OPENING_LEVELS.md`: sign placement rule.
- `docs/LABEL_LAYOUT_REVIEW.md`: this verification record.
