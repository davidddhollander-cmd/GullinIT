# Peck, snatch and tumbling-trash polish

Date: 25 October 2026. Status: implemented.

## Goal

Make pecks and successful snatches feel sharper without obscuring the food or
changing collision timing. Make every piece of litter thrown from a bin visibly
tumble until it lands. Keep the effects small, pixel-snapped and consistent with
the existing cream, gold, coral, teal and navy palette.

## Current state

- `scripts/effects.gd` already owns hit-stop, camera shake, floating text and
  short-lived particles. Most non-feather particles are flat 1-2 px rectangles.
- Dive pecks show the gull's snatch pose and a HUD ring. Ground pecks show the
  dedicated pose, a short gold line and source wobble/squish.
- The successful-snatch impact currently happens later, when the carried food is
  swallowed and scored, rather than at the beak/food contact frame.
- `scripts/stash_raids.gd` already moves bin contents with deterministic velocity
  and gravity, but litter has no angle or angular velocity and is drawn upright.

## Approach choice

**Recommended: extend the two existing lightweight simulations.** Add textured
particles and contact helpers to `BeachEffects`; add `rotation` and
`angular_velocity` to litter dictionaries in `BeachStashRaids`. This is the
smallest change, preserves deterministic tests and keeps the current particles
option authoritative.

Two heavier alternatives are not recommended for this pass: dedicated
`GPUParticles2D` scenes would make exact pixel placement and headless assertions
harder, while a `RigidBody2D` per litter item would duplicate the existing
ballistic update and add collision/lifecycle overhead for purely decorative
objects.

## Improvement plan

1. **Add a tiny transparent VFX texture set.** Create/import a compact atlas with
   a beak-contact star, a short curved snatch slash, two crumb/dust flecks and a
   small impact wedge. Preserve the complete source under `assets/reference/`,
   crop only for runtime assets, use nearest filtering and keep every mark
   readable at the 320x180 game resolution. Do not repaint or procedurally draw
   any gull or human artwork.

   Skills: `imagegen`, `godot-prompter:assets-pipeline`.

2. **Layer peck feedback at the real contact point.** Extend
   `scripts/effects.gd` so texture particles can carry angle, spin, scale and
   lifetime. Add a restrained `peck_contact(...)` burst for accepted bag, bin,
   toddler and crab pecks. Ordinary hits get one contact mark plus 2-3 flecks;
   the release hit gets a slightly wider burst alongside the existing source
   rebound. Empty pecks retain their quiet hollow response and do not receive the
   full success burst. Trigger from the source that accepted the peck, not merely
   from the input press, so feedback never reports a false hit.

   Skills: `godot-prompter:particles-vfx`,
   `godot-prompter:animation-system`.

3. **Put snatch feedback on the catch frame.** Add `snatch_contact(...)` at the
   food/beak position inside the successful theft path. Fan the slash and flecks
   opposite the gull's motion, with a stronger gold accent for a stall-counter
   bonus. Move the existing snatch hit-stop/shake and snatch sound to this
   immediate contact; leave the score callout and point award at swallowing so
   digestion/scoring rules do not change. A glancing knockdown uses the existing
   crumble burst plus a smaller coral contact mark. Avoid a second impact when
   the food is swallowed.

   Skills: `godot-prompter:particles-vfx`,
   `godot-prompter:animation-system`.

4. **Tumble only the litter thrown from bins.** Give each garbage item a seeded
   starting angle and non-zero angular velocity when spawned. Advance its angle
   during the existing ballistic update, damp/reverse spin on an edge bounce,
   then stop it at a small stable resting angle on the sand. Draw the current
   wrapper/paper art in a local rotated transform. Leave edible scraps upright
   so they remain easy to identify and collect. This should stay in the current
   dictionary simulation; no physics-body conversion is needed.

   Skills: `godot-prompter:physics-system`,
   `godot-prompter:animation-system`.

5. **Expose restrained tuning and verify the result.** Put particle counts,
   contact lifetimes and litter spin range under `juice` tuning while preserving
   the existing `juice.particles` master switch. Add checks that accepted pecks
   emit the correct effect, misses/disabled particles do not, a successful
   snatch fires at contact only once, airborne litter changes rotation, landing
   stops it, and garbage remains inert/non-collectible. Capture fixed gameplay
   frames for a bag peck, direct dive snatch and bin burst, then run
   `tools/validate.ps1` and inspect the captures at 1x and zoomed.

   Skills: `godot-prompter:godot-testing`,
   `godot-prompter:godot-code-review`.

## Done when

- Ground pecks show a readable contact texture and small material-specific flecks.
- Direct snatches visibly pop on the catch frame, not only when food is swallowed.
- Stall-counter snatches are distinct but do not hide the bonus window or food.
- Every airborne bin-litter item visibly rotates and settles at a varied angle.
- Food physics, peck/snatch collision windows, scoring, digestion and bin contents
  are unchanged.
- Disabling `juice.particles` removes the new effects and all validation checks
  pass with no new failures.

## Implementation result

- Added six transparent, palette-limited runtime textures prepared from the
  preserved ImageGen source in `assets/reference/peck-snatch-vfx-v1/`.
- Added material-aware peck bursts and catch-frame snatch bursts to
  `scripts/effects.gd`; hit-stop, shake and sound now happen on contact, while
  swallowing still owns the score award and callout.
- Added seeded bin-litter rotation, edge-bounce spin damping and varied resting
  angles to `scripts/stash_raids.gd`. Cosmetic rotation uses a separate seeded
  RNG so it cannot change food trajectories or rival decisions.
- Added gameplay-scale review captures for a bag peck, two successive bin-tumble
  frames and a direct snatch under `assets/previews/`.
- Added `tests/vfx_polish_checks.gd` for texture contracts, accepted/rejected
  pecks, immediate single-fire snatch feedback, the particle master switch and
  the complete airborne-to-rest tumble lifecycle.
- Ran `tools/validate.ps1`: **13,930 checks, 0 failures**. The final Godot code
  review found no remaining critical or improvement items in this feature.
