# 082 — Beach waves ambience on menus and the results/high-score screen

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: 079, 080 (SFX tasks, merged)
Created: 2026-11-11

## Goal
Menus and the results screen sound like the seaside: gentle waves with distant gulls under them. Levels never play it.

## Context
- Source: `C:\Users\david\Desktop\GAssets\SoundsFX\freesound_community-gentle-ocean-waves-birdsong-and-gull-7109.mp3`. It is 115 s, 24 kHz stereo, −32.2 LUFS, LRA 4.1, and under the Pixabay Content License. Add it to `assets/audio/pixabay_SOURCES.txt` in that file's existing style. Do not modify the source file.
- Screen flow lives in `scripts/main.gd` `_navigate()` and `_finished()`. Screens are `title`, `pick`, `shop`, `select`, `options` (from the title), `results`, `pause`, `options_pause` and `game`. Audio lives in `scripts/autoload/audio.gd`.
- Web-audio rule: any new player uses `PLAYBACK_TYPE_STREAM`.

## Requirements
1. **Loop asset.** Make `assets/audio/menu_waves.ogg`, about 40–60 s long, mono or stereo as you prefer, with a seamless loop seam (crossfade the tail into the head, as `rain_loop.ogg` was made). Level it to about −20 LUFS, and keep the peak at or below −3 dBFS. Choose a stretch without an abrupt gull call at the seam. Add the processing to `tools/make_sfx.py` (it already reads from the SoundsFX folder) or to a small sibling script.
2. **Ambience player.** Add one persistent ambience player to `Audio` on the SFX bus, so the SFX volume and mute and `juice.audio` apply. Use `play_ambience(id, fade)` and `stop_ambience(fade)`. If the same id is already playing, it only fades to the target level and never restarts the loop.
3. **Where it plays.**
   - On: `title`, `pick`, `shop`, `select`, the title `options`, and `results`.
   - Off: `game`, `pause` and `options_pause` (during a level the waves stay silent, even when paused).
   - Navigating between menu screens never restarts or dips the loop.
   - It fades out over about 0.8 s when a level starts.
   - On `results` it fades in about 1.2 s after the result sting, so the sting stays clear.
   - The very first title screen at boot fades it in.
4. **Levels.** Add `"ambience": {"menu_waves_db": ...}` to `data/tuning.json`, with two values:
   - `title_db` (about −16), because the waves sit under the title music.
   - `quiet_db` (about −10), for the selection screens and results, where music is stopped.

   Move between the two levels as music starts and stops.
5. **Tests.** Add tests to `tests/sfx_checks.gd` (or a new checks file wired into `integration.gd`):
   - the waves play after `_navigate("title")` and `_navigate("select")`
   - `start_level` stops them
   - pause does not start them
   - `results` starts them
   - title to select to shop keeps the same playing stream without restarting

## Out of scope
- In-level ambience, music changes, and the VS mode screens from the other inbox tasks.

## Done when (acceptance)
- [ ] `menu_waves.ogg` measured in the Report: duration, peak, LUFS, plus a seam check (RMS of the last 0.5 s versus the first 0.5 s within 3 dB).
- [ ] Behaviour as in requirement 3, covered by tests.
- [ ] Headless integration passes with no new failures. The baseline before this task should be about 17218 checks with 2 known failures (the sunbather run-off teleport and `demo.json`). Re-measure it first, because `main` has moved.
- [ ] `pixabay_SOURCES.txt` and the README audio notes are updated.

## Report
**Files**: `assets/audio/menu_waves.ogg` (+ `.import`), `tools/make_menu_waves.py` (new sibling script, imports helpers from `make_sfx.py`), `scripts/autoload/audio.gd` (`play_ambience`, `stop_ambience`, ambience player), `scripts/main.gd` (`_waves` helper and hooks), `data/tuning.json` (`ambience.menu_waves_db`: `title_db` -16, `quiet_db` -10), `tests/sfx_checks.gd` (`_waves`, 15 checks), `assets/audio/pixabay_SOURCES.txt`, `README.md`.

**Loop measurements** (`menu_waves.ogg`): 52.0 s mono 44.1 kHz; peak -3.19 dBFS; -20.2 LUFS. Start chosen automatically (18 s into the source) as the stretch with the least prominent 1.5-5 kHz gull bursts. Seam: 3 s equal-power crossfade of the tail into the head; RMS last 0.5 s -22.83 dB vs first 0.5 s -21.10 dB (diff 1.73 dB, within 3 dB); sample jump across the wrap 0.009.

**Tests**: baseline 17218 checks, 2 failures (sunbather run-off teleport, `data/demo.json`). Final 17233 checks, 2 failures (the same two). Run headless with `--audio-driver Dummy`.

**Decisions**: `play_ambience(id, fade, db, delay)` takes the target dB and an optional delay; results uses `delay` 1.2 / fade 1.2 so the player starts at once (silent) and fades in after the sting. Same id playing only retargets the volume tween. `stop_ambience` fades to -60 dB then stops. Menu screens use `quiet_db` (music stopped); title and boot use `title_db` with a 2 s fade at boot. Title options and returning from options need no hook (the bed is already playing). Source dB values are relative to the SFX bus, so SFX volume/mute and `juice.audio` apply. Nothing in the task was left unmet. Not pushed or merged.

**Branch / commit**: `sonnet/082-menu-waves`, last commit hash: see `git log -1` (recorded in the hand-off message).

## Review notes
Reviewed by Claude Opus 2026-11-11: diff read; merged into main together with 082/083 (audio.gd and sfx_checks.gd conflicts resolved by keeping both sides). Integration on main 17332 checks, same 2 pre-existing failures.

Reviewer merged main (VS mode) into the branch: waves also play on the VS menu, and VS rounds fade them out via _start_game.
