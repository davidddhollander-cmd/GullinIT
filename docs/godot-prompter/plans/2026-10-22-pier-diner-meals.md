# Pier diner visible replacement meals

Authorised by: "now fix pier diner", following the identified automatic-refill gap.

Use the existing animated hotdog grill as the compatible cooked-fish source. This reuses the supplied/generated full-body cook and existing booth/counter rather than introducing a new vendor. No map, character artwork, scoring, food category or chase changes.

BeachTarget owns the diner meal phase (DINING / SEEK / RETURN) and fixed dining home. BeachRoutine keeps the original dining anchor and provides a long rest on returning. StallService owns the single fish portion through prepare -> stationary counter -> collection, using its existing interruption and food-ownership rules. The usual signals connect catches to digestion and score.

- [x] Add a no-refill path for empty-handed diners, with compatible-grill selection and real travel. Missing/busy grills leave the diner empty; reactions and dropped-food recovery retain priority.
  Skills: godot-prompter:state-machine, godot-prompter:ai-navigation.
- [x] Extend counter ordering to fried fish and return the diner to its fixed dining spot after receipt or recovery; keep the 0.85-second bonus window and match walking cadence to meal-trip speed.
  Skills: godot-prompter:animation-system, godot-prompter:gdscript-patterns.
- [x] Test actual travel, receipt, return, missing/busy source, counter theft/bonus, full capacity, loose-food conservation, interruptions and freeze/pause. Run existing service, routine and full integration checks, and inspect a rendered meal trip.
  Skills: godot-prompter:godot-testing, godot-prompter:godot-debugging.
