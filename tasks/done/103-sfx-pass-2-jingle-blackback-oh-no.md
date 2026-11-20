# 103 — SFX pass 2: point jingle, Black Back calls from real recordings, "oh no" voice

Status: done
Author: Claude (Opus)
Assignee: Claude Sonnet
Depends on: 085
Created: 2026-11-20

## Goal
David reviewed the sounds in the SFX Lab (`SFX Lab.bat`, verdicts in `data/sfx_approvals.json`) and wants three things better: the point jingle, the Black Back gull calls, and the people reactions. Make several candidates of each so David can choose in the lab, and make the game play whichever candidate he approves.

## Context
- Audio hub: `scripts/autoload/audio.gd`. It has `play`, `pick(cues, start)` and `rejected(cue)`, plus `approved_cues` and `has_approvals`, which are filled from the lab verdicts by `set_approvals`. Voices only play once approved (`voices.require_approved`). Every other sound plays unless it is rejected.
- Generators: `tools/make_sfx.py` uses numpy and ffmpeg, with no scipy. It holds `bellow()`, `write_ogg`, `lufs` and the current `bb_*` builds. Its `snatch()` currently writes `assets/audio/snatch.wav`.
- Lab config: `sfx_lab.json`. Files named `name_1`, `name_2` and so on group as variants of one sound.
- Sources from David, in `C:\Users\david\Desktop\GAssets\SoundsFX\`. Read them from there and never copy the raw downloads into the repo:
  - `freesound_community-herring-gull-1-27057.mp3` (33 s) and `freesound_community-herring-gull-2-64026.mp3` (20 s). Both are Pixabay Content License, free for commercial use with no credit needed.
  - `kalsstockmedia-human-voice-saying-oh-no-301694.mp3`, also Pixabay. The `(1)` file is a duplicate.
  - `kenney_interface-sounds.zip`, Kenney CC0. Extract it into a scratch folder, never into the repo.
- Where the cues are used:
  - Snatch: `game.gd` lines ~213, ~306 and ~1086 call `Audio.play("snatch", 1+score.tier*0.08)`.
  - Combo tier up: `game.gd` ~269 calls `Audio.play("score", ...)`. `score.ogg` is rejected.
  - Black Back: the `sfx` map for `great-black-backed` in `data/species.json`, read through `game.gd species_cue()`, plus the power sound `bb_shakedown`.
  - People reactions: `tuning.voices.events` in `data/tuning.json`. `give_up` currently has no approved take, so it is silent.
- Web audio rule (CLAUDE.md): use the SFX bus and Stream playback. Keep this for anything you touch.
- Use the `godot-prompter:audio-system` skill for the Godot side.

## Requirements
1. **Point jingle candidates.**
   - `snatch_1..4` (ogg): short, bright, satisfying "got it!" jingles, 0.15–0.4 s, peak around -3 dBFS, matching the loudness of the current `snatch.wav`.
     - At least 2 synthesised, for example a 2–3 note rising arpeggio with square/triangle tones plus a soft bell shimmer, built in `tools/make_sfx.py`.
     - Up to 2 trimmed from the Kenney interface pack, picked for being short and positive.
     - Nothing Mario-like: no B5→E6 coin interval.
   - `score_1..2`: a short combo-up sting in the same family as the jingles.
   - In the game:
     - snatch plays the first candidate in `tuning.sfx.snatch` that is approved. If none is approved, it plays the first one that isn't rejected. Keep the existing tier pitch-up.
     - Combo-up does the same with `tuning.sfx.score`.
     - Add a small `Audio` helper for "first approved, else first not rejected" and reuse it in reqs 1 and 2.
     - The old `snatch.wav` and `score.ogg` stay as the last fallbacks in those lists.
2. **Black Back from the real herring gull recordings.**
   - Cut the clearest long calls and single "kyow"/"kek" calls from the two herring gull files.
   - Turn them into deep, hoarse, seal-like great black-backed calls: pitch down about 0.55–0.7×, add subharmonic/rough growl, a little low-mid body, and trim the high fizz.
   - Write `bb_screech_long_1..3`, `bb_screech_short_1..3` and `bb_shakedown_1..2`.
   - Let the species `sfx` map and the power `sound` accept an array; it plays through the helper from req 1. Append the old `bb_screech_long`, `bb_screech_short` and `bb_shakedown` as the last fallbacks.
   - Loudness must match the current `bb_*` files (use `lufs`), so the Black Back doesn't jump out of the mix.
3. **"Oh no" voice.**
   - Cut the cleanest "oh no" from the kalsstockmedia file. Make `voice_oh_no_man`, `voice_oh_no_woman` and `voice_oh_no_kid`, pitch-shifted (not time-stretched) from the source so each sits in its register. Measure the source f0 and record it in the Report.
   - Add `oh_no` to the `give_up` cues and the `theft` cues in `tuning.voices.events`.
   - They play only once David approves them, which is the existing rule.
4. **Sources and licences.** Add lines to `assets/audio/pixabay_SOURCES.txt` for the herring gull and "oh no" cuts, and a Kenney line to the right license/sources file. Each line gives the cut times and the processing.
5. **Tests.** Extend `tests/sfx_checks.gd`:
   - the helper picks approved first, skips rejected, and returns "" when all are rejected;
   - snatch, combo and the Black Back cue go through it;
   - every new file loads and is not silent.

   Inject the approvals map in the tests, as the bark fallback test does, so David's verdicts don't affect the results.

## Out of scope
- Other people lines: more downloads are coming, and that will be a follow-up task.
- UI clicks and the results stings.
- Gull sounds for other species.
- Changing the approval rules for non-voice sounds.

## Done when (acceptance)
- [ ] The new candidate files exist in `assets/audio/` and appear in the lab under the right categories, grouped as variants.
- [ ] The game plays approved candidates first, falls back sensibly, and stays silent only when every option is rejected.
- [ ] `./tools/validate.ps1` passes with no new failures. Two known failures are allowed: "nobody teleports across the beach while running off" and "data/demo.json enables the four-level demo".
- [ ] The Report lists each new file with a one-line description of what it sounds like and what it was made from.

## Report
Branch `sonnet/103-sfx-pass-2`. Tests: `INTEGRATION: 18591 checks, 0 failures` (the two known failures did not fire in this run). New checks are in `tests/sfx_checks.gd` (`_variant_checks`).

Generator: `tools/make_sfx_103.py <kenney-dir>` (imports `tools/make_sfx.py`; leaves existing cues untouched). Sources read from the GAssets folder, Kenney zip extracted to a scratch folder outside the repo.

New files (all `assets/audio/*.ogg`):
- snatch_1: synth D5-F#5-A5 triangle arpeggio with bell shimmer, 0.34 s. snatch_2: synth F5-A5-C6, squarer tone, 0.30 s.
- snatch_3: Kenney confirmation_003 trimmed, 0.32 s. snatch_4: Kenney glass_001 trimmed, 0.27 s. All four matched to snatch.wav loudness (-18.2..-19.3 LUFS padded, snatch.wav -18.3); peaks -3.5..-5.4 dBFS.
- score_1: synth G5-D6-G6 sting, 0.42 s. score_2: synth C5-E5-G5-C6, 0.42 s. Both about -15.4 LUFS padded, same as score.ogg.
- bb_screech_long_1..3: herring gull 1 long calls (8.44, 10.30, 14.60 s) at 0.60x / 0.55x / 0.68x, 1.2-1.6 s; hoarse, seal-like.
- bb_screech_short_1..3: herring gull 1 single kyow/kek (9.36, 15.78, 11.92 s) at 0.60x / 0.55x / 0.65x, 0.4-0.47 s.
- bb_shakedown_1..2: herring gull 2 long phrases (12.74-14.44, 14.60-16.50 s) at 0.58x / 0.62x, about 3.1-3.2 s, harder saturation.
- voice_oh_no_man / _woman / _kid: "oh no" phrase (0.12-1.66 s) pitch-shifted with rubberband (duration kept), ratios 0.42 / 0.62 / 0.88.

Measurements: source "oh no" f0 median 369 Hz (oh 464, no 357). Output f0: man 159, woman 236, kid 342 Hz. Black Back loudness matched on active RMS to the old bb_* files (new -18.2 dBFS vs old -18.1/-18.0; shakedown -14.7 vs -14.2). Spectral centroid: new long 920-1250 Hz, short 1300-1620 Hz, shakedown about 1190 Hz, against herring screech_long 1777 Hz and screech_short 4856 Hz, so clearly lower. The f0 estimator is noisy on distorted calls (long 318-462, short_3 747); old bb_screech_long read 354.

Decisions: voice loudness matched on active RMS to the mean of the existing voices of each register; rubberband formants move with pitch. Added `Audio.first_allowed`, `Audio.resolve` (string or list) and `Audio.sfx(key)` (reads new `tuning.sfx.snatch|score`); all `Audio.play("snatch")` calls and combo-up use it; species `sfx` map and power `sound` accept arrays (`game.species_cue`, `brashness.fire`). `oh_no` added to `theft` and `give_up` cues and to `VOICE_LINES`. Old snatch/score/bb_* kept as last fallbacks. Two older assertions (shakedown sound, black-back screech) updated to the list form. The helper is deterministic (first approved, else first not rejected), so the Black Back plays candidate 1 until David picks.
Not done: nothing listening-tested; lab categories unchanged (names already fit the Gull / Black Back / UI / Voices regexes and group as _N variants).
