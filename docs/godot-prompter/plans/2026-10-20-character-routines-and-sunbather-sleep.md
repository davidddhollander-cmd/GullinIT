# Character routines and sunbather sleep

Status: approved and implemented on 20 October 2026, including the follow-up
sleep letters and perfect-snatch chase. Rendered integration: 14,623 checks,
zero failures. Sleep and running-chase captures visually reviewed.

## Approved follow-up changes

- Sleeping sunbathers display a small drifting, fading `Zzz`, driven by the
  simulation clock so it freezes with gameplay. It disappears when waking starts.
- A perfect direct snatch from a shopper or pier diner, including a shopper's
  counter portion, commits them to a 2.2-second running pursuit, bounded to 120
  units from its start. High/distant escape no longer cancels that pursuit
  immediately. A 0.65-second angry give-up pause follows, then their routine
  resumes. Normal approach warnings and loose-food recovery retain their
  ordinary reaction paths.
- Dedicated yell/curse artwork is deferred as requested and tracked in
  `docs/CHARACTER_ANIMATION_TODO.md`. The current give-up uses existing angry art.
- Stand arrivals check actual nearby people, allowing a new buyer once previous
  customers have strolled away. Existing counter food and bonus timing remain.
- The opening tutorial keeps its authored short patrols; level 2 walks remain
  within its teaching areas. Later levels use the expanded role profiles.

## Intended feel

People should have a reason to move: buy a snack, stroll, stop to eat or look out
to sea, then choose somewhere else. The larger range should spread encounters
across the beach without emptying every food station at once. A sleeping
sunbather provides four safe bag pecks, followed by a clearly signalled transition
to a more watchful opponent.

These are the approved starting values, based on the current map scale. Rendered
checks confirm their behaviour; further subjective tuning can follow playtesting.

## Current behaviour found in the project

- The camera shows 320 logical world units across. Later maps are 1280 units wide.
- Most generated adults receive a patrol radius of 12 units. Authored shoppers
  use radii of 5-24 units, while the fallback is 35. Walk speed is 9 units/second
  before individual speed modifiers.
- Walking is a continuous left/right patrol. A successful stall purchase moves
  the shopper's patrol centre back beside that counter.
- Pier diners and dog owners do not normally stroll: their target types are not
  included in the normal walking branch, although walk animations are available.
- Lifeguards already patrol. Families have their own shopping/following routines.
- A bag raid starts a wake timer on the first peck. Additional pecks raise alert
  and shorten that timer. The general adult reaction can independently issue a
  warning on proximity or wake a sunbather when loose food is stolen.
- Bag progress resets after every three pecks. Each release scatters up to two
  snacks from a finite stock of three. A completed raid is deleted after settling.
  None of those temporary values can safely own a lifetime four-peck allowance.

## Movement proposal

### Approach options

1. **Recommended: destinations and pauses.** Small per-character routine state
   with a chosen destination, a pause, and a new destination. Supports believable
   eating stops, varied walk lengths and predictable interruption/resumption.
2. **Larger patrol radii only.** Smaller change, but people still turn at fixed
   endpoints and successful purchases still tether them to a stand.
3. **Full daily schedules.** Offers more simulation but adds unnecessary machinery
   for the current short rounds.

### Proposed ranges and timing

Distances below are maximum displacement from the named anchor, not extra
distance accumulated on every leg. All endpoints are clipped to valid ground,
level bounds and authored tutorial restrictions.

| Character | Proposed routine |
| --- | --- |
| Snack buyers and strolling shoppers | Common destinations 120-220 units from their purchase/stroll anchor, roughly half to two-thirds of a camera view. About one trip in five can reach 240-300 units on maps with room. After buying, leave the serving area before the next discretionary stop. |
| Pier diners | Eat or look out to sea for 6-12 seconds, then stroll to a destination 80-140 units from their dining anchor. Some destinations may extend up to 100 units onto the connected promenade, bounded by that same overall range. Return for another longer dining stop after one or two destinations. |
| Dog/owner encounter | Introduce a relaxed local stroll within 120-180 units of its promenade anchor, with 2-5 second stops using existing idle/bark art. |
| Lifeguard | Patrol within 100-160 units of the tower anchor, with 2-4 second lookout pauses and regular returns to the tower. |
| Picnic families and toddlers | Retain the picnic anchor, linked children and shopping trips. A toddler's local movement remains close to the parent; broader family travel continues through the existing group trip. |
| Vendors | Remain at their serving windows, because serving is their job. |
| Sunbathers | Remain at their towels during rest. Movement is for rising, retrieving scattered food, reacting and returning. |

- General strolling stops last 2-5 seconds; eating stops last 4-8 seconds.
- Retain current walk speed and individual modifiers for the first pass. At
  normal speed, a 120-220-unit walk takes about 13-24 seconds.
- Choose a destination at the end of a walk/pause, never every frame. Use the
  level's seeded random source so the initial routine can be reproduced.
- Mix initial pause phases and destinations. If all buyers leave a shared area,
  bias the next available shopper toward a stand; do not teleport anyone.
- Nearby stand service remains a temporary movement lock. Counter food still
  rests on the counter for the existing readable dive-snatch bonus window.
- Warning, chase, retrieval and family shopping interrupt strolling. After an
  interruption, resume or select a nearby valid destination rather than marching
  back to an old spawn point solely to restart a patrol.
- Keep each character's role anchor separate from the position at which a chase
  starts. Existing bounded chase distances need not increase with walking range.
- Keep level 1's lesson targets near their authored stations until their lesson
  is complete. In level 2, clip expanded walks to each teaching area. From level
  3 onward, allow the wider connected promenade/pier walks above.

## Sunbather proposal

### Exact four-peck rule

The first four **accepted pecks on that person's stocked bag** are protected.
The body stays asleep throughout pecks 1-4: no rising, warning, swat, chase,
proximity alert or retrieval. Bag squish, sound and normal snack release still
work. Collecting the food released on peck 3 also leaves the person asleep.

Immediately after peck 4 resolves, start a visible 0.7-second waking sequence.
Show a brief exclamation cue at its start. No attack lands during this sequence.
Peck 5 and subsequent disturbances receive the awake response; input during the
rise cannot cancel or restart it, or bypass its protection from an immediate hit.

Count successful bag hits, not button presses: cooldown-rejected, out-of-range,
bin, toddler and empty-bag pecks do not advance the count. Pausing the game
freezes the waking and reaction timers.

### Once awake

- Keep that sunbather awake for the rest of the round, including after retrieval
  and returning to the towel. Reclining is then watchful rest, not renewed sleep.
- Start reactions to another bag peck or successful bag-food theft after a
  0.25-second notice delay. A new peck must not keep resetting that delay.
- Restore normal close-approach warning behaviour, using a 0.3-second warning.
- Keep the existing visible 0.42-second bag swat windup and range check. For
  chase swats, keep at least a 0.4-second windup. Faster awareness must not remove
  the player's chance to escape.
- Keep existing retrieval speed, bounded chase, food ownership and hit rules.
- Keep sleep state separate from decaying alert: alert can calm down without
  granting four more protected pecks.
- Tutorial reaction multipliers may lengthen timings after the threshold; they
  must never reduce the four protected hits.

### Food balance

Keep the current three-peck snack-release rule. This gives a first release on
peck 3 while asleep, waking after peck 4, and a second release on peck 6 against
the now-awake owner if stock remains. The protection count and release-progress
count are independent. Retrieving food does not reset either the person's wake
history or create extra food.

### State and ownership design

Existing scene structure remains sufficient:

```text
Game
├── BeachTarget (each person)
│   ├── character sprite
│   └── held-food sprite
├── BeachStashRaids (bag interactions and loose food)
└── StallService (purchase coordination)
```

| Owner | Responsibility |
| --- | --- |
| BeachTarget | Routine anchor, destination, move/pause phase; sunbather disturbance total and SLEEPING/WAKING/AWAKE state with waking timer. |
| AdultReaction | Warning/chase/return actions, gated by the sunbather's shared sleep state. Return to a sensible routine position. |
| BeachStashRaids | Accepted bag hits, burst progress and finite snack retrieval; respects the same sleep state rather than a separate authoritative wake timer. |
| StallService | Temporary service lock and real food handoff; releases shopper to the wider routine after service. |
| BeachLevelGenerator / level data | Per-role movement profiles, anchors, valid connected areas and tutorial restrictions. |

Data flow:

1. Valid bag peck -> advance release progress and the owner's disturbance count.
2. Release threshold -> scatter real stock as today, independently of sleep.
3. Fourth accepted hit completes -> owner enters WAKING and starts its cue/timer.
4. Waking timer completes -> owner enters AWAKE; retrieval/reaction may proceed.
5. Later proximity, peck or theft -> existing reaction path with the awake delays.
6. Return/settle -> retain AWAKE and resume watchful rest or a walking routine.

Existing snatched, departed, bag_collected and collection signals keep their
current purposes. The peck path can notify the owner directly; no new global
event bus is required. Round restart/new spawn restores sleeping state; training
bag restocking alone does not reset it.

## Implementation

- [x] Add destination/pause routine state and role-specific movement profiles.
  Skills: godot-prompter:state-machine, godot-prompter:ai-navigation,
  godot-prompter:gdscript-patterns.
- [x] Integrate routine interruption/resumption with service, reactions, food
  retrieval and existing family behaviour; preserve counter service timing.
  Skills: godot-prompter:state-machine, godot-prompter:animation-system.
- [x] Add per-person sleep/waking/awake state and accepted-peck count. Gate every
  proximity, theft and retrieval entry point on that state; retire competing
  automatic wake ownership in raids.
  Skills: godot-prompter:state-machine, godot-prompter:gdscript-patterns.
- [x] Reuse existing rest/rise/alert/walk animations and food anchors. Any missing
  character artwork must come from supplied art or built-in image generation;
  never draw character anatomy with code. Preserve generated source artwork.
  Skills: godot-prompter:animation-system, godot-prompter:assets-pipeline.
- [x] Add focused behavioural checks and run relevant existing suites; visually
  playtest a later map and the tutorial before tuning the proposed ranges.
  Skills: godot-prompter:godot-testing, godot-prompter:godot-debugging.

## Acceptance checks

- Buyers can travel at least 120 units from a stand where the map permits it;
  completed purchases no longer force immediate short patrols beside the counter.
- Pier diners visibly alternate stops and walks, including a valid promenade
  excursion. Walk/food art faces the correct direction without endpoint flicker.
- World edges, lesson bounds, family cohesion and stall access remain valid.
- Pause, reactions, retrieval and service resume without teleporting, duplicated
  orders or abandoned movement locks. Crowds retain readable spacing.
- Stand portions remain stationary and collectable during the counter bonus
  window. Vendors remain full-body adult-scale assets masked by their stalls.
- Each of pecks 1, 2, 3 and 4 has no body reaction or attack, including with long
  gaps between hits. Nearby gulls and first-burst food theft cannot bypass sleep.
- Fourth hit starts exactly one waking sequence after resolving. A fifth hit
  during that sequence cannot cause an early swat or restart the timer.
- The next disturbance while fully awake responds faster, with a visible attack
  windup and a fresh range check before any hit.
- Two different sunbathers track independent counts. Settling, calming down,
  raid deletion, recovered food and training restocking cannot reset immunity.
- Bag burst counts and finite food stock remain correct; failed pecks and other
  interactables do not affect wake progress. Restart resets both people and food.
- Pausing freezes routine, waking and reaction clocks; large simulation steps
  cannot skip directly from a sleeping protected hit to an unannounced impact.
