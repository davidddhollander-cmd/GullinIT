# Level layout generator — 10 October 2026

**18 October update:** Levels 1–3 now use distinct authored routes; see [OPENING_LEVELS.md](OPENING_LEVELS.md). The shared route and station contract below now apply only to levels 4–6.

Levels 4–6 follow the same readable route, with bounded variation in positions, stand order and scenery:

| Section | World position | Food opportunities |
| --- | --- | --- |
| Sunbathers | 0–330 | Two spaced sunbathers with finite picnic bags |
| Family bay | 330–640 | Two mums with one toddler each, plus beach bins |
| Promenade | 640–960 | Dog owner, ice-cream stand and hot-dog stand with customers |
| Pier dining | 960–1280 | Diner and seafood vendor |

Families keep their existing identities and siblings. Children start close to their own mum, and shopping trips find the generated ice-cream stand. Sunbathers remain on sand. Scenery is sparse around food stations so food and reactions remain visible.

## How to adjust it

`scripts/level_generator.gd` builds the runtime layout when `Config` loads the six level recipes. `data/level_layout.json` controls station centres, small position variation, family spacing, patrol distance and arrival clearance. Each recipe's `seed` selects its repeatable variation; retries use the same layout. Level timers, score thresholds, wind and rivals retain their authored values.

The current recipe contract is two sunbather stations, two family groups and two stand customers. Playable layouts cap each family at one toddler; sibling support remains available in the underlying behaviour and is tested with explicit fixtures. Children start 44 units from mum, and family centres are 150 units apart. Surplus authored sunbathers and toddlers are filtered before placement. Missing core food sources are added. Expanding the roster beyond these station counts requires extending the placement rules as well.

Normal patrols stay near home. New stand customers are only admitted when both current positions and reserved home positions leave enough room. A customer chasing the gull therefore does not accidentally open a slot for a second customer to occupy their return spot.

`tools/expand_beach.py` still maintains the supplied scenery atlas and older source defaults. Its source positions are superseded by the runtime generator; tune the new layout rules for playable placement.

## Verification

Latest rendered integration run after reducing population: **13,186 checks, zero failures**. Layout checks cover 20 seeds for each of six recipes (120 layouts), deterministic results, unmodified source recipes, population limits, section boundaries, family links, initial actor spacing and gaps between food opportunities. Initial actor centres remain at least 28 units apart, and adjacent food opportunities stay within 180 units in these checks. Arrival checks also exercise repeated spawn attempts on occupied levels. The lower check count reflects fewer character pairs in the spacing checks.

The resolved six layouts are saved in `test-output/generated-levels.json`. Views of all four sections on each level are saved as `test-output/layout-N-sunbathers.png`, `layout-N-families.png`, `layout-N-promenade.png` and `layout-N-pier.png` (N = 1–6).

These checks establish placement and functionality. Human playtesting is still needed to judge travel time, food depletion and the existing score targets with the new distribution.
