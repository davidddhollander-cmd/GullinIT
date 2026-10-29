# Watergun teenager generation prompts

Built-in image generation was used. Existing shopper, lifeguard, and approved
adult-cast artwork were supplied as style and scale references.

## Identity

One consistent slim teenage boy, about ten percent shorter than the adult cast,
with warm medium skin, a backward coral baseball cap, short dark hair, teal
T-shirt, navy knee-length shorts, cream sneakers with coral accents, and a small
turquoise/orange toy water pistol. Four right-facing full-body identity poses:
idle, walk, run, and two-handed level aim. Transparent background; game-matched
pixel/cel clusters and deep navy outlines; no water stream or effects.

## Animation sheets

The identity pilot was reused as the strict character reference for:

- six-frame walk and run loops
- alert, warning, angry, windup, and six-frame free-hand swat
- six-frame surprise and fist-shake reactions
- four-frame sit-down and four-frame seated idle; stand-up reverses sit-down
- four-frame breathing/blinking idle
- three-frame aim/fire/recover sequences aimed high, level, and low

All sheets request complete right-facing figures, consistent scale and outfit,
transparent gutters, no food, no scenery, and no water projectile. Left-facing
animation is supplied through runtime mirroring.

## Water effects

Built-in image generation was also used for three effects-only source sheets,
using the game-scale teenager preview as the style reference. All prompts asked
for genuine transparency, hard binary alpha, chunky square pixels, no blur or
glow, and the water palette `#e8fbff` over `#6ec6f0`.

- `water-stream-source.png`: one row of four right-pointing pulse frames,
  progressing through pressure bead, stretched stream, trailing separation and
  compact recovery; no character, gun, scenery, text or frame borders.
- `water-muzzle-source.png`: one row of three tiny right-pointing spray-puff
  frames—pressure pop, widest short cone and separated bead; explicitly water,
  not fire or smoke, with no character or gun.
- `water-splash-source.png`: one row of five centred impact frames—contact,
  rising crown, widest burst, falling droplets and collapsing beads—with no
  puddle or ground-specific base so the same animation works in air and on sand.

`tools/prepare_watergun_vfx.py` splits the generated rows, thresholds alpha,
reduces with nearest-neighbour sampling and maps visible pixels to the approved
two-colour palette. The full generated sources above remain unchanged.
