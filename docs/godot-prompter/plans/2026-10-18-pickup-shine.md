# Pickup shine: plan

Date: 18 October 2026. Status: implemented with the default decisions; needs a human look at band width and frequency.

Reference: Pedro Medeiros (Saint11), "Simple Shine Tutorial" (patreon.com/saint11/posts/simple-shine-6837557). The post is a GIF and a short note: a highlight band sweeps across the sprite, the timing matters most, and the third frame skips most of the area being shined. The effect can be a single shine, a second "extra shine" after one empty frame, or only the extra shine. I could read the note but not the animation frames, so the exact frame positions below are my interpretation to be tuned by eye.

## Goal

Every pick-me-up glints now and then so players can read what is collectable from a distance: full picnic bags, loose food on the ground (crumbs, chips, stash and bin spills, knocked-down snacks) and bins that still hold scraps. Subtle, pixel-snapped and quiet; no glow, no particles.

## Approach

Draw the shine in the existing `_draw()` code, not with a shader. The items are all drawn from shared nodes (`BeachScraps`, `BeachStashRaids`, `BeachTarget`), and a canvas shader applies to a whole node, so it cannot give each item its own phase. Pixel-snapped CPU frames also match the look of the reference.

A new helper `scripts/pickup_shine.gd` (`class_name PickupShine`, static functions plus a cache):

- `frame(texture, step) -> Texture2D`: a copy of the sprite where only the pixels inside the shine band are lit, and everything else is transparent. It is cached per texture and step, built lazily from `texture.get_image()` (check that `AtlasTexture.get_image()` returns the region, since bins and foods come from `Config.frames()`).
- Only opaque pixels are lit, and the navy outline pixels (`#183b4e`) are skipped, so the shine reads as light on the fill, as in the reference. Lit pixels use the cream from the shared palette (`#fff4da`).
- The band is a 45 degree diagonal, 2-3 px wide, moving across the sprite in 4 steps at about 12 fps. Step positions as a fraction of width+height: about 0.0, 0.25, 0.7, 1.0, so the third step jumps over most of the sprite, as the tutorial describes. An optional 1 px "extra shine" follows after one empty step.
- `step(time, seed) -> int`: returns -1 when idle, otherwise 0-3 (or the extra-shine steps). A cycle of about 2.6 s is mostly idle, and each item gets a seed offset (from its x position or index) so they do not flash together.

Callers draw `PickupShine.frame(...)` over the normal sprite with the same rect and the same transform, so squish and wobble carry over.

## Changes

1. **Helper and tests**: `scripts/pickup_shine.gd`; checks in a new `tests/pickup_shine_checks.gd`. Lit pixels are a subset of opaque non-outline pixels, the band moves between steps, idle steps return nothing, different seeds differ, and the cache returns the same texture twice.
2. **Ground items**: `scripts/scraps.gd` (crumbs and chips, only when not waiting to respawn and `gull.can_collect_food(id)`) and `scripts/stash_raids.gd` `_draw()` (grounded or airborne snacks after the pickup delay; garbage never shines). Each node keeps its own running clock.
3. **Picnic bags**: `scripts/target.gd` bag drawing. Shine only while `stash_remaining > 0`, drawn inside the existing squish transform; stops once the bag is empty.
4. **Bins**: `scripts/beach.gd`. Bins are `AnimatedSprite2D` props that rotate when pecked, so add a child `Sprite2D` per bin that follows the wobble; `BeachStashRaids.tick` tells the backdrop which bins still have scraps (`set_bin_full`).
5. **Tuning and docs**: `juice.shine` (bool), `juice.shine_cycle` and `juice.shine_step` in `data/tuning.json` and `tools/generate_assets.py`; a README line; an on/off switch alongside the other juice flags.

## Verification

- New helper checks, plus predicates for the three sources (`bag shines only with food inside`, `bin shines only with scraps`, `scraps shine only when collectable`), run in `tools/validate.ps1`.
- A rendered snapshot at a fixed clock showing mid-sweep frames for a bag, a ground item and a bin, checked at 1x and zoomed.
- Playtest: the shine should help spot targets but not read as a UI marker or distract during dives. Tune `shine_cycle`, band width and colour by eye.

## Decisions for you (defaults in brackets)

- Shine colour [cream `#fff4da`; white would be stronger].
- Frequency [about every 2.6 s per item, staggered; shorter feels busier].
- Skip items the gull cannot eat right now because its stomach is full [yes].
- Should kiosk or customer food held in hands shine? [no, only things the gull can pick up from the ground or crack open].
- Add a player option to turn shine off [no, tuning flag only].
