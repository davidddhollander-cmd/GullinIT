# Crab habitat and retreat

Authorised: implement the reviewed crab rules; no pinching.

Scene structure stays BeachGame -> CrabPopulation -> BeachCrab -> supplied-art AnimatedSprite2D. Population owns legal sandy intervals, crowd clearance and arrivals. Each crab owns fixed home bounds, persistent lane, calm/notice/escape/settle activity and retreat. Existing snatched/departed signals retain food and score ownership.

- [x] Bound arrivals to each level's beach and connected quiet pockets, respecting live people, family/towel anchors and service areas. Delay unavailable arrivals. Wire people/gulls into population without sharing their RNG.
  Skills: godot-prompter:ai-navigation, godot-prompter:gdscript-patterns.
- [x] Add local 40–60-unit walking radii, pauses, rear-lane preference, notice and bounded escape, and short sea retreat. Match supplied sprite scale, feet and collision position to actual depth. Preserve catches, capacity, score, clocks and no attacks.
  Skills: godot-prompter:state-machine, godot-prompter:animation-system.
- [x] Extend crab checks for habitat, crowd changes, lane occupancy, boundaries, misses, catch geometry and determinism; run focused/integration suites and inspect rendered lane/retreat frames.
  Skills: godot-prompter:godot-testing, godot-prompter:godot-debugging.
