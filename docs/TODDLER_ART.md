# Toddler: first polished entity sheet

The first beachgoer art pass replaces the original block placeholder with a consistent toddler in a yellow sunhat, coral shirt, teal dungarees and sandals. The supplied gull and existing food sprites remain unchanged.

## Assets and frame contract

- `assets/sprites/toddler_polished.png`: original generated transparent RGBA sheet, 1448×1086, twelve frames in four columns and three rows. Generated with the built-in ChatGPT image tool, not Godot or the API fallback. The old `toddler.png` is retained.
- `data/toddler_art.json`: curated frame bounds, offsets, animation mapping, visual scale and food anchor. Its entry is merged into the live `data/sprites.json`; the placeholder generator preserves this override.
- Logical frame canvas: 362×362. Each region is bottom-aligned to the same baseline using AtlasTexture margins. Scale 0.075 gives a 27.15-pixel canvas height in the 320×180 game.
- Row one: idle/blink, eating anticipation. Row two: four walking poses. Row three: four startled/crying poses. Leftward motion mirrors the same artwork and the separate food attachment.
- Ice cream is deliberately absent from the character sheet. The game attaches the food sprite at the hand, so it vanishes correctly after theft. A cutout shader rejects faint edge fringe; the source alpha is preserved unchanged.

## Animation behavior

Toddlers pause to eat for 1.2 seconds of each six-second patrol cycle. Otherwise they walk in their movement direction. After theft they plant their feet and cry during the existing recovery period, with the existing parent-alert signal intact. After recovery they resume walking; replenishment restores the separate ice cream. After repeated theft they walk out of the scene. These brief pauses are the only patrol change in this art pass.

The generic target animation fallback no longer restarts toddler animations every frame. Scaled art height also positions awareness indicators correctly. Other target types keep their existing behavior and artwork.

## Verification and next entities

Rendered Godot run: 693 checks, zero failures. Added checks cover atlas bounds and aligned baselines, eating/walking/crying/departure selection, animation continuity, mirrored hand position, successful theft and parent alert, food restoration and visual scale. Captures include `toddler-eating.png`, `toddler-crying.png` and `toddler-sheet-preview.png` in `test-output/`.

This establishes the character-sheet approach for subsequent passes. Suggested order: sunbathers, parents/picnic families, dog and owner, kiosk customers, pier diners, lifeguard, seafood vendor, then rival gulls. Those entities still use their existing placeholder sheets. Each should retain separate food and clear idle/action/reaction silhouettes.

## Exact generation prompt

Create a polished production pixel-art animation sprite sheet for a seaside seagull arcade game. Transparent background with real alpha. EXACTLY twelve isolated frames arranged in a uniform FOUR COLUMN by THREE ROW grid. Canvas 1024x768. Each cell 256x256. The SAME friendly cartoon toddler in every frame: oversized round head, warm peach skin, short curly brown hair, sunny yellow bucket hat with coral band, coral-red short-sleeve shirt, teal dungaree shorts with cream buttons, little yellow sandals. Short chubby proportions, expressive readable face, navy pixel outlines, restrained seaside cream/coral/teal/gold colors, clean pixel clusters and 3-tone shading. Side view facing RIGHT, consistent model, scale and lighting throughout. Intended rendered height about 26 game pixels, so simplify detail and use strong silhouettes as if drawn at 32x40 then enlarged with nearest-neighbor. Not vector, not smooth painted art. All frames have identical foot baseline at y220 within each cell, body centered at x128, entire character inside x48..208 y28..220. Keep large clear transparent gutters. Row1 frames left to right: relaxed standing with front/right hand extended empty at chest height to hold separately rendered ice cream; subtle idle blink in same pose; happy licking/eating anticipation pose leaning head gently toward that same empty outstretched hand; second eating anticipation with happy eyes. DO NOT draw any food or cone, game overlays food separately. Row2: four distinct consecutive rightward walking cycle poses (left foot forward, passing feet, right foot forward, passing feet), front hand still held near chest at same location, clear alternating sandals. Row3: four crying animation poses after losing snack: startled open empty palms; puffed cheeks beginning sob; eyes shut open mouth crying with two small turquoise tears close to cheeks and hands rubbing eyes; open-mouth wail with hands lowered. Tears belong close to face and inside cell. Full body in every frame, no overlap. No text, labels, numbers, gridlines, shadows, props, background, extra people or food. Keep consistent character size and ground line; genuinely transparent between sprites.
