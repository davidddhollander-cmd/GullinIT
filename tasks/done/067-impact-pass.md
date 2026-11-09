# 067 — Impact pass: flashes, squash, weighted snatches

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on:
Created: 2026-11-09

## Goal
The game has plenty of particles, but bodies barely react to hits and every reward lands at the same size. Make hits read on the body that was hit, make the gull's body move with its actions, and make bigger snatches feel bigger. Code and tuning only.

## Context
- `scripts/effects.gd`: `impact()`, `snatch_contact(at, motion, bonus)`, `collect_burst()` (already scales by food size; reuse its size-to-amount calculation), `message()`, `whisper()`, the `ring` particle (`dive_release` shows how to use it), `_draw()`.
- `scripts/gull.gd`: `tick()` resets `sprite.scale` and `sprite.modulate` each frame, then applies `power_scale` and `power_tint` later, with beak and feet anchors using the scaled size. Lines 284-301 set the sprite material: `gull_cutout` (player), `rival_tint` (rivals), or none. Line 704 copies the material to body parts. The windup squash at line 517 is skipped for `native_alpha` art.
- `scripts/target.gd:285-289`: people's sprites use `gull_cutout` or no material.
- `scripts/score.gd`: `combo_changed(tier)`. `game.gd:229` only plays a sound on it.
- `game.gd:919` is the player's snatch, `game.gd:933` the swallow/score moment, and `game.gd:1101-1115` the rival bumps. `brashness.gd` `hit_fx()` also sets freeze and shake.
- `scripts/overlay.gd:383`: the score label.
- AGENTS.md: tinting and scaling existing sprites is allowed. Do not draw any part of a character.
- CLAUDE.md: UI text is on the native 8 px grid (8 or 16 px only). **Never scale text with a transform.**
- Check `godot-prompter:shader-basics` and `tween-animation` first. Put every number in the `juice` block of `data/tuning.json`.

## Requirements
**Hit flash**
1. Add a `flash` amount (0 to 1) that mixes the sprite's colour toward white. It must work on all three gull sprite cases and on people's sprites. Keep each shader's alpha discard and the rival feather tint. Each character needs its own flash value: a rival must not flash because another rival was hit. Body parts that copy the gull's material (line 704) flash with it.
2. Flash lasts `flash_time` (about 0.07 s) and fires when: any gull is stunned or tumbles, a rival is bonked, a blocked hit shows "NOPE!", and a person loses food to Gang Call or Shakedown.
3. Gate the flash on `juice.flash` and on `GameState.options.shake`, the existing reduce-motion style option.

**Squash and stretch**
4. Add one short squash timer to `BeachGull`, applied where `power_scale` is applied so beak, feet and hit positions don't move. It multiplies with `power_scale`.
5. Poses: stretch along the body during `STRIKE`, growing with `dive_speed`; squash on landing, stronger on a hard landing; a quick bulge when the player swallows. Add `juice.squash` as an on/off switch. Amounts stay subtle enough to keep pixel art readable (start within 0.8 to 1.25 on each axis).
6. Find out why the windup squash skips `native_alpha` art. Apply the new poses to all three species, or record in the Report why one can't have them.

**Weighted snatches**
7. Give `snatch_contact` a weight from 0 to 1 based on food size and combo tier. A bonus counter snatch is always full weight. Freeze and shake interpolate from today's `snatch_stop` and `snatch_shake` at weight 0 to new `snatch_stop_max` (0.09) and `snatch_shake_max` (3.5) at weight 1. Callers with no food, such as rival bumps, stay at weight 0, so they feel as they do today.
8. Fix `impact()` so a smaller hit can never cut a larger freeze or shake short (`maxf`). Check `hit_fx()` for the same problem.

**Combo and score**
9. On a combo tier rise only: a gold ring at the gull plus a floating "X<multiplier>" from `Config.tuning.score.tiers`. No ring when the combo resets.
10. Score pop: when points rise, the score label hops up 2 px and briefly turns white, then settles. No scaling and no layout shift in the top bar.

**Floating text**
11. All floating text hops on appearance: a few pixels of overshoot in its first 0.1 s. No scaling.
12. The short impact words (BUMP!, BONK!, DROPPED!, MUGGED!, MINE!, PECK!, NOPE!, SKULL!, SOAKED!, GOTCHA!) use the outlined, plate-free style, keeping their own colours. Let `whisper` take a colour, or add a small sibling. They hold for the normal `float_time` and don't use the whisper fade. Score messages, tips and training text keep their plates.

## Out of scope
- New art, sound or pixelfx sheets; power moments (ready glow, screen dim, Shakedown stomp); hit-stop or slow motion on ordinary pecks; more particle types; perks; balance changes.

## Done when (acceptance)
- [ ] Flash reaches each sprite type, returns to exactly 0, and affects only the character that was hit
- [ ] With the shake option off there is no flash and no shake
- [ ] Squash leaves `beak()` and foot positions unchanged, and sprite scale returns to normal, including alongside Shakedown's `power_scale`
- [ ] A large food at a high tier freezes and shakes harder than a crumb at tier 0; a crumb at tier 0 matches today's values
- [ ] A snatch straight after a stun leaves the stun's shake and freeze intact
- [ ] The ring and multiplier appear on tier rises only
- [ ] Score hop leaves the top bar's layout unchanged
- [ ] No floating text or HUD label is drawn with a scale other than 1
- [ ] Checks added in `tests/impact_pass_checks.gd` for the logic above; `./tools/validate.ps1` has no new failures. No screenshots needed; David will judge the look in game

## Report
Branch `sonnet/067-impact-pass` (not pushed, not merged).

**Files changed**
- New: `scripts/hit_flash.gd`, `assets/shaders/sprite_flash.gdshader`, `tests/impact_pass_checks.gd` (+ .uid files).
- `assets/shaders/gull_cutout.gdshader`, `rival_tint.gdshader`: `flash` uniform, alpha discard and feather tint kept.
- `scripts/gull.gd`, `target.gd`: per-character `flash_left` and `hit_flash()`; gull squash timer, `squash()`, `squash_scale()`.
- `scripts/effects.gd`: `impact(at, stunned, weight)` with `maxf`, `food_size_amount()`, `snatch_weight()`, `shout()`, `combo_pop()`, `text_hop()`, text age.
- `scripts/score.gd`: new `combo_rose(tier)` signal (rises only; `combo_changed` unchanged).
- `scripts/game.gd`, `brashness.gd`, `shakedown.gd`, `overlay.gd`; `data/tuning.json` (all numbers in `juice`); `tests/integration.gd` (registration).

**Tests**: baseline 16,721 checks / 2 failures; now 16,790 checks / 2 failures. Same two known failures only: "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo". 69 new checks in `tests/impact_pass_checks.gd`.

**Decisions**
- Flash: people and native-alpha gulls have no material, so a flash-only material is attached for the length of the flash and removed again at 0 (existing `material == null` tests still hold). Gulls decay in `_process` (real time, so it is not stretched by hit-stop); people got a small `_process` too. Fades linearly from 1 to 0 over `flash_time`. Triggers: `begin_tumble` (every stun/tumble, rival bonks included), the NOPE!/SKULL! handler, people whose food is knocked by Gang Call or the Shakedown slam. Gated on `juice.flash` and `options.shake`.
- Weight = food size share (`weight_size_share` 0.5, same size curve as `collect_burst`) + combo tier ratio; counter snatch = 1. Only the player snatch (game.gd `_snatched`) passes a weight; bumps, mugs and Shakedown knocks stay at 0.
- `impact()` now uses `maxf` for freeze and shake. `brashness.hit_fx()` and `ground_slam` already used `maxf`: no change needed.
- Stretch during STRIKE is x +0.2 / y -0.1 at full dive speed; landing 0.1 (hard 0.2); swallow bulge 0.12; all inside 0.8-1.25.
- Added `combo_rose` instead of changing `combo_changed`, because `combo_changed` also fires when already at the top tier (the sound relies on that).
- Score hop moves `score_label.position.y` only (restored to the captured rest y at the end); container size/other labels untouched; not gated on the shake option (spec only gates the flash).
- Impact words use new `effects.shout()` (outlined, plain, own colour, `float_time`, no fade). "MUGGED BY NAME!" and score messages keep plates.
- Text hop is position only (`text_hop`, 3 px over 0.1 s, rounded to whole pixels).

**`native_alpha` windup squash**: not a rendering limit. The `frame_beaks` placement code (gull.gd) positions the sprite from a single scalar `art_scale*power_scale`, so any non-uniform sprite scale moved the bill and sole off their anchors; the windup squash (1.15, 0.75) was skipped for native-alpha art to avoid that. I made the anchor math per-axis from the final `sprite.scale`, which keeps bill and sole pinned under any squash, and removed the skip, so the windup squash now also plays on native-alpha gulls (all three species and rivals; checked for herring, kittiwake, great black-back). This is a visible change to the windup pose on all current gulls; to restore the old look, re-add the `native_alpha` guard on that one line.

**Existing test changed**: `tests/shakedown_checks.gd` "the gull is drawn at bully_scale during the power" now clears the swallow bulge first (`player.squash_left = 0.0`), because the swallow the test performs just before now deliberately bulges the body.

**Not done / not verified**: no screenshots or in-game look check (as specified). `rival_tint` and `gull_cutout` flash are tested by assigning those materials to gulls, since current gull art is all native-alpha and never uses them at runtime. The swallow bulge test uses the scrap path of `_swallowed`. Score hop restore relies on the HBox not re-sorting its children's y mid-hop (a re-sort just re-applies the offset next frame).


## Review notes
<!-- Filled in by the reviewer. -->
