# Picnic bag variations

Created 18 October 2026 with built-in ImageGen, then prepared with `tools/prepare_picnic_bags.gd` using nearest-neighbour reduction and the shared environment palette.

Three separate transparent 32 × 24 PNGs in `assets/sprites`:

- `retro-picnic-bag-coral-32bit.png`: coral canvas duffel with cream straps.
- `retro-picnic-bag-teal-32bit.png`: teal insulated cooler bag with front pocket.
- `retro-picnic-bag-woven-32bit.png`: woven straw tote with coral stripe.

All cells use bottom-centre ground anchor (16, 23), binary alpha and a maximum 28 × 21 silhouette. Render at 1× with nearest filtering; mipmaps off. The review sheet in `assets/previews/picnic-bags-review-v1.png` shows coral, teal and woven from left to right at 8×. Sources are preserved in `assets/reference/picnic-bags`. The bags are now in gameplay: each sunbather's picnic bag uses one of the three, chosen randomly (seeded per level) by `BeachSpawner._free_bag_variant` so no two live bags in a level share a style. The remaining-peck dots are still drawn over the sprite.

Regenerate native assets and the review sheet from the project root:

```powershell
& .\.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/prepare_picnic_bags.gd
```

## Generation prompts

### coral

Use case: stylized-concept. Asset type: single production pixel-art picnic bag prop for Gullin' It, a seaside 2D game at 320x180 logical resolution. Create ONE coral canvas picnic duffel, closed zipper, rounded rectangular body, two cream webbing straps running vertically across its front and a single short raised carry handle. Broad front face with a narrow right side and a shallow visible top, almost side-on game view. Navy #183B4E stepped outline, coral #EF725C main fabric, muted brick #B94D4E shadow, cream #FFF4DA straps, one tiny gold #FFC65C zipper pull. Match chunky 32-bit-era beach props, readable silhouette, broad flat color clusters, no more than 8 colors, only 2 tones per material. Design as if on a strict 32x24 pixel grid enlarged with nearest-neighbor; bag silhouette about 28 pixels wide and 20 pixels high including handle. Obvious large square pixels, uniform pixel size, no fine detail. Center one complete isolated bag on a transparent canvas with generous clear margin, flat horizontal bottom, entire handle visible. No labels, letters, food, towel, characters, ground, cast shadow, scene, watermark, checkerboard, gradients, antialiasing, soft edges, realistic fabric or painted texture. Genuine transparent alpha background.

### teal

Use case: stylized-concept. Asset type: single production pixel-art picnic bag prop for Gullin' It, a seaside 2D game at 320x180 logical resolution. Create ONE teal insulated picnic cooler BAG made of soft fabric, compact boxy rectangular zipped body, cream lid trim, two short navy carry handles joined above the lid, cream webbing straps and a small rectangular front pocket. Clearly a portable soft lunch bag, not a hard cooler chest or suitcase. Broad front face with a narrow right side and a shallow visible top, almost side-on game view. Navy #183B4E stepped outline, teal #408FA8 main fabric, deep teal #28667B shadow, cream #FFF4DA trim, tiny gold #FFC65C zipper pull. Match chunky 32-bit-era beach props, readable silhouette, broad flat color clusters, no more than 8 colors, only 2 tones per material. Design as if on a strict 32x24 pixel grid enlarged with nearest-neighbor; bag silhouette about 28 pixels wide and 20 pixels high including handles. Obvious large square pixels, uniform pixel size, no fine detail. Center one complete isolated bag on a transparent canvas with generous clear margin, flat horizontal bottom, entire handles visible. No labels, letters, food, towel, characters, ground, cast shadow, scene, watermark, checkerboard, gradients, antialiasing, soft edges, realistic fabric or painted texture. Genuine transparent alpha background.

### woven

Use case: stylized-concept. Asset type: single production pixel-art picnic bag prop for Gullin' It, a seaside 2D game at 320x180 logical resolution. Create ONE warm straw-colored woven picnic tote BAG, broad soft trapezoid body slightly wider at the top, two short arched dark tan carry handles, cream folded top trim and a single broad coral horizontal stripe around its lower third. Reads as a soft woven beach picnic tote, not a rigid wicker basket, no hinged lid. Broad front face with a narrow right side and a shallow visible top, almost side-on game view. Navy #183B4E stepped outline, sand #E8C58E main body, tan #C69A68 shadow, warm wood #AA7047 handles, cream #FFF4DA trim, coral #EF725C stripe. Suggest weaving with only two or three broad stepped flat blocks, no fine weave pattern. Match chunky 32-bit-era beach props, readable silhouette, broad flat color clusters, no more than 8 colors, only 2 tones per material. Design as if on a strict 32x24 pixel grid enlarged with nearest-neighbor; bag silhouette about 28 pixels wide and 20 pixels high including handles. Obvious large square pixels, uniform pixel size, no fine detail. Center one complete isolated bag on a transparent canvas with generous clear margin, flat horizontal bottom, entire handles visible. No labels, letters, food, towel, characters, ground, cast shadow, scene, watermark, checkerboard, gradients, antialiasing, soft edges, realistic fabric or painted texture. Genuine transparent alpha background.

