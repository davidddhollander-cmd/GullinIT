# Sea redo plan

## Visual target

The horizon must be defined by atmospheric colour separation, never a dark outline. Far water should sit close to the sky's value and hue, then become progressively greener and darker toward the lower part of the sea layer. The surface should remain calm and readable behind the gull.

The visible shoals are distant shallow-water and low-breaker patches immediately below the horizon. They are broad, thin and irregular. They do not scroll as rigid stripes. Each patch independently grows from its centre, brightens, breaks into two or three short pieces, dims and contracts until it disappears.

## Runtime structure

- 320 x 40 frames at scale 1, on the same pixel grid as every other sprite. (A 2x-density version rendered half-size pixels under `canvas_items` stretch and read as far too busy.)
- 16-frame seamless loop at 150 ms per frame (2.4 seconds, about 6.7 fps).
- No dark horizon line.
- Flat bands, no plate texture: rows 0-1 far water close to the sky value, rows 2-3 and 4-6 transition, rows 7-18 base, rows 19-39 deep.
- About 20 short dashes (2 px near the horizon, 3-4 px lower) that fade in, peak and fade out on staggered cycles, drifting one pixel late in their life.
- Each frame changes only tens of pixels.

## Animation phases

Shoal patches use staggered 16-frame lifecycles:

1. Absent.
2. A short muted centre segment appears.
3. The segment expands one pixel at each end.
4. It expands again and becomes a little brighter.
5. The widest phase splits into two or three nearby fragments.
6. The fragments shorten and dim.
7. Only a muted centre fragment remains.
8. The patch disappears.

Different patches start at different phases, so the horizon never blinks in unison. Nearby surface ripples follow small closed one-pixel paths and pulse between muted and mid highlights rather than translating the whole sea.

## Reference takeaways

- Pixel-water guidance: keep a low-contrast base, small overlays, 1-2 px wave dashes and one-pixel motion; avoid a dense rug of white marks. https://pixeli.pebbly.space/knowledge/rules/64-water
- Ocean edge timing: expansion can be quicker than contraction, with slower recession reading more naturally. https://wolthera.info/category/artwork/
- Existing animated sea packs commonly separate sky, clouds, sea and wave layers instead of baking one moving strip. https://pixel-salvaje.itch.io/parallax-backgrounds-pixel-art
- Public-domain animated pixel-ocean scale reference: https://commons.wikimedia.org/wiki/File:Ocean_pixel_art.gif

## Acceptance checks

- No dark pixel row separates sky and sea.
- Far-water average value is closer to the sky than the lower sea is.
- Shoal visibility changes gradually and independently across the loop.
- No ripple moves more than one source pixel between adjacent frames.
- Frame 16 transitions cleanly to frame 1.
- No cloud pixels occur in the bottom eight sky rows.
- Sun remains a single flat colour with binary alpha.
