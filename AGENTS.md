# Project art requirements

- NEVER use code-generated art for main characters, including vendors. Use the built-in image generator or artwork supplied by the user. Do not draw character bodies, faces or limbs with code, vector primitives or programmatic pixel painting, including as placeholders.
- Code may import, crop, align and animate generated sprite assets; it may mask a full-body character behind scenery. Preserve the complete generated source artwork.
- Vendors are full-body characters at the normal adult scale. Inside stalls, show their upper body through the serving window and hide the lower body behind the stall/counter.
- Stall service places food on the counter for the buyer to collect. Preserve the readable dive-snatch bonus window while the food rests on the counter.

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

Claude plans and reviews; Codex implements. Tasks live in `tasks/` (see `tasks/README.md`).
When asked to "process the task queue":

1. `git pull` on `main` first. If `tasks/LOCK` exists, stop and report who holds it.
2. Take the lowest-numbered file in `tasks/inbox/`. Create `tasks/LOCK` containing your agent name, the task file and the time. Move the task to `tasks/doing/` and set `Status: doing`.
3. Create branch `codex/<task-file-name-without-.md>` from `main`. Work only on that branch; never commit directly to `main`.
4. Follow the task's Requirements and "Done when" list exactly. If something is ambiguous, make the most reasonable choice and record it in the Report rather than stopping.
5. Run the tests (`./tools/validate.ps1`, or headless `tests/integration.tscn`). Do not mark a task done with new test failures.
6. Fill in the task's `## Report` (files changed, test results with check counts, decisions, anything not done, branch and last commit). Move the file to `tasks/done/`, set `Status: done`, commit, push the branch, then delete `tasks/LOCK`.
7. Do one task per run unless told otherwise.

When asked to "review the task queue" (Claude): review each task in `tasks/done/` against its acceptance list and the branch diff, run the tests, then merge to `main` and set `Status: merged`, or add `## Review notes`, set `Status: changes requested` and move it back to `tasks/inbox/`.

