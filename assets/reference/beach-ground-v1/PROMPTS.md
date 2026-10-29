# Beach ground v1 source plates

Generated 29 October 2026 with the built-in image generator. The two supplied
project images were style and colour references only:

- `assets/previews/background-v2-composite-320x120.png`
- `assets/previews/beach-signs-level3-1280-v3.png`

The four `*-source.png` files in this folder are the complete, unchanged
generator outputs. `tools/prepare_beach_ground_v1.py` crops and quantises them,
extracts their bands and small marks, aligns those generated motifs to the
native runtime grid, wraps repeated marks, and creates the review previews.

## Shoreline source

Use case: stylized-concept. Asset type: source plate for a shoreline strip in
the 2D side-scrolling game Gullin' It. The supplied images are style and colour
references only: match the calm green-blue sea, pale-gold sand, crisp hard pixel
clusters, limited palette, and quiet 1990s arcade finish. Create one extremely
wide, thin horizontal opaque strip showing a gentle shoreline, viewed straight
on with no perspective. From top to bottom: deep teal-green sea; a narrow band
of pale shallow aqua water; a small stepped cream foam edge that wobbles gently
in broad 40-60-pixel-equivalent waves; a slightly darker damp wet-sand band;
then dry pale-gold sand. Keep foam sparse and simple, with a few short
2-6-pixel-equivalent stepped foam dashes above the waterline and generous gaps.
Broad flat colour clusters, calm and low detail, no pure white. The full image
must be a clean source plate suitable for nearest-neighbour reduction and
cropping. Opaque rectangle. No dark outline or dark line at the waterline,
gradients, glow, spray, large breaking waves, rocks, seaweed, shells larger than
a pixel or two, people, footprints, boats, birds, sky, text, UI, border,
watermark, blur, antialiasing, or dithering.

## Sand source

Use case: stylized-concept. Asset type: seamless-style sand texture source
plate for the 2D side-scrolling game Gullin' It. The supplied images are style
and colour references only. Create one extremely wide, flat, top-lit beach-sand
texture in the same pale-gold base as the game, with a restrained slightly
lighter cream and slightly darker tan. Add sparse, tiny, quiet details with
generous empty space: a few single-pixel-equivalent pebbles, a few
1-3-pixel-equivalent cream shell flecks, a few faint short ripple dashes, and a
few tiny paired footprint dimples that do not resemble recognisable feet. Keep
every mark low contrast, evenly scattered, and subordinate to character
sprites; the sand must read as nearly flat colour. Polished 1990s 32-bit arcade
pixel art, hard stepped pixels, broad flat colour clusters, limited palette.
Opaque rectangle suitable as a source plate for nearest-neighbour reduction
and cropping. No horizon, water, foam, wet patch, seaweed, crabs, bottles,
litter, large rocks, strong shadows, gradients, glow, vignette, dense noise,
grain, uniform rows, blur, antialiasing, dithering, text, border, or watermark.

## Promenade source

Use case: stylized-concept. Asset type: source plate for a wooden promenade
boardwalk strip in the 2D side-scrolling game Gullin' It. The supplied game
image is a style, scale, and colour reference only. Create one extremely wide,
thin, straight-on opaque strip of warm medium-brown wooden boardwalk planks.
Boards run horizontally across the screen, separated by evenly spaced thin
darker vertical joints; each plank segment is a little wider than the strip is
tall. Include a slightly lighter top lip and darker lower edge. Add quiet
restrained detail: two to five short horizontal hard-pixel wood-grain dashes per
plank segment and one tiny nail head near each joint; vary four repeating plank
treatments subtly, with an occasional slightly lighter or darker plank.
Polished 1990s 32-bit arcade pixel art, crisp hard stepped pixels, broad flat
colour clusters, limited warm palette, detail well below sprite contrast.
Opaque rectangle suitable as a source plate for nearest-neighbour reduction,
extracting motifs, and exact grid alignment. No black, heavy outline, large
knots, cracks, rust, puddles, leaves, litter, railings, people, gradients, glow,
perspective, blur, antialiasing, dithering, text, border, or watermark.

## Pier source

Use case: stylized-concept. Asset type: source plate for the front face of a
wooden pier deck with support posts in the 2D side-scrolling game Gullin' It.
The supplied game image is a style, scale, and colour reference only. Create
one extremely wide horizontal opaque strip, viewed perfectly straight on with
no perspective. Along the top: a narrow pale warm-gold deck lip with a small
stepped notch at regular plank joints. Beneath: a warm reddish-brown fascia beam
with one slightly lighter horizontal highlight and tiny nail heads at regular
intervals. Below the fascia: evenly spaced wooden support posts, each with a
stepped cap where it meets the deck, lit on its left half in lighter brown and
shaded on its right half in darker brown, plus a small flat dark-tan hard-edged
contact shadow at its foot. Use plain flat pale-gold sand behind and between
posts so it can be removed during preparation. Polished 1990s 32-bit arcade
pixel art, hard stepped pixels, broad flat colour clusters, restrained palette,
quiet detail below sprite contrast. Opaque source plate suitable for
nearest-neighbour reduction, extracting post motifs, and exact spacing. No
black, heavy outline, water, barnacles, seaweed, ropes, lamps, railings, boats,
people, birds, gradients, glow, blur, antialiasing, dithering, text, border, or
watermark.

## Runtime preparation adjustments

- Fixed 18-colour shared palette; no dithering and binary alpha only.
- Source-derived shoreline contours are normalised to the required 20 rows.
- Small sand and grain components are extracted as stamps and re-scattered with
  fixed seeds, minimum spacing, wrap checks, and the y=152-168 quiet zone.
- Generated plank, fascia, and post motifs are aligned to exact 16 px and 64 px
  runtime phases. No new decorative motifs are drawn by the preparation script.
- The optional animated shoreline was deliberately omitted: the static edge is
  calmer and keeps this first review focused on the approved visual direction.
