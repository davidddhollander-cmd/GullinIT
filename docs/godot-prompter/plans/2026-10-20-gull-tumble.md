# Gull impact tumble

Approved feel: quick arcade tumble, approximately 50–70 game pixels of travel,
1–2 spins, a small bounce, and control restored after about 0.9 seconds.

## Physics design (before asset generation)

Keep BeachGull's existing Node2D flight model and STUNNED state. A rigid body
conversion would conflict with its swept-beak collision and perch model.
STUNNED owns a short ballistic trajectory, independent of aim and flap input.

- All character attacks pass their world position to stun(). Launch horizontally
  away from that position, with a small upward impulse. Cancel dive/peck/perch
  state. An exactly aligned attacker uses opposite incoming motion/facing.
- Integrate gravity and horizontal drag in bounded substeps; bounce once on sand
  or promenade with reduced vertical and horizontal speed. Clamp world edges,
  removing outward velocity. Perches do not catch a tumbling gull.
- Rotate only the existing sprite around its body. Never rotate collision or UI.
  Use the existing folded/idle pose so the silhouette reads as a tumbling bird.
- Ease upright during the final 0.18 seconds, restore grounded/flight control and
  existing invulnerability. A subsequent protected hit cannot restart the tumble.
- Ground crashes share the tumble motion but retain their separate scoring event.

## Feather design

Generate a transparent raster feather atlas with small white, gray and dark-tipped
feathers matching the game's retro art. Preserve its complete generated source.
Crop the isolated feathers into small runtime textures; no code-painted artwork.
BeachGull emits feather requests at impact, once on bounce, and at brief intervals
early in the tumble. BeachGame connects requests from players and rivals to
BeachEffects. World-space feathers inherit some launch motion, flutter, fall
slowly, and fade; they respect the existing particles option and clean themselves up.

Scene ownership: BeachGame -> BeachGull -> existing AnimatedSprite2D;
BeachGame -> BeachEffects -> feather texture particles.

## Implementation and checks

1. Add impact trajectory, spin, bounded recovery and attacker positions.
   Skills: physics-system, gdscript-patterns.
2. Generate and integrate feather textures and world-space particle lifecycle.
   Skills: imagegen, particles-vfx.
3. Check direction, displacement, spin, bounce, recovery, protected hits,
   airborne/perch/edge impacts, rival and crash handling, particle cleanup and
   disabled effects. Run integration checks and render a visual preview.
   Skills: godot-code-review.

Completed: physics, generated feather assets, gameplay wiring, rendered preview,
858 focused checks and 14,575 integration checks (zero failures). Implementation
and tuning notes are in `docs/GULL_TUMBLE.md`.
