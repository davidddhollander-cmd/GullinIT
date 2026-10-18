# Retro beach environment style

Status: implemented native-pixel pass, 15 October 2026. The buildings, flagpoles and beach props follow the adult cast's approved 32-bit-era direction in [RETRO_ADULT_CAST_STYLE.md](RETRO_ADULT_CAST_STYLE.md).

- Work at the game's 320 × 180 logical resolution. Each asset is reduced to its final in-game pixel dimensions before import; nearest-neighbour filtering and opaque/transparent alpha keep every edge square at 4× display scale.
- Use a shared 16-colour environment palette: navy outline, cream, coral, teal, blue, wood, sand, green and stone families. Each individual prop uses only the relevant subset. Broad clusters and stepped roof/leaf/flag contours carry form; no painted gradients, feathered edges or fine wood grain survive the native reduction.
- Keep silhouettes and relative sizes readable beside a 36–40-pixel adult: food stands 52 × 56 pixels, lifeguard tower 56 × 70, beach hut 40 × 52, palm 44 × 62, parasols 40 × 42, deckchairs 24 × 23, bin 16 × 22. Each transparent image includes the same bottom ground anchor used by the level placement code.
- Flagpoles use rectangular pixels and three stepped flutter poses driven by the existing wind direction and strength. Flags are part of the backdrop and remain visible on the tower and food stands without changing collision or gameplay.
- The ImageGen concept sheets are in `assets/previews`. `tools/prepare_retro_environment.gd` converts the selected objects to native transparent PNGs with integer nearest-neighbour reduction and the shared palette. `tools/map_retro_environment.ps1` maps `data/sprites.json` to those assets. The original painted sprite sheet remains available as a reference.
- Review the props in levels at 1× and 4×. Reject clipped silhouettes, off-ground feet/bases, unclear kiosk versus hot-dog identity, props with stray pixels, or new details that are finer than the characters' pixel clusters.
