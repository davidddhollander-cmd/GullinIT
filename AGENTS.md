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
