# Older woman's walk and direction correction

20 October 2026. The direction flicker was reproduced independently of the sprite artwork. An actor outside her patrol radius reversed `facing` every simulation tick, even when already walking inward. She alternated left/right over the same small distance instead of returning to the patrol span. This can follow displacement by shopping, food retrieval or a chase and applies to the shared shopper movement.

`scripts/target.gd` now chooses the inward direction from the endpoint exceeded, with patrol bounds clipped to the world. It retains that heading until reaching the patrol area. Ordinary endpoint turns still work. The reproduction failed 12 checks before the change; the expanded regression now passes 26 checks covering all three shopper appearances, both sides, outward-facing recovery and world endpoints. Stall service passes its 94 checks after the movement correction.

The older woman's walk artwork is replaced with six complete ImageGen drawings based on the original shopper's six walk poses and her own existing idle identity. The flowers, silver bun, glasses, sandals and short, plump body are retained. More distinct sandal lift and lower-leg poses make movement visible below the dress. Exact prompts, reference roles, untouched outputs and the prior metadata are preserved in `assets/reference/sundress-walk-v2/`.

`tools/prepare_sundress_walk.gd` crops, scales and aligns these complete generated figures into `assets/sprites/shopper-sundress-walk-v2.png`. Only cells 1–6 and their food anchors change; idle, run, alerts, swats and unused cells stay pixel-identical to the earlier atlas. Walking retains six frames at 8 fps, the 40-pixel adult height and mirrored food attachment. The common shopper rebuild applies the replacements as well.

`tools/sundress_walk_preview.tscn` captures the original shopper, previous lady and new lady using identical walk frame indices. Enlarged lower-leg crops show the pose differences. The bottom row uses actual patrol ticks to demonstrate both directions returning from outside the patrol area without alternating facing. The 36 captured frames play at 24 fps, with each of the six walk poses held for three samples.

Completed validation: 13,447 rendered integration checks and 51 standalone shopper checks, zero failures. The 26 focused patrol checks and 94 standalone stall-service checks also passed. Full logs are in ignored `test-output/sundress-walk-validation.log`, and `assets/archive/previews/sundress-walk-v2.gif` contains the rendered comparison.
