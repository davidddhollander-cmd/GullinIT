# Stand roof signs — revision 2 approval assets

ChatGPT image-generation edits of the v1 designs, with more flourished retro lettering and a matching food cut-out overlapping each upper-left corner. The hot-dog sign keeps coral/cream/navy; the ice-cream sign keeps teal/cream/navy.

Selected transparent PNGs (2172×724 each):
- `assets/sprites/stand-sign-hot-dogs-v2.png`
- `assets/sprites/stand-sign-ice-cream-v2.png`

Original generated sources and exact prompts are preserved here. Both v1 assets remain untouched. The user approved integration of these v2 assets; the existing stands now display runtime crops produced by `tools/prepare_stand_roof_signs.gd`. Full-size approved PNGs remain unchanged. Lettering, icon placement and complete silhouettes were reviewed visually; transparent corners were checked.

Runtime assets: `assets/sprites/stand-sign-hot-dogs-runtime-v2.png` and `stand-sign-ice-cream-runtime-v2.png`. Display width is 64 game pixels with nearest filtering; a 256-pixel-wide source crop preserves the flourished text and food cut-outs. Both signs end one pixel above the serving-window top and keep the original shared draw depth.

Actual combined render: `assets/previews/stand-roof-signs-integrated-v2.png`. Full desktop and phone renders are beside it; reproduce with `tools/stand_roof_sign_preview.tscn`. That preview uses the production stand assembly, hiding unrelated wayfinding signs only in its review backdrop.

Validation: all six levels pass focused sign-placement checks; all 132 vendor/service checks pass. Full integration reports 15,919 checks with only the previously confirmed `level 6 rival leaves the scene of a theft` failure. The render error log is empty. Both desktop and phone renders were visually reviewed.
