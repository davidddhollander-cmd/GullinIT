# Brashness & gull powers — nice-to-have backlog

Saved 2026-10-27, after the herring Gang Call shipped. Nothing here is scheduled; pick items up as tasks when wanted.

## Done so far (for context)
- Brashness meter (`scripts/brashness.gd`, `brash` in `data/tuning.json`). It fills from direct snatches, counter grabs and muggings, and from screeching (faster from high perches). Stuns cost meter.
- Herring **Gang Call**: 3 allies dive and knock food loose; crowd looks up, then panics (task 040, `CrowdPanic`).
- Juice: ready sting, sound-wave rings, "!" pops, gang shadows, dive whoosh, ground-impact shake/freeze/feathers/rising hit cries, food flies higher, panic dust.
- Panic art: shoppers (041). Pier diners queued (task 042).

## More juice (nice to have)
- **Puffed-up gull while ready:** a pulsing gold glint on the player gull when the meter is full.
- **Darker screen on fire:** the screen dims slightly during the 0.5 s look-up beat.
- **Music duck:** music drops about 1 s when Gang Call fires (Audio already supports ducking).
- **Speed lines:** a feather or streak trail behind diving gang gulls (`vfx-speed-streak-v1.png` exists).
- **Stacking ally cries:** each gang gull gives a short call, pitched up in turn.
- **Slow-motion on the first hit:** about 0.2 s, using the existing slow-motion system.
- **Combo text:** "SCATTER x3!" when all three gulls land a hit, maybe with a small brashness refund.
- **Crowd screams:** a short "AAH!" or gasps on panic. Needs a sound source (CC0 from Freesound, or David's clips); confirm the licence first.
- **Panic quips:** one runner yells a line from `quips.json` ("MY CHIPS!").
- **Gang exit laugh:** a distant gull "ha-ha-ha" as the allies leave ("Seagull Ambient 6/7" in David's Downloads may fit).
- **Results board:** a "GANG CALLS: n" line at level end.
- **Stronger look_up pose:** the 041 shopper heads tilt only slightly; ask Codex for a stronger tilt if it reads weakly in game.
- **Panic art for the rest of the cast:** sunbather, mum/parent, lifeguard, market cleaner, old man (after 042).

## Powers for the other gulls (later)
Each species gets one power, fired the same way (screech, Q, or the touch CALL button on a full meter). Add a `power` block to the species in `data/species.json` and a branch in `BeachBrash.fire()`. Screeching is currently herring-only (`_can_screech` in `game.gd`) and needs a screech animation per species.

**Great black-back** (tough, shoves rivals)
- ⭐ **Shakedown:** for 5 s you can't be stunned; touching a rival makes it drop its food to you; humans flinch and drop food on contact.
- Bellow: an instant shockwave screech that stuns every rival and makes nearby humans drop food.
- Hostile Takeover: the vendor freezes and the stall's counter food is yours for a few seconds.

**Kittiwake** (fast diver)
- ⭐ **Feeding Frenzy:** for 4 s dives have no recovery time and flow into one another; each clean snatch adds +1 s. The cheapest to build: mostly timers on existing systems.
- Slipstream: you ignore wind and fly very fast for 5 s.
- Afterimage: decoy gulls draw swats and the dog while you strike.

**Open questions**
- Bullet Time perk vs brashness: both use Q and the touch button. The plan was to retire Bullet Time into a "Brazen" perk (brashness fills about 35% faster).
- Sound licence: the screech and hit clips come from an unlabelled Seagull pack in Downloads; check it before a public release.
