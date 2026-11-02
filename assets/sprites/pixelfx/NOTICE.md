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

`hit-spark-v1.json` is the unmodified export for reference.
