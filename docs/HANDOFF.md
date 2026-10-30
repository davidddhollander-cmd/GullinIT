# Continuation handoff — 2026-10-04

## Perching implemented — 10 October 2026

Existing point-down landing now supports both food stand tops, the tower roof and lamp top. Small landing marker, gentle slowdown, grounded digestion, roof walking/edge departure, fixed pole stance and immediate flap takeoff are connected. Diving releases the departure surface; hard beak-first roof impacts emit the existing crash/zero-score signal. One-way surface crossing prevents catching from below. See `PERCHING_PROPOSAL.md` (now implementation notes). Rendered validation: **13,219 checks, zero failures**, with wind landings and impacts at 30/60/120 Hz. Stand feet alignment capture reviewed.

## Quieter layouts and perch proposal — 10 October 2026

Reduced all playable levels from four toddlers to two (one per mum), and three sunbathers to two. Family centres are 150 units apart, with 44 units between each child and mum. Layout rules version 2 filters surplus authored characters before placement. Sibling behaviour remains tested using explicit fixtures, independent of the playable population. Rendered validation: **13,186 checks, zero failures**, covering 120 layouts; family-bay capture visually reviewed. Both food stands remain. See `PERCHING_PROPOSAL.md` for the proposed roof/pole landing controls and implementation outline; perching is not implemented yet.

## Logical level generation — 10 October 2026

Implemented a seeded runtime generator for all six levels: sunbathers 0–330, family bay 330–640, promenade 640–960 and pier dining 960–1280. Core food opportunities are distributed across the route, with both stands on the promenade. Families retain their links and shop at the generated ice-cream stand. Small position changes, alternating stand order and sparse scenery provide repeatable variety. Patrols stay local; arriving customers respect occupied positions and reserved homes even during chases.

Tune `data/level_layout.json`; runtime generation in `scripts/level_generator.gd` supersedes older source placement from `tools/expand_beach.py`. See `LEVEL_GENERATOR.md`. Rendered validation: **16,436 checks, zero failures**, including 120 layouts and 24 section captures. Resolved layouts are saved in `test-output/generated-levels.json`. Timers and score targets remain unchanged; next playtest should assess travel time and food depletion. Existing remaining-art tasks still apply. Picnic-bag refills remain cancelled.

## Food digestion and bounded reactions — 9 October 2026

Implemented the interviewed spec in `FOOD_AND_REACTIONS_SPEC.md`. Food display/pickup sizes now match slightly oversized hand-held portions. Player stomach capacity is four spaces (small 1, medium 2, large 4), processing in order at 0.5/1.5/3 seconds, twice as fast grounded. Large meals require an empty queue and lock pickups for a further 2 seconds after swallowing. Points and existing bonus metadata are awarded on swallowing; scraps retain their low-value/no-combo treatment. The HUD shows ordered snack icons, eating progress, digestion and the snack at the beak.

Successful swats stun, subtract 5 points clamped at zero, and scatter only the current unscored snack with its progress reset. Recovery uses the normal 0.3-second scatter pickup grace and preserves score metadata without duplicating ownership. Remaining queued snacks survive. Rival mugging now preserves original food identity/category. Pause, restart and end-of-level processing respect the queue.

`AdultReaction` handles first-entry warning, second entry within five seconds, immediate theft chase, slower sunbather waking, three-second/80-unit chase bounds and return to the interruption point. Hovering uses separate entry/exit radii. A safe-height escape ends pursuit. Actual impact rechecks reach and uses existing invulnerability. Adults no longer permanently leave after two thefts. Family trips yield during mum reactions, handovers wait, and sunbather retrieval resumes afterward. Toddlers run immediately with moving legs and drawn tears instead of a stationary crying delay. Existing art supplies the reactions; remaining placeholder actors still need the planned art pass.

Rendered and final headless validation: **1,231 checks, zero failures**. New tests cover queue timing at 30/60/120 Hz, mixed capacity, grounded speed, digestion lock, actual swat/drop/recovery, pause/restart, warnings, reentry, timeout and high escape. Source-only legacy fixtures explicitly advance eating; new digestion tests do not. Capture references: `digestion-snack-queue`, `digestion-large-meal`, `polished-customer-and-dog`, and toddler running captures. Queue and corrected food sizes visually inspected. Camera far limit now follows the extended map width. Final headless validation also covers the brief warning-swat follow-through.

## Customer and dog-owner art — 9 October 2026

Replaced kiosk-customer and dog-owner placeholders with two generated eight-pose transparent sheets, including the small terrier and leash. `BeachgoerArt` handles walk, idle, alert, upset and dog barking; food stays separate and mirrors with frame-specific hand anchors. Customers pause for 0.5 seconds after first theft to react, then walk again; departure takes precedence. Existing dog detection/danger rules remain. See `BEACHGOER_ART.md` for source paths, full built-in generation prompts, mapping, captures and limitations. Rendered validation: **1,166 checks, zero failures**. Next character batch: pier diners, lifeguard, seafood vendor.

## Longer beach and supplied scenery — 9 October 2026

All six maps now use 1280 width: sand 0–640, promenade 640–960, pier 960–1280. User sheet saved as `beach-props.png`, cropped through atlas metadata for scenery and interactive bins/tower. Ice-cream kiosk stays at 520; hot-dog stand added at 740 with a stealable hot-dog customer. Later periodic customers select either stand. Family links, new map marker, arrivals and beach bounds follow layout. See `BEACH_MAP.md` and `tools/expand_beach.py`. Rendered validation: **1,113 checks, zero failures**. Both stand captures visually reviewed. Longer-route timing/balance awaits player feedback.

## Mum animations — 8 October 2026

Added a new generated 16-pose mum sheet with walking, carrying, handover, shield, alert and swat animations. `MumArt` selects poses from existing family/defense actions and aligns the separate stealable snack, including mirroring and lowered handover frames. Stationary family trip states no longer restart walking. Uses aligned atlas frames, 0.13 scale, linear mipmapped filtering and the existing alpha-cutout shader. One mum appearance currently serves all families. Source, prompt and mapping documented in `MUM_ART.md`. Rendered validation: **981 checks, zero failures**, with carrying and handover captures visually inspected. Next: polish remaining sunbather towel edges/action art, then remaining beachgoer sheets. Picnic refill remains cancelled.

## Reaction animations — 7 October 2026

Implemented with two Luna agents, then reviewed and corrected in the parent session. Sunbather raid actions now include a 0.34-second pickup bend, 0.42-second swat warning with range checked at impact, 0.14-second follow-through and 0.42-second settling at home. Food stays available during bending; if the gull steals it, the owner cannot also regain it. A new peck interrupts settling. Existing rise/run frames supply the crouch, raised arms, forward swing and return sequence; these are adapted poses, not newly drawn swat frames. Moved rise frames use a frame-local towel colour mask; original resting towels remain at home and separate towels render during pursuit.

Toddlers pause to cry for 0.6 seconds after theft, then accelerate at 55 px/s² to 42 px/s toward mum. The reaction is bounded and yields back to existing family following/handovers, preserving stock and sibling trips. World tuning keys are `toddler_cry_duration`, `toddler_run_speed`, `toddler_run_acceleration`, mirrored in generator defaults. Current sizes and crisp rendering retained.

Rendered validation: **935 checks, zero failures**. Includes cry/run at 30/60/120 Hz, existing family loops, theft during pickup, delayed swat hit/escape, finite retrieval and return settlement. Captures include `sunbather-bending`, `sunbather-settling`, `sunbather-swat-warning`, `sunbather-swat-impact`, `toddler-crying`, `toddler-running-to-mum`, and `female-sunbathers-bending` in `test-output`. Picnic-bag refill trips remain cancelled.

## Female sunbathers and sizing — 6 October 2026

Added the user's female PNG sheet with both colours and seven rise/run frames each, alongside male variants. Explicit `appearance` in all six level definitions selects variants, mirrored in generator defaults. All adults enlarged 10%, with resolution-normalized female scale and larger stationary towels. Toddlers reduced 30%; their food anchors follow the new hand positions. Existing crisp canvas rendering remains. No source raster edits or new gameplay rules. See `SUNBATHER_ART.md`. Rendered validation: **889 checks, zero failures**; resting, rising and running captures reviewed.

## Toddler rendering quality — 6 October 2026

Sol implemented a rendering-quality pass after the user reported coarse sprites. `project.godot` now uses `canvas_items` stretch: gameplay coordinates remain 320×180, but drawing occurs at the window resolution (1280×720 in validation). This is a game-wide rendering change and preserves more source detail in other characters/food too. Only the toddler overrides nearest filtering with `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`; mipmaps are enabled in `toddler_polished.png.import`. The existing cutout shader remains. No source art, character size, movement, collision or sunbather animation changes.

Parent inspected the unobstructed before/after captures at `test-output/toddler-render-quality-before.png` and `test-output/toddler-render-quality.png`: face, hat, limbs and clothing are substantially clearer at unchanged size. Rendered validation: **844 checks, zero failures**, including existing UI/input checks and added filter/mipmap checks. This is automated validation, not a physical-device playtest. Rendering more pixels may cost more GPU time on lower-powered devices; no performance measurements were taken.

## Supplied sunbather animation sheet — 6 October 2026

Integrated the user's selected JPEG unchanged as `assets/archive/sprites/sunbather-user-sheet.jpg`. `scripts/sunbather_art.gd` defines atlas regions for both colour variations, resting, seven getting-up poses and seven running poses. A black-key shader hides the JPEG background. Wake countdown controls rising; movement controls running and facing. The old drawn standing person is removed; towels remain anchored at home during pursuit. No new food mechanics or refill trips. See `SUNBATHER_ART.md` for limitations and mapping. Rendered validation: **842 checks, zero failures**; rest/wake/run captures visually inspected.

## Beach placement, faster retrieval and peckable bins — 5 October 2026

Sunbathers retrieve scattered snacks at 40 px/s (previously 24). All six levels place sunbathers on sand; setup clamps their home positions to x24..300, keeping towels and bags before the promenade at x320. Their scattered snacks remain within x24..308 so pursuit also stays on sand. Beach bins now sit at x305.

Bins use the existing grounded E / controller X / touch PECK action. Four taps release three objects from a finite nine-object supply. The repeating mix contains mostly crumbs, plus code-drawn wrappers and paper. Crumbs have the same per-item 0.3-second pickup protection as bag food, use the 2-point scrap award path, and do not build combos or practice progress. Garbage cannot be eaten or scored; it remains until retry/level cleanup. Bin state is per game instance. Tuning and level defaults are mirrored in the asset generator.

Delegated implementation to Sol; parent completed review and validation after the agent reached its usage limit. Rendered Godot validation: **838 checks, zero failures**. Coverage includes six-level placement, faster owner movement, beach bounds, bin taps, scatter protection, inert garbage, crumb scoring, finite exhaustion, and reset. Capture `test-output/bin-peck-scatter.png` shows actual flight at 0.25 seconds, before collection is allowed. This was automated engine validation, not a manual device playtest.

## Sunbather picnic-bag-only adjustment — 5 October 2026

Sunbathers no longer hold exposed food. Their full three-item supply begins in a larger code-drawn picnic duffle beside their feet, with handle, straps, zip and stock markers. Its position stays fixed when the owner retrieves scattered snacks. Pecking is the only release path; automatic reach/replenishment logic and its obsolete tuning key are removed. Direct held-food theft is rejected for sunbathers. Food scattered by pecking remains catchable/retrievable as before.

This supersedes the earlier walk-up snack and finite held-snack behavior recorded below. Dive collision regression tests now use a kiosk customer, which still carries food; sunbather checks cover sealed full stock, no automatic release, no direct pickup and fresh sealed stock on retry. Rendered validation: **786 checks, zero failures**; obsolete exposed-snack expectations were replaced. Capture: `test-output/sunbather-picnic-bag.png`.

## Pass-progress HUD and stash raids — 5 October 2026

Added the right-side NEXT LEVEL score bar against the first star's score. It uses earned points, excluding the pending clean bonus. Level six uses FINAL GOAL; Practice uses its snatch target.

`scripts/stash_raids.gd` manages tap-to-peck stash interaction, finite random bursts, airborne/ground pickups, sunbather wake delay and swats, ground-food retrieval, and returning to the stationary stash. Controls: E / controller X / PECK touch button. Three taps release up to two reserve items, with an anti-repeat recovery; keyboard echoes do not count. Pickup uses relative swept motion for airborne snacks and grounded beak reach on sand. Player collection wins a simultaneous claim and awards normal stolen-food scoring exactly once. Owners recover only their own grounded items, restoring stock without a disappearance timer. Ambient scraps are unchanged. Existing caution controls wake time; owner movement/standing art is a first code-drawn placeholder.

Rendered validation passes **796 checks, zero failures**. New regression checks exercise peck range/state, key repeat, finite debit, opposite scatter directions, faster reaction, owner retrieval and return, air/ground scoring once, stash depletion, swats, touch peck, pause and retry cleanup. Captures: `stash-scatter.png`, `stash-retrieval.png`, and `aim-to-land.png` with the new HUD. Non-family kiosk restocking and fast rear shield breakthrough remain next; no automatic stash refill was added.

## Aim-to-land flight adjustment

Releasing flap and aiming down within a narrow corridor under the airborne gull now requests a gentle landing. Horizontal steering brakes toward the aim point and compensates for the normal wind push; descent accelerates smoothly up to 70 px/s, then slows near the sand. Flap overrides this immediately, and explicit dive remains the separate risky swoop. Passive gliding and walking keep their previous rules. The overlay shows a LANDING hint and marker. Eight `flight.landing_*` tuning values are mirrored in generator defaults.

Rendered validation passes **770 checks, zero failures**. New checks cover 30/60/120 Hz landing timing, momentum braking, bounded descent, flap override and takeoff, diagonal-aim exclusion, dive priority, wind correction and score preservation. The shared wind-drift fixture now uses neutral aim to avoid intentionally engaging landing steering. See `test-output/aim-to-land.png` for the rendered cue.

## Family kiosk trips

Mums now own a visible trip state flow: gather, walk to kiosk, buy, return, retreat and cooldown. A depleted request or deterministic ice-cream insistence gathers every valid linked child. The stand position comes from each level's real `kiosk` prop (all six currently use x=520). The stand supplies only missing children, preserves food already held by siblings, and tops mum to exactly two crisps inclusive of the held bag. Cookie reserves remain finite and are not magically restored.

Purchased child food and mum's carried bag use the existing `BeachTarget.food` and `food_sprite`, so normal swept collision can steal them. Only food tagged as bought on the active return aborts that attempt. A failed attempt retreats within the level, offers remaining crisp/cookie fallback, then observes the editable retry delay. Successful return clears tags. Family cohesion gates buying, return completion and fallback; followers move faster than mum and concurrent requests share the one mum-owned state.

New integration coverage exercises one- and two-child families, actual stand arrival, sibling food preservation, exact inventory/debit, swept theft of carried purchase, retreat/fallback cooldown, no immediate loop, travelling defenses, mirrored food/pickup alignment and purchase-tag cleanup. The final rendered Godot run passes **749 checks, zero failures**. Inspected captures are `family-gathering.png`, `family-kiosk.png`, `family-return.png`, and `family-retreat.png`. Human playtesting is still needed for the 22% insistence frequency and trip pacing. Stash pecking/scatter/retrieval, non-family purchases, caution escalation and fast rear shield breakthrough remain future scope.

## Finite food and family foundation

Mums, toddlers and sunbathers no longer use the generic timed food respawn or two-theft permanent departure. Each level spawn gives toddlers and mums explicit `family_id` values; two siblings can share one actual mum even when they begin far apart. A robbed child walks to its designated mum, pauses for a visible handover, and receives the mum's held crisp bag or one item from her shared reserve. Stock is debited exactly once. The held bag counts as one of two total crisp bags, and the separate cookie reserve starts at two as an editable tuning assumption. If stock is empty, the child settles without an endless request loop.

Sunbathers draw a code-native beach bag and remaining-stock pips. Their three total snacks are revealed through a short reach pause and stay depleted. The placeholder cookie is a small code-native SVG and an eighth food definition. Level 1 replaces two of five sunbathers with mums so its four existing toddlers form two sibling pairs without adding NPC clutter; this introduces shielded targets to that level and needs human difficulty playtesting.

Rendered validation passes **730 checks, zero failures**. New simulation checks cover distant designated-parent approach, walking animation during the approach, fixed direction-correct handover positions, stable local patrols after successful and empty-stock arrivals, exact-family alerts, a stolen held bag, conserved sibling stock, single debit, cookie fallback, empty-stock termination, visible finite sunbather depletion, score-once behavior, retry reset, and all six existing level/control/score/result/art loops. `test-output/family-handover.png`, `test-output/sunbather-reach.png`, and `test-output/game-family.png` are the main visual captures.

This is intentionally only the approved foundation. Kiosk trips and purchases, failed-purchase retreat, ice-cream insistence, peck controls, stash scattering/retrieval, caution escalation, fast rear shield breakthrough and other NPC supply conversions remain unimplemented. Ground scraps and unrelated NPC timed replenishment are unchanged.

## Latest toddler art pass

Added `assets/sprites/toddler_polished.png` and curated `data/toddler_art.json`, preserved by placeholder regeneration. Twelve generated poses cover idle/blink, eating, walking and crying, aligned to a shared baseline. Target rendering supports scaled art and correctly placed awareness indicators. Toddlers mirror their hand/food position with facing, pause briefly to eat and during post-theft crying, then resume patrol/departure. Existing parent alerts, scores and food respawn remain intact. Other entities remain placeholders for subsequent passes.

Rendered validation passes **693 checks, zero failures**. Inspected in-game eating/crying and sheet preview captures. Source, exact built-in image-generation prompt, frame contract, small patrol changes and rollout order are documented in `docs/TODDLER_ART.md`.

## Latest results-board pass

The results screen is a hanging wooden sign with ropes, grain and bolts over the frozen beach. Earned points, clean bonus, statistics and total count up sequentially, with total and stars last. Existing score calculations are unchanged; Risky/Upwind/Mugged remain clearly separate event counts. Click, tap or confirm finishes the tally without activating a navigation button. Retry and Escape remain available immediately.

A perched gull celebrates earned stars and Practice completion with a brief wing animation and synthesized screech; zero stars trigger a gag and falling fish skeleton. Three stars strengthen the celebration. Sounds respect Master/SFX settings. Current elapsed time and saved best remain visible. Hiding or replacing the board stops input, animation and sound; the fish stays still until launched and resets its launch position.

Final rendered Godot validation: **628 checks, zero failures**. Captures cover all menus plus tally start/middle/final, poor and three-star reactions, and Practice. Tests cover exact totals, safe skip, early retry during tally, hidden-board input, natural fish launch timing, elapsed versus best time, layout bounds, text-fit bounds, non-overlapping tally rows, and native-grid menu font sizes. Reactions reuse the existing gull atlas with movement/stretch animation; they do not have bespoke beak/cough frames. Audio cues are synthesized first-pass effects.

Menu text now stays on GullPixel's native 8 px grid (8 px body text and 16 px display text). The previous 7, 11, and 14 px result labels resampled the bitmap and dropped one-pixel strokes; the shared label helper now prevents those fractional scales, and rendered validation checks every menu label and button against the native grid.

## Sleeping sunbather pickups

Sleeping sunbathers now allow their crisp box or crisp bag to be stolen either by walking up from the left or right or by crossing it in a dive/swoop. Walk-up theft uses the grounded gull artwork's beak height and is restricted to the `sunbather` target kind; other beachgoers retain their existing dive, shield, umbrella, and attack rules. Collision sweeps preserve the movement state's beak endpoint until resolution, so landing or pulling up on the successful frame no longer discards a hit. The swept ellipse calculation now finds the nearest point after normalizing by its radii, avoiding anisotropic false hits and misses.

Rendered Godot validation passes 373 checks with zero failures, including both snack choices and approach directions, downward and rising sweeps, landing-frame collection, miss geometry, one award before respawn, crash/stun priority, ground scraps, and exclusion of awake defensive targets. The captured `sunbather-walkup.png` confirms the detailed gull reaches the snack location without an oversized global pickup range.

## Original food pass

The first food pass introduced seven independent definitions across small, medium and large categories, with generated transparent sprites integrated into ground pickups and held food. People choose from configured food pools; scoring, rival priorities and pickup sizes use the food definition. Small bites remain separate from combo/practice snatches. Curated food atlas entries survive placeholder regeneration. The current catalog has eleven foods and updated point values; see `docs/FOOD.md` for exact mappings and artwork details.

Rendered Godot validation passes 358 checks, zero failures. Inspected the in-engine food gallery at enlarged and actual gameplay sizes. Balance and tiny-sprite readability still warrant human playtesting; platform export status below is unchanged.

## Latest visual pass

The player now uses artwork prepared from the user's seagull sheet: idle, distance-driven walking, flapping, glide and rotated dive poses, plus a ground shadow. The supplied sheet is preserved unchanged in `assets/reference/`; the transparent derivative and frame mappings live in the project. Rivals remain placeholders. See `docs/VISUALS.md` for the proposal, exact image-tool prompt, limitations, asset paths and replacement notes. Rendered validation passes 322 checks. No movement or scoring rules changed in this visual pass.

## Latest mechanics revision

All six physics-review recommendations are implemented: momentum-preserving coast after swoops (flap restores powered flight), neutral-stick ground stop / airborne heading preservation, slope-proportional uphill braking, moving dive preparation, downward-speed-based beak-first crash severity with an early red warning, and consistent wind push blended over time across all airborne modes. Wind labels and scenery reflect the blended push. Obsolete crash angle/total-speed and separate dive-wind settings were removed from tuning and generator defaults.

Follow-up tuning: walking speed is now 28 versus 140 in flight, including an immediate speed cap when landing. A procedural folded-wing ground pose shows alternating feet driven by distance walked and stops stepping at rest. Upward dives use separate deceleration (420) plus extra drag (75), and stay in the swoop down to speed 20 before returning to ordinary flight. Tests cover walking speed, grounded pose/takeoff, landing speed, and continuous slowdown while rising.

The requested flight changes supersede the original fixed-speed dive and automatic pull-up described below. Shared gull movement now supports slow passive descent, grounded left/right walking, flap takeoff, accelerating dives with live aim steering, and momentum spent on an upward swoop. Food collection no longer forces a pull-up. Fast beak-first ground impacts reset current points and combo, stun once, and leave saved records unchanged. Slow/shallow landings preserve points.

Ground scraps are a separate, visible pickup system, replenishing after 18 seconds. The latest food pass replaces the former fixed 2-point value with crumbs (2) and chips (5). They neither build combos nor replace practice snatches. Flight, turn speed, crash thresholds, and scrap spacing/respawn are configurable in tuning JSON; food values live in foods JSON. The existing controller A / Space / left-click flap bindings are preserved.

Validation now passes 253 checks in a rendered Godot run. New tests cover landing, walking, wind-free ground rest, scraps and replenishment, takeoff, high/low dive speeds, steering upward, momentum loss, crash penalties at multiple time steps, safe shallow landings, and retaining dive control after food collection. Human testing is still needed to tune the feel of turning and acceleration. Windows/Web exports must be rebuilt after this revision.

## Assessment of the interrupted session

The previous work exists as a complete prototype scaffold: six JSON levels, shared gull movement, target reactions, AI pilots, scoring, wind, menus, practice, save data, placeholder sprite manifest, and integration scene. The bitmap font imports successfully. All project files were untracked at assessment; this continuation preserves that work and does not create a commit.

The original integration run had 150 checks and nine failures. Confirmed gameplay/UI defects were a dive trajectory calculated from the body instead of the beak and an options screen extending beyond the viewport. Other failures came from tests expecting a full 90 seconds of game time in 90 seconds of simulation despite hit-stop, and expecting the wrong nearest parent to react.

## Changes in this continuation

- Dive direction now originates at the beak's expected position after the windup hitch. Wind drift and angle limits still apply to player and rivals.
- Options spacing fits the 320×180 canvas. The unsupported ampersand in the save button is replaced with a slash.
- Corrected timer and nearest-parent fixtures; added casual-results layout coverage and routed input checks for intro consumption, dive, pause, resume, restart, and touch climb press/release.
- Test teardown stops audio before exit and gives the audio server time to release playbacks. This removes the resource-leak warnings in the integration run.
- Added repeatable validation script, usage documentation, and Windows/Web export presets with explicit JSON inclusion.

## Verified

- Local engine identifies itself as Godot 4.7.2 stable, official build `ed1daf0bf`.
- Integration: 186 checks, zero failures in headless mode and rendered mode.
- OpenGL Compatibility rendering on NVIDIA GeForce RTX 4050 Laptop GPU.
- Inspected PNGs of title, options, gameplay at both beach ends, and casual results; captures also include level select, pause, touch overlay, and arcade results.
- Windows resource-pack export succeeded; launching that PCK with the local engine passed a startup/level-one smoke run. This is not a standalone executable.

## Outstanding limits

- Standalone Windows export was attempted and failed because matching export templates are absent. Web preset exists but no browser build has been validated. No physical controller, touchscreen, Android, or iOS device test has been performed.
- Sandbox runs report `Failed to read the root certificate store`; the prototype uses no networking and the tested loops complete. Forced smoke-run termination can report audio playback resources still in use; the full integration teardown exits without these leaks.
- Visuals and sounds are generated placeholders. Human playtesting is still needed for difficulty, scoring thresholds, dive feel, audio quality, and accessibility at actual display sizes.
- JSON reload has shallow validation only. Changed spawns and rival profiles require restarting a level.

Next release step: install matching export templates, export Windows and Web, then run real playthroughs with mouse, keyboard, controller, and touch. Do not label configured platforms as device-tested.


Picnic-bag snacks now carry an independent age and cannot be collected by the gull or retrieved by their owner for their first 0.3 seconds. Their gravity and scatter motion continue during that grace period, and collision sweeps begin at the exact eligible fraction when the threshold falls within a physics frame.

