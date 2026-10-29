# Opening level redesign — 18 October 2026

The first four levels use authored JSON layouts with deterministic +/-3 position variation. Their rosters are not filled by the legacy generator. Level 6 keeps the existing generation rules.

| Level | Geometry | Cast and rhythm |
| --- | --- | --- |
| Training Day | 800 units of sand; open flight area, customer, bag, family | Four actors, calm air, slower customer and longer warnings. Nine action-driven lessons on the first visit. |
| Family Picnic | 1040 units of sand; quiet sunbathers, separated families, kiosk | Seven actors; gentle steady breeze; family restocking creates moving opportunities. No rival, dog, or pier. |
| Boardwalk Bustle | 1280 units; promenade begins at 430, pier at 920 | Sunbather, two customers, dog owner, pier diner. Gary arrives after the first swallowed non-scrap snack. No vendor or lifeguard. |
| Dog Day Afternoon | 1280 units; Boardwalk Bustle's promenade/pier layout, wind gusts, Gary from the start | The Boardwalk cast plus an off-lead terrier (`scripts/off_lead_dog.gd`, tuning in `data/tuning.json` under `off_lead_dog`) roaming the quiet beach x=250-410. It barks (0.4 s windup), chases at 95 px/s, leaps at low fliers and stuns on a bite. A gull more than 40 px above the sand is safe. A chase of 1.5 s or more that ends without a catch is an OUTRUN. |
| Three's a Crowd | 1280 units; Dog Day's promenade/pier layout without the dog, two pier diners (fried fish) | Gary from the start; Chip (speed 1.1, mug_chance 0.8) joins after the first swallowed snack with a `taunt` profile line (`after_snatch` and `taunt` are per-rival profile keys). Rivals race and mug each other and the player. |

## Training rules

The first-level opening panel waits for the **LET'S GULL IT** button. Mouse, touch, and keyboard/controller confirmation can activate it. Gameplay inputs and elapsed time cannot dismiss it; gameplay controls stay disabled until confirmation, including after pausing and resuming.

1. Hold flap and climb above y=110, then steer at least 30 units right of the start. Takeoff is remembered if flap is released before steering; the tip switches to the remaining steering action.
2. Land and collect a ground scrap.
3. Make a direct held-snack snatch during a dive, then climb above y=100 without a stun or crash.
4. Peck a sunbather bag and collect a snack from it. Bin crumbs and unrelated food do not advance this lesson.
5. Land by the highlighted bin and tap peck four times to release scraps and litter. Ordinary crumb collection does not complete this lesson. The practice bin is restocked when this lesson begins.
6. Choose another held snack and repeat the clean swoop and escape without a target highlight.
7. **Bump** (HUD lesson 8/9): a Dummy gull (`training_dummy` in `level_01.json`) flies a slow lap with an empty beak. Dive into it. A dive into an airborne rival with nothing to steal bumps it ("BONK!"), which completes the lesson.
8. **Mug** (HUD lesson 9/9): the Dummy now carries a snack (`BeachGame.DUMMY_FOOD`) once it has recovered from the bump. Dive through it to mug the snack. If the player's stomach is full the tip says to finish the snack first. Mugging completes the course.

The Dummy (`RivalPilot.dummy`) is not in `level.rivals`, so there is no rival score panel. It only patrols between the ends of its `range`, never hunts, dives, mugs or catches dropped food, and appears when lesson 7 begins (or on resume at lesson 7 or 8). Its art is the plain herring gull until the X-eyed variant arrives.

The lesson index is saved after each success. Restart resumes an unfinished course; Train Again starts at lesson zero. Course completion has its own saved flag, unlocks level two, and does not fabricate stars or a Practice time. The normal Training Day level card always opens the lessons: unfinished courses resume their checkpoint, while completed courses show REPLAY LESSONS and start at lesson zero. Replaying a completed course leaves existing records intact. The other levels use the selected Arcade/Practice mode.

Training replenishes the customer snack every five seconds (abandoned knocked food is removed before restoration) and refills an empty bag only once no loose food remains owned by it. These assistance rules run only during the course. All ordinary level food remains governed by the existing finite stock and replacement rules.

## Implementation and tuning

- `data/levels/level_01.json` through `level_03.json` own `world`, `zones`, `spawns`, and `props`. Keep each family's kiosk and children together in the recipe.
- `Config.apply_level_world()` resets geometry from the base tuning before applying a level, including beach retrieval/scatter bounds. Returning to menus restores base geometry.
- `BeachGame` owns lesson transitions, completion, and deferred rivals. `BeachStashRaids.bag_collected` distinguishes a real bag pickup from other food.
- Per-actor `speed_mult`, `awareness_mult`, and `reaction_delay` tune patrol speed, detection, and warning/wake timing. They default to 1 for existing actors.
- Backdrop signs use level zones; the HUD map scales to the level width and marks its sand, promenade, and pier boundaries. Existing sprites provide the different scenery arrangements; no new art sheets or audio were generated.
- Zone signs size to their 8 px labels, stay within zone/world bounds, and slide around props and standing adults.
- Arcade starting targets: Training Day 105 seconds / 100, 200, 300 points; Family Picnic 120 seconds / 250, 400, 550; Boardwalk Bustle 135 seconds / 250, 550, 750. These are initial tuning values, not a claim of human playtest balance.

## Validation focus

Exercise fresh and existing saves, checkpoint restart, forced lesson replay, no timed tutorial expiry, clean swoop versus dropped food, depletion recovery, family links, delayed rival arrival, per-level geometry restoration, menu bounds, and the existing six-level mechanics suite. Human playtesting should assess lesson wording, peck timing difficulty, travel time, and score targets.

Final rendered validation: **10,084 checks, zero failures**, using `tools/validate.ps1 -Capture`. Tutorial prompts, touch controls, completion board, and representative family/promenade/pier captures were also visually inspected. Logs and captures are under `test-output/`.

Zone sign boards use native 8 px text at y=84-95 (above the full 64 px standing actor band), with posts to y=134; text-width boards start at zone.from+28, search right then left within a 4 px zone inset, and avoid scaled prop sprites and flags. No level data or art changes are required.
