# Gullin' It

A six-level, data-driven seaside arcade prototype for Godot. Aim a gull, hold climb, and dive to steal food while avoiding defensive beachgoers and competing gulls. Tested with the local Godot 4.7.2 Windows build.

The opening now progresses from **Training Day** (a compact, calm teaching beach), to **Family Picnic** (two picnic groups and their kiosk trips), to **Boardwalk Bustle** (customers, a dog owner, and a pier diner). These three maps have authored rosters, boundaries, landmarks, and small repeatable placement variations. Levels 4–6 retain the larger generated route.

Training Day teaches takeoff and steering, landing and crumbs, a timed swoop followed by a safe climb, bag raiding, and an independent swoop. Selecting its level card always opens the lessons, including after completing the tutorial; completed saves show **REPLAY LESSONS** and start from lesson one. There is no timer or snatch quota. Completed lessons save automatically; unfinished courses resume their checkpoint. Practice snacks are restored during training. Finishing unlocks Family Picnic without awarding stars or setting a Practice best time. **TRAIN AGAIN** explicitly starts over. Existing scores and unlocks are preserved. Gary enters Boardwalk Bustle after the first non-scrap snack is swallowed.

See `docs/OPENING_LEVELS.md` for the map contracts and tuning notes.

## Run

Import `project.godot` into Godot and press F6 on `scenes/main.tscn`, or F5 to run the project. The local engine is also available at `.tools/Godot_v4.7.2-stable_win64.exe` (ignored by Git).

## Controls

| Action | Mouse / keyboard | Controller |
| --- | --- | --- |
| Aim | Mouse, WASD, or arrow keys | Left stick |
| Climb | Hold left mouse or Space | Hold A |
| Dive | Right mouse or Shift | B |
| Peck during a dive / nearby stash on foot | Tap E | Tap X |
| Pause / resume | Escape or HUD pause button | Start |
| Restart | R | Back |
| Fullscreen | F11 | Options menu |
| Debug overlay / reload JSON | F1 / F2 | — |

Touch: drag the beach to aim, hold FLAP, and tap DIVE. Enable the touch overlay in Options when previewing on desktop. The first level waits for **LET'S GULL IT** at the bottom of its opening panel; click, tap, or confirm the focused button to begin. Other level introductions dismiss on the first button press or after two seconds. Controller A, Space, or left mouse flaps; keyboard A remains leftward aiming.

Holding flap beats the wings in short strokes (about three a second) that outpace a gentle gravity, so climbing is steady rather than instant and a single stroke only lifts a few pixels. Wind eases the sinking in either direction. Swoops with the wind are much faster, swoops against it much slower, and flap strokes are weaker when flying into the wind (stronger with it), so lifting out of an upwind dive is hard. Tuning lives under `flight.stroke_*`, `flight.gravity` and `wind.lift_*`/`wind.dive_drag`. Without flapping, the gull descends and lands on the sand. Aim left or right to walk on visibly stepping feet with folded wings, at one fifth of normal flying speed. Landing immediately limits movement to this walking pace. Ground crumbs award 2 points and single chips award 5; both reappear after 18 seconds. Hold flap to take off. Scraps do not count toward the 15 practice snatches or build a combo.

At the end of a run, the frozen beach stays visible beneath a hanging wooden score sign. Earned points, the clean-run bonus, snatches, stuns, special-event counts, and the final total tally in sequence before the stars appear. Click, tap, or press confirm to finish the tally immediately. A perched gull celebrates successful and Practice runs with a short screech, while a failed run gets a gag and a falling fish skeleton; these one-shot sounds follow the SFX and Master volume settings.

Sunbathers keep all food inside a large picnic duffle beside their feet. There is no exposed snack to steal by walking or diving. Land and peck the bag to scatter food, then catch or collect it for normal score, combo and Practice credit. Other beachgoers still carry food that can be stolen in a swoop.

Sunbather picnic bags show straps, a handle, a zip and small stock markers. All three snacks stay inside until pecked; newly scattered snacks fly for 0.3 seconds before either the gull or owner can collect them. Sunbathers remain on the sandy beach and retrieve snacks at 40 pixels/second after waking. The sunbather never automatically takes one out. An empty bag does not refill. Toddlers are linked to a specific mum through level data. A robbed toddler walks to that mum for a visible handover from the family's shared supply. Each mum starts with two crisp bags total, including the one already in her hand, plus a separate two-cookie reserve. These counts and the approach/handover timing are editable in `data/tuning.json`.

Beach bins also respond to the peck button (E / controller X / touch PECK). Four taps scatter three objects: mostly crumbs plus wrappers and paper. Each bin has nine objects per level attempt. Crumbs become edible after 0.3 seconds and award only 2 scrap points, without combos or practice credit. Garbage stays visible on the ground and cannot be eaten. Restarting the level resets the bin contents and litter.

When that supply is empty, or a toddler's seeded ice-cream insistence roll succeeds, mum gathers every linked child and walks the family to the visible kiosk. The stand quickly supplies only children missing food and tops mum back up to two crisp bags inclusive of the one in her hand. Children who still have food keep it. Purchases are held by the family as ordinary stealable food on the way home. Stealing a new purchase makes the family retreat elsewhere on the beach, offer any remaining finite backup, and wait before trying again; they do not leave permanently or loop straight back to the stand. The kiosk-trip timings, retreat distance and insistence chance are editable in `data/tuning.json`.

Tap dive to enter a steerable swoop. Keep moving the mouse, stick, or touch aim throughout the dive: aim downward to gain speed, then ahead and upward to rise using that speed. Rising uses stronger braking so the gull visibly slows as it climbs, nearly running out of speed before returning to normal flight. Higher dives have more room to accelerate. Collecting food does not pull the bird up automatically. Flapping returns to normal flight. Wind still pushes the dive; approach protected pier food at a shallow angle.

A fast, steep, beak-first impact with the sand resets the current run's points and combo and briefly stuns the gull. Slow or shallow landings keep your points. Saved best scores and unlocked levels are unaffected. The movement and crash thresholds can be adjusted in `data/tuning.json`.

Flight refinements: the dive preparation animation keeps moving; braking grows gradually with the upward angle. At the end of a swoop the gull coasts with its remaining speed instead of automatically accelerating sideways. Hold flap to regain powered flight. Letting go of the controller stick stops walking on the ground and preserves heading in the air. Mouse movement resumes mouse aiming after controller/touch input.

Held snacks require one timed peck during the active swoop. Tap E, controller X, or touch PECK just before the beak reaches the food; the strike lasts 0.12 seconds and cannot be retried until the next dive. A clean hit steals the snack. A glancing hit knocks it to the ground, where the gull can collect it after a brief grace period. The owner may recover it first: ice cream is never picked up, hotdogs have a 50% recovery chance, and crisp bags are always recovered if the gull leaves them. A dropped snack remains the same item and scores only when the gull claims it.

Crash severity uses downward impact speed (170 by default) when the beak leads the feet into the sand. Fast sideways movement alone is safe. The red `PULL UP! CRASH AHEAD` warning appears when descending toward the sand and approaching dangerous impact speed. Wind push uses the same rule in every airborne mode, changes gradually, and the HUD shows the push currently affecting the player.

Arcade awards stars and unlocks the next level after earning at least one star. Casual / Practice ends after 15 snatches with no time limit and keeps a separate best time; it uses the same level unlocks and does not award stars. Scores and options save to Godot's `user://save.json`.

## Tuning and art

Ground landings and takeoffs make five small sand pixels. Bag and bin pecks squish or wobble more strongly and rise slightly in pitch as the release approaches; the final hit rebounds and adds a short accent with six dust or crumb pixels. A depleted source gives a quiet hollow tap and a brief EMPTY message that fades, with the normal peck cooldown. An available nearby source takes priority over an empty one. Particles use `juice.particles` in `data/tuning.json`, floating labels use `juice.floating_text`, and raid sounds use `juice.audio` plus the Master/SFX sliders. For replacement art, adjust `BAG_PIVOT` and `BAG_SQUISH_TIME` in `scripts/target.gd`, or `BIN_WOBBLE_TIME`, `BIN_WOBBLE_ANGLE`, and the optional per-bin `wobble_pivot_y` prop value in `scripts/beach.gd`. The particles are drawn by `scripts/effects.gd` and do not depend on sprite frames.

The right-side **NEXT LEVEL** bar shows earned points against the first-star requirement. It excludes the pending clean-run bonus; final results still apply that bonus normally. The last level shows FINAL GOAL, and Practice shows snatches toward its completion target.

To raid a sunbather's bag, land beside it and tap E, controller X, or the PECK touch button three times. Holding the button does not repeat pecks. Up to two random snacks scatter from the finite stash; catch them in flight or collect them on the ground. Each counts as a stolen snack for points, combos and Practice. A disturbed sunbather stands, can swat nearby gulls, retrieves dropped food and returns to the bag. Retrieved food restores stash stock; food taken by the gull does not. Repeated pecking increases existing caution and shortens the reaction delay. Bags stay fixed beside the towel while their owner retrieves snacks. Standing/retrieval art is a temporary code-drawn pose pending the sunbather sprite pass.

To land deliberately, release flap and aim down beneath the gull (mouse/touch, or down on the stick/S key). The gull brakes sideways movement, sinks toward the ground and slows near touchdown. A LANDING hint and ground marker confirm the action. Hold flap to climb again or take off; the dive button still starts the faster, risky swoop. Normal sideways aiming keeps the existing slow passive descent. Landing tuning lives under `flight.landing_*` in `data/tuning.json`.

Toddlers now use a polished twelve-pose sheet, with short eating pauses, walking, blinking and crying after theft. Ice cream remains a separate stealable sprite. See `docs/TODDLER_ART.md` for frame mapping, provenance and the next entity-art passes.

The player gull now uses the supplied sprite-sheet artwork with standing, walking, flight and dive poses. See `docs/VISUALS.md` for the first visual-improvement plan, asset preparation, and frame alignment details. The original sheet is preserved separately; regenerating placeholder assets preserves the curated player manifest.

- `data/tuning.json`: flight, dive, scoring, wind, spawning, and effects.
- `data/foods.json`: eight foods in small, medium and large categories, including the code-native placeholder cookie, with points, sizes and sprites. See `docs/FOOD.md` for the generated food-atlas details.
- `data/targets.json`: each person's possible foods, awareness and defensive behavior.
- `data/levels/level_01.json` through `level_06.json`: level layout, rivals, wind, timers, and star thresholds.
- `data/sprites.json`: sprite sheet paths, dimensions, frame indices, animation speeds, and loop settings. Replace the PNGs while preserving those contracts, or update the manifest to match new sheets.
- `tools/generate_assets.py`: original placeholder pixel art, font, sounds, and initial JSON generator (Python standard library only). **Running it overwrites assets and tuning data**, including hand edits; back up changes first.
- Menu typography uses the bundled 8 px GullPixel bitmap face at its native size or an exact 2x size. Keep menu font overrides on that 8 px grid so one-pixel letter strokes stay crisp.

F2 reloads JSON and refreshes art during play. Reload validates parsing, top-level tuning sections, food categories/values and food references; preserve the supplied schema and numeric ranges. Restart to apply changed level spawns, food choices or rival profiles. Keep active food IDs when reloading an existing level.

## Validation

From PowerShell in this directory:

```powershell
./tools/validate.ps1
./tools/validate.ps1 -Capture
```

Use `-Godot 'C:/path/to/Godot_console.exe'` for another installation. The script keeps engine settings and test saves under ignored `.tools/userdata`; it does not change your ordinary player save. Capture requires a graphics device and writes PNGs to `test-output/`.

The integration scene exercises all six timed loops, scoring, persistence, unlocks, dive hits, stun recovery, explicit family links, shared-stock conservation, finite sunbather depletion, retry reset, parent shields and alerts, vendor telegraphing, wind gusts, rival mugging, casual completion, menu bounds, and input routing. It uses deterministic simulation, not a human playthrough. See `docs/HANDOFF.md` for the validated state and remaining limits.

## Export

`export_presets.cfg` contains Windows Desktop and single-threaded Web presets, explicitly including gameplay JSON. Install export templates matching your engine version, create `build/windows` and `build/web`, then use Project > Export or:

```powershell
godot --headless --path . --export-release 'Windows Desktop'
godot --headless --path . --export-release 'Web'
```

These presets are configuration, not evidence of a tested release. No mobile platform presets, signing credentials, or native-device certification are included.

