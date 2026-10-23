# Customer bite poses, task 006

Created 23 October 2026 with the built-in image generator. Each customer's existing production atlas was supplied as its identity, style and palette reference. The complete, unmodified generated strips and exact prompts are kept here:

| Appearance | Generated source | Prompt | Runtime bite indices |
| --- | --- | --- | --- |
| `kiosk_customer` | [kiosk-source.png](kiosk-source.png) | [kiosk-prompt.txt](kiosk-prompt.txt) | 38, 39, 40 |
| `shopper_mullet` | [mullet-source.png](mullet-source.png) | [mullet-prompt.txt](mullet-prompt.txt) | 26, 27, 28 |
| `shopper_sundress` | [sundress-source.png](sundress-source.png) | [sundress-prompt.txt](sundress-prompt.txt) | 26, 27, 28 |

The three frames raise the snack hand, hold it at the mouth, and lower it. The `bite` animation is non-looping at 5 fps (0.6 seconds total), ready for task 007. The images contain empty hands; the existing separate food sprite remains visible and stealable. `food_anchors.bite` follows each hand and mirrors through the existing food alignment code.

Prepared atlases are `assets/sprites/shopper-diner-style-v2-bite-v1.png`, `shopper-mullet-walk-v2-bite-v1.png` and `shopper-sundress-walk-v2-bite-v1.png`. Each uses the existing 128px canvas, 80px source actor height, 0.5 display scale, 40px adult height, sole baseline 116 and sprite offset -26. Existing animation cells remain pixel-identical. Preparation only crops, cleans alpha, scales with nearest-neighbor, aligns and packs generated artwork; it does not draw anatomy. Original atlases and complete generated strips remain intact.

Rebuild from the project root using Godot:

```
godot --headless --path . --script tools/prepare_shopper_bites.gd
godot --headless --path . --editor --import --quit
godot --path . --rendering-method gl_compatibility tools/shopper_bite_preview.tscn
```

The preparation updates `data/shopper_art.json`, `data/shopper_variants_art.json`, and only the corresponding three entries in `data/sprites.json`. No additional mapper is needed. The preview uses real customer sprites and real food alignment, including mirrored bite poses, alongside the previous idle art. Its text uses GullPixel at 8 and 16px. It writes [the review screenshot](../../previews/shopper-bite-production-v1.png) and checks 45 registration/alignment assertions.

Task 006 is asset registration only. Entering the bite state and awarding the mid-air snatch quest remain task 007.
