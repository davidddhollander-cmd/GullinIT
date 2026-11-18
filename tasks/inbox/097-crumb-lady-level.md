# 097 — Level 4 "Feeding Time": crumb lady and pigeons

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-18

## Goal
A new level 4 built around a crumb lady who walks the beach throwing crumbs every 8-10 s, and a pigeon flock that races the gull for them. The gull mugs pigeons to scatter them for a few seconds, then they come back. Crumbs and bins are the main food, so the pass score is lower than level 3.

## Context
- Art (already committed, use as-is, never redraw): `assets/lab/crumb-lady-v2-sheet.png` (6 cols x 4 rows, 1536x1000: row 1 walk, row 2 angry swat, row 3 panic run, row 4 crumb throw; crumbs leave her hand in frames 4-5), `assets/lab/pigeon-v1-sheet.png` and `assets/lab/pigeon-v2-sheet.png` (4 cols x 5 rows, 1664x1400: row 1 idle + 3 walk, row 2 walk, row 3 wingbeat, row 4 glide / dive prep / dive / pull-up, row 5 airborne snatch, ground peck, landing, stunned crouch). Move or copy them into `assets/sprites/crumb-lady-v2/` and `assets/sprites/pigeon/` and keep the full source images. Code may crop, align, scale and animate them.
- Closest existing pattern for a standalone NPC with its own sheet: `scripts/watergun_teen.gd` + `data/watergun_teen_art.json`. Fixed ground crumbs: `scripts/scraps.gd`. Mug/stun on the gull: `scripts/rival_gull.gd`, `Config.tuning.rival.mug_*`. Quests: `scripts/quests.gd` and the `quests` blocks in `data/levels/*.json`.
- Levels load from `data/levels/level_%02d.json` (`scripts/autoload/config.gd`).
- AGENTS.md: no code-drawn characters (pigeons and the lady are sprite-only). UI text on the 8 px GullPixel grid. Tuning goes in `data/*.json`, not code constants.
- Use the `godot-prompter:state-machine` and `godot-prompter:ai-navigation` skills for the lady and pigeon behaviour.

## Requirements
1. **Insert as level 4.** Rename `level_04..07.json` to `level_05..08.json` and bump their `"id"`. New level is `level_04.json`. Grep scripts, tests and data for every hard-coded level number (known: `level_generator.gd` `id <= 5` / `id >= 5`, `spawner.gd` `id >= 4`, `beach_routine.gd`, `main.gd`, `data/leaderboards.json` seed boards keyed by id, quest ids like `l4_*`, tests) and shift them so levels 5-8 behave exactly as old 4-7 did. Decide each check for the new level 4 on its merits (mark it `"authored": true` if that keeps the generator out of it). Leave `data/demo.json` `last_level: 3` alone. Don't migrate saves. Say in the Report what happens to saved progress and online boards for the shifted levels.
2. **Level 4 data.** Name "Feeding Time", time limit ~120 s, stars `[200, 400, 550]`. No rival gulls, crabs on. Food: 3-4 bins plus a wheelie bin, one light food NPC (a kiosk customer with a kiosk) and maybe one sunbather. Turn off the fixed scrap row for this level with a level flag, so crumbs come from the lady. Add a twist tip like `MUG THE PIGEONS, NICK THEIR CRUMBS!` (use the existing twist/tip mechanism). Quests, e.g. "EAT 15 THROWN CRUMBS" and "SCATTER THE PIGEONS 5 TIMES". Add events where none exist.
3. **Crumb lady.** Normal adult scale, matching other adults. Walks a patrol range (from level data) with the walk row. Every 8-10 s (random, from data) she stops, faces her walk direction and plays the throw row. On the release frame she throws a fan of ~5-8 crumbs that land in an arc about 15-50 px ahead. Thrown crumbs use the existing `crumbs` food (points, pickup radius, look). They stay until eaten, never respawn, and are capped (e.g. 24 on the ground). If the gull is grounded or pecking within ~18 px of her, she turns and plays the angry swat row, and the gull is knocked and stunned the way a mug stuns (reuse that path), with a cooldown. She doesn't swat while throwing. The panic-run row is unused for now.
4. **Pigeons.** A flock of about 6, alternating the v1 and v2 sheets, drawn about the same size as or a bit smaller than the gull's grounded sprite. Idle and wander near the lady. When thrown crumbs land, each pigeon walks to the nearest unclaimed crumb, pecks it (peck frame, ~0.6 s) and removes it. They walk slower than the gull flies, so a quick gull wins most races. Rival-gull ground jobs should keep ignoring thrown crumbs only if that is simpler (there are no rivals in this level).
5. **Mugging pigeons.** When the gull dives or swoops into a pigeon (same contact rules as bumping or mugging a rival; don't invent new controls), that pigeon and every pigeon within ~40 px take off with the wingbeat row and fly away up and off-screen. After ~6 s (from data) they glide back in and land near the lady (glide → landing frames). A pigeon in the air can't be mugged or eat crumbs. Give the scatter a small feedback cue using existing effects/SFX. Emit an event for the quest.
6. Put all tuning (throw interval, fan size and spread, crumb cap, swat range/cooldown, pigeon speed, peck time, scatter radius, return delay, flock size) in data, either a level block or a `tuning.json` section.

## Out of scope
- New art, the panic-run behaviour, rival gulls eating thrown crumbs, save migration, changing the demo lock.
- Rebalancing levels 5-8 beyond keeping them identical to old 4-7.

## Done when (acceptance)
- [ ] Level select shows 8 levels with "Feeding Time" at 4, and levels 5-8 play exactly like old 4-7.
- [ ] The lady walks and throws a crumb fan every 8-10 s. Crumbs land, can be eaten by the gull for `crumbs` points, and don't respawn.
- [ ] Pigeons go for fresh crumbs and eat them. Mugging scatters the nearby flock for ~6 s, then they return.
- [ ] Landing beside the lady gets the gull swatted (angry row) and stunned, with a cooldown.
- [ ] Characters are sprite sheets only, with no code-drawn bodies.
- [ ] Integration checks added and wired into `tests/integration.gd`: level count/order, lady throws within 10 s and adds crumbs, a pigeon eats a crumb, a mug scatters and the pigeon returns, the swat stuns. Fix existing tests that pointed at old level numbers.
- [ ] Headless `tests/integration.tscn` passes with no new failures (one known failure in the play copy, "demo.json enables the three-level demo", is expected there only).

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->
