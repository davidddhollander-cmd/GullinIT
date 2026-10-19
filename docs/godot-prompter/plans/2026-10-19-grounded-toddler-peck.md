# Grounded toddler food peck

## Goal
When the gull is on foot and a food-carrying toddler comes within reach, pressing the existing peck action knocks their current food onto the ground. Support ice cream and any other held food through food_id. Proximity alone must not trigger theft.

## Design
Extend the existing grounded peck path, rather than adding an input or a parallel pickup system. game.gd routes grounded input; stash_raids.gd owns ground peck cooldown, feedback, and loose food; target.gd owns held food and theft lifecycle. No new scene or autoload is needed.

Flow: peck input -> grounded/running/cooldown checks -> nearest eligible toddler in forward reach -> target.knock_food(player) -> existing food_knocked signal -> add_knocked_food -> existing delayed pickup -> claim_dropped -> existing theft/reaction lifecycle.

Prefer this small extension over a separate interaction component (unnecessary lifecycle duplication) or automatic proximity theft (removes deliberate peck timing).

## Ordered implementation tasks
1. Inspect current input, ground peck targeting, target food positions, and tests. Preserve all existing uncommitted work. Skills: godot-prompter:input-handling, godot-prompter:player-controller.
2. Add deterministic nearest-toddler targeting for grounded pecks. Require held food, valid/non-leaving toddler, forward horizontal reach, and a sensible vertical tolerance using actual food/beak positions. Use tunable reach if existing peck reach cannot accommodate toddler food height. One press affects at most one target. Toddler targeting takes priority over bag/bin fallback only when eligible. Skills: godot-prompter:gdscript-patterns, godot-prompter:math-essentials.
3. Reuse knock_food and the existing shared cooldown/peck feedback; do not award food or score at knock time. Ensure stationary gulls produce a readable falling food drop. Preserve pickup grace, capacity checks, one-time collection, family purchase bookkeeping, and toddler crying/running reactions on completed theft. Do not introduce toddler health or combat damage. Skills: godot-prompter:gdscript-patterns, godot-prompter:state-machine.
4. Add a concise contextual hint if appropriate within the existing HUD, and document the control. Preserve training progression, dive pecks, bag raids, and bin pecks. Skills: godot-prompter:hud-system.
5. Extend the existing test harness: grounded in-range success; stationary player; ice cream and another food; out-of-range/behind player rejection; airborne rejection; cooldown; empty toddler; nearest of multiple targets; no duplicate drops or immediate rewards; later collection and family reaction; bag/bin fallback. Run relevant integration and training checks plus Godot parse/import validation. Skills: godot-prompter:godot-testing, godot-prompter:godot-code-review.

## Acceptance
The player can wait or walk on the ground, peck once when a toddler is close and ahead, see their food fall, and collect it through normal pickup rules. Repeated pecks cannot duplicate food. Existing aerial theft and stash interactions continue to work.

## Delegation
Terra owns implementing this plan, focused tests, and relevant documentation. Other work is present in this checkout: do not revert it, overwrite it wholesale, or reset the repository. Review the diff and report checks and any limits. Do not commit or publish unless separately requested.
