# Exact built-in image generator prompts

All generations used transparent output. The existing pier diner, approved 128px shopper atlas, and approved adult-cast comparison were supplied as style/proportion references where named.

## Base sheet

```text
Use case: stylized-concept
Asset type: untouched source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the existing pier diner whose chunky outline, palette discipline, and readable full-body pose language should be matched but whose identity and clothes must not be copied; Image 2 is the approved 128px shopper atlas whose pixel density, black/dark-navy outline weight, crisp hard-edged pixels, adult scale, and right-facing pose readability are the primary style reference; Image 3 is the approved cast comparison for shared proportions.
Primary request: Create one consistent new full-body pier diner character across exactly 12 isolated poses arranged in a clean 4-column by 3-row sprite-sheet grid. He is a clearly different younger adult man with a tall, lean silhouette, lime-yellow bucket hat, angular purple sunglasses, vivid magenta sleeveless tank top, sunny yellow knee-length board shorts with a simple purple side panel, and white high-top trainers. Medium-brown skin. No facial hair.
Pose order left-to-right, top-to-bottom: 1-4 calm idle variations while presenting one open forward palm for a separate fried-fish food sprite; 5 notice/suspicious glance; 6 watch/track overhead gull; 7 alert while pointing upward, food-supporting hand on the opposite side; 8 low defensive brace protecting the food hand; 9 raised-hand swat windup while the other palm supports food; 10 first swat extension; 11 swat contact with strong reach; 12 planted angry hands-on-hips pose.
Style/medium: polished 1990s arcade pixel art, hard alpha, deliberately chunky pixels, limited saturated seaside palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same pixel density as the approved 128x128 shopper frames.
Composition/framing: every pose is a complete head-to-shoes full-body figure facing screen-right, identical identity and clothing, centered in an equally sized cell with generous transparent separation, shared sole baseline within each row, no overlap and nothing clipped.
Constraints: transparent background; exactly 12 figures and no extras; no labels, guide lines, text, shadows, scenery, props, food, gulls, or watermarks. The forward palm must remain visibly open and unobstructed so the game can place its separate fried-fish paper cone or tray there. Preserve clear anatomy and readable hand silhouettes.
Avoid: red caps, visor caps, teal stripes, navy shorts, orange jackets, swim briefs, old-man features, feminine silhouette, copied faces, smooth vector rendering, painterly shading, gradients, semi-transparent pixels.
```

## Locomotion sheet

```text
Use case: stylized-concept
Asset type: untouched locomotion source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the newly approved base-pose sheet and is the strict identity, clothing, proportions, color, pixel density, and outline reference; Image 2 is the approved shopper atlas and is a motion/readability reference only.
Primary request: Draw exactly 10 complete poses of the same new male pier diner from Image 1, arranged in a clean 5-column by 2-row grid. Preserve his lime-yellow bucket hat, angular purple sunglasses, vivid magenta tank top, sunny yellow board shorts with purple side panel, medium-brown skin, white high-top trainers, tall lean adult silhouette, and right-facing orientation in every frame.
Pose order left-to-right: top row is walk phases 1-5 of a smooth six-phase rightward walk with natural opposing arms and legs while one forward palm remains ready to support a separate food sprite; bottom row begins with walk phase 6, followed by run phases 1-4 of a faster determined rightward chase, with increased lean and stride.
Style/medium: polished 1990s arcade pixel art, hard alpha, deliberately chunky pixels, limited saturated seaside palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same pixel density as approved 128x128 shopper frames.
Composition/framing: each pose complete head-to-shoes, centered in an equal cell, generous transparent separation, shared sole baseline per row, consistent body size and identity, no overlap or clipping.
Constraints: transparent background; exactly 10 figures and no extras; no labels, guide lines, text, shadows, scenery, props, food, gulls, or watermarks. Keep the supporting palm clearly readable for the game's separate fried-fish sprite.
Avoid: changing clothes or identity, red caps, teal stripes, navy shorts, extra limbs, merged silhouettes, smooth vector edges, painterly shading, gradients, semi-transparent pixels.
```

## Eating sheet

```text
Use case: stylized-concept
Asset type: untouched eating-animation source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the strict identity and base-pose reference for the new male pier diner; Image 2 is his approved locomotion sheet and must be matched exactly in clothing, body proportions, palette, outline, and pixel density.
Primary request: Draw exactly 4 complete eating poses of this same right-facing man, arranged left-to-right in one evenly spaced row: 1 presents an open forward palm at chest height ready to support the separate fried-fish tray; 2 lifts that supporting palm toward his mouth and leans in; 3 takes a bite with the palm closest to the mouth and pleased expression; 4 lowers the palm back to the presentation position. Preserve lime-yellow bucket hat, angular purple sunglasses, vivid magenta tank top, sunny yellow board shorts with purple side panel, medium-brown skin, white high-top trainers, and tall lean silhouette.
Style/medium: polished 1990s arcade pixel art, hard alpha, chunky deliberate pixels, limited saturated palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same density as approved 128x128 frames.
Composition/framing: all four figures complete head-to-shoes, centered in equal cells, shared sole baseline, consistent size, generous transparent separation, no clipping.
Constraints: transparent background; exactly 4 figures; no labels, guide lines, text, shadows, scenery, food, props, gulls, or watermarks. The game renders fried fish separately, so show only the supporting hand pose and never draw the fish itself.
Avoid: identity drift, changed clothing, red cap, teal stripes, navy shorts, extra limbs, smooth vector edges, painterly shading, gradients, semi-transparent pixels.
```

## Reaction sheet

```text
Use case: stylized-concept
Asset type: untouched reaction-animation source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the strict identity, clothing, proportions, palette, outline, and pixel-density reference for the new male pier diner; Image 2 is his approved locomotion sheet for consistent dynamic motion.
Primary request: Draw exactly 12 complete reaction poses of the same new male pier diner, arranged in a clean 6-column by 2-row grid. Preserve his lime-yellow bucket hat, angular purple sunglasses, vivid magenta sleeveless tank top, sunny yellow board shorts with purple side panel, medium-brown skin, white high-top trainers, tall lean adult silhouette, and right-facing identity.
Top row, surprise phases 1-6: calm presentation pose; eyes/face turn toward abruptly empty supporting hand; startled realization; shoulders and hands recoil; full shocked lean-back with both hands open; recover into a determined chase-ready lean.
Bottom row, fist-shake phases 1-6: planted angry stance; fist rises; first vigorous shake; recoil between shakes; second vigorous shake; final grumpy planted settle. Keep all fist-shake frames stationary at the feet.
Style/medium: polished 1990s arcade pixel art, hard alpha, deliberately chunky pixels, limited saturated seaside palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same pixel density as approved 128x128 shopper frames.
Composition/framing: each pose complete head-to-shoes, centered in equal cells, shared sole baseline per row, consistent size, generous transparent separation, no overlap or clipping.
Constraints: transparent background; exactly 12 figures and no extras; no labels, guide lines, text, shadows, scenery, props, food, gulls, or watermarks. Surprise must read as reacting to stolen food with empty hands.
Avoid: identity drift, changed clothing, red cap, teal stripes, navy shorts, extra limbs, merged figures, smooth vector edges, painterly shading, gradients, semi-transparent pixels.
```

The first reaction result added detached comic motion symbols. The final reaction source was created with this targeted built-in edit:

```text
Use case: precise-object-edit
Asset type: cleaned untouched reaction-animation source sprite sheet
Primary request: Remove only the detached orange/yellow comic alert wedges, exclamation-like bursts, and curved motion-line symbols floating near the characters' heads and fists. Restore those removed areas to genuine transparent background.
Invariants: keep exactly the same 12 full-body character poses in the same 6-column by 2-row layout; keep every character pixel, pose, face, hand, clothing color, sunglasses, bucket hat, proportions, outline, hard pixel edges, spacing, and transparent background otherwise unchanged. Do not redesign or redraw the character. Do not add anything.
Constraints: transparent background; no symbols, effects, labels, text, shadows, scenery, props, food, gulls, or watermark.
```
