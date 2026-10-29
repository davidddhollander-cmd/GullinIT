# Background v2 generation prompts

Generated with ChatGPT's built-in image generator. Complete generated sources, including the superseded first sea source, are preserved unchanged beside this file. Runtime assets are prepared by `tools/prepare_background_v2.py`.

## Sky and clouds

Use case: stylized-concept. Asset type: production sky-and-cloud background plate for a 2D side-scrolling game. Create a new wide daytime sky background for *Gullin' It*, a cheerful retro seaside arcade game. Use a pale turquoise coastal sky with five or six small cream-white fair-weather clouds. Keep the clouds sparse, simple, and mostly toward the left half, lower-left, and far-right edge. Reserve a large completely clear open patch in the upper-right quadrant for a separate sun sprite. Use polished 1990s 32-bit arcade pixel art with crisp hard stepped contours, broad flat color clusters, and a limited palette. Keep generous open flying space through the center. Keep every cloud fully inside the canvas and both side edges clear. Use one pale turquoise-blue sky color, cream-white cloud tops, and one pale cool-blue underside shade. Opaque rectangle. No gradient, glow, texture, noise, antialiasing, dithering, sun, moon, sea, horizon, land, birds, buildings, text, UI, border, or watermark.

## Sun

Use case: stylized-concept. Asset type: isolated transparent sun sprite for a 2D side-scrolling game. Use the generated sky only as a style reference. Create exactly one compact circular daytime sun with a symmetrical stepped pixel circumference. Use a pale warm cream-gold main disk, one small lighter cream highlight cluster, and one restrained warm-gold lower-right shade cluster. Match the sky's polished 1990s arcade pixel art, hard steps, broad flat clusters, and simple silhouette. Center the complete sun on a square canvas with generous transparent padding. Genuine transparent alpha outside the sun. No outline, rays, face, sky, clouds, sea, text, halo, glow, lens flare, gradient, bevel, blur, antialiasing, dithering, noise, border, checkerboard, shadow, watermark, or duplicates.

## Sea source v2

Use case: stylized-concept. Asset type: new source plate for a layered animated sea background in a 2D side-scrolling game. Use the composed background only as a style reference; do not reproduce its dark horizon line or dense uniform ripple pattern. Create one calm, extremely wide, water-only green-blue coastal texture for *Gullin' It*. At the top, use pale desaturated aqua-green far water close in value to the sky. Transition downward through two broad low-contrast turquoise-green bands into darker teal-green lower water. Include a few subtle, thin, irregular pale-aqua shallow-water patches in the upper far-water zone, with generous gaps. Use sparse short 1-2-pixel-equivalent ripple dashes and connected wave chunks, keeping the overlay below roughly twenty percent. Near marks may be slightly longer than distant marks. Use polished 1990s 32-bit arcade pixel art, hard stepped pixels, broad flat clusters and a restrained palette. No dark horizon outline, continuous separator, full-width stripe, pure white, sky, clouds, sun, land, beach, boats, birds, fish, people, large waves, thick foam, dense noise, uniform dash rows, blur, antialiasing, text, border or watermark.

## Runtime preparation adjustments

The prepared cloud clusters are shifted upward, leaving eight clear sky pixels above the sea surface. The runtime sun uses one flat cream-gold color with binary alpha to stay clean at 34 x 34 pixels. The sea is deliberately simple: 320 x 40 frames at native scale, flat colour bands sampled from the sea-source-v2 palette, about twenty sparse fading dashes and five horizon shoals that independently grow, brighten, fragment, recede and disappear on staggered phases. The plate's texture is not copied; it stays as the colour and style reference. The runtime loop has sixteen frames at 150 ms each. Generated sources remain unchanged.

## Dusk (runtime only)

Dusk adds no generated art. `assets/shaders/dusk_tint.gdshader` repaints the sky plate as seven flat bands keyed on screen row (violet, mauve, rose, salmon, orange, gold, pale gold); lit cloud pixels become a warm cream-peach and shaded undersides a cooler mauve. The sun is the day sprite modulated deep orange and moved to y 76 so the sea covers its lower half. A few flat gold dashes under it form a sparse glint. The sea is modulated toward indigo.
