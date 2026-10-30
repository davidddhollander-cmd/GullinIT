# assets/ layout

Where a file sits tells you whether the game uses it.

| Folder | Meaning | In the exported game? |
|---|---|---|
| `sprites/`, `audio/`, `fonts/`, `ui/`, `shaders/`, `stage2/` | **Wired in.** The game (code, data, scenes) loads these. Looks up by pattern: `sprites/retro-*`, `sprites/background-v2/sea-frame-*`, audio cues by name. | yes |
| `lab/` | **In the Art Lab, not in the game.** Candidates under review (`data/art_lab.json`). Imported by Godot so the lab can show them. When one is accepted, move it into `sprites/` and point `data/sprites.json` at it. | no |
| `archive/` | **Neither.** Superseded sprites, old review pictures, early pilots. Godot ignores it (`.gdignore`), so it is never imported. `archive/MOVED.md` lists every file with its old path. | no |
| `reference/` | Raw generated sources and prompts, also Godot-ignored. | no |
| `previews/` | Review pictures that tests read or write (`tests/`), kept where they are. | no |

Nothing under `lab/`, `archive/` or `previews/` may be referenced by `sprites/` data: exports leave those folders out.

Rule for a new generated asset: source in `reference/<name>/`, candidate in `lab/<name>/` plus an Art Lab entry, then promote to `sprites/` once accepted.
