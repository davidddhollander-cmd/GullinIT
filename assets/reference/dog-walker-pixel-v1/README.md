# Pixel dog walker and terrier

User-requested prerequisite to task 008, created 23 October 2026 with the built-in image generator. The original `assets/sprites/dog-owner-polished.png` was the identity reference; `assets/previews/shopper-variants-production-v1.png` supplied the current cast's pixel style. The old art and both complete generated sheets remain intact.

- [paired-source.png](paired-source.png): original eight-pose pixel replacement, including idle, alert, bark and angry utility poses.
- [walk-source.png](walk-source.png): follow-up four-pose walk strip, with distinct contacts/passing poses for the owner and dog.
- [paired-prompt.txt](paired-prompt.txt) and [walk-prompt.txt](walk-prompt.txt): exact built-in generation prompts.

The woman retains her dark ponytail, lavender tee, beige shorts and lilac/white trainers. The sandy terrier retains its muzzle tufts and teal collar. A drawn leash joins the pair. Her forward hand is empty in the artwork; existing stealable food is overlaid and mirrors with the actor.

`tools/prepare_dog_walker_pixel.gd` only crops, cleans generated alpha, resizes with nearest-neighbor, aligns and packs existing source pixels. It preserves both figures even if the thin leash becomes disconnected during downsampling. No character bodies or limbs are drawn with code. Variable source-column widths are detected from transparent gutters, preserving paws and noses beyond nominal column boundaries.

Production atlas: `assets/sprites/dog-owner-pixel-v1.png`, eight 192×128 cells. Owner height 80 source pixels / 40 game pixels at scale 0.5; sole baseline 116 and sprite offset -26. The human's face fixes the horizontal pivot so dog movement does not slide her body. `data/dog_owner_art.json` holds the existing `dog` registry entry, mirrored into `data/sprites.json`. Existing clip names and timing remain walk 7 fps, idle/alert/angry 1 fps, bark 6 fps. Runtime uses nearest sampling, lossless hard alpha and no mipmaps/cutout shader.

Rebuild with Godot:

```
godot --headless --path . --script tools/prepare_dog_walker_pixel.gd
godot --headless --path . --editor --import --quit
godot --path . --rendering-method gl_compatibility tools/dog_walker_pixel_preview.tscn
```

[Production comparison and every pose](../../previews/dog-walker-pixel-v1.png), rendered with real actors and separate food alongside the current shoppers. Preview labels use GullPixel at 8/16px. The updated terrier supplies the visual identity for the later off-lead sheet.
