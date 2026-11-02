# pixelfx sheets

Sprite sheets in this folder are rendered with `tools/render.mjs --sheet --no-actor` from
https://github.com/patch-gg/pixelfx (commit a841596, v0.3.0), MIT License, Copyright (c) 2026 Patch.
Effects adapted from Sprite Fusion's open-source pixel art VFX (https://www.spritefusion.com/pixel-art-vfx),
MIT License, Copyright (c) 2026 Hugo Duprez.

Only standalone effects are used here: no pixelfx character, pose or act is imported (see AGENTS.md art rules).

Sheets are trimmed to their used area and empty tail frames (tools were run outside the repo); each sprite entry in
`data/sprites.json` carries the `pivot` (pixel in the frame that lands on the effect's position). All face right.

| sheet | pixelfx effect | frames | frame | pivot | notes |
|---|---|---|---|---|---|
| hit-spark-v1.png | impacts/hit-spark | 13 of 16 | 136x80 | 44,64 | every snatch |
| crit-hit-v1.png | impacts/crit-hit | 25 of 28 | 174x132 | 77,102 | bonus/counter snatch |
| poof-v1.png | spawn/poof | 43 of 49 | 92x76 | 43,65 | bin burst |
| collect-burst-v1.png | pickups/collect-burst | 33 of 42 | 78x88 | 36,81 | points awarded; gold palette `["#3a1c0a","#8a4a12","#d4832a","#ffc65c","#ffe9a8","#ffffff"]` |

`collect-burst-v1.png` is post-processed after export: opaque sparkle pixels are thickened by one pixel (4-neighbour) and given a
1 px dark outline (`#3a1c0a`) so it reads on light sand and sky; the soft glow is left as exported.

Later additions, same pipeline and trimming: `heavy-landing-v1.png` (impacts/heavy-landing, 36 of 49 frames, 135x42, pivot 69,28, scale 0.5, dive-speed touchdowns), `stunned-v1.png` (status/stunned, 60 frames, 48x31, pivot at centre, scale 0.7, looping stars and birds above a stunned gull). The poof sheet is kept but not played. No pixelfx water effect suits a mid-air watergun hit (splash, rain-splash, drip, bubbles and acid-splash are all floor based), so none is used.

`hit-spark-v1.json` is the unmodified export for reference.
