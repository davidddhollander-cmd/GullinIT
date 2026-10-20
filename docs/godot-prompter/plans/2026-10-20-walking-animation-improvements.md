# Walking animation assessment and proposed improvement

**Superseded by user review, 20 October 2026.** The existing original shopper walks well and must be the reference. The cutout pilot was rejected. The earlier system-wide diagnosis and proposed driver/cast changes below are not the active plan. See `docs/SHOPPER_WALK_REASSESSMENT.md`: concentrate on the older woman and stocky mullet shopper's six drawn walking poses, preserving the established animation method and original shopper.

Assessment date: 20 October 2026. Scope: assess and propose; production artwork, movement and animation code are unchanged by this assessment.

## Findings

The main limitation is the pose sequence, compounded by fixed playback timing and a few movement-state overrides.

The playback probe called the normal `update_art_pose(true)` selection every frame for 1.8 seconds. All eight tested setups advanced through every available walk frame: the three shoppers and Mum each reached all six; lifeguard, diner, toddler and dog owner each reached all four. This rules out a general problem where repeated animation selection continually restarts walking. The sunbather's timer-driven movement was inspected separately in code, rather than included in this playback probe.

The source sheets and actual production frames show several sequences repeating similar contact/passing positions without a clear opposing-leg contact halfway through. Small changes to arms, clothing and head position make frames distinct but do not establish alternating weight-bearing legs. The toddler and dog owner have especially little lower-body change. The six-frame shopper/Mum sequences also need a stronger complete stride. See the diagnostic frame sheet in `test-output/walk-art-audit.png`: rows are original shopper, mullet shopper, sundress shopper, Mum, male sunbather, lifeguard, diner, toddler and dog owner. The dog row uses nearest-neighbour reduction for inspection; its actual runtime filtering differs.

| Group | Current walk clip | Proposed priority |
| --- | --- | --- |
| Three shoppers | 6 frames, 8 fps | First: frequent, prominent walking characters |
| Toddler | 4 frames, 6 fps | First: very weak visible foot alternation |
| Dog owner | 4 frames, 7 fps | First: weak movement plus stationary reaction overrides |
| Mum / sunbathers | 6-frame walks at 10 fps; sunbathers also use a manually advanced 7-frame run | Second: improve contacts, carrying and retrieval consistency |
| Lifeguard / diner | 4-frame walks, 8 / 7 fps | Second: complete stride and state consistency |

Playback is independent of distance travelled. Ordinary patrols travel at 9 logical pixels/second, kiosk trips at 20, and adult chases commonly at 45. A shopper's six-frame, 8-fps loop repeats every 0.75 seconds, so a patrol covers only 6.75 pixels per loop. The same cadence at different movement speeds contributes to sliding or shuffling.

Two additional cases were reproduced: a moving, recovering diner selects `angry`, and a moving, highly alerted dog owner selects `bark`. Those stationary reaction clips can replace locomotion while position continues changing.

The preparation pipeline also tight-crops, recentres and normalises individual adult poses to a common height. This can suppress authored bounce and shift the torso when limb extents change. A consistent body origin is preferable to recentering every silhouette independently. This is a likely contributor, rather than a measured explanation for every character.

## Proposed implementation

1. **Produce one eight-frame shopper pilot using ImageGen.** Use the existing character as the identity/style reference. Require near-leg contact, down, passing, up, opposite-leg contact, down, passing and up. Both knees and feet must visibly change; the opposite contact must reverse the supporting leg. Keep an appropriate separate-food carrying hand. Show a looping preview both standing in place and travelling at the actual patrol/trip speeds.
2. **Fix frame preparation and anchors.** Keep one scale, torso/hip origin and ground reference throughout the cycle. Preserve intentional vertical motion. Do not shift or stretch each frame to fit its own bounds. Recalculate the separate food hand anchors and check both directions. Runtime assets retain complete generated characters and the existing gameplay size.
3. **Drive step phase from simulation travel.** Accumulate distance before crowd-lane visual offsets are added, then advance the gait using an authored stride length. Stop on a planted frame when movement stops; preserve phase through direction changes and freeze during pause/hitstop. Evaluate whether the very slow 9-pixel/second patrol needs a shorter-stride stroll alongside the normal walk. Keep movement speeds and AI tuning intact during this pass.
4. **Resolve moving reactions.** Use moving angry/carrying variants where needed, or deliberately plant the actor during a stationary gesture. Audit diner recovery, dog-owner barking, swat anticipation, departures, family trips, dropped-food retrieval and service queues. Distinct running cycles need longer strides and clear passing/flight poses.
5. **Roll out and validate.** Apply the approved pilot method to shoppers, toddler and dog owner first, then Mum, sunbathers, lifeguard and diner. Vendors retain their stationary service poses. Existing artwork remains as a fallback until each replacement passes review.

## Acceptance criteria

- At gameplay size, a viewer can identify which foot supports the body in each half of the cycle.
- The swing foot lifts and passes the planted leg; the next contact uses the opposite leg.
- A planted foot stays approximately fixed against the ground during travel, with a practical target of at most one logical pixel of drift over its contact interval.
- Character scale and identity remain stable. Food tracks the visible hand and remains stealable at that position.
- Both directions, slow patrols, kiosk trips, chase, retrieval, start/stop and crowd-lane transitions work visibly. Rear walkers continue to pass behind the stalls.
- Automated checks cover frame progression, movement-state selection, pause/stop and anchor stability. Lower-body changes supplement existing whole-image uniqueness checks; motion previews remain the deciding visual check.

Keep `AnimatedSprite2D` for this sprite-based work. A more complex animation graph would not supply the missing leg poses. Character bodies and limbs must continue to come from generated or user-supplied artwork, as required by the project `AGENTS.md`.

## Audit evidence

- `test-output/walk-playback-audit.log`: complete frame progression and the two reproduced stationary-pose overrides.
- `test-output/walk-art-audit.png`: production walk frames arranged for comparison.
- `scripts/shopper_art.gd`, `scripts/mum_art.gd`, `scripts/pier_diner_art.gd`, `scripts/beachgoer_art.gd`: clip selection.
- `scripts/adult_reaction.gd`, `scripts/stash_raids.gd`: manual sunbather locomotion timing.
- `tools/diner_adult_atlas_source.gd`: per-pose cropping, scale and alignment.
