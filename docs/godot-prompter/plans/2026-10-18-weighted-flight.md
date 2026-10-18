# Weighted gull flight: assessment and edit plan

Date: 18 October 2026. Status: implemented with deliberately subtle values (gravity 75, stroke 36 px/s every 0.3 s, sink cap 45, wind gravity cut 30%, dive drag 0.55). Needs a rendered playtest; `tests/flight_dynamics_checks.gd` covers 30/60/120 Hz.

## Intended feel

The gull should gain modest height per wingbeat, lose upward momentum promptly after release, and need repeated wingbeats to remain airborne. Wind should extend a glide and slow a dive. Preserve responsive steering, held-button controls, intentional landing, and momentum through swoops.

Interpretation: holding FLAP produces repeated physical wingbeats. Tapping remains possible, but repeated manual clicking is not required. Wind provides an arcade soaring benefit in either horizontal direction; this is a gameplay rule rather than a full aerodynamic simulation.

## Assessment

| Finding | Evidence | Effect |
| --- | --- | --- |
| Flapping is continuous thrust | `scripts/gull.gd:274`; gravity 45 versus climb acceleration 260 | Holding flap gives 215 px/s² net upward acceleration, reaching the 90 px/s climb cap in about 0.42 seconds from rest. Animation wingbeats have no physical timing. |
| Weak gravity preserves climb momentum | `scripts/gull.gd:274-280` | Releasing at -90 px/s takes about two seconds to reach the apex if the ceiling does not interrupt it. |
| Passive descent is very slow | `data/tuning.json`; maximum descent 32 px/s | A 100-pixel descent takes at least 3.1 seconds, plus acceleration time from rest. |
| Wind only shifts position horizontally | `scripts/gull.gd:230,341` | Wind has no lift or dive braking, including during gusts. A straight-down dive has identical vertical motion in calm and wind. |
| Fast downward momentum is braked automatically | `scripts/gull.gd:277-278` | Returning to GLIDE above the descent cap uses climb acceleration as a brake even with flap released. Separate passive drag from active recovery. |
| Player and rivals share this model | `scripts/rival_gull.gd:24-71` | Changes need AI altitude checks, particularly the always-flapping retreat behavior. |

Movement is implemented manually on `BeachGull`, a Node2D, and called from `BeachGame._physics_process()`. Adding a mass field alone would have no effect. The useful changes are force balance, wingbeat timing, drag, and momentum handling within the existing model.

### Measured baseline

Ran an isolated headless Godot 4.7.2 probe against the current flight code at 30, 60, and 120 physics ticks per second. Neutral aim avoided the separate aim-to-land controller; there were no perch surfaces. Wind was initialized at its steady strength to isolate its effect.

| Scenario | Result |
| --- | --- |
| Hold flap from y=145, initially stationary | Reaches the y=20 ceiling in 1.60 seconds at all three rates. |
| Release from y=120 with upward velocity -45 px/s | Continues rising for 1.00 second, gains about 22 pixels, and lands after 3.10-3.12 seconds. |
| Same release with wind strengths 0, 0.65, and 1.04 | Identical rise and landing times. |
| Straight-down STRIKE from y=25 at speed 65 px/s | Hits after 0.78-0.80 seconds at about 257-261 px/s, identically across all three wind strengths. |

These are movement measurements, not a full-suite pass or a human playtest. The temporary probe reported resource cleanup warnings at shutdown; no movement errors were reported. The probe was removed after measurement.

## Recommended approach

Use timed wingbeats and explicit arcade forces in the current shared model. Tuning gravity alone would improve weight but leave held flap as continuous thrust. Replacing the actor with a RigidBody2D would introduce collision and control changes beyond this adjustment.

### 1. Add a physical wingbeat cycle and stronger gravity

Files: `scripts/gull.gd`, `data/tuning.json`, `tools/generate_assets.py`.

Skills: `godot-prompter:physics-system`, `godot-prompter:player-controller`, `godot-prompter:gdscript-patterns`.

- Replace continuous `climb_acceleration` during normal flight with a bounded lift stroke followed by a recovery period. Gravity acts throughout both phases.
- Holding starts the first stroke immediately and repeats at a fixed cadence. Keep the cadence in the shared gull so players and AI receive the same physics. Releasing and rapidly pressing again must not bypass the minimum stroke interval.
- Suggested starting range: gravity 120-150 px/s², passive descent limit 60-75 px/s, climb limit 50-60 px/s, stroke interval 0.30-0.36 seconds, and lift equivalent to roughly 45-55 px/s per stroke. Deliver lift over a short downstroke and tune its duration together with these values; they are starting ranges, not independently interchangeable settings.
- Select a combined configuration whose average lift at full cadence exceeds gravity modestly. Sparse strokes should lose height; sustained flapping should climb gradually.
- Give takeoff enough immediate clearance for sand and roofs. Account for its launch boost and first stroke together to avoid a double boost. Clear stroke state on landing, stun, and dive transitions; preserve cooldown against input exploits.
- Preserve dive-exit velocity and brake it smoothly. Use separate passive drag and active flap recovery, rather than applying powered braking automatically above `max_descent`.
- Mirror final defaults in the asset generator by editing its dictionaries; running the generator overwrites other curated project data.

### 2. Add bounded wind support during gliding

Files: `scripts/gull.gd`, `data/tuning.json`, `tools/generate_assets.py`.

Skills: `godot-prompter:physics-system`, `godot-prompter:math-essentials`.

- Derive wind support from the magnitude of the existing smoothly blended `wind_force`. Keep the current horizontal drift and gust scheduler.
- Reduce effective downward acceleration and increase descent drag as wind strengthens. Start with a maximum gravity reduction around 35-45%, then tune against actual level strengths (0.2-0.65; the strongest gust reaches 1.04).
- Keep a positive downward acceleration and sink rate even at the strongest configured gust. Wind alone must not create indefinite hovering or upward motion from rest.
- Distinguish passive soaring from intentional landing. The landing controller must still bring the gull to sand or a perch reliably in wind.
- Verify the lift transition through a reversing gust: using the signed force's magnitude creates a temporary lull as it crosses zero. Keep that behavior smooth and intentional.

### 3. Add wind drag to the dive speed calculation

Files: `scripts/gull.gd:307-310`, `data/tuning.json`, `tools/generate_assets.py`.

Skills: `godot-prompter:physics-system`, `godot-prompter:math-essentials`.

- Add a wind-strength-dependent, speed-dependent drag term to STRIKE acceleration, before integrating `dive_speed`. It must affect a vertical dive as well as diagonal dives.
- Start with a coefficient that reduces late-dive speed roughly 15-25% in strong steady wind, with more braking in a gust. Compare equal-height trajectories; do not infer braking from sideways displacement.
- Preserve downhill acceleration, existing uphill momentum expenditure, and smooth pull-up. Apply drag over time instead of snapping speed to a new wind-dependent cap.
- Continue deriving crash severity and warnings from actual downward impact speed. Wind may make some impacts survivable; do not compensate by silently lowering crash thresholds.

### 4. Match animation and rival behavior

Files: `scripts/gull.gd`, `scripts/rival_gull.gd`, and, if needed, `data/sprites.json`.

Skills: `godot-prompter:animation-system`, `godot-prompter:ai-navigation`.

- Synchronize the existing climb frames with the physical stroke cycle; the current six frames at 11 fps form a roughly 0.55-second loop. Avoid resetting animation every tick or tying physics to rendered frames.
- Let the shared model schedule AI wingbeats. Add an altitude dead band and vertical-speed awareness to cruise and retreat flap decisions so rivals can hold height without oscillating or climbing into the ceiling.
- Preserve the current mouse, keyboard, controller, and touch bindings. `scripts/input_controller.gd` already supplies a held request; edit it only if routing checks reveal a need.

### 5. Verify and document the new behavior

Files: new `tests/flight_dynamics_checks.gd`, `tests/integration.gd`, `tests/training_checks.gd`, `README.md`; review `docs/OPENING_LEVELS.md` if tutorial timing changes.

Skills: `godot-prompter:godot-testing`, `godot-prompter:godot-debugging`, `godot-prompter:godot-code-review`.

- Add deterministic trajectories at 30/60/120 Hz: one stroke, intermittent strokes, held strokes, release to apex, and passive descent. Compare equal start positions and velocities away from ceiling and ground clamps.
- Initial feel targets: a single airborne stroke gains roughly 5-12 pixels from rest; release from -45 px/s reaches its apex within 0.5 seconds in calm air; held takeoff requires several visible strokes to gain 80 pixels, targeting roughly 3-5 seconds.
- In wind, assert longer passive airborne time and lower equal-height dive impact speed than calm. At maximum gust strength, assert eventual descent without flapping. Check calm, both wind directions, ramp-up, lull/reversal, and ramp-down.
- Verify dive-to-flap recovery without velocity snaps, landing in wind, immediate takeoff from sand and all perch types, safe shallow impacts, dangerous steep impacts, and high-speed swept food collisions.
- Review existing `refinement_checks()` and `landing_aim_checks()`: some assertions encode the old slow coast or require landing descent to exceed the old passive descent cap. Replace those with the intended behavioral guarantees rather than preserving obsolete numeric relationships.
- Exercise rival cruising, retreat after stealing food, and all training lessons using real controls. Keep tutorial instructions compatible with held FLAP; adjust timing fixtures only where the new motion requires it.
- Run `tools/validate.ps1`, then a rendered playtest in calm and the strongest gust level. Judge weight, controllability, and wingbeat rhythm before selecting final constants. Avoid unrelated opening-level, menu, or scoring changes already present in the working tree.

## Implementation order

Establish calm-air weight and wingbeat rhythm first. Add wind soaring second, dive drag third, then tune visuals and AI and run the regression checks. This keeps each change measurable against the baseline above.
