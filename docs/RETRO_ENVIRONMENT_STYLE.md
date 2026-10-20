# Retro beach environment style

Status: implemented native-pixel pass, 15 October 2026. The buildings, flagpoles and beach props follow the adult cast's approved 32-bit-era direction in [RETRO_ADULT_CAST_STYLE.md](RETRO_ADULT_CAST_STYLE.md).

- Work at the game's 320 × 180 logical resolution. Each asset is reduced to its final in-game pixel dimensions before import; nearest-neighbour filtering and opaque/transparent alpha keep every edge square at 4× display scale.
- Use a shared 16-colour environment palette: navy outline, cream, coral, teal, blue, wood, sand, green and stone families. Each individual prop uses only the relevant subset. Broad clusters and stepped roof/leaf/flag contours carry form; no painted gradients, feathered edges or fine wood grain survive the native reduction.
- Keep silhouettes and relative sizes readable beside a 36–40-pixel adult: food stands 52 × 56 pixels, lifeguard tower 56 × 70, beach hut 40 × 52, palm 44 × 62, parasols 40 × 42, deckchairs 24 × 23, bin 16 × 22. Each transparent image includes the same bottom ground anchor used by the level placement code.
- Flagpoles use rectangular pixels and three stepped flutter poses driven by the existing wind direction and strength. Flags are part of the backdrop and remain visible on the tower and food stands without changing collision or gameplay.
- The ImageGen concept sheets are in `assets/previews`. `tools/prepare_retro_environment.gd` converts the selected objects to native transparent PNGs with integer nearest-neighbour reduction and the shared palette. `tools/map_retro_environment.ps1` maps `data/sprites.json` to those assets. The original painted sprite sheet remains available as a reference.
- Review the props in levels at 1× and 4×. Reject clipped silhouettes, off-ground feet/bases, unclear kiosk versus hot-dog identity, props with stray pixels, or new details that are finer than the characters' pixel clusters.

## Palm placement — 20 October 2026

Every playable level has three palms, using the existing 44 × 62 sprite. Training Day places them at x=145/370/665; Family Picnic at 70/570/1005; Boardwalk Bustle at 125/745/1130. Levels 4–6 use the generated scenery template at 32/350/965. Crowns remain inside the map, trees sit behind the actors, and the stalls' serving windows and counter food stay clear. Keep this count in the generator as well as the authored opening maps: later-level recipes have their scenery replaced during generation.

## Palm leaf wind — 20 October 2026

All palms use the approved v2 leaf sway from `assets/shaders/palm_leaf_sway.gdshader`. The outer fronds flex on a slow eight-second cycle; leaf bases and trunks stay fixed. Each tree has a repeatable phase offset. Movement follows the beach's smoothed wind, easing through gusts and reversals and stopping in calm weather. Animation follows the gameplay clock, including pause and slow motion. The original palm sprite is preserved. See [PALM_WIND_PILOT.md](PALM_WIND_PILOT.md) for the comparison scene and previews.

## Green bin sizing — 20 October 2026

The green wheelie bin renders at 0.8 scale (22.4 x 30.4 game pixels), with nearest sampling and a subtle 0.18 local contrast sharpen on its lid and panel pixels. Its original 28 x 38 transparent sprite is retained. Lid contact, opening height and landing width scale together; contents, raid rules and wobble timing remain unchanged.

## Promenade readability — 20 October 2026

The new ImageGen lamp uses a 24 × 90 pixel frame, a long metal shaft and a compact curved lantern. `assets/reference/tall-lamp-v1` preserves its full source and prompt; `tools/prepare_tall_lamp.gd` reduces it into the shared palette and measures the top perch. The environment mapper preserves this replacement. Ground crumbs render at 5 × 3 pixels with a brighter top and dark underside. A missed snatch emits a golden crumb spray and a short trail as the existing dropped food falls; these cosmetic particles follow the particles setting.
