# Herring gull long screech

The complete six-pose source sheet `herring-screech-source.png` was created with Codex's built-in image generator on 26 October 2026, using `../gull-production-v1/herring-source.png` as the approved character reference. No character pixels are painted by code. `tools/prepare_gull_screech.py` crops connected poses, scales all six equally, aligns their feet, and packs the transparent animation atlas.

The pose sequence follows the herring gull long call: a forward dip, then the bill swings high as the neck extends, a held open-bill peak, and recovery. Reference: [Cornell Lab, American Herring Gull sounds](https://www.allaboutbirds.org/guide/American_Herring_Gull/sounds) and [Cornell Bird Academy, Decoding Gull Behavior](https://academy.allaboutbirds.org/decoding-gull-behavior/).

The exact generation prompt is archived in `herring-screech-prompt.txt`. Built-in image-generation tool used; no CLI fallback.

In game, tap E retains the existing peck. Holding E for 0.24 seconds while the herring gull is grounded and still starts the screech and existing gull-call sound. The animation holds its raised-head pose until E is released; release plays the recovery pose. Movement, takeoff, pause, and level exit cancel the hold.
