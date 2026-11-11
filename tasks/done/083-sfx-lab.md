# 083 — SFX Lab: a generic sound review tool, plus the game honouring its verdicts

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none (082 menu waves is in flight and also edits `scripts/autoload/audio.gd`. Keep the game-side change small and self-contained so the merge is easy.)
Created: 2026-11-11

## Goal
David can open a local page, browse every game sound by category, listen, and mark each one approved or rejected with an optional note. The game never plays a rejected sound and picks an approved or unreviewed alternative where one exists. The tool is game-agnostic: copy one folder and write one config file to use it in another project.

## Design (keep it this small)
- `tools/sfx_lab/sfx_lab.py`: Python stdlib only (`http.server` with `ThreadingHTTPServer`, `json`, `hashlib`, `argparse`, `webbrowser`).
  - Run it as `python tools/sfx_lab/sfx_lab.py [--project PATH] [--config sfx_lab.json] [--port 8777] [--no-browser]`. The project defaults to the current directory, and the config path is relative to the project.
  - It binds to 127.0.0.1 only.
  - It serves the page, plus `GET /api/sounds` (config, file list with category, size, sha1 and current verdict) and `GET /audio/<relpath>` (only files inside the configured audio dirs; refuse `..` and anything else).
  - `POST /api/verdict` with `{path, status, note}` writes the approvals file atomically: temp file, then rename.
  - It opens the browser unless `--no-browser` is given.
- `tools/sfx_lab/sfx_lab.html`: a single file with inline CSS and JS. No CDN and no build step.
- `tools/sfx_lab/README.md`: how to run it, the config format, the approvals format, and how to adopt it in another game (copy the folder, write the config, read the approvals file).
- Project config: `sfx_lab.json` at the repo root.
  ```json
  {
    "title": "Gullin' It SFX Lab",
    "audio_dirs": ["assets/audio"],
    "recursive": false,
    "extensions": [".ogg", ".wav", ".mp3"],
    "approvals_file": "data/sfx_approvals.json",
    "categories": [
      {"name": "Voices: man",   "match": "^voice_.*_man$"},
      {"name": "Voices: woman", "match": "^voice_.*_woman$"},
      {"name": "Voices: kid",   "match": "^voice_.*_kid$"},
      {"name": "Black Back",    "match": "^bb_"},
      {"name": "Gull",          "match": "^(dive|snatch|stun|screech_|gull_|wing_flap|gang_call|263786)"},
      {"name": "Dog",           "match": "^dog_"},
      {"name": "People and props", "match": "^(swat_|whistle|bag_|bin_)"},
      {"name": "Weather and ambience", "match": "^(thunder|rain|gust|menu_waves)"},
      {"name": "UI and results", "match": "^(ui_|click|score|level_end)"},
      {"name": "Other",         "match": ".*"}
    ],
    "group_variants": "_(man|woman|kid|\\d+)$",
    "preview_pitch": {"Voices: man": [0.86, 1.04], "Voices: woman": [0.96, 1.04], "Voices: kid": [0.91, 1.04]}
  }
  ```
  - Categories are regexes on the file stem. The first match wins.
  - `group_variants` strips a suffix, so variants of the same line show as one row group: "hey" lists its man, woman and kid takes together.
  - `preview_pitch` is optional and gives a per-category playback-rate range for the "game pitch" preview.
- Approvals file `data/sfx_approvals.json`:
  ```json
  {"version": 1, "sounds": {"assets/audio/voice_hey_man.ogg": {"status": "rejected", "note": "robotic", "sha1": "...", "reviewed": "2026-11-11T10:02:00"}}}
  ```
  - `status` is `approved`, `rejected` or `unreviewed`. A file missing from the approvals file counts as `unreviewed`.
  - Keep `sha1` as it was when reviewed. If the file has since changed (for example after re-running `make_sfx.py`), the page marks it "changed since review" and the game treats it as `unreviewed`.

## Page requirements
1. A left column lists the categories with approved, rejected and unreviewed counts. The main panel lists that category's sounds, grouped by variant stem. Each row shows the name, duration, a play button, ✓ approve, ✗ reject, ↺ reset, a note field (saves on blur), a status colour, and the "changed since review" badge.
2. Filters: All, Unreviewed, Approved, Rejected, Changed. A search box filters by name.
3. Playback uses one shared `<audio>` element, so starting a sound stops the previous one. Add:
   - a volume slider
   - a "game pitch" toggle that plays at a random rate within the category's `preview_pitch` range, with `preservesPitch = false`
   - a "play group" button that plays a group's variants back to back
4. Keyboard:
   - ↑/↓ select a row
   - Space plays
   - A approves and moves to the next row
   - R rejects and moves to the next row
   - U resets
   - N focuses the note field
5. Every change saves immediately through the API. Show a small "saved" or error indicator. Reloading the page restores the state.
6. Works in current Chrome, Edge and Firefox at 1280×800 and wider. Keep it plain and readable; no design-system work.

## Game side (Gullin' It)
1. `Audio` loads `res://data/sfx_approvals.json` at `_ready` if present. A missing or unreadable file means everything is allowed.
   - Add `Audio.rejected(cue: String) -> bool`. It matches by file stem across the extensions and ignores entries whose sha1 differs from the current file. If comparing sha1 is awkward in Godot, compare file size and record that decision.
   - Godot cannot read `.ogg` source bytes in an exported build. Have `sfx_lab.py` write the hash it saw, and have the game compare `FileAccess.get_file_as_bytes`. If the source file isn't readable in the export, treat a `rejected` status as authoritative and skip the hash check. Record what you chose.
2. `Audio.play(cue)` returns `null` for a rejected cue.
3. Every random variant pick filters rejected cues first and plays nothing if all are rejected. That covers `Audio.react` line and register picks, `Audio.bark()`, wing flaps, `gull_hit_1..3`, and anything else that picks among numbered variants (grep for `% 3` and `randi()` near `Audio.play`).
   - For voices: if a line's register take is rejected, try another line in the same event before falling back to another register. Never use the wrong register for a kid (toddler) unless it is the only option left.
4. Add `data/sfx_approvals.json` with `{"version":1,"sounds":{}}`. It's under `data/*.json`, so the web export includes it.

## Tests
- Game: add to `tests/sfx_checks.gd` using an injected approvals dictionary, not the real file:
  - a rejected cue doesn't play
  - `react` skips a rejected line and picks another
  - all lines rejected gives `null`
  - a rejected variant is skipped in the bark and flap picks
  - an empty or missing file allows everything
- Tool: `tools/sfx_lab/selftest.py` (stdlib) starts the server on a free port against a temp project with a few dummy `.wav` files and checks:
  - categorisation
  - a verdict POST round-trips
  - the atomic write leaves valid JSON
  - path traversal is refused
  - a changed file shows as changed
- Also open the page in a browser once, by Playwright or the in-app browser if available, and confirm it lists real sounds and plays one. Report what you could verify.

## Out of scope
Waveform drawing, batch editing, multi-user, uploading or renaming files, and regenerating sounds from the page.

## Done when (acceptance)
- [ ] `python tools/sfx_lab/sfx_lab.py` opens the lab on this repo, and every file in `assets/audio` appears in a category.
- [ ] Verdicts persist to `data/sfx_approvals.json`, and the game honours them as above.
- [ ] `selftest.py` passes, and the headless integration has no new failures. Re-measure the baseline first; `main` moves often.
- [ ] `tools/sfx_lab/README.md` explains reuse in another game in under a page. A README note points to the lab.

## Report
Files: `tools/sfx_lab/{sfx_lab.py,sfx_lab.html,selftest.py,README.md}`, `sfx_lab.json`, `data/sfx_approvals.json` (empty), `scripts/autoload/audio.gd` (`set_approvals`, `rejected`, `pick`, `_voice_cue`, `_sha1`; `play` returns null for rejected; flap/bark/react use them), one-line pick changes in `scripts/game.gd` (gull_hit, held-screech long/short), `scripts/brashness.gd` (gull_hit), `scripts/squall_rain.gd` (thunder), `tests/sfx_checks.gd` (`_verdict_checks`, 17 checks), `README.md` note.

Tests: baseline (before changes) INTEGRATION 17280 checks, 2 failures; final 17297 checks, 2 failures. The same two failures exist on baseline ("nobody teleports across the beach while running off", "data/demo.json enables the four-level demo"); none new. `python tools/sfx_lab/selftest.py`: `selftest ok` (categorisation, verdict round-trip, atomic write leaves valid JSON and no temp file, traversal and bad verdict path refused, changed file flagged).

Browser (in-app browser, real repo): the page listed 15 man voices in the first category, a play click advanced the shared audio element (currentTime 0.62 s, no media error), the R key saved a rejection to `data/sfx_approvals.json`, and after a reload the category count read rejected 1 and the row was still marked. The test verdict was removed afterwards (the committed approvals file is empty). `/api/sounds` returns all 83 audio files in `assets/audio` (82 in named categories, `music.wav` in Other). Not checked in Chrome or Firefox, and not by ear (headless).

Decisions:
- sha1: the lab stores the SHA-1 of the file bytes. The game recomputes it with `HashingContext` over `FileAccess.get_file_as_bytes("res://<path>")` (Godot 4.7 has no `FileAccess.get_sha1`). If the source file is unreadable or empty (exported build ships only the imported copy) the check is skipped and `rejected` is authoritative; an entry with no sha1 (as in the tests) is also authoritative. A mismatch means the entry is ignored.
- Cues map to files by stem; `gull_call` maps to `263786__steaq__seagull-single-call` through `Audio.CUE_FILES`. Procedural cues have no file and can't be rejected.
- `Audio.pick(cues, start=-1)` returns a random allowed cue, or with `start` the first allowed one from that index (keeps the deterministic alternation for brashness hits and thunder). The screech long/short pick still draws the same level-rng value.
- Voices: `_voice_cue` picks a random allowed line in the event's register; when none is left it tries the other registers in order (man, woman, kid, skipping the own register), so a kid is voiced by an adult only after every kid take is gone, and `wah` (kid only) still serves as the fallback for adults. All rejected gives null. This changes which line is picked in the rare case a line has no take in the register (it is now skipped, not substituted).
- A verdict of `unreviewed` with an empty note removes the entry from the file.
- The page treats a changed file as unreviewed in counts and filters, and shows it under the Changed filter with the badge.
- Config bug found while testing: `group_variants` needs `\d` in JSON; the committed `sfx_lab.json` has it escaped.

Not done: no Chrome/Firefox check; no check of the web export. Menu waves (task 082) not touched; the Weather category regex already includes `menu_waves`.

Launch: `python tools/sfx_lab/sfx_lab.py` from the repo root (add `--no-browser` to skip opening the page, `--port` to change 8777).

## Review notes
Reviewed by Claude Opus 2026-11-11: diff read; merged into main together with 082/083 (audio.gd and sfx_checks.gd conflicts resolved by keeping both sides). Integration on main 17332 checks, same 2 pre-existing failures.
