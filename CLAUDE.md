# Gullin' It — Claude Code notes

Shared rules for all coding agents (Codex and Claude) live in AGENTS.md:

@AGENTS.md

## Working in this repo

- Engine: Godot 4.7.2 (GL Compatibility, logical canvas 320x180). Gameplay tuning lives in `data/*.json`; prefer data changes over code changes.
- Tests: `./tools/validate.ps1` (Windows) runs `tests/integration.tscn`; add `-Capture` for rendered screenshots in `test-output/`. Headless Linux: `godot --headless --path . tests/integration.tscn`.
- Web build for itch.io: `tools/export_web.sh` (exports from a temp copy, writes `build/GullinIt-web.zip`). The demo lock and feedback link are in `data/demo.json`.
- UI text uses the GullPixel bitmap font on its native 8 px grid (8 or 16 px only).
- Web audio: buses are defined in `default_bus_layout.tres` and every AudioStreamPlayer uses Stream playback; keep both, or web builds go silent.
- Never commit `build/`, `test-output/`, `.godot/`, `.tools/` (already in .gitignore). Commit only files you changed; another agent may have uncommitted work in progress.
