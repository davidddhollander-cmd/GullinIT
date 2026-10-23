# Off-lead pixel terrier, task 008

Generated 23 October 2026 with the built-in image tool, **after** the user-requested pixel-style replacement of the dog walker and leashed dog. The identity/style reference was `assets/reference/dog-walker-pixel-v1/paired-source.png`: the same small sandy terrier, cream muzzle/chest, folded ear tips, dark nose, expressive eyes, upturned tail and teal collar. There is no owner, leash, food or caught object in this sheet.

The complete untouched [generated source](dog-source.png) and [exact prompt](PROMPT.txt) remain here. The source has actual transparent alpha; hidden RGB background colour is discarded only where alpha is transparent. No API/CLI fallback or code-drawn character art was used.

`tools/prepare_off_lead_dog.gd` detects the five rows and six dogs in each row from transparent gutters rather than assuming nominal grid boundaries. It crops, hardens alpha, removes detached edge flecks, resizes with nearest-neighbor, aligns and packs the generated pixels. One scale derived from the idle row applies to **all thirty poses**, preserving head/body size through crouching, leaping and sniffing. The teal collar fixes the horizontal pivot; original relative paw heights within each source row are retained, including airborne poses. No anatomy is synthesized or repainted.

Production atlas: `assets/sprites/off-lead-dog-pixel-v1.png`, 6×5 cells of 128×96 pixels, display scale 0.5, idle art height 16 game pixels beside a 40px adult. Source paw baseline 84, sprite offset -18. Crisp lossless alpha, nearest sampling, no mipmaps. Flip horizontally for left-facing poses.

Registration: `data/dog_art.json`, mirrored into `data/sprites.json` under **`off_lead_dog`**. This preserves the existing `dog` ID for the paired dog walker.

| Clip | Frames | FPS | Loop |
| --- | --- | --- | --- |
| `run` | 0–5 | 12 | yes |
| `leap` | 6–11 | 10 | no |
| `catch` | 12–17 | 12 | no |
| `bite` | 12–17 (alias of catch) | 12 | no |
| `idle` | 18–23 | 4 | yes |
| `sniff` | 24–29 | 6 | yes |

This is asset preparation only: no off-lead dog spawns, navigation, jump physics, stun/catch behavior or Level 4 quest logic are added. Future gameplay code can use `Config.frames("off_lead_dog")` and the registry's scale/offset.

Rebuild and review with Godot:

```
godot --headless --path . --script tools/prepare_off_lead_dog.gd
godot --headless --path . --editor --import --quit
godot --path . --rendering-method gl_compatibility tools/off_lead_dog_preview.tscn
```

The [production preview](../../previews/off-lead-dog-production-v1.png) shows every drawn frame, mirrored poses for all five animation groups and the current walker/leashed dog for scale. It renders real `Config.frames` registrations with GullPixel labels at 8/16px, and reports **68 asset checks** for complete isolated dogs, gutters, native alpha and registration.
