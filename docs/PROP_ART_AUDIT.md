# Unused prop art audit — 20 November 2026

Art consistency and pixelation check on every beach prop registered in `data/sprites.json` but not placed in any level, plus the unused ground strips, the lifeguard and the user-supplied litter/bag/food sheets. No level data was changed.

Standards used (from `docs/ART_AUDIT_2026-10-27.md` and `RETRO_ENVIRONMENT_STYLE.md`): props are hand-pixelled at 1:1 on the 320×180 grid, 19-colour palette (`tools/art_audit/palette.hex`), dark `#183b4e` outline, top/front light; the cast is 128 px cells at `visual_scale` 0.5 (~40 px tall adult). Small objects drawn by draw scale at full detail (litter at 0.35, crabs at 0.25) are the approved exception to the 1:1 grid.

## Verdicts

| Prop | Source | On screen | Verdict | What to fix / note |
| --- | --- | --- | --- | --- |
| `tower` | `retro-tower-32bit.png` 56×70 @1.0 | 44×70 | **OK** | 1:1, 10 colours, all on palette, full outline, same wood and red as hut/kiosk. Deck sits at adult head height; reads right next to the lifeguard. Base flush with frame bottom (sits on y 160). When placed: add to `Spawner.DEPTH_PROP_TYPES`; `beach.gd` `_draw()` still draws a legacy code flagpole at `x+12` for `"tower"` that hides behind the art's own flag — remove it then. |
| `pier` | `pier.png` 64×40 @1.0 | 64×40 | **Regenerate** (or drop) | Two flat colours, no outline, no shading: a placeholder. The `pier-320x22` ground strip below already does this job properly. |
| `beach_chair` (red) | `retro-beach-chair-32bit.png` 24×23 @1.0 | 24×18 | **OK** | Palette swap of the in-use `beach_chair_blue`; identical outline, light and footprint. Not in `DEPTH_PROP_TYPES` (the blue one is) — add it when placing in L1/L2. |
| `beach_sign` | `retro-beach-sign-32bit.png` 34×44 @1.0 | 34×38 | **OK** | 1:1, 5 colours, on palette, outline matches bench/bin. Add to `DEPTH_PROP_TYPES` when placed. Optional re-trim: 6 empty rows on top. |
| `beach_boards` | `retro-beach-boards-32bit.png` 32×44 @1.0 | 32×25 | **OK** | 1:1, on palette, matching outline and top light. 25 px vs a 40 px adult, so they read as short boards/bodyboards, not full surfboards; if adult-height surfboards are wanted, regenerate larger (do not upscale). Add to `DEPTH_PROP_TYPES` when placed. Optional re-trim: 19 empty rows on top (frame_h is 44). |
| `beach_ball` | `beach-props-v1` 48×46 @0.25 | 12×11 | **OK** (backdrop) | Drawn on a 4× finer grid than other props, like litter and crabs. Fine at this size. Saturation 0.74 vs 0.44–0.62 for in-use props: it is the brightest small thing on the sand, which is acceptable for a toy. |
| `beach_bucket` | 80×64 @0.25 | 20×16 | **Needs fix: palette** | 10% on palette, saturation 0.84: pure red bucket and yellow spade outshine everything on screen. Shift the red and yellow onto palette reds/yellows (the castle flag and parasol red). Keep the detail; no outline change. |
| `beach_shells` | 72×59 @0.25 | 18×14 | **OK** (backdrop) | Soft colours, low outline weight; sits well beside the castle. |
| `beach_jet_ski` | 176×97 @0.25 | 44×24 | **OK** (backdrop) | Top-lit, strong silhouette. 44 px long next to a 40 px adult is small for a jet ski but works as backdrop at base y 148. Best placed near the shoreline for L5. |
| `beach_lifebuoy_flat` | 104×65 @0.25 | 26×16 | **Needs fix: palette** | Orange-and-white at saturation 0.81 (18% on palette); the tower's own lifebuoy and the hung one are red-and-white. Recolour the orange to the tower's lifebuoy red so the L5/L7 set matches. |
| `beach_lifebuoy_hung` | 64×93 @0.25 | 16×23 | **OK** (backdrop) | Red-and-white matches the tower's lifebuoy. |
| Ground strip `pier-320x22` | 320×22 @1.0 | 320×21 | **OK** | 1:1, 5 colours, on palette, no outline (like the in-use sand and shoreline strips), tiles seamlessly (checked at the 320 px joint). It is the art version of the pier deck `beach.gd` draws with rects; swapping it in is a code change. |
| Ground strip `promenade-320x14` | 320×14 @1.0 | 320×14 | **OK** | Same as above for the promenade (14 px, matches the code rect at y 151–165, 16 px slabs). Tiles seamlessly. |
| `lifeguard` | `lifeguard-diner-style.png` 128 cells @0.5 | 31×40 | **OK** | On the cast standard (same cell size, scale and 40 px art height as the shoppers); painted cast style, 589 colours, which is normal for the cast. Feet land on y 160 with `sprite_offset_y` −26. Needs Spawner depth logic like any ground character if spawned. |
| New litter (untracked): `banana`, `bone`, `bottle_brown`, `bottle_green`, `crisps`, `cup_plain`, `cup_red`, `flipflop`, `sweet`, `tin` | `retro-trash-*.png` 13–22 px @0.35 | 5–8 px | **Needs fix: outline** | Cut from the user's litter sheet with its dark outline ring still on: dark share one pixel inside the edge is 0.42–0.96 vs 0.02–0.48 for 11 of the 12 in-use pieces (only `wrapper` is heavier, 0.81), so they read heavier and darker in the bin spill. Strip the `#183b4e` ring the same way as the in-use set; keep full detail and the 0.35 draw scale. |
| `Colourful Pixel-Art Litter Sprite Sheet.png` | 2172×724 | — | **Source only** | Painted sheet, 100% soft alpha, ~400k colours. Never load at runtime; slice, trim, strip outline as above. |
| `Three Pixel-Art Bags Collection.png` | 2172×724 | — | **Source only** | Same: source for the picnic bags. Slice and draw by scale. |
| `Ultimate Pizza and Fast-Food Sticker Atlas.png` | 1536×1024 | — | **Source only** | Painted illustration, not pixel art (100% soft alpha, ~550k colours). Fine as the source for `food_pizza_slice_*`; never place directly. |

**Safe to use now:** tower, red beach chair, beach sign, beach boards, beach ball, shells, jet ski, hung lifebuoy, both ground strips, lifeguard. **Fix first:** bucket (palette), flat lifebuoy (palette), the 10 new litter cut-outs (outline). **Regenerate:** `pier.png`.

## Depth rule follow-ups (code not changed)

When any of these are placed, add them to `Spawner.DEPTH_PROP_TYPES` in the same change (AGENTS.md rule 3): `tower`, `beach_boards`, `beach_sign`, and also `beach_chair` (only the blue chair is listed). The `beach-props-v1` toys are backdrop (`BeachBackdrop.BACKDROP_PROPS`, z 0, base ~148) and need no entry.

## Comparison images

Rendered by the real `BeachBackdrop` (same placement and z as the game), candidates marked `*` in yellow beside in-use props in white and a standing adult. Saved to `test-output/prop_audit/` (git-ignored; regenerate with the command below):

- `1-ground-props-1280.png` / `-1x.png` — bench, blue chair, bin vs red chair, boards, sign
- `2-tall-props-1280.png` / `-1x.png` — hut, lamp, palm vs tower, `pier.png`, with an adult and the lifeguard
- `3-backdrop-toys-1280.png` / `-1x.png`, `3-backdrop-toys-zoom.png` — castle, rocks, umbrella vs ball, bucket, shells, lifebuoys, jet ski (zoom shows the 4× finer grid)
- `4-ground-strips-1280.png` / `-1x.png`, `4-ground-strip-tile-joint.png` — pier and promenade strips under adults and the kiosk; tile joint check
- `5-litter-1280.png` / `-1x.png`, `5-litter-zoom.png` — in-use litter (top) vs new cut-outs (bottom) at 0.35
- `overview-1x-at-2x.png` — all panels at 1× logical size
- `metrics.md` — per-sprite numbers (texel density, colours, palette share, saturation, outline, light, base gap, soft alpha)

`-1280` files are the game's real 1280×720 render (canvas_items, 4× integer), which is what a player sees; `-1x` files are the same frame at the 320×180 logical size.

```
python tools/art_audit/prop_candidates.py > test-output/prop_audit/metrics.md
<godot>/Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility tools/prop_audit_capture.tscn
```

## How the numbers were read

- **Pixel size:** every 1:1 candidate has a run-length block of 1 (no stored upscale) and draws at 1.0 art px per logical px, matching the in-use props. The `beach-props-v1` set and the litter are deliberately finer (0.25 and 0.35); no candidate is drawn at an uneven scale like the old wheelie bin (0.8). No soft alpha in any runtime candidate.
- **Outline:** in-use props have a dark edge on 61–100% of the silhouette; all 1:1 candidates fall in that range except `pier.png` (0%). The ground strips have none, like the in-use ground.
- **Light:** most in-use props are brighter in the top half (+4 to +54 luma), but bin, wheelie bin and castle are not (−6 to −32), so the measure is loose. Candidates sit inside that spread (tower −1, sign −2, boards +3, bucket −29) and none shows a side light that clashes; by eye all read as lit from the front/top.
- **Base:** all props have 0–1 empty rows under the art (the lifeguard's 6 are handled by its `sprite_offset_y`), so they sit on their base y without floating.

## Fixes (v2)

`tools/prepare_beach_props_v2.py` re-runs v1's reduction from the sheet at new widths, then blends each colour toward its nearest `palette.hex` colour. `tools/strip_litter_outline.py` strips the litter ring (originals kept in `assets/reference/litter-cutouts-v1/`). v1 PNGs are untouched.

| Prop | Size (game px) | Blend | sat | pal | Status |
| --- | --- | --- | --- | --- | --- |
| `beach_bucket` | 20×16 | 0.8 | 0.84 → 0.67 | 0.10 → 1.0 | fixed |
| `beach_lifebuoy_flat` | 26×16, orange → red | 0.8 | 0.81 → 0.62 | 0.18 → 1.0 | fixed |
| `beach_ball` | 12 → 10 wide | 0.45 | 0.74 → 0.60 | 0.35 → 0.74 | resized + palette tweak |
| `beach_shells` | 18 → 12 | 0.5 | 0.69 → 0.61 | 0.40 → 1.0 | resized + palette tweak |
| `beach_jet_ski` | 44 → 64 | 0.5 | 0.73 → 0.65 | 0.28 → 0.85 | resized + palette tweak |
| `beach_lifebuoy_hung` | 16 → 14 | 0.5 | 0.70 → 0.64 | 0.36 → 0.93 | resized + palette tweak |

The jet ski's source is only 200 px wide, so it is kept at native size (204×112) and drawn at `visual_scale` 0.3137 (a 4× cell would need upscaling and leaves gaps). The 10 new litter pieces: luma < 70 edge pixels removed for 2 passes, then cropped; dark share one pixel inside the edge is now 0.00–0.35 (was 0.42–0.96). Fixed; not yet wired into `LITTER_KINDS`.
