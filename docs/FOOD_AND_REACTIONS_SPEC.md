# Food and reactions — agreed specification

Status: implemented; validation details recorded in the continuation handoff.

## Food size

Food should be only very slightly oversized relative to people. Revise the current oversized food art display sizes while keeping snacks readable and pickup positions aligned with hands.

## Food queue and eating

- Capacity: four spaces. Small snacks occupy one, medium two, large four.
- Multiple small snacks can be collected consecutively, subject to capacity. Medium snacks share that same capacity budget.
- A large snack can only be collected with an empty stomach/queue. It prevents further food collection until its eating and digestion stages finish.
- Snacks that cannot fit stay at their source; no theft or score is registered for a rejected pickup.
- Eating is automatic, in pickup order. Only the first queued snack is processed at a time.
- Base eating times while flying: small 0.5 seconds, medium 1.5 seconds, large 3 seconds.
- After a large snack is swallowed, a further 2-second digestion pause blocks new collection. Small and medium snacks have no additional digestion pause in this first specification.
- Eating and digestion both run twice as fast when grounded or perched. Switching between flight and rest changes the processing rate without resetting progress.
- Points are awarded once, on swallowing, rather than on pickup. A large meal scores when swallowed, before its additional digestion pause ends.
- Display snack icons in queue order and progress through them consecutively in a small bar near the gull. Show the large-meal digestion stage distinctly after its snack has been swallowed.
- Show the current snack carried by the gull while it is being eaten.

## Swat consequences

- A successful swat briefly stuns the gull and deducts a fixed 5 points, clamped at zero.
- Only the snack currently being eaten is dropped. Its eating progress is lost.
- Dropped food can be recovered. Remaining queued snacks and already-swallowed food are preserved.
- If the queue is empty, including during post-swallow digestion, there is no current snack to drop; the stun and fixed penalty still apply.
- One successful hit must produce one penalty and at most one dropped snack, respecting existing invulnerability protection.

## Toddler reaction

- Theft is the trigger; close approaches alone do not trigger crying and running.
- Cry while running toward mum, rather than standing still to cry before starting.
- Retain the existing acceleration and family replacement/shopping mechanisms unless later tuning requires changes.

## Adult reaction

- First close approach: warning/swipe.
- A second distinct close approach within approximately five seconds: short chase.
- Actual theft: immediate chase reaction, with sunbathers retaining their slower wake-up response.
- Chase lasts roughly three seconds and remains near the adult's original spot.
- Give up when the gull flies beyond reach, then walk back to the original spot.
- Sunbathers respond more slowly than other adults.
- Preserve the existing caution-fades-over-time behaviour.

## Implementation details to resolve consistently

These are engineering/tuning details, not additional user-approved mechanics: use a leave-and-reenter condition so hovering does not count as repeated approaches; select approach radius, safe height, chase distance and stun duration through playtesting. Define how mum chasing temporarily yields to existing family travel, and how sunbather chasing yields to stash retrieval. Preserve finite food ownership when an item moves from a person/bag to the gull queue or ground. Carry any applicable theft bonus information to the swallow award without awarding points twice. Existing ground-crash penalties remain separate from swat penalties.

Implemented starting values: close approach within 38 horizontal units below y=105, reset after moving beyond 52 units or above y=95; warning window 5 seconds; warning delay 0.35 seconds (sunbathers 0.8); chase maximum 3 seconds/80 units from its starting point; escape above y=100 or beyond 85 units; adults move at 45 units/second, sunbathers at 30. Swats check range again after a 0.4-second chase windup and use existing stun duration/invulnerability. Chasing temporarily pauses family travel; children wait or seek mum, and handovers wait until her reaction ends. Sunbather stash retrieval resumes after the chase without a second wake delay. The first warning swipe can hit a gull that stays within reach.

Implementation: `GullDigestion` owns ordered capacity and processing; `AdultReaction` owns approach entries, warnings, bounded chase and return. The player uses digestion for held snacks, ground scraps, bag/bin food, recovered food and rival mugging. Rival theft retains its existing carrying window but now preserves food identity so mugging uses the correct category. Grounded is the game's current resting/perched state; this change does not introduce new perch geometry.

Food dimensions are reduced in `data/foods.json`, including an 8×4 hot dog and 4×7 ice cream, with matching pickup bounds. The HUD draws queued icons, current eating progress, large-meal digestion progress and the carried snack. Toddlers use moving leg frames with animated tears while seeking mum; no new raster assets were generated.

Existing source/collision regression fixtures explicitly advance digestion before checking awards. Separate digestion tests check real delays, capacities, landing speed changes and loss/recovery without that helper. Level completion does not award unfinished snacks; retry starts with an empty queue. The camera's far limit also now follows world width, correcting the old 800-unit limit on the extended beach.

## Suggested implementation order

1. Correct food sizes; implement capacity, ordered eating, grounded speed boost, large-meal digestion and the icon progress bar.
2. Route scoring through swallowing; implement current-snack drops and fixed swat penalties, including recovery without duplication.
3. Implement crying while running, distinct-approach warnings and bounded adult chases, then test alongside family shopping and stash retrieval.

## Acceptance checks

- Four small snacks fit; a fifth remains available. Two medium snacks fit.
- A large snack cannot be added to a nonempty queue; no new snack can be collected during its eating/digestion lock.
- Snacks process strictly in order, with correct timings and a continuous rate change when landing/taking off.
- Swallowing awards once. A hit before swallowing awards nothing for that snack and drops only it, resetting its progress.
- Recovering a dropped snack neither duplicates it nor restores lost eating progress.
- A hit without carried food still deducts 5 points at most once and never makes the score negative.
- Toddler theft produces simultaneous crying and running, with no close-dive false trigger.
- Hovering counts as one approach. Reentry within the warning window can provoke a chase.
- Chases end on timeout, distance/height escape, and return adults home without disrupting finite supplies or family ownership.
