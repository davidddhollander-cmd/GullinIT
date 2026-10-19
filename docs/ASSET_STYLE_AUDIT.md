# Gullin' It asset style audit

Current production update, 19 October 2026: the user approved the sharper diner-led pilot, now applied to Mum and all four sunbather variants with 128-pixel source cells shown at half scale. The diner's 24 poses have since been isolated into padded atlases to remove neighbouring-frame fragments. The toddler now uses matching crisp artwork at 22 logical pixels tall, with separate crying-run frames. The shopper and lifeguard are also integrated at the adult scale, including whistle and action timing. See `DINER_ADULT_PRODUCTION_V1.md`, `DINER_TODDLER_UPDATE_V1.md` and `SHOPPER_LIFEGUARD_PRODUCTION_V1.md` for current implementation; the assessments below are historical.

19 October 2026 update: the five native adult atlases described below have been replaced using the selected review artwork plus three supplemental motion sources. Their earlier geometric-silhouette findings are resolved by that replacement; held reaction poses and adapted chase cycles remain documented limitations. See `ADULT_ASSET_REPLACEMENT_V3.md` and `assets/previews/adult-replacement-review-v3.png`. The remaining audit is the historical 17 October snapshot.

17 October 2026. Visual target: the native 320 × 180, hard-edged, restrained-palette, 32-bit-era pixel style in `RETRO_ADULT_CAST_STYLE.md` and `RETRO_ENVIRONMENT_STYLE.md`. Judgements below use `data/sprites.json`, runtime rendering settings, generated level placement, and recent in-game captures. `*.import` files are generated metadata, not separate art.

**Inventory:** 58 sprite source images, 22 review/render PNGs, 1 reference PNG, 3 font files, 1 app icon, 3 shaders, and 6 WAV files. The sprite registry names 37 distinct source images. Three additional sunbather colour/sex sheets are loaded directly by `SunbatherArt`, giving 40 production-referenced sprite images. The other 18 sprite images are old or unmapped sources. Some registered props and icons are still dormant in generated levels.

## Style status of production visuals

| Asset(s) | Status | In-game evidence and action |
| --- | --- | --- |
| `gull_reference_clean.png` (player and rival) | **Out of style** | Painted 240 × 200 frames reduced to 18% at runtime. Soft feather detail and resampling contrast sharply with square-pixel props and UI. The rival also shares this source, then receives a tint. Rebuild both birds on a native grid, retaining their distinct flight/dive poses and readable rival identity. |
| `toddler_polished.png` | **Out of style** | 362 × 362 frames reduced to 5.25% with linear mipmap filtering. The face, hat and soft edges read as a miniature illustration beside the native-pixel mum. Rebuild at final in-game size with the shared palette and hard alpha. |
| `customer-polished.png` | **Out of style** | 400 × 500 frames reduced to 8.5% with linear mipmaps; painterly shading and proportion/detail density differ from the beach cast. Rebuild on the same adult pixel grid. |
| `dog-owner-polished.png` | **Out of style** | 600 × 460 frames reduced to 9% with linear mipmaps; the woman and dog are painted with smooth detail. Rebuild both at native size, keeping their walk/bark/reaction poses. |
| `food_bites.png` (crumbs, chip, box, ice cream, bag, hot dog, fish) | **Out of style** | Large illustrated food regions are scaled into tiny hand-held and dropped sprites. Their gradients/highlights and fine outlines do not share the props' pixel clusters. Redraw each food at its actual pickup size. |
| `retro-mum-32bit.png` | **Partly aligned** | Correct native 64 × 64 cells, palette, alpha and nearest filtering; the latest redraw improves the face and blouse. At gameplay size the silhouette still reads simpler and stiffer than the approved large-pixel character reference and the pier diner. Refine anatomy/pose readability without losing the native grid or hand anchors. |
| `retro-sunbather-male-red-32bit.png`, `retro-sunbather-male-blue-32bit.png`, `retro-sunbather-female-red-32bit.png`, `retro-sunbather-female-blue-32bit.png` | **Partly aligned** | Native hard pixels, consistent palette swaps and required clips are present. The standing and reclining bodies are much more geometric than nearby props and the approved character reference. Refine silhouettes and transitions as a matched set. |
| `pier-diner-retro-large-pixels.png`, `pier-diner-motion-large-pixels.png` | **Partly aligned** | Stylized blocky outlines and readable poses are closer to target. Each 400 × 400 frame is nevertheless scaled to 11% instead of being authored on the world grid, leaving pixel size and edge quality inconsistent with the native adults. Rebuild at final size and align idle/action/motion sheets. |
| `lifeguard.png`, `seafood_vendor.png` | **Out of style** | Old 16 × 32 tiny NPC sheets. In the pier render the lifeguard reads as a small flat placeholder beside a detailed tower and diner. Redesign at the adult cast's apparent height and palette. |
| `cookie.svg` | **Aligned with caveat** | The active cookie is a small rect-based icon with `crispEdges`; its simple form suits the pixel grid. Verify its final rendered size and palette when the rest of the food is redone. |
| `retro-kiosk-32bit.png`, `retro-hotdog-stand-32bit.png`, `retro-tower-32bit.png`, `retro-bin-32bit.png`, `retro-umbrella-32bit.png` | **Aligned** | Native-sized, stepped outlines, shared colours and nearest filtering. Distinct silhouettes read clearly in renders. |
| `retro-beach-parasol-32bit.png`, `retro-beach-parasol-blue-32bit.png`, `retro-beach-palm-32bit.png`, `retro-beach-castle-32bit.png`, `retro-beach-rocks-32bit.png`, `retro-beach-lamp-32bit.png`, `retro-beach-bench-32bit.png` | **Aligned** | Consistent with the environmental palette and grid. The palm/rocks/castle add the right density without smooth edges. |
| `retro-beach-chair-32bit.png`, `retro-beach-chair-blue-32bit.png`, `retro-beach-sign-32bit.png`, `retro-beach-boards-32bit.png`, `retro-beach-hut-32bit.png` | **Aligned art, dormant placement** | The sprites follow the style, but `BeachLevelGenerator.generate()` replaces authored props with its own list, so these do not appear in generated gameplay layouts. Restore intentional placement before spending time repainting them. |
| `pier.png` | **Dormant** | Registered but the playable pier is drawn by `BeachBackdrop`, not this sprite. Keep as a reference or remove from the production registry. |
| `chips.png`, `ice_cream.png`, `sandwich.png`, `hot_dog.png`, `cone.png`, `fish_chips.png`, `seafood.png` | **Dormant** | Registered 8 × 8 legacy food icons. Actual food definitions point to `food_bites.png` or `cookie.svg`. These are too simple to use as direct replacements without a fresh size/readability pass. |
| Backdrop, flags and signs drawn in `beach.gd` / `stand_sign.gd` | **Aligned, sparse** | Hard-edged colours and rectangular flag motion fit the target. The broad empty sky/sand areas make the cast's mixed rendering styles more noticeable. Keep this grid when adding detail. |
| `gull_pixel.bdf`, `gull_pixel.fnt`, `gull_pixel.png` | **Aligned** | Bitmap UI lettering fits the native pixel layout. |
| `icon.svg` | **Aligned** | Uses stepped gull geometry and the game's navy/cream/gold palette; its SVG output is for app icon sizes. |

## Sources not used by the current production sprite registry

The 18 unmapped sprite files are `beach-props.png`, `bin.png`, `dog.png`, `kiosk_customer.png`, `kiosk.png`, `mum-polished.png`, `parent.png`, `pier_diner.png`, `pier-diner-motion-pilot.png`, `pier-diner-retro-pilot.png`, `player_gull.png`, `rival_gull.png`, `sunbather-female-sheet.png`, `sunbather-user-sheet.jpg`, `sunbather.png`, `toddler.png`, `tower.png`, and `umbrella.png`. They are references, pilots or legacy versions; do not treat their visual mismatches as active gameplay defects. The three other `retro-sunbather-*-32bit.png` sheets absent from the registry are **active** through code, not legacy.

The 22 images under `assets/previews` are review/capture material, not runtime art. `assets/reference/gull_sheet_original.png` is a source reference. The six WAV files (`click`, `dive`, `gust`, `music`, `snatch`, `stun`) are active audio assets; the two visual style specifications do not define an audio target, so this audit makes no aesthetic pass/fail judgement on them. The shaders are rendering support; the cutout/tint shaders matter here because they allow painted, high-resolution sheets to remain in the game.

## Replacement order

1. **Player and rival gulls, toddler, customer, dog owner and held food.** These are the most visible smooth/painted assets against the native environment.
2. **Lifeguard and seafood vendor.** Replace the tiny placeholder silhouettes at the pier.
3. **Finish the adult cast as one set.** Refine mum and four sunbathers together, preserving their existing animation counts, foot baseline, mirrored hand anchors and gameplay signals.
4. **Normalize the pier diner.** Keep the successful shapes and poses, but rebuild at native size.
5. **Restore or retire dormant props and registry entries.** Audit generated placement first; avoid repainting assets that never render.

The current scene mixes at least three image scales: native 40-pixel adults, large pixel-like 400-pixel diner sheets reduced fractionally, and painted 240–600-pixel gull/people/food sheets reduced with smoothing. The mismatch is visible even where each asset looks good in isolation. The replacement gate should be a full gameplay render at 320 × 180 logical size enlarged by nearest-neighbour to 1280 × 720, with the whole cast and food visible together.
