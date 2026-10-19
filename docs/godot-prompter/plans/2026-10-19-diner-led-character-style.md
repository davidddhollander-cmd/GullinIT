# Diner-led character art plan

**Production progress:** the user approved the pilot and steps 1–5 are complete. All five adult atlases now use the approved higher-detail finish. Final rendered validation: 10,933 checks, zero failures. See `../../DINER_ADULT_PRODUCTION_V1.md`. Step 6 remains future work for the other characters and food.

## Accepted direction

User direction, 19 October 2026: in the current-cast lineup, only the **pier diner** has the right style. Mum and the male/female sunbathers are close, but too blocky and pixelated. Make them sharper and more defined in the diner's style, while staying below the smooth, highly polished treatment of the toddler, shopper and dog owner.

This supersedes the earlier assessment that the native 40-pixel adult treatment was the final style target. The diner remains the approved visual reference. Matching its finish does not automatically require copying its body shape, outfit or facial identity onto every character.

## Why the current adults are too coarse

The current preparation in `tools/adult_atlas_source.gd` reduces standing figures to around 40 source pixels tall and maps them into at most 14 opaque colours. That conversion discards contour, facial and shading detail before the sprite is displayed. The diner uses larger source frames and retains finer stepped outlines, readable facial features and richer compact shading at a comparable apparent height. Enlarging or filtering the already reduced adult PNGs cannot recover those details.

## Work sequence

- [x] **1. Establish the diner reference and a small pilot brief.** Use the current idle, walk and swat diner artwork as the visual standard. Compare outline weight, edge steps, eye/face clarity, hair clusters and shading at actual gameplay display size. Preserve mum's ponytail, coral blouse, teal shorts and sandals; preserve male sunglasses/trunks and female sunglasses/bun/one-piece. Preserve existing apparent heights as the starting point. No requirement to make every figure as short or large-headed as the diner.
  Skills: `godot-prompter:assets-pipeline`.

- [x] **2. Make a sharper adult pilot before complete sheets.** Prepare one standing pose each for mum, male and female, plus one mum walking and one swat pose. Start from the original review images and supplemental sources, before their current low-resolution/palette reduction. Trial twice the current source detail: 128 × 128 frame cells, standing figures around 80 source pixels tall, presented at half scale to retain their current gameplay size. This is a test configuration, not a predetermined final resolution. Allow the extra face/hair/skin midtones needed to match the diner instead of enforcing the old two-tone/14-colour treatment. Use clean stepped contours, deliberate shading clusters and readable hands; avoid painted gradients, glossy lighting and softened outlines. Generate new pilot artwork with the built-in image tool only where the available sources cannot achieve the match, using the diner as the primary style reference and the existing adults as identity references.
  Skills: `godot-prompter:assets-pipeline`; `imagegen` for new/edited raster artwork.

- [x] **3. Review the pilot beside the unchanged diner in-engine.** Produce a labeled old-adult / pilot / diner comparison and a normal gameplay capture. Check at desktop and phone display sizes. Assess sharper faces/edges without painted polish, consistent outline weight, apparent height, head stability and food-hand alignment. Keep pilot outputs separate from production until this visual checkpoint settles the style. If the first pass is still coarse, adjust source detail deliberately; if too polished, simplify the artwork's shading and surface treatment. Do not use blur or a game-wide renderer change as the style adjustment.
  Skills: `godot-prompter:assets-pipeline`.

- [x] **4. Complete the five adult atlases after the style checkpoint.** Carry the selected treatment through mum plus male/female red/blue variants. Keep the shared red/blue silhouettes and timing, separating garment colour swaps from skin/hair. Finish independent walk/chase motion and reaction transitions using the new visual standard. Retain separate food, towels and bags. Carry over clip names/counts, foot/world anchors and action contact timing. Validate handover and carrying in both directions.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`.

- [x] **5. Adapt integration to the selected artwork resolution.** If the pilot confirms larger source cells, update the adult atlas loader, mum registry frame regions, sunbather runtime scale, atlas preparation and preview tools together. Preserve logical character height, y=58-equivalent sole baseline, separate-food anchors and interaction locations. A 2× source grid needs matching 0.5× presentation; changing source dimensions alone would change gameplay size. Keep nearest sampling and lossless alpha as the starting point. Revise only tests that encode superseded source-grid/palette requirements; retain behavior, anchor, bounds and clip coverage. Update the style documentation with the actual selected format.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`, `godot-prompter:godot-testing`, `godot-prompter:godot-code-review`.

- [ ] **6. Bring the remaining cast toward this established style.** Retain the approved diner as the reference. First adapt the existing lifeguard and toddler review art where suitable and design the missing seafood vendor. Then bring the shopper, dog owner/dog and both gulls into the same contour/detail/shading treatment. Retain current identities as the starting brief; character-specific anatomy remains distinct. Make small previews before full animation batches. Food receives a later consistency pass against the same rendering treatment. Environment/UI remain secondary to completing the cast.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`; `imagegen` for new/edited raster artwork.

## First concrete deliverable

A five-pose adult pilot and a comparison against the approved diner at the same gameplay display scale. This is the next visual decision; full animation sheets follow that review rather than committing another whole cast to an unproven conversion.

## Scope of this planning turn

Planning and recording the corrected style target only. No generation, atlas replacement, loader changes, gameplay changes or test runs are part of this turn.
