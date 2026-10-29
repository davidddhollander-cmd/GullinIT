# Project art requirements

- NEVER use code-generated art for main characters, including vendors. Use the built-in image generator or artwork supplied by the user. Do not draw character bodies, faces or limbs with code, vector primitives or programmatic pixel painting, including as placeholders.
- Code may import, crop, align and animate generated sprite assets; it may mask a full-body character behind scenery. Preserve the complete generated source artwork.
- Vendors are full-body characters at the normal adult scale. Inside stalls, show their upper body through the serving window and hide the lower body behind the stall/counter.
- Stall service places food on the counter for the buyer to collect. Preserve the readable dive-snatch bonus window while the food rests on the counter.

## Character depth rule (draw order against scenery)

Draw order on the beach comes from `z_index` bands, not Y-sort: props are siblings of the `actors` node, and `z_index` beats Y-sort across parents. A character that never sets `z_index` sits at 0 and is drawn *under every prop and every NPC*, whatever its feet do.

Bands: 0 backdrop/behind-prop (palms, rear-lane crabs) · 1 scenery and rear-lane walkers · 2 beach hut, stalls (`FoodStall.DRAW_DEPTH`), mid-lane walkers · 3 foreground walkers, anything standing in front of a prop · 4 gulls, stall portions, stash raids · 5 effects, projectiles, bubbles.

1. **Feet decide.** Any character with feet on the sand (NPC, teen, dog, crab, future vendors/staff) gets its `z_index` from its feet Y against the prop's base Y (the prop's `y`, default 160), every tick. Feet more than 4 px above the base: behind the prop (z below the prop's). Otherwise: in front (z above the prop's, and 3 or higher).
2. **One implementation.** Use the Spawner's depth logic (`depth_props`, `BEHIND_PROP_Z`, lane bands). Do not hand-pick a z in a character class and do not add a second copy of the rule.
3. **Every layered prop counts.** `Spawner.DEPTH_PROP_TYPES` must list every prop a character can overlap: benches, bins, wheelie bins, rocks, stalls, and also the hut (z 2), lamps and parasols. A new prop type that can overlap a walker is added there in the same change.
4. **Characters against characters.** Nearer feet draw on top, whatever the class. Non-`BeachTarget` actors (teen, dog) join the same lane bands as NPCs rather than sitting at 0.
5. **Use z, not masks, for ordinary props.** The only deliberate mask is a stall counter hiding a vendor's lower body (see art rules above).
6. **Test it.** Each new ground character gets a check: stand it at `(prop.x, base_y+8)` and `(prop.x, base_y-8)` beside a bench, bin and stall, and assert its `z_index` is above, then below, the prop's. Also pass it an NPC in front of and behind it.

Known exceptions: grounded gulls stay at z 4 and can draw over a prop they stand behind; shots stay at z 5.

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing
any game system, check for a matching `godot-prompter:*` skill and use it. This
applies to all agents and future sessions working in this repository.

Key skills: `player-controller`, `state-machine`, `event-bus`,
`scene-organization`, `component-system`, `resource-pattern`, `godot-ui`,
`hud-system`, `ai-navigation`, `camera-system`, `audio-system`, `save-load`,
`inventory-system`, `godot-testing`.

For the full skill list, use `godot-prompter:using-godot-prompter`.

## Task queue protocol

Claude (Opus) plans and reviews. Claude Sonnet implements game code; Codex generates pixel sprite assets with its image generator (and any task assigned to it). Each task's `Assignee:` line says who. Tasks live in `tasks/` (see `tasks/README.md`).
When asked to "process the task queue":

1. `git pull` on `main` first. If `tasks/LOCK` exists, stop and report who holds it.
2. Take the lowest-numbered file in `tasks/inbox/` whose `Assignee:` is you and whose `Depends on:` tasks (if any) are merged. Create `tasks/LOCK` containing your agent name, the task file and the time. Move the task to `tasks/doing/` and set `Status: doing`.
3. Create branch `<codex|sonnet>/<task-file-name-without-.md>` from `main`. Work only on that branch; never commit directly to `main`.
4. Follow the task's Requirements and "Done when" list exactly. If something is ambiguous, make the most reasonable choice and record it in the Report rather than stopping.
5. Run the tests (`./tools/validate.ps1`, or headless `tests/integration.tscn`). Do not mark a task done with new test failures.
6. Fill in the task's `## Report` (files changed, test results with check counts, decisions, anything not done, branch and last commit). Move the file to `tasks/done/`, set `Status: done`, commit, push the branch, then delete `tasks/LOCK`.
7. Do one task per run unless told otherwise.

When asked to "review the task queue" (Claude): review each task in `tasks/done/` against its acceptance list and the branch diff, run the tests, then merge to `main` and set `Status: merged`, or add `## Review notes`, set `Status: changes requested` and move it back to `tasks/inbox/`.

