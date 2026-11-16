# Clouds v2 — generation and preparation

Generated with the built-in image generator, transparent background enabled.
The previous sky plate and `assets/reference/background-v2/PROMPTS.md` were the
style reference. The older `sky-clouds-v1/PROMPT.md` named in task 094 is absent.
No existing plate or runtime file was changed.

## Source A — clouds-source.png

Use case: stylized-concept. Asset: TINY NATIVE-RESOLUTION pixel-art cloud atlas, transparent. Output canvas 1024x1024. The entire atlas must occupy ONLY a 416x144 rectangle at top left of the canvas; leave the rest fully empty transparent. Exactly 12 tiny clouds on 4 columns x3 rows, cell size104x48. Cell centers x=52,156,260,364 and y=24,72,120. Pixel cloud widths row1 =20,24,22,36; row2=40,48,72,88; row3=56,72,88,96. Most canvas MUST be empty. Actual 1-pixel contour steps and very low resolution cloud sprites, NOT large painted clouds and NOT upscaled pixels. Fair weather first8 clouds: 3 thin wisps,3 small cumulus,2 wide cumulus. Windy last4: thin elongated flatter streaks. Three solid colors ONLY: cream #fff4da highlight, muted light bluegrey #8e9b9e shade, restrained bluegrey #617782 underside. Distinct stepped silhouettes, simple broad flat shapes. No outlines, blur, antialiasing, semitransparency, glow, tiny specks, dithering, texture, yellow edging, text, sea, sun, birds, labels, checkerboard, background. Genuine alpha background. Critical: these clouds must stay tiny at exact prescribed pixel widths, occupying less than one sixth of the full canvas area combined; do not enlarge the art to fill canvas. Keep all art within the top-left 416x144 rectangle.

## Source B — clouds-large-source.png

Use case: stylized-concept. Production transparent pixel sprite sheet of TWELVE isolated small clouds, 4 columns and3 rows. All artwork confined to TOP LEFT 560x160 of a 1024x1024 transparent canvas, remainder EMPTY. One cloud at each regular cell center, cells140x52. Row1 three THIN SMALL WISPS width28,30,32; fourth a rounded medium cloud width48. Row2 two medium cumulus clouds width56 and64, then two LARGE cumulus width96 and120. Row3 four long LOW FLAT WINDY cloud streaks width72,96,112,128. Preserve these relative sizes carefully. First3 wisps low and airy with asymmetric peaks, next3 medium clouds round with varied lobes, next2 large clouds billowing and different, last4 stretched low wind clouds. EXACT THREE solid colors: #fff4da cream-white lit tops, #8e9b9e muted bluegrey lower bodies, #617782 restrained blue-grey lowest accents. Fair clouds mostly cream; windy clouds mostly lighter bluegrey with cream rims. Pure 1990s pixel art, hard single-pixel stepped contours, few big flat clusters. NO smooth shading, NO blur, NO antialiasing, NO gradients, NO dark outlines, NO glows, NO scattered pixels, NO extra disconnected details, NO texture or dithering. Genuine transparent alpha outside silhouettes. Keep generous empty gap between clouds. NO sky, sun, birds, horizon, text, label, gridlines, checkerboard, border. Art must remain small in upper left of large mostly empty canvas. Exact12 clouds, no duplicates.

## Source C — clouds-wisp-source.png

Use case: stylized-concept. Transparent TINY native pixel sprite sheet. Three very small thin fair-weather CLOUD WISPS ONLY, one row, all inside TOP LEFT 256x48 pixels of a large1024x1024 transparent canvas. Most canvas entirely EMPTY. Centers at (40,24),(120,24),(208,24). Widths24,28,32 pixels, heights5,7,9 pixels. Make wisp1 a low taper with a tiny off-center hump; wisp2 a little broken-back double hump with long leftward tail; wisp3 a narrow cream tuft with a stepped rightward tail. Distinct silhouettes, NOT round diamonds or boxes. Look like tiny distant coastal clouds from a 1990s pixel arcade game. Actual1pixel steps, broad simple flat clusters. TWO colors ONLY: #fff4da cream tops, #8e9b9e blue-grey undersides. NO dark outlines, blur, texture, shading gradients, dithering, translucent edges, glow, isolated specks, backgrounds, sky, sun, birds, labels, text, checkerboard. Genuine transparent alpha. Keep these clouds at the prescribed tiny size, do NOT enlarge to fill canvas.

Only the first cloud in this source is used, for a thinner fair-wisp-01.

## Preparation and integration contract

Run `python assets/reference/clouds-v2/prepare.py` with Pillow installed.
It crops generated clouds without resizing, thresholds alpha at 128, removes
detached generation specks, maps colours to the two final palette entries, and packs
the sprites on a 4 by 3 grid of 192 by 112 pixel cells. Minimum padding is 8 px;
regions are tight cloud bounds within the cells, in unscaled atlas pixels.
Complete generated sources are retained unchanged. No silhouettes are drawn.

`clouds-v2.json` has a `clouds` array: each entry supplies `id`, `set` (`fair` or
`windy`), `size`, `region` (`[x,y,w,h]`, top-left origin), source provenance, and
recommended display scale. Task 095 should look up entries by ID, never index.
Use nearest-neighbour filtering, no mipmaps, and snap rendered positions.

The approximate widths in task 094 are interpreted as display widths because
the task explicitly requires retaining source detail and drawing at 0.5 or
integer scales. All clouds recommend 0.5. Small display widths
are 25, 16.5, 17.5; medium 29, 31.5, 38; large 81, 65; windy 47, 59, 66.5,
73.5 pixels. These are approximate ranges, not resampled delivery images.

The two opaque colours are exactly `#fff4da` and `#8e9b9e`, both
from `tools/art_audit/palette.hex`. There is no dark navy outline: the existing
plate has pale cloud edges, and the dusk shader would classify navy as sky.
The light grey shade uses the shader's red > 0.45 branch. The originally
requested `#617782` generation accent is mapped to `#8e9b9e` during palette
cleanup: its red channel is below 0.45 and the shader would erase it into sky.
This keeps every cloud pixel distinct from dusk sky without changing the shader.

## Preview

`preview.png` is rendered by Godot using the actual `dusk_tint.gdshader`, not a
generic colour overlay. It shows every sprite against day sky and dusk sky at
recommended display scale, enlarged 2x for inspection. Separate textures are
cropped from the atlas for this fixture, so shader UVs run from 0 to 1 per
cloud. Shader `plate_top` and `plate_height` are set for each cloud's position
and scaled height. Task 095 must account for per-cloud UVs and screen position
when applying the plate-oriented shader to separate sprites. The preview
fixture is retained as `preview.gd`; it is a standalone tool, not game code.
