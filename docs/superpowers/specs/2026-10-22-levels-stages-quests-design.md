# Levels, stages and mini-quests — design

Date: 2026-10-22. Status: approved by David in interview; Stage 3 deliberately left open.

## Goal

Replace "the last level with more of everything" with a three-stage story game where every level has its own rule (twist), three mini-quests that pay bonus points, and a boss/story finale per stage. Build the stage 1 demo levels (1–3) to this spec first so the itch.io playtest validates quests and twists.

## Story arc

1. **Beach** (6 levels): a hungry gull works its way up beach life. Ends at sunset, following a fishing boat out to sea.
2. **Pier & Sea** (4 levels): harbour, market, trawler. Ends with a whale swallowing everyone.
3. **Future** (4 levels): the whale spits the gull out years later on a ruined, post-apocalyptic beach. Something inside the whale made it a super gull. Powers, cast and levels to be interviewed later.

## Progression

- Straight line. 1 star (score target) opens the next level, as now.
- Stars stay as three score thresholds per level; they gate nothing beyond the next level.
- The last level of each stage is a **boss/story level**: won by its objective, not a score. Winning opens the next stage.

## Mini-quests

- Each level has **3 quests**: 2 fixed + slot 3 = **"Eat N <food>"**, rolled per run from the foods present in that level (e.g. 5 half-eaten doughnuts).
- Exceptions: Training Day has 2 fixed quests, no random slot, and shows quests only on replay (first run stays pure lessons).
- Every completed quest gives bonus points on every run.
- The first completion of each fixed quest pays **1 Feather**. The random slot pays 1 Feather the first time it is completed in that level; later rolls give points only.
- Quests show on the level card (ticked when done) and as a small in-run checklist with a completion toast.
- Quests are counters over game events. Existing events: snatch (risky/upwind/mugged/handover), stun, COUNTER. New events needed: food eaten by type, crab eaten, toddler cried, bin emptied, mid-air bite snatched, dog outrun/caught, rival mugged by name, dive catch, bucket raided, net-haul catches, whole-fish carry, bag snatch.

## Stage 1 — Beach

| # | Level | Twist | Rivals | Fixed quests |
|---|---|---|---|---|
| 1 | Training Day | None — the lessons are the level | — | Empty the bin · Snatch a mid-air bite |
| 2 | Family Picnic | **Wind intro**: steady breeze, flags show direction, one-time upwind-bonus tip | — | 3 clean ice-cream snatches · Make a toddler cry |
| 3 | Boardwalk Bustle | **Gary arrives**: intro beat/taunt card; he only steals loose or dropped food | Gary | Mug Gary · Eat a crab |
| 4 | Dog Day Afternoon *(was Ice Cream Rush)* | **Off-lead dog**: fast, chases you on the ground and in low flight; stuns on catch | Gary | Pull off a COUNTER · Outrun the dog ×3 |
| 5 | Three's a Crowd *(was Pier Patrol; no whistle mechanic)* | **Chip debut**: a fast thief; Gary, Chip and you all fight over the pier food | Gary, Chip | 2 fried fish · Mug Chip |
| 6 | **Sunset Showdown — boss** | **Wind flips** periodically. **Bev** debuts: big and bossy, shoves smaller gulls off food, can only be mugged from behind | Gary, Chip, Bev | Mug all 3 rivals · Win by double (2× the second-place rival) |

Boss objective (L6): out-eat Gary, Chip and Bev on a rival scoreboard before the sun sets.

**Rivals compete, never cooperate** (decided 2026-10-23). Every gull is for itself:
- Rivals no longer split the beach between them: each picks the best food for itself, so they often race for the same target. First beak wins; the loser pulls up and looks elsewhere.
- Anyone can mug anyone in the air: rivals mug each other, the player mugs rivals, and rivals mug the player when the player carries food. Climbing away or swallowing quickly protects you.
- Personalities differ by numbers in data (speed, accuracy, how eagerly they mug), not by alliances. Chip is the most eager mugger; Gary's level 3 intro still only takes loose food.

Levels 4–6 become hand-built JSON layouts like 1–3 (`data/levels/level_0X.json`). The generator stays for filler/testing only.

## Stage 2 — Pier & Sea

New core mechanic: **diving** — plunge below the surface to catch fish, with a breath meter. New rivals replace Gary's gang: **cormorant** (out-dives you, steals underwater) and **skua pirate** (chases you mid-air until you drop your catch).

| # | Level | Twist | Rivals | Fixed quests |
|---|---|---|---|---|
| 7 | Harbour Quay | **Diving intro**: fishermen toss guts into calm water; catch them before they sink | Cormorant | Catch 3 fish underwater · Raid a bait bucket |
| 8 | Fish Market | **Hose vendor**: sprays gulls; soaked gulls fly heavy and slow for a few seconds | Skua (+ cormorant) | Steal a whole fish · Snatch from a shopper's bag |
| 9 | Trawler | **Net haul** every ~30 s spills fish on deck: a frenzy window | Cormorant, skua | Grab 3 fish in one net haul · Dive-catch a fish that slid overboard |
| 10 | **Whale — boss** | Starts at the trawler stern, scrolls out to open water (buoys, debris, the shoal) | Cormorant, skua | 10 dive catches · Mug both sea rivals |

Existing pier/sea environment art to start from (outside this repo): `C:\Users\david\Desktop\Contra-bands\assets\environment\pier\` — `animations/pier_sea_v11_animated.gif`, `references/pier_sea_v11_still.png`, `references/pier_sea_v11_four_frames.png`, and the generator `source/build_pier_v11.py`. Stage 2 art tasks import/adapt these before generating new pier or sea scenery.

Boss objective (L10): race the rivals to the fish shoal. The whale surfaces and swallows everyone (scripted ending → Stage 3).

## Stage 3 — Future (placeholder)

4 levels, super-gull powers, cast and twists to be decided in a separate interview. Only the story bridge (spat out years later) is fixed.

## Feathers shop

Opens after winning Sunset Showdown. Purchases are permanent.

**Species** (existing sprites: `assets/sprites/gull-*-diner-style.png`), small stat trade-offs:

| Species | Trade-off | Price |
|---|---|---|
| Herring gull | Baseline (default) | free |
| Great black-backed | Slower and heavier; shoves rivals; stunned less | 6 |
| Kittiwake | Best in wind and dives (stage 2 specialist) | 6 |

**Perks** — buy once, **equip 1** per run:

| Perk | Effect | Price |
|---|---|---|
| Bigger stomach | Eat more before slowing down | 3 |
| Keen eye | Highlights the best snatch target / longer bonus window | 3 |
| Dive speed | Faster dives | 4 |
| Strong skull | Ignore the first swat each run | 4 |
| Bullet time | Meter fills from clean snatches; spend it on slow-motion | 5 |

Economy: 29 first-time Feathers in stages 1–2 (2 + 5×3 + 4×3); everything costs 31, so buying it all needs almost every quest. Prices live in data, final values set in playtest.

## Data and code shape

- Per level JSON gains `"twist"` (id + params), `"quests"` (2 fixed: id, event, count, conditions, bonus points), `"random_quest"` (N range, eligible foods) and `"boss"` (objective id + params) where relevant.
- One quest tracker listens to game events and counts; no per-level quest code.
- Each twist is a self-contained component switched on by its id (wind intro, dog chaser, rival debut, wind flip, hose, net haul…).
- Save: completed quests per level, Feathers, owned species/perks, equipped species/perk. Existing stars and lesson records untouched.
- Prices, quest counts and bonus points in `data/*.json`, not code.

## Who builds what

| Work | Owner |
|---|---|
| Planning, task writing, review and merging | Claude (Opus) |
| Game code: quest tracker, twists, rivals, shop, save, diving, level JSON | **Claude Sonnet** |
| Pixel sprite assets (characters, vendors, rivals, dog, cormorant, skua, whale, fish, new food, props with character-like detail) | **Codex**, using its built-in image generator |
| Simple level elements drawn directly in Godot (water surface/waves, breath meter, flags, light/sky tints, buoys, nets, UI checklist) | Claude Sonnet, Godot direct pixel/primitive drawing |

Rule from `AGENTS.md` still applies: no code-drawn bodies, faces or limbs for any character (vendors, rivals, animals included). Direct Godot drawing is limited to scenery, effects and UI. Tasks in `tasks/inbox/` should state their owner so Codex picks only asset tasks and Sonnet picks code tasks; an asset task must land before the code task that uses it.

## Build order

1. Quest tracker + random food slot + Feathers save, on levels 1–3 (demo). L2 wind intro, L3 Gary intro beat.
2. Level 4 dog chaser (Codex: off-lead dog sprite sheet first), L5 Chip debut (competing rivals first, task 011), L6 boss scoreboard + Bev + wind flip (Codex: Bev sprite first). Hand-built JSON for 4–6.
3. Feathers shop, species stats, perks incl. bullet-time meter.
4. Diving + breath meter, cormorant and skua (Codex sprites first).
5. Levels 7–10 and the whale ending (Codex: harbour/market/trawler/whale art first).
6. Stage 3 interview.

## Testing

Each step extends `tests/integration.tscn`: quest counters fire on the right events, the random slot only rolls foods present in the level, Feathers pay once, boss objectives open the next stage, save round-trips quests/feathers/purchases, and equipped perks/species change the intended stats. Human playtest judges twist readability, quest difficulty and prices.
