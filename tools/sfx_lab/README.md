# SFX Lab

A tiny local page to listen to a project's sounds and mark each one approved or rejected. Python stdlib plus one HTML file; no installs, no network (binds to 127.0.0.1).

## Run

```
python tools/sfx_lab/sfx_lab.py [--project PATH] [--config sfx_lab.json] [--port 8777] [--no-browser]
```

`--project` defaults to the current directory; `--config` is relative to it. Check the tool with `python tools/sfx_lab/selftest.py`.

Page: categories on the left (with approved / rejected / unreviewed counts), sounds grouped by variant on the right. Filters (All, Unreviewed, Approved, Rejected, Changed), name search, volume, a "game pitch" toggle (random rate in the category's `preview_pitch`) and "play group". Keys: Up/Down select, Space play, A approve and next, R reject and next, U reset, N edit note. Every change saves at once.

## Config (`sfx_lab.json` in the project root)

```json
{
  "title": "My Game SFX Lab",
  "audio_dirs": ["assets/audio"],
  "recursive": false,
  "extensions": [".ogg", ".wav", ".mp3"],
  "approvals_file": "data/sfx_approvals.json",
  "categories": [
    {"name": "Voices", "match": "^voice_"},
    {"name": "Other",  "match": ".*"}
  ],
  "group_variants": "_(man|woman|kid|\\d+)$",
  "preview_pitch": {"Voices": [0.9, 1.05]}
}
```

- `categories`: regexes on the file stem (no extension); first match wins, so end with a catch-all.
- `group_variants` (optional): a suffix regex stripped from the stem to group variants of one sound.
- `preview_pitch` (optional): per-category playback-rate range for the "game pitch" preview.
- Only files inside `audio_dirs` (with a listed extension) can be served.

## Approvals file

```json
{"version": 1, "sounds": {"assets/audio/voice_hey_man.ogg": {"status": "rejected", "note": "robotic", "sha1": "...", "reviewed": "2026-11-11T10:02:00"}}}
```

Keys are project-relative paths. `status` is `approved`, `rejected` or `unreviewed` (a file not listed is `unreviewed`). `sha1` is the file hash at review time: if the file has changed since, the page shows "changed since review" and consumers should treat the verdict as `unreviewed`. Writes are atomic (temp file, then rename).

## Use it in another game

1. Copy `tools/sfx_lab/` into the project.
2. Write `sfx_lab.json` (above) at the project root.
3. Run the command above, then review.
4. Have the game read the approvals file at startup and skip `rejected` entries whose `sha1` still matches (or ignore the hash when the source files are not shipped). Gullin' It does this in `scripts/autoload/audio.gd` (`set_approvals`, `rejected`, `pick`).
