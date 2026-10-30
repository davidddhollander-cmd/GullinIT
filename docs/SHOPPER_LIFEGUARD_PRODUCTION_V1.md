# Shopper and lifeguard production — 19 October 2026

Both characters now use the approved diner-led rendering treatment. Shopper identity remains dark curly hair/stubble, mustard overshirt, cream tee, navy shorts and sandals. The lifeguard retains the older review design: blond hair, red cap/vest, navy shorts, yellow whistle and red/white/teal shoes.

## Art and source reuse

- `assets/archive/sprites/shopper-diner-style.png`: 1024 × 512, 26 mapped frame slots covering idle, six-frame walk, six-frame chase, alert, warning, empty-hand theft reaction, swat windup and swat contact/recovery.
- `assets/sprites/lifeguard-diner-style.png`: 1024 × 512, 32 mapped frame slots covering idle/blink, lookout, alert, patrol, whistle preparation, whistle/wave, pointing, angry, six-frame run, swat and windup.

Both use 128 × 128 source cells, 80-pixel standing figures, half-scale display, 40 logical-pixel height, source sole baseline 116 and sprite offset -26. Genuine binary alpha, nearest sampling and no mipmaps replace painted downsampling/cutout for the shopper. Isolated connected figures and transparent gutters prevent adjacent-frame contamination. The old runtime source images are retained as archives.

The lifeguard's existing two review sheets supply the base design, idle/lookout/patrol and whistle/pointing poses. Disconnected whistle symbols are omitted. Only run and swat gaps required new sources. The first generated run row repeated overly similar strides, so a targeted replacement supplied clearer narrow passing and knee-lift poses. The new shopper pilot was viewed beside the diner/mum at runtime size before its motion/action sheets were generated. All new full sources and exact built-in image-generation prompts are in `assets/reference/shopper-lifeguard-v1/`.

Idle, alert and warning include held poses; this does not claim a unique drawing for every repeated clip slot. Left-facing art is mirrored, with food positions mirrored at the same time. Shopper reactions intentionally reuse selected utility images rather than repurposing the old painted expressions.

## Runtime behaviour

`ShopperArt` selects idle, walking, dedicated chase, warning, theft reaction, windup and actual swat contact. Separate snack positions come from per-frame waist-palm anchors and update with animation frame changes. Those visible positions remain authoritative for theft. The free arm swats while the snack hand stays available. Existing departure, replenishment, scoring and chase/hit rules remain authoritative.

`LifeguardArt` selects patrol, whistle, lookout, pointing, chase and swat. The existing whistle trigger is evaluated before the shared adult-reaction early return so close dives no longer bypass it. The mouth-whistle frame is selected before the event is emitted; the same event retains nearby awareness alerts and its cooldown. A brief 0.8-second presentation timer plants the guard during the standing whistle poses, including during shared chase/return movement. A new whistle waits for an active swat-contact pose to finish. Generic fallback animation selection no longer overwrites lifeguard poses.

Both new swat sequences distinguish preparation from contact. Shared swat timers select windup; the actual `_hit` sets a 0.28-second contact/recovery presentation starting at drawn contact frame 2. Animation does not create a second hit or change hit reach.

## Reproduction and review

Run Godot with `--headless --path . --script tools/prepare_lifeguard.gd`, then `tools/prepare_shopper.gd`, then run `tools/map_staff_art.py` with Python. The prepared manifests are `data/lifeguard_art.json` and `data/shopper_art.json`; the mapper updates only their registry entries. The older beachgoer mapping tool now preserves the new shopper manifest when rebuilding the dog-owner entry.

`assets/archive/previews/shopper-lifeguard-production-v1.png` shows actual runtime art and separate food. `shopper-style-pilot-v1.png` retains the initial style check. `tools/staff_production_preview.tscn` reproduces the final comparison. Gameplay captures are retained in `assets/previews/shopper-lifeguard-production-v1/`.

Validation uses `tools/validate.ps1 -Capture` with the existing whole-game suite plus `tests/staff_art_checks.gd`. It covers alpha, atlas bounds, gutters, isolated silhouettes, foot baselines, distinct advancing travel/action frames, scale/filter settings, real whistle event/pose synchronization and cooldown, close left-facing whistle, planted whistle feet, no interruption of contact, nearby alerts, chase/windup/contact timing, mirrored snacks and swept food theft. The rendered run and gameplay error log are `test-output/staff-production-validation.log` and `test-output/capture-errors.log`.

Final rendered validation: **11,416 checks, zero failures**, with an empty gameplay error log. The production comparison and gameplay captures were visually checked for style/scale, complete limbs, snack placement, whistle readability and actual swat contact.

Code review checked animation priorities, timer ownership, frame callbacks, mirroring, source preservation, regeneration paths and scope. No new signal connections or texture/resource loads are introduced in per-frame animation updates. Existing dog-owner art and behaviour are unchanged. Full source preparation remains an offline task; standalone preparation scripts emit the previously observed Godot resource-cleanup warnings, separately from rendered gameplay validation.
