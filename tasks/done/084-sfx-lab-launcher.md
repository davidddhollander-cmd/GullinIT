# 084 — Double-click launcher for the SFX Lab

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 083 (merged)
Created: 2026-11-11

## Goal
David opens the SFX Lab by double-clicking `SFX Lab.bat` in the repo root, the same way `Art Lab.bat` opens the Art Lab.

## Context
- Model it on `Art Lab.bat`: a header comment saying what it opens and listing the lab's keys, using `%~dp0` paths.
- The lab is `tools/sfx_lab/sfx_lab.py` (stdlib Python). It serves on 127.0.0.1:8777, opens the browser itself and runs until stopped. See `tools/sfx_lab/README.md`.

## Requirements
1. `SFX Lab.bat` in the repo root.
   - `cd /d "%~dp0"`, so the project and config default correctly.
   - Find Python: try `python`, then `py -3`. If neither works, print a clear message and `pause`.
   - Run the lab in the same window, so the window is the server. Set the window title to something like `SFX Lab - close this window to stop`.
   - If the lab exits with an error, for example because the port is busy, `pause` so David can read the message.
   - Do not change `APPDATA` or `LOCALAPPDATA`. Changing them made the Python launcher download a runtime last time.
2. Port busy: if 8777 is already taken, the most likely cause is that the lab is already open. Have `sfx_lab.py` handle this: when binding fails, print one line saying the lab may already be running and open that URL in the browser, then exit 0. Keep the change small, and add a check for it to `tools/sfx_lab/selftest.py`.
3. Add a "Windows: double-click `SFX Lab.bat`" line to `tools/sfx_lab/README.md`, and tell other games to copy the bat alongside the folder (it's game-agnostic). Update the README pointer in the repo root too.

## Done when
- [x] Double-clicking, simulated by running `cmd /c "SFX Lab.bat"` from another directory, starts the server for this repo. Check with `curl http://127.0.0.1:8777/api/sounds`, then stop it.
- [x] A second launch while the first is running exits cleanly with the "already running" message.
- [x] `python tools/sfx_lab/selftest.py` passes. No Godot changes, so the integration run isn't needed.

## Report
Files: `SFX Lab.bat` (new), `tools/sfx_lab/sfx_lab.py`, `tools/sfx_lab/selftest.py`, `tools/sfx_lab/README.md`, `README.md`.
- Bat: cd to repo, title set, `python` then `py -3`, message + pause if neither, runs the lab in the same window, pauses on non-zero exit. APPDATA/LOCALAPPDATA untouched.
- Busy port: `sfx_lab.py` prints "Port N is busy; the SFX Lab may already be running at URL", opens it, exits 0.
- Decision: on Windows `SO_REUSEADDR` (the HTTPServer default) let a second lab bind the same port silently, so the check never fired. Added `Server` subclass with `allow_reuse_address = False`.
- Selftest: new check launches a second `sfx_lab.py` on the busy port, expects exit 0 and the message. `selftest ok`.
- Verified: `cmd /c "SFX Lab.bat"` from another directory served `/api/sounds` for this repo; second launch printed the message and exited 0; server stopped, nothing listening. No Godot changes, integration run skipped.
- Branch sonnet/084-sfx-lab-launcher.

## Review notes
<!-- Filled in by the reviewer. -->
