# Gull kick and swat tumble

Character hits launch the existing gull sprite away from the attacker. The gull
travels roughly 65 pixels with 1–2 body turns, bounces once, eases upright, and
regains control after 0.9 seconds. Airborne birds resume flight; grounded birds
stand up. Aim, flapping and pecking cannot redirect the reaction. Repeated hits
cannot restart it, and the existing recovery invulnerability remains active.

All adult, stash-owner and toddler hits supply their position. Mugged rivals use
the player's position. Ground crashes use incoming horizontal movement and retain
their separate score penalty. Tumble motion ignores one-way perches, clears old
perch support, and clamps terrain, ceiling and world edges.

`data/tuning.json` -> `tumble` contains duration, launch speed/upward impulse,
gravity, drag, bounce, spin, recovery time, and feather shedding cadence. Explicit
stun durations (such as rival mugging) still apply. Ground contact is raised by
body size while spinning so the folded bird has clearance.

Feathers use four generated RGBA textures, preserving the complete source and
generation prompt in `assets/reference/gull-feathers-v1/`. `BeachGull` emits an
impact burst, pairs of feathers through the first half second, and a small bounce
burst. `BeachEffects` renders them in world space with inherited motion, flutter,
slow fall and a final fade. The existing particles setting controls emission.
Particle RNG is independent of gameplay RNG. The existing effects particle list
keeps this small, CPU-visible effect deterministic in tests without extra nodes.

## Review and validation

- Final validation: 858 focused checks and 14,575 integration checks passed with
  no failures. Rendered impact, mid-spin, bounce and recovered frames inspected.
- Focused scene: `res://tests/gull_tumble_checks.tscn`.
- Integration suite includes tumble checks and existing penalties/food dropping,
  crashes, adult reactions, perch movement, and rival simulations.
- Preview scene: `res://tools/gull_tumble_preview.tscn`; package its captures with
  `tools/package_gull_tumble_preview.py`.
- Animated result: `assets/archive/previews/gull-tumble-v1.gif`.
- Code review: typed calls, existing sprite-only rotation, signal-owned VFX,
  preloaded textures, bounded emission and cleanup, input lockout, and scoring
  callbacks checked. No character artwork was generated or painted for this change.
