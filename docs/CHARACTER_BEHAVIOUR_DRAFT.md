# Character behaviour scripts — review draft

Date: 22 October 2026.
Status: crab habitat/routine and pier-diner replacement meals authorised by the user's follow-ups and implemented; remaining character scripts stay proposals. See CRABS.md and PIER_DINER_BEHAVIOUR.md for current behaviour and validation.

Crab revision: the user rejected pinching and specified beach-edge/quiet-sand appearances, no boardwalk walking, a local walking radius, and longer use of the second lane to allow quick retreat. Crab rules are now implemented with editable starting values; other cast proposals below have not been implemented by this change.

This is a player-facing behaviour specification. Each rule should eventually define its trigger, visible action, gameplay consequence and way back to the normal routine. Review crabs first, then expand and approve one character at a time. IDs remain stable during revisions.

## Existing foundations to preserve

- Crab catches currently require a ground peck or timed dive peck. Crabs are large food, need an empty stomach, and award 100 base points once on swallowing. Misses do not turn them into dropped food. Red and blue currently follow the same rules and value.
- Current crab population: first arrival after 18 seconds, then 22–28 seconds between arrivals, maximum two active, about 14 seconds before retreat. All remain starting values unless revised explicitly.
- Adult approaches use a warning, then escalation on a distinct repeat approach; theft causes a stronger reaction. Swats need a visible windup and a fresh range check. Successful swats use the existing stun, five-point penalty and current-snack drop rules.
- Sunbathers stay asleep through four accepted stocked-bag pecks, then begin waking after the fourth resolves. Awake status lasts for the round; empty bags stay empty unless their own food is recovered.
- Toddlers cry and run towards their own mum after theft. Families have linked children and finite shared supplies, with visible replacement purchases and retreat after theft of a new purchase.
- Stall food rests on the counter for the established 0.85-second bonus window before collection. Vendors remain adult-scale full-body characters masked behind their stalls.
- Shoppers and pier diners already have a stronger, committed pursuit after a perfect direct snatch. Any revisions must explicitly account for that rule rather than silently replacing it with ordinary warnings.

## Crab design direction

Habitat and movement boundaries take priority over reactive actions. Crabs are local beach wildlife, with a short route back to the sea. Pinching is rejected: no attacks, damage, stun, food drops or point penalties caused by crabs.

### Agreed habitat constraints and starting tuning

- **Appearance:** only at the edges of the sandy beach or in quiet sandy pockets. A screen edge is eligible only when it intersects that habitat; the camera reaching a boardwalk must never make a boardwalk spawn valid. Sea emergence must also lead into an eligible sandy pocket.
- **Excluded surfaces:** no spawning, wandering, escape bursts or retreat paths on the promenade, boardwalks, pier, stalls or human service routes. Read actual level boundaries, since the opening maps differ from later maps.
- **Quiet pockets:** proposed definition is a local patch with clearance from people, active picnic/towel interaction areas and busy crossings, plus a clear sandy route to the shoreline. Treat this as local clearance, not a ban on every beach section containing a human. If no suitable pocket is available, delay the arrival rather than forcing it into a busy location. Exact clearance is still to be tuned.
- **Local radius:** suggested starting radius is 40–60 logical units either side of its appearance anchor. Clip that range to the quiet sandy pocket and shoreline access. It is not permission to roam across the full beach. Escape bursts stay within the same habitat and bounded lateral range; the return-to-sea path may move in depth.
- **Second lane:** interpreted here as the rear, sea-side lane behind the main human walking line. Proposed preference is 70–80% of active time there, with occasional short visits towards the front sand lane. Unlike a person's brief passing step, the crab may forage and pause in this lane for an extended period. This is a lane preference, not an increase to its total lifetime.
- **Retreat access:** keep the sea-side exit open. If people enter the pocket, the crab favours the second lane and retreats if the pocket becomes busy or its route is threatened. Do not solve a blocked route by crossing a boardwalk. Exact retreat trigger distance and speed remain proposals.
- **Readable depth:** lane movement must be visible and keep sprite size, foot position and catch position aligned. Rear-lane catch range and ground-peck accessibility need explicit verification; do not make an apparently nearby crab secretly collectable from another lane. Dive pecks must use its actual position.

The following actions operate inside those habitat constraints. C10 remains as a rejected ID so earlier review references stay meaningful; C11–C13 record the new placement and movement rules.

| ID | Trigger | Proposed action | Consequence / return |
| --- | --- | --- | --- |
| C1 — Arrive and assess | An eligible beach-edge or quiet-sand pocket is available. | Retain the one-second visible arrival, favouring the second lane. Sea entries grow with depth; sandy side entries use the scale appropriate to their lane. Briefly pause and look around. | Become catchable on completing arrival. If no valid habitat is available, delay spawning. Never substitute a boardwalk screen edge. |
| C2 — Scuttle and forage | Calm and not retreating. | Move sideways for 1–2 seconds within the local radius, then pause for 0.4–0.8 seconds as if inspecting sand. Spend longer stretches in the second lane. | Pauses create deliberate catch opportunities. No real food is consumed or spawned by this idle action. Stay within the selected sandy pocket. |
| C3 — Notice a threat | A gull approaches low within roughly two crab body widths, or a grounded gull closes within one. | Stop for about 0.3 seconds and face the threat using available supplied poses. High flight alone does not trigger fear. | Give the player one readable reaction opportunity before escape. Leaving the area lets the crab settle. Exact distances need playtesting. |
| C4 — Escape within the pocket | Threat remains after the notice pause. | Make a short burst away from the gull at about 1.6 times normal speed for 0.8–1.2 seconds, favouring the second lane and sea access. Choose the route at burst start rather than continuously steering away from the gull's aim. | Stay catchable during the escape burst. Respect the local radius and sandy habitat. If no safe local escape remains, begin the distinct return-to-sea retreat instead of crossing a boardwalk. |
| C5 — Settle after escape | Burst ends and the gull has backed off. | Pause watchfully for about 0.6 seconds, then resume ordinary scuttling. | This is a renewed catch opportunity. A fresh fear response requires the gull to leave and re-enter the threat area, preventing endless freeze/burst loops from hovering. |
| C6 — Respond to a missed peck | A valid nearby peck misses the crab. | Make one short escape burst after the miss; if already escaping, finish the existing burst. | Do not reset its lifetime, add invulnerability, drop crab food or trigger an attack. A full-stomach rejected catch preserves the crab and has no penalty; proximity can still scare it normally. |
| C7 — Catch cleanly | An eligible ground or dive peck connects. | Enter caught state immediately and leave the live target list. | Retain large-food capacity, digestion and once-only swallow scoring. Simply walking into it never collects it. |
| C8 — Return to the sea | Its existing lifetime expires, or the pocket becomes too busy for a safe local escape. | Take the short sandy route through the second lane towards the sea, shrinking with depth. Its usual rear-lane position keeps this retreat quick. | Proposed catchability retains the current rule: uncatchable when committed sea retreat starts. Distinguish this visually from a catchable local escape burst. No attack, teleport, timer reset or crossing of a boardwalk. |
| C9 — Use colour consistently | Red or blue crab appears. | Give both colours the same movement, threat response, catch rules and 100-point base value in the first version. | Colour is visual variety. Any later personality or difficulty split needs explicit approval and a readable cue. |
| C10 — Pinching rejected | Any encounter. | Never pinch, attack or pursue the gull. | Explicit user decision; remove the former optional pinch proposal. |
| C11 — Choose beach habitat | Population attempts an arrival. | Select a beach edge or quiet sandy pocket with shoreline access. | Exclude promenade, boardwalk, pier and busy human areas. No valid pocket means no arrival yet. |
| C12 — Stay local | Choose a walk or escape destination. | Remain within the pocket and a proposed 40–60-unit radius either side of the appearance anchor. | Turn or settle before reaching its bounds. Lateral range never expands to follow the player. |
| C13 — Linger in the second lane | Calm foraging, pauses or a nearby disturbance. | Prefer extended rear/sea-side lane stays, provisionally 70–80% of active time, with only short front-lane excursions. | Maintain a quick retreat route; do not force the crab onto the human walking line after a brief passing timer. |

Example encounter: a crab emerges in a quiet beach-edge pocket, lingers and scuttles in the second lane, briefly ventures towards the front sand lane, notices a low approach and escapes back towards its sea-side refuge. It may settle inside the same pocket if the threat passes, or take the short route into the sea if pressure continues. It never joins promenade traffic.

Priority: habitat restrictions apply to every action; successful catch or already-started retreat takes precedence over other actions; lifetime expiry starts retreat; threat responses interrupt calm scuttling. Caught is terminal. Proposed catchability is calm, notice, local escape and settle, but not arrival or committed sea retreat. Catch geometry must match the occupied lane.

Presentation: use the supplied crab frames and whole-sprite movement/animation. Do not draw anatomy with code. Confirm which poses read as notice or foraging before committing to those gestures; request generated or supplied artwork if a gesture is missing.

## Initial scripts for the remaining cast

These are proposed role scripts, not claims that every detail is already implemented. Existing foundations above remain binding. Timing and individual traits below are provisional.

| Character | Proposed behaviours to expand and approve |
| --- | --- |
| Toddler | T1: wander close to their own mum, with brief eating stops. T2: after theft, immediately cry while accelerating towards her. T3: stop beside mum and receive a visible snack from finite family stock. T4: follow the whole-family shopping trip when backup is insufficient; do not independently wander to another parent. |
| Mum / picnic parent | M1: remain near the picnic and watch linked children. M2: turn towards a low approach and shield held food. M3: react to theft with a bounded pursuit, then regroup with children. M4: share finite supplies, visibly handing over one snack at a time. M5: gather everyone for a stand visit; retreat and regroup if a newly purchased item is stolen. |
| Sunbather, all appearances | S1: recline with sleep cues and honour four protected bag pecks. S2: visibly wake after peck four, with no instant hit. S3: once awake, react to later disturbance with a warning/windup. S4: retrieve their own scattered snacks, creating a visible race with the gull. S5: return to the towel and remain watchful for the rest of the round; never regenerate bag stock. |
| Original shopper | O1: approach the correct stall and place an order. O2: wait through preparation and collect only after the counter window. O3: leave the counter, stroll, then stop to eat. O4: warn on approach; react to theft with surprise, the appropriate pursuit and an angry give-up. O5: return to a real stand when needing a replacement. |
| Mullet / cap shopper | A1: use the same buying and theft rules as other shoppers. A2: favour longer strolling legs and fewer discretionary stops. A3: stop and turn to watch a nearby gull, then resume walking when it leaves. A4: after a failed pursuit, pause angrily before continuing. Personality changes movement rhythm, not secret reach or damage. |
| Sundress shopper | D1: use the same buying and theft rules as other shoppers. D2: favour shorter walks with longer eating/lookout pauses. D3: turn visibly towards a low gull before warning. D4: resume a nearby sensible destination after a pursuit. Appearance alone does not grant weaker defenses or easier theft. |
| Pier diner | P1: longer dining/lookout stops near the original anchor. P2: local pier/promenade strolls and return. P3: turn and defend against close approaches. P4: preserve bounded theft pursuit and give-up. P5: implemented visible replacement purchase at the existing hotdog grill, stationary counter-snatch window, and carry back to the original dining spot. No timer-based fish regeneration. |
| Dog / owner encounter | G1: stroll locally and stop to sniff/look around, within the current encounter's art and layout. G2: become attentive when the gull lingers overhead. G3: bark before a short, grounded lunge at a low gull. G4: stop at the local encounter boundary and settle instead of pursuing across the beach. G5: keep held-food ownership distinct from defense; decide the encounter's replacement-food source before implementation. A separately moving dog/owner pair is additional scope requiring its own art review. |
| Lifeguard | L1: patrol around the tower and pause to scan the beach. L2: face and whistle at a nearby diving gull. L3: alert nearby adults after the visible whistle, with limited range and a cooldown. L4: resume patrol and periodically return to the tower. L5: remain a source of warning and pressure without automatically taking points or food from the player. |
| Ice-cream vendor | I1: idle at the serving window. I2: acknowledge an order and prepare the requested portion. I3: place it on the counter for the existing bonus window. I4: react visibly if it is stolen; let the affected buyer's rule control pursuit. I5: reset the serving area and accept the next valid order without duplicating the stolen portion. |
| Hotdog vendor | H1: idle at the grill/window. H2: prepare one ordered hotdog. H3: put it on the counter for the same readable collection window. H4: react to a counter theft, then return to service. H5: remain inside the stall and avoid adding an untelegraphed attack to the counter bonus opportunity. |
| Seafood vendor type | F1: guard the fish serving area. F2: visibly warn a low gull. F3: wind up a short broom sweep if it stays within reach. F4: recover before another sweep, remaining at the work area. F5: require a visible source for replacement fish. Keep this separate from the two animated counter vendors until their roles are explicitly reconciled. |
| Gary, rival gull | R-G1: patrol broadly and favour exposed, valuable food. R-G2: line up a conspicuous swoop with relatively forgiving aim. R-G3: after theft, visibly flee with the carried item during the mugging window. R-G4: recover before choosing another target. Proposed personality: bold and predictable. |
| Chip, rival gull | R-C1: patrol and reassess opportunities more often. R-C2: favour nearby exposed snacks rather than always the most valuable distant item. R-C3: commit once a dive starts; no mid-dive perfect tracking. R-C4: flee and recover through the same readable mugging rules. Proposed personality: opportunistic and restless. |
| Bev, rival gull | R-B1: favour higher-value, less-defended targets. R-B2: wait for a cleaner opening before committing. R-B3: use the more accurate dive profile, with a visible lineup. R-B4: flee with food, then recover before hunting again. Proposed personality: patient and precise. |
| Player gull | U1: keep movement, pecking and diving under player control. U2: show automatic eating and current capacity clearly. U3: visibly settle when grounded or perched, using the existing faster digestion rate. U4: show a brief reaction to hits and dropped current food. U5: give clear feedback when a catch is rejected for capacity, without consuming the target or awarding points. |

Rival personality differences are proposals beyond the existing shared hunting loop and accuracy profiles. Retain current speed values unless a speed change is approved. Rivals currently hunt human food; adding crab hunting would be a separate decision.

## Review and next steps

1. Playtest implemented C1–C9 and C11–C13, especially walking radius and second-lane timing. C10 is rejected and remains excluded.
2. Revise concrete cues, triggers and consequences before tuning exact distances.
3. Expand the next chosen character into the same trigger/action/consequence format.
4. After approval, create an implementation plan listing the matching GodotPrompter skills for each task. Likely skills: state-machine, ai-navigation, animation-system, resource-pattern and godot-testing; add role-specific skills as needed.
5. Implement only approved rules and check interrupted actions, catch/food ownership, pause behaviour, clear cues and return to routine.

Sources reviewed: docs/CRABS.md, scripts/crab.gd, scripts/crab_population.gd, data/targets.json, scripts/beach_routine.gd, scripts/target.gd, scripts/stall_service.gd, scripts/shopper_art.gd, data/levels/level_06.json, docs/FOOD_AND_REACTIONS_SPEC.md, docs/FOOD_REPLENISHMENT_SPEC.md and the approved character-routines/sunbather-sleep plan.
