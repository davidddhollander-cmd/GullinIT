# Exact built-in image generator prompts

All calls requested transparent output. The named existing game assets were supplied only as style, scale and differentiation references.

## Guard and action sheet

```text
Use case: stylized-concept
Asset type: untouched source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the approved 128px shopper atlas and is the primary pixel-density, adult-proportion, hard-outline, palette, and right-facing pose reference; Image 2 is the approved lifeguard atlas and is the action-readability reference; Image 3 is the fish-and-chips stall vendor who must NOT be copied; Image 4 is a pier diner who must NOT be copied.
Primary request: Create one consistent full-body seafood guard across exactly 12 isolated poses arranged in a clean 4-column by 3-row grid. He is a sturdy older male fishmonger guarding a pier, with a broad square silhouette, weathered medium-light skin, large bushy grey moustache, cream ribbed fisherman beanie, dark forest-green knitted jumper, bright mustard-yellow rubber bib apron, charcoal trousers, and brick-red rubber wellies. He holds one clearly visible traditional broom in every pose: long warm-brown wooden handle and wide golden straw bristle head.
Pose order left-to-right, top-to-bottom: 1-4 calm idle variations holding the broom upright beside him while scanning the sky; 5 alert glance upward with broom ready; 6 stronger alert pointing his gaze overhead and gripping broom with both hands; 7 planted angry warning scowl with broom vertical; 8 planted angry shake of one fist while retaining the broom; 9 first windup with broom lifted diagonally; 10 stronger windup with broom raised high behind the shoulder, unmistakable telegraph; 11 broad broom swat through contact; 12 broom-swing follow-through.
Style/medium: polished 1990s arcade pixel art, hard alpha, deliberately chunky pixels, limited saturated seaside palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same pixel density as the approved 128x128 shopper frames.
Composition/framing: every pose is a complete head-to-wellies full-body figure facing screen-right, identical identity and clothing, centered in an equally sized cell with generous transparent separation, shared sole baseline within each row, no overlap and nothing clipped. The entire broom, including handle and bristles, must fit inside every cell and remain visibly connected to his hands/body silhouette.
Constraints: transparent background; exactly 12 figures and no extras; the broom is generated character equipment and must appear in all 12 poses; no labels, guide lines, text, shadows, scenery, fish, food, gulls, stalls, counters, or watermarks.
Avoid: white sailor cap, white apron, blue shirt, lime bucket hat, magenta tank top, yellow board shorts, orange jacket, red cap, teal stripes, navy shorts, tiny old-man scale, cane, smooth vector rendering, painterly shading, gradients, semi-transparent pixels, detached props.
```

## Walk sheet

```text
Use case: stylized-concept
Asset type: untouched walking-animation source sprite sheet for a Godot 2D pixel-art game
Input images: Image 1 is the newly approved seafood guard action sheet and is the strict identity, clothing, broom, proportions, palette, outline, and pixel-density reference; Image 2 is the approved shopper atlas and is a walk-cycle readability reference only.
Primary request: Draw exactly 6 complete walking poses of the same sturdy older male seafood guard from Image 1, arranged in a clean 3-column by 2-row grid, ordered left-to-right across the top row then left-to-right across the bottom row. Create a smooth six-phase rightward walk with natural opposing legs and body weight shifts. He carries the same entire traditional broom diagonally or upright in both hands in every frame, with the warm-brown wooden handle and wide golden straw bristle head always clearly visible.
Identity invariants: broad square silhouette, weathered medium-light skin, large bushy grey moustache, cream ribbed fisherman beanie, dark forest-green knitted jumper, bright mustard-yellow rubber bib apron, charcoal trousers, brick-red rubber wellies.
Style/medium: polished 1990s arcade pixel art, hard alpha, deliberately chunky pixels, limited saturated seaside palette, dark navy 2-pixel-equivalent outline, minimal anti-aliasing, same pixel density as the approved 128x128 shopper frames.
Composition/framing: each pose complete head-to-wellies with the full broom, centered in an equal cell, generous transparent separation, shared sole baseline per row, consistent body size and identity, no overlap or clipping. Keep broom and hands visibly connected to the body silhouette.
Constraints: transparent background; exactly 6 figures and no extras; broom visible in all six; no labels, guide lines, text, shadows, scenery, food, fish, gulls, stalls, counters, or watermarks.
Avoid: identity drift, changed clothes, white sailor cap, white apron, blue shirt, extra limbs, extra brooms, detached props, smooth vector edges, painterly shading, gradients, semi-transparent pixels.
```

The initial walk result included a dark studio-style RGB backdrop. The final source was created with this targeted built-in transparency edit:

```text
Use case: background-extraction
Asset type: cleaned transparent walking-animation source sprite sheet
Primary request: Remove only the dark blurred gradient/studio background and replace it with genuine full transparency.
Invariants: keep exactly the same six full-body seafood guard figures, in the same 3-column by 2-row positions, with every character and broom pixel, pose, identity, moustache, beanie, green jumper, yellow apron, charcoal trousers, red wellies, wooden handles, straw bristles, proportions, dark pixel outlines, and spacing unchanged. Keep each complete broom. Do not redesign, redraw, crop, move, resize, or add anything.
Constraints: actual transparent background everywhere outside the six character-and-broom silhouettes; crisp hard alpha edges; no shadows, glow, labels, guides, text, scenery, props beyond the held brooms, or watermark.
```
