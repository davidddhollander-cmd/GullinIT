# High landing spots

Implemented 10 October 2026. Uses the existing point-down landing control, with four surfaces per generated level: both stand awnings/roof edges, the lifeguard tower roof and the lamp top. No extra scenery added.

Use these high points to rest, look around and digest food.

## Controls and behaviour

- Aim at a nearby roof or pole top from above and release flap. A small marker appears on the reachable landing spot. The gull slows and lowers its feet as it approaches, reusing the deliberate downward landing control.
- Catch the surface only when descending slowly and feet-first within its actual width. Flying underneath or past a roof must not pull the gull onto it. Explicit diving takes priority over assisted landing.
- Roofs allow slow walking. Pole tops hold a standing pose. Walking off a roof returns to flight; flap takes off immediately. Starting a dive leaves the perch and resumes ordinary aiming.
- Perching gives the same faster digestion as resting on the ground. It does not award extra score or replenish food. Adults can stop chasing when the gull is out of reach, using the existing escape rules.
- A fast beak-first strike into a perch surface should use the existing crash penalty, with a clear impact reaction. No instant snapping from a fast dive into a safe rest.

## Implementation

`BeachGull.setup_perches` creates explicit horizontal surfaces from eligible props, aligned to their current art. The supported surface is tracked independently of sand. Standing, takeoff and digestion reuse the grounded state. Only the player receives these surfaces. They are one-way tops: upward approaches pass through, and intentional dives ignore the departure surface until clear. Slow nose-first contact and fast shallow contact bounce back into flight; fast beak-first impacts use the existing crash signal and score loss.

Rendered integration validation: **13,219 checks, zero failures**. Added checks cover roof and pole landing in wind at 30/60/120 Hz, feet height, walking off roof edges, steady pole stance, takeoff, dive departure, approaches from below, faster digestion and hard-impact score loss. Existing ground landing checks also pass. Stand feet alignment was inspected in `test-output/perching-stand-roof.png`. New prop artwork or scales require updating the surface offsets in `setup_perches`.
