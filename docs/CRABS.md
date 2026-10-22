# Catchable beach crabs

Implemented 22 October 2026 from the user's `assets/sprites/crabs-transparent.png`. No crab art was generated or drawn with code. The supplied sheet has six red poses and six blue poses. Both colors are live animated prey with the same **100 base points**, above every other food's base value. Normal combo/upwind modifiers still apply when earned; crabs never get the stall counter bonus.

## Artwork

The original sheet is untouched. An identical archival copy is `assets/reference/crabs-v1/supplied-source.png`; both SHA-256 hashes are `865A41F13DF331EB955B9E554C84D5F40E612018A1035FEC9F84D75155C31524`.

Run `tools/prepare_crabs.gd` with headless Godot to reproduce the two six-frame atlases. It finds transparent column gutters rather than assuming exact cells, preserving the blue crab's oversized claws; it asserts that no crop crosses opaque artwork. It crops, clears edge alpha, reduces with nearest sampling, and aligns complete characters into 48×40 source cells, with visible art up to 40×32 source pixels. Display at 0.5 scale retains the same 20×16 logical-pixel crab while preserving twice the detail in eyes, claws and outlines. The current derived files are `assets/sprites/crab-red-v2.png` and `crab-blue-v2.png`; v1 remains available for comparison.

## Behavior and controls

- Crabs appear at eligible sandy screen edges or quiet sandy pockets with direct shoreline access. Habitat stops before each level's promenade/pier boundary, including the different authored opening maps. Boardwalks and piers are excluded from arrivals, walking and escapes. An invalid side entry falls back to visible quiet sand; no available pocket delays arrival by two seconds.
- Quiet pockets exclude people and fixed towel/family anchors by 48 units, stall service areas by 64 units, and bins, rocks, sandcastles and tower bases by 24 units. Another arrival needs 28 units of separation from live crabs. These are local clearances, not bans on entire inhabited beach sections.
- Each crab receives a fixed 40–60-unit walking radius either side of its appearance anchor, clipped to the connected quiet pocket. Walks last 1–2 seconds with 0.4–0.8-second pauses. They never follow the player along the whole beach.
- The rear/second lane is 14 units behind the human ground line. Crabs linger there for 4.5–5.5 seconds, with front visits of 1.2–1.8 seconds and smooth depth changes. Sea arrivals grow from 35% to the rear lane's 90% scale during the one-second arrival. Sprite feet, depth, draw order and pickup point follow actual position. Existing artwork and manifest display scale are preserved.
- They become catchable after arrival. Red and blue share rules and value. Supplied poses animate at 8 fps, or 12 fps during an escape burst. Ground contact alone never collects a crab.
- Use normal **PECK** while landed near a front-lane crab, or timed **dive PECK** at either lane's actual position. Ground pecks require normal reach and feet within six vertical units of the crab's lane. A nearby missed peck animates normally and scares the crab without producing dropped food.
- A crab is a large snack: it needs an empty stomach and follows the existing swallowing/rest rules. Score is awarded on swallowing, once. Failed/full-stomach attempts preserve it. Catching immediately removes it from the active target list.
- A low gull within 40 horizontal units causes a 0.3-second notice pause, then a committed 0.8–1.2-second escape at 1.6 times normal speed. High flight does not scare them. Escape stays inside home bounds and favours the rear lane. If the gull leaves, the crab settles for 0.6 seconds and resumes foraging. Sustained pressure or insufficient escape space leads to sea retreat rather than repeated bursts. A miss cannot reset an active burst.
- A person coming within 36 horizontal units causes a notice cue followed by retreat. After 14 seconds an uncaught crab also retreats. Retreat moves from the actual position to the shoreline over 0.7 seconds while shrinking and fading; it never snaps back to the main ground line. Committed sea retreat is uncatchable; local escape remains catchable.
- Rivals retain human-food target selection, although a low rival can frighten a crab. Crabs never pinch, attack, stun, deduct points or knock food from a gull.

## Composition and spawning

`BeachGame` owns `CrabPopulation`, which owns `BeachCrab` target actors and their supplied-art `AnimatedSprite2D` children. `BeachCrab` implements EMERGE → SCUTTLE → CAUGHT/EXIT and reuses the normal target `snatched` signal. `CrabPopulation.crab_created` connects upward to the existing game target wiring, so digestion, score announcements and sound use the established catch flow. Crab actors stay separate from the crowd cap and human-food inventory.

Each level enables crabs through its top-level `crabs` configuration, preserved by the level generator. Shared tuning is in `data/tuning.json` under `crabs`: first arrival after 18 seconds, subsequent arrivals every 22–28 seconds, maximum two active, speed 22 pixels/second, lifetime 14 seconds, arrival duration one second, ground-peck reach 14 pixels and successful-peck cooldown 0.3 seconds. Levels can override these fields locally. Existing level time/star targets are unchanged.

The population has its own level-seeded RNG and does not consume the gameplay RNG stream. Sea/left/right entry types cycle, with alternating colors. Active tutorial lessons suppress spawning without advancing the first-arrival timer; replaying the level after training uses normal arrivals. Pause, hit freeze, intro/results and scaled time use the same clock as the rest of gameplay. Level teardown frees the population and all surviving actors.

## Verification and renders

### Current habitat revision

The current focused suite passes **119 checks, zero failures**, including per-level boundaries, quiet-pocket exclusion, crowded-arrival deferral/retry, fixed walking bounds, sustained rear-lane occupancy and short front visits, high/low gull reactions, persistent-pressure and human-triggered retreat, misses, rear-lane dive catches, front-lane ground catches, unchanged scoring/capacity, pause/freeze and seeded repeatability. Log: `test-output/crab-habitat-checks.log`.

Final full integration: **15,956 checks, one failure**, the previously documented `level 6 rival leaves the scene of a theft` check. The log also contains an unrelated UI focus error (`grab_focus` on a control outside the tree). All crab checks pass within the full run. Log: `test-output/crab-habitat-integration.log`.

Run `tools/crab_habitat_preview.tscn` for the current real-game review. It captures arrival, rear/front lanes, ground catch, notice, escape, retreat and rear-lane dive catch at desktop and phone sizes. Both catches use actual collection/digestion/score routes and produce **200 points from two crabs**. Render log: `test-output/crab-habitat-render.log`; error log is empty. Rear/front desktop frames and the phone retreat frame were visually inspected. The supplied source SHA-256 remains unchanged.

Composition update: population reads live people from the spawner and receives current gulls from the game tick. Crabs keep the EMERGE/SCUTTLE/CAUGHT/EXIT lifecycle, with WALK/PAUSE/NOTICE/ESCAPE/SETTLE activities inside SCUTTLE. Individual routines use independent seeded RNGs. Failed arrivals do not advance the entry sequence. All timers still follow the game's scaled clock.

The records below describe earlier revisions, before bounded habitat and persistent lanes.

`tests/crab_checks.tscn` passes **73 checks** covering supplied poses, aligned complete art, highest base points, all three entry types, animation/movement, configured levels, ground pecks, swept dive catches, missing pecks, walking contact, full stomachs, once-only collection/scoring, absence of the counter bonus, population cap, training suppression, RNG isolation, pause/freeze/results, retreat and teardown.

The full headless integration run reports **15,910 checks, one failure**: `level 6 rival leaves the scene of a theft`. This is the same rival escape-distance failure previously reproduced with order bubbles disabled at the 1.4-second preparation tuning; crab checks and all other integration checks pass. Logs: `test-output/crab-checks.log` and `test-output/crab-integration.log`.

Run `tools/crab_preview.tscn` for the reproducible actual-game capture: red sea emergence, blue right-edge arrival, ground peck, red left-edge arrival, and blue dive-snatch. The capture finishes with two swallowed crabs and 200 points. It manually steps a staged scene and uses the real catch/digestion/scoring routes. Output frames go to `test-output/crab-frames/`, assembled at 20 fps using FFmpeg.

Preview artifacts: `assets/previews/crab-cycle-v1.gif`, `crab-desktop-v1.png` and `crab-phone-v1.png`. Desktop/phone arrival, ground-catch and dive-catch frames were visually inspected; the render error log is empty.

## Sharper art and emergence revision

The current preview is `assets/previews/crab-cycle-v2.gif`, with `crab-desktop-v2.png` and `crab-phone-v2.png`. It uses the sharper supplied-art imports and perspective growth described above. The original source artwork remains untouched. Its staged ground/dive catches still produce 200 points from two swallowed crabs. Both desktop and phone renders, including a small sea-emergence frame, were visually inspected.

V2 focused checks: **82 checks, zero failures**, including source detail/alignment, small sea arrival, growth/foot anchoring, full-size land/edge arrival and shrinking retreat, alongside all previous capture/scoring checks (`test-output/crab-v2-checks.log`).

V2 full integration: **15,919 checks, one failure**, the same known level-6 rival escape-distance check (`test-output/crab-v2-integration.log`). Render errors remain empty and the original source hash is unchanged.
