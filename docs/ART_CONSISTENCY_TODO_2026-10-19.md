# Art consistency review — 19 October 2026

**Production update:** the sharper diner-led pilot was approved and is implemented across Mum and all four sunbather variants. See `DINER_ADULT_PRODUCTION_V1.md`. Remaining painted characters, placeholder staff and food still need their own passes; the diner remains the approved reference.

**User correction:** the pier diner is the approved style reference. The new mum/sunbathers are too blocky and require a sharper pass; the toddler/shopper/dog-owner treatment is too polished. The assessment and recommendations below predate that correction. Follow `godot-prompter/plans/2026-10-19-diner-led-character-style.md` for the current priority and pilot plan.

The adult replacements improve recognizable identities and action silhouettes, but the overall game still mixes chunky native pixels, smoothly painted figures, strongly exaggerated pixel-like figures, and placeholder rectangles. The environment and interface provide the most consistent palette and edge treatment. The new cast should be treated as a working direction, with room for pixel cleanup rather than assumed finished master artwork.

Evidence: a new in-engine comparison of the current production actors at their runtime scales, plus gameplay captures from the final rendered adult replacement run earlier today. The cast comparison freezes actors and omits separate food, bags and towels so silhouettes can be compared. It is a diagnostic scene, not a playable level. No production artwork, gameplay or rendering settings were changed for this review.

Screenshots are saved in `assets/previews/art-audit-2026-10-19/`:

- `cast.png`: current cast at production scale, with labels.
- `family.png`: new mum beside the painted toddler and gull.
- `promenade.png`: painted customer, owner and dog beside the native props.
- `pier.png`: exaggerated diner, tower and rectangular seafood-vendor placeholder.
- `food.png`: enlarged food previews alongside their actual gameplay sizes.

## Prioritized to-do list

| Priority | Work | Existing art versus new work | Direction needed |
| --- | --- | --- | --- |
| 1 | Replace the player/rival gull treatment with a shared chunky pixel style. Preserve recognizability and every required flight, dive and ground pose. Make the rival readable beyond a blue tint. | Existing gull image is an identity/motion reference, not a matching pixel sheet. New art is warranted. | Natural bird proportions or a more expressive cartoon gull? Recommend a recognizable gull with simplified wings and a larger readable face; white player, distinct darker rival markings. |
| 1 | Replace lifeguard and seafood-vendor rectangles with actual staff characters at the adult cast's apparent scale. Add readable whistle/warning and broom anticipation/contact/recovery. | `lifeguard-pixel-review-v1.png` and `lifeguard-motion-review-v1.png` already supply a design and several poses. Review/integrate those before generating duplicates. The vendor needs a design and action sheet. | Keep the red cap/vest lifeguard concept? Vendor identity, outfit and personality are open. Suggested default: friendly older fish seller, cream shirt, teal apron, clear broom silhouette. |
| 2 | Bring the customer, dog owner and dog into the same outline, shading and pixel-size treatment as mum/sunbathers. Match their adult proportions without losing distinct silhouettes. | Existing painted sheets can guide identity and posing; fresh matching pixel sources are likely needed. | Keep current mustard-shirt customer, purple-shirt owner and small tan dog, or redesign? Recommend keeping those recognizable identities. |
| 2 | Replace the toddler's painted rendering while preserving the small-child silhouette, hat, empty snack hand, crying and running readability. | `toddler-pixel-review-v1.png` and `toddler-motion-review-v1.png` are available candidates. Fit/review them at the current small gameplay size before generating more. | Keep the yellow hat/coral top/teal outfit and present child size? Recommended default: yes. |
| 3 | Normalize the pier diner. Its oversized head, saturated shading and heavy outline are stronger than the new adult set. Align idle/action/motion sources and held-food placement. | Existing pixel-like sheets provide reusable designs/poses. New intermediate poses may be needed after proportion cleanup. | Retain the exaggerated short, large-headed character, or use the same adult proportions as mum/sunbathers? Recommend retaining the outfit/identity and matching adult proportions. |
| 3 | Unify food rendering and recognizability: illustrated crisps/hotdog/fish/ice cream, a simple square cookie, and coarse leftovers currently look like different sets. | Existing food and leftover images are useful references. Final-size pixel cleanup/redrawing is needed; wholesale generation may be unnecessary. | No essential design decision: preserve food identities and scoring sizes; use the same broad pixel clusters and restrained shading throughout. |
| 4 | Finish the updated adult art: balance mum's dense shading against flatter sunbather skin, improve tiny faces/sunglasses and contour clusters, and check head/body stability between source sheets. | Pixel cleanup of current atlases/source preparation. Avoid starting all five designs again. | No essential identity decision unless the current chunky adult treatment is being reconsidered. |
| 4 | Finish adult animation: independent chase/sprint cycles, subtle idle/rest motion, clearer reaction transitions, individually drawn left kicks, and foot/hand continuity. | Current clips hold key poses and reuse walk/run sources; selected missing sequences need new art. | A short style/proportion check before producing more cycles will prevent inconsistent new frames. |
| 5 | Environment polish after cast/food alignment: check unused furniture/hut/sign placement against current authored and generated levels, then add restrained variation if needed. | Many suitable props already exist. Placement is primarily layout work, not new-asset generation. | Only needed if a richer or busier beach is desired. Current sparse backdrop is a valid visual choice. |

## What to retain

The kiosk/hotdog stand distinction, tower, parasols, palm, bins, picnic bags, bitmap UI, signs and shared navy/cream/coral/teal palette are a coherent base. They do not need another wholesale replacement. Minor prop cleanup can wait until the cast and food share one treatment.

## Suggested decision order

1. Choose gull proportions and rival distinction.
2. Choose staff identities, especially the new seafood vendor; use the existing lifeguard design as the starting option.
3. Confirm whether the remaining people should keep their current identities while moving to the new adult style, including whether the diner keeps its exaggerated proportions.

Those decisions are sufficient to prepare concrete asset prompts. Toddler/lifeguard review sources should be evaluated for reuse first. Palette cleanup, food consistency and the documented animation gaps have clear technical/artistic next steps without requiring separate concept choices.
