# Shopper and lifeguard sources

New source sheets were generated with the built-in image-generation tool on 19 October 2026. Each complete prompt is saved beside its source:

- `shopper-pilot.png` / `shopper-pilot-prompt.txt`: identity-preserving style pilot, used for the production idle and as the identity reference for subsequent generation.
- `shopper-locomotion.png` / `shopper-locomotion-prompt.txt`: six walk and six chase poses.
- `shopper-actions.png` / `shopper-actions-prompt.txt`: six utility/reaction poses and six swat poses. Selected poses are mapped to production clips.
- `lifeguard-actions.png` / `lifeguard-actions-prompt.txt`: swat sequence. Its first run row was superseded by the more clearly phased run source below.
- `lifeguard-run.png` / `lifeguard-run-prompt.txt`: revised run cycle with distinct contact/down/passing silhouettes.

`shopper-pilot-0.png` through `shopper-pilot-2.png` are deterministic 128-pixel source-cell preparations, not independent generations. The shopper was checked beside the approved diner and mum before extending the animation sheets.

Lifeguard idle, lookout, patrol, whistle and pointing come from the pre-existing `assets/previews/lifeguard-pixel-review-v1.png` and `lifeguard-motion-review-v1.png`. These remain intact. The new sheets supply only missing movement/action coverage.

Production assets: `assets/sprites/shopper-diner-style.png` and `assets/sprites/lifeguard-diner-style.png`. Mapping/preparation details and validation are documented in `docs/SHOPPER_LIFEGUARD_PRODUCTION_V1.md`.
