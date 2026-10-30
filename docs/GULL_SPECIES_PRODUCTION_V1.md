# Approved gulls — production pass, 19 October 2026

Implemented the selected Herring B / Chip Thief, Kittiwake C / Sea Dart, and Great black-backed C / Breakwater Bruiser. Three new transparent atlases replace the runtime player/rival painted art. Original images and the nine design alternatives remain available. Full generated sources and exact prompts live in `assets/reference/gull-production-v1/README.md`; the built-in image-generation tool was used.

| Species | Standing height | Flight speed multiplier | Default assignment |
| --- | --- | --- | --- |
| Herring gull | 16.5 game pixels | 1.0 | Player; Bev |
| Black-legged kittiwake | 12.75 game pixels | 1.2 | Chip |
| Great black-backed gull | 21 game pixels | 1.0 | Gary |

Speed is provisional game balance. The kittiwake multiplier affects ordinary horizontal flight; existing profile speed, diving physics, ground speed, food hit radii and wind rules still apply. Any species can be assigned to either role: set a level's optional `player_species` or a rival profile's `species` to `herring`, `kittiwake` or `great-black-backed`. No new selection menu is added. Defaults are herring for the player and great black-backed for an unspecified rival.

Each sheet has twenty isolated drawn poses: idle, seven walk poses, four wingbeat poses, glide, dive preparation, dive, pull-up, airborne snatch, ground peck, landing and stun. Walking is tied to distance, wings remain folded on the ground, wingbeat playback follows the existing stroke cadence, and horizontal dive/snatch poses rotate with the swoop. Contact, landing and pull-up receive distinct short pose holds; these transitions are not interpolated multi-frame sequences. Idle/glide are held poses; a separate blink is not part of this pass.

Natural species markings stay intact for player and rivals. Role/name badges identify opponents without recolouring plumage, and move above the current wing/dive silhouette. Title and result screens use the new art and its registered scale. All standing feet align to the existing sand/perch contact plane. Standing bill height now follows each species' visible bill rather than the older fixed-height reference; airborne dive bill anchors retain the existing interaction offset and rotation.

Review files:

- `assets/archive/previews/gull-species-production-v1.png` — species, movement and actual game sizes.
- `assets/archive/previews/gull-species-production-v1.gif` — walking and wingbeat preview.
- `assets/archive/previews/gull-herring-frames-v1.png`, `gull-kittiwake-frames-v1.png`, `gull-great-black-backed-frames-v1.png` — all drawn poses.
- `assets/archive/previews/gull-species-game-lineup-v1.png` — assigned player and rivals in the game (also captured in `test-output/`).

Preparation rejects incomplete actors, removes detached fragments and validates atlas margins. Integration checks cover clean isolation, approved sizes, feet/bill anchors, both movement directions, species in both player/rival roles, wingbeats, rotated dives, snatch, pull-up, landing, ground peck, stun, faster kittiwake flight, authored rival assignments and label clearance. The existing high toddler-snack fixture is positioned relative to the new bill height so it still tests food outside vertical reach. Run `tools/validate.ps1 -Capture` for the full gameplay suite, including rival simulations.

Final validation: **11,677 checks, zero failures**, including rendered game captures, three rival simulations, and result-screen size checks. Gameplay and preview error logs are empty. All sixty prepared poses have binary alpha, clean connected silhouettes and transparent gutters. The production and complete-pose boards were visually inspected. The results-screen reaction now scales relative to the registered gull size, so celebrating and returning to idle cannot shrink it to the old painted-art scale.

Visual sizing, 20 October 2026: all gull roles and species now render at 75% of their previous size (atlas scale 0.375). Sprite offsets preserve grounded sole alignment and airborne bill contact through dive rotation. Title/results use the same registered scale. Source atlases remain unchanged.

Validation for the visual sizing pass: 11,844 full integration checks and 302 focused gull/bin/reaction checks passed with zero failures. Sixteen rendered towel checks cover every appearance in rest, rise, away and settle poses; the review captures were visually inspected.
