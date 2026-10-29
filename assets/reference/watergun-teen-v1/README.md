# Watergun teenager v1

Generated full-body character sources for a teenage beach troublemaker. The
source identity is locked across idle, locomotion, reactions, seated movement,
swatting, and three water-pistol aim heights. No eating animation is included.

Runtime contract:

- 128 x 128 frames, eight columns, 62 populated frames
- right-facing source art; mirror for left-facing movement and shooting
- visual scale 0.5, matching the existing shopper and lifeguard
- hard alpha, nearest-neighbour pixel preparation
- separate 3 x 3 shooting sheet ordered high / level / low by row and
  aim / fire / recover by column

Files:

- `assets/sprites/watergun-teen-v1/watergun-teen-v1.png`
- `assets/sprites/watergun-teen-v1/watergun-teen-shooting-v1.png`
- `data/watergun_teen_art.json`
- `tools/prepare_watergun_teen_v1.py`

The preparation script only crops, aligns, scales, hardens alpha, and animates
the complete generated figures. It does not draw or reconstruct character
anatomy. Every full generated source is preserved in this directory.
