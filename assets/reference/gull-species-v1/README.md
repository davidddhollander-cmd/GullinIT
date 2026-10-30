# Gull concept collection — three species, three alternatives each

Created with the built-in image-generation tool on 19 October 2026. Nine source sheets each contain a standing and a flying view: **nine design alternatives / eighteen bird illustrations**. Each exact prompt is saved in the corresponding `*-prompt.txt`. Herring A additionally has `herring-a-correction-prompt.txt`, which changes the flying bird's tail to adult white plumage.

| Species / game role | A | B | C |
| --- | --- | --- | --- |
| Herring gull / standard | Coastal | Chip Thief | Harbour Rogue |
| Black-legged kittiwake / smaller and faster | Coastal | Quick Flick | Sea Dart |
| Great black-backed gull / larger | Coastal | Big Boss | Breakwater Bruiser |

`*-source.png` files are the full generated sheets. `concepts.json` records the labels and intended roles. `SOURCES.md` provides identification sources, source photographs and attribution information. B variants used their corresponding A sheet as an additional style-family reference; C variants used the species photograph and diner style reference directly to explore alternative silhouettes.

Prepared review silhouettes are in `assets/pilots/gull-species-v1/`. Each concept has a full-detail transparent standing/flying cutout and a separate compact pixel-size preparation. No old gull source or production sprite registry entry is replaced during this concept stage.

Review boards:

- `assets/archive/previews/gull-species-herring-v1.png`
- `assets/archive/previews/gull-species-kittiwake-v1.png`
- `assets/archive/previews/gull-species-great-black-backed-v1.png`
- `assets/archive/previews/gull-species-size-comparison-v1.png`

The first three present design detail, with standing and flight views aligned for comparison; they are not biological scale charts. The last board compares B at proposed game sizes: 22, 17 and 28 logical pixels of standing height. These are game-art proposals. Kittiwake speed tuning and all other gameplay statistics remain a later implementation decision.

Reproduce prepared silhouettes with Godot `--headless --path . --script tools/prepare_gull_species_concepts.gd`; render the four boards with `tools/gull_species_review.tscn`. Source alpha is isolated to the complete bird, and compact previews use hard alpha and nearest sampling without palette reduction.

Next production pass, after design selection: build idle/blink, walk, full flap, glide, climb, dive preparation, dive, beak/snatch contact, pull-up, landing/perch and stun poses. Match body/head scale across states, use individual padded atlas cells, and align beak/feet with existing interaction anchors. Species should be independent of player/rival assignment; preserve species markings rather than relying on a global blue tint to define rivals. Exact animation counts and speed/hitbox tuning should be resolved with the chosen silhouettes.
