# 080 — SFX round 2: clearer voices, deeper Black Back, swat thwack, wing flaps, real dog bark

Status: done
Author: Claude
Assignee: Claude Sonnet
Depends on: 079 (merged)
Created: 2026-11-11

## Goal
David played task 079. The people's reactions are hard to make out, and the Black Back needs to sound deeper. Swats need an impact sound, the player's gull needs wing flaps, and the dog needs a real bark.

## Context
- Generator: `tools/make_sfx.py`, from task 079. Runtime: `scripts/autoload/audio.gd` (`Audio.play`, `Audio.react`, `fx_rng`), `data/tuning.json` → `voices`.
- David's source files live in `C:\Users\david\Desktop\GAssets\SoundsFX\`. They are Pixabay Content License (free for commercial use, no attribution, not CC0). Record each one in `assets/audio/pixabay_SOURCES.txt` in that file's existing style. Copy nothing into the repo except the trimmed game cues.
- Same web-audio rules and no-download rule as 079. All playback goes through `Audio.play()`. Use `fx_rng` for cosmetic randomness, never the level `rng`.
- No agent can hear audio. Measure, and write the audition file.

## Requirements

### 1. Clearer people voices
Likely cause: `Audio.react` changes `pitch_scale` per kind (0.72–1.5). That moves the formants together with the pitch, so women and children come out chipmunk-like and men come out muddy.
- Render each voice line offline in three registers: `man`, `woman`, `kid`. Each register gets its own f0 contour and a modest formant scale (about 1.0 / 1.12 / 1.25). Name the cues `voice_<line>_<register>`.
- Runtime pitch becomes jitter only (about ±4%). `voices.pitch` changes to a map from `BeachTarget.voice_kind()` (and the `default`/`teen` kinds) to `{"register": ..., "pitch": [lo, hi]}`. `old_man` is `man` at about 0.9. `teen` is `kid` or `woman` at about 0.95, your choice. `toddler` is `kid`.
- Make each line read as a word:
  - stronger consonant onsets (`h`, `w`, `y`, `sh`, `n`)
  - narrower formant bandwidths, about 0.7× current
  - a presence lift around 2–4 kHz so the voices cut through the music
  - slightly longer vowels and more exaggerated cartoon pitch contours
- Raise `voices.volume_db` from −11 to about −7. The loudest voice cue must stay below the dive and snatch cues in integrated loudness.
- Extend the set and map the new lines into `voices.events` (each event picks from 2–4 lines):
  - theft: `hey`, `oi`, `my_chips` (three-syllable "my CHIPS!" prosody), `no_no` ("no-no-NO")
  - surprise and notice: `whoa`, `huh`, `eek`
  - warning: `shoo` ("SHOO!"), `hey`, `get_off`
  - swat: `hah`, `gotcha`
  - give up: `aww`, `ugh`, `hmph`
  - panic: `aah`, `eek`
  - cry: `wah` (kid only)
- Keep every existing gating rule unchanged (one voice at a time, gaps, speaker gap).

### 2. Deeper Black Back
- Lower `bb_screech_long`, `bb_screech_short` and `bb_shakedown` by about 3–4 more semitones: total speed around 0.58–0.62 instead of 0.72. Strengthen the octave-down layer, low-pass at about 3.5 kHz, keep the length cap and loudness match.
- Report the measured fundamental (autocorrelation or similar) of the original screech and the old and new `bb_` versions. The new one should be at least 8 semitones below the original.

### 3. Swat thwack
- Source: `freesound_community-thwack-wobble-96509.mp3` (1.63 s). Find the onset, keep the thwack plus a short wobble, and trim to at most 0.8 s with a fade. The result is `swat_thwack.ogg`, normalised to sit with the gull_hit cues.
- Play it whenever a person, sweeper or dog-owner swat knocks a gull: `AdultReaction._hit`, `BeachSweeper` swat (around `sweeper.gd:386`), `target.gd:556`, and `stash_raids.gd:381`. Add ±5% pitch.
- When the swatted gull is the player, the player-stun handler in `game.gd` must not also play `stun`/`bb_stun` in the same frame. Use a small `Audio` timestamp and a check of 60 ms or less. Rival stuns can keep their current sounds.

### 4. Player wing flaps
- Source: `freesound_community-wing-flap-1-6434.mp3` (0.98 s). If it holds several flaps, slice out 2–3 single flaps of 0.15–0.35 s each as `wing_flap_1..3.ogg`. If it holds one, ship that one, trimmed.
- Play one flap per wing stroke for the player gull only, where `gull.gd` sets `stroke_started` (it fires every 0.3 s while flap is held, so keep it light). Add a signal or a check in `game.gd`, your choice. Use a random variant and ±8% pitch.
- Black Back uses pitch 0.85 and slightly louder, through the species `sfx` map or a pitch field.
- Add a `"flap"` block to `data/tuning.json` with `volume_db` (start about −13) and `min_gap` (about 0.2 s).

### 5. Real dog bark
- David is downloading Pixabay "Small Dog Barking" (https://pixabay.com/sound-effects/nature-small-dog-barking-84707/, freesound_community/michorvath, about 3 s) into the SoundsFX folder.
- `make_sfx.py` looks for a file matching `*dog*bark*` in that folder. If it finds one, it slices 2 single barks as `dog_bark_1..2.ogg`, and the `barked` handler picks one at random. If it finds none, it keeps the generated `dog_bark.ogg` and prints a clear notice. Note in the Report which path ran.
- Make re-running the script after the download the only step needed.

### 6. Audition
Regenerate `test-output/sfx-audition-2.wav` with 0.5 s gaps:
1. Old voices (from `git show main:`), then the new voices grouped per line as man, woman, kid.
2. Original screech, old `bb_screech_long`, new `bb_screech_long`.
3. The new swat thwack, the flaps, and the dog barks.

Copy it to `C:\Users\david\Documents\ChatGPT\GullinIt\test-output\`.

## Out of scope
Rival gull flaps, music, ducking, and any change to when voices trigger.

## Done when (acceptance)
- [ ] `python tools/make_sfx.py` regenerates everything deterministically, as in 079.
- [ ] Measurements table in the Report: duration, peak and loudness per new or changed cue, plus the screech fundamentals.
- [ ] Tests updated or added: register selection per kind; runtime voice pitch stays within ±5%; every event's cues load; swat on the player plays `swat_thwack` and not `stun`; a stroke plays at most one flap and `min_gap` holds; the dog bark falls back cleanly.
- [ ] Headless integration passes with no new failures. The baseline is 17181 checks with 2 known failures: the sunbather run-off teleport and `demo.json`.
- [ ] `pixabay_SOURCES.txt`, `generated_SOURCES.txt` and the README audio notes are updated.

## Report
Nothing could be listened to; everything below is measured.

**Dog bark path that ran: REAL.** `freesound_community-small-dog-barking-84707.mp3` (2.82 s, three barks) was present; `make_sfx.py` sliced the two loudest as `dog_bark_1/2.ogg` (0.30 / 0.32 s). The generated `dog_bark.ogg` stays in the repo and in the script as the fallback: with no `*dog*bark*` file the script prints a NOTICE, deletes stale slices and ships only `dog_bark`. `Audio.bark()` picks from `Audio.dog_barks` (recorded barks, else `["dog_bark"]`); the fallback is covered by a test that forces `dog_barks = ["dog_bark"]`.

**Files changed**: `tools/make_sfx.py`; `assets/audio/` new `voice_<line>_<man|woman|kid>.ogg` (46, `wah` kid only) plus `.import`, removed the 8 old `voice_<line>.ogg`, new `swat_thwack.ogg`, `wing_flap_1..2.ogg`, `dog_bark_1..2.ogg`, re-rendered `bb_screech_long/short`, `bb_shakedown` (other regenerated oggs are byte-different only through the libvorbis stream serial; `dive.wav`/`snatch.wav` unchanged), `pixabay_SOURCES.txt`, `generated_SOURCES.txt`; `scripts/autoload/audio.gd` (cue loading, `react` register map, `swat_hit`/`swat_recent`, `flap`, `bark`); `scripts/gull.gd` (`wing_stroke` signal, `swatted()`); `scripts/game.gd` (`_wing_stroke`, stun cue yields to a swat, `Audio.bark()`); `scripts/adult_reaction.gd`, `scripts/sweeper.gd`, `scripts/target.gd`, `scripts/stash_raids.gd` (swats call `swatted()`); `data/tuning.json` (`voices` reshaped, `flap` block), `data/species.json` (Black Back `flap`); `tests/sfx_checks.gd`; `README.md`. Audition: `test-output/sfx-audition-2.wav`, copied to `GullinIt/test-output/`.

**Tests**: baseline 17181 checks / 2 failures; final **17218 checks, 2 failures** (same two: sunbather run-off teleport, `demo.json` four-level demo). 37 new checks in `tests/sfx_checks.gd`: every event line loads for each register, register selection and jitter-only pitch per kind (+-5% of the kind's base, inside its span), the wah kid fallback, swat on the player plays `swat_thwack` and not `stun`/`bb_stun`, one flap per stroke and `min_gap`, bark fallback.

**Measurements** (shipped files, decoded; LUFS zero-padded to 400 ms so short cues read low)
| cue | dur s | peak dBFS | LUFS |
|---|---|---|---|
| bb_screech_long (was 079: 4.5 s, -7.3, -21.0) | 4.500 | -8.31 | -21.0 |
| bb_screech_short | 2.419 | -8.10 | -16.3 |
| bb_shakedown | 3.200 | -6.93 | -17.3 |
| swat_thwack | 0.747 | -8.93 | -22.4 |
| wing_flap_1 / _2 | 0.173 / 0.207 | -3.50 / -3.12 | -25.3 / -23.9 |
| dog_bark_1 / _2 | 0.297 / 0.321 | -3.11 / -3.29 | -19.9 / -19.4 |
| dog_bark (generated) | 0.200 | -2.89 | -14.3 |
| gull_hit_1/2/3 (reference) | 0.49 | -2.7 / -8.2 / -5.7 | -16.3 / -16.0 / -16.2 |
| dive / snatch (reference) | 0.52 / 0.24 | -3.0 / -3.0 | -15.8 / -16.5 |
Screech vs original LUFS: bb_screech_long -0.2 LU from screech_long (-20.8), bb_screech_short -0.3 LU from screech_short (-16.0).
Voices, 46 cues: man 15 cues 0.30-0.78 s, peak -10.7..-5.3, LUFS -21.8..-13.9; woman 15 cues, peak -6.8..-5.8, LUFS -18.8..-14.0; kid 16 cues, peak -6.7..-5.8, LUFS -20.5..-14.2. Loudest voice `voice_aah_man` LUFS about -13.9 raw; at `volume_db` -7 it is about -20.9, below dive (-15.8) and snatch (-16.5). By plain rms it is -20.7 dBFS in game versus dive -19.9 and snatch -14.7 (0.8 dB under the dive, so tight).
Fundamentals (autocorrelation, median over loud frames, 60-3000 Hz): screech_long 1225 Hz; old bb_screech_long 432 Hz; new bb_screech_long 354 Hz; that is 21.4 semitones below the original (old: 18.2). screech_short 1961 Hz, new bb_screech_short 1225 Hz (-8.1 semitones); bb_shakedown 368 Hz. The long-screech figure is a spectral-dominance reading (the octave-down layer and 280 Hz boost dominate), not a clean pitch shift; the resampling alone is 0.6x = -8.8 semitones. The short screech, the cleaner reading, is -8.1.

**Decisions / deviations**
- Event `cues` in `voices.events` now list line names (`hey`, `my_chips`...); `Audio.react` builds `voice_<line>_<register>` from `voices.pitch[kind].register`. `teen` = `kid` at 0.91-0.99 (about 0.95). `old_man` = `man` 0.86-0.94 (0.9). All others 0.96-1.04 jitter. "+-5%" is enforced around each kind's own base.
- `notice` is huh/whoa/eek, `warning` shoo/hey/get_off, `swat` hah/gotcha, `give_up` aww/ugh/hmph, `panic` aah/eek, `theft` hey/oi/my_chips/no_no. Task 079's `whoa` left `theft`/`panic` per the new lists.
- Multi-syllable voices (`my_chips`, `no_no`, `get_off`, `gotcha`) run to 0.78 s; the 079 cap of 0.5 s could not hold three syllables. Single-word lines are 0.30-0.62 s.
- Register synthesis: f0 112 / 205 / 320 Hz, formant scale 1.0 / 1.12 / 1.25, bandwidths 0.7x, +5 dB bell at 3 kHz, noise consonants for h, sh, s, f, ch, t, k, p, glides for w, y, n.
- Black Back: `BB_SPEED = 0.6`, octave-down layer -2 / -5 / -3 dB (long / short / shakedown; was -5 / -10 / -6), roll-off 3.5 kHz, growl and length caps unchanged, loudness matched. Short screech grows to 2.4 s (was 2.0).
- Swat thwack: the source ramps in slowly (no sharp onset). Onset is where its 5 ms rms reaches 12% of the maximum (about 0.3 s in), 0.75 s kept, 150 ms fade, rms matched to the mean of the gull_hit cues, soft-limited; its peak (-8.9) is lower than the hit cues. All four swat sites call new `BeachGull.swatted()`, which plays the thwack only when the knock will land (not stunned, not invulnerable, no stun shield) and stamps `Audio.swat_ms` before calling `stun()`; `game._stunned` skips the stun cue if the stamp is within 60 ms. Rival stuns are unchanged.
- Flaps: the source holds two strokes, cut at the interior energy valley with short pre/post-roll to reach 0.17 and 0.21 s (so 2 variants, not 3). Hook is a new `wing_stroke` signal emitted next to `stroke_started = true` in `wingbeat()`, connected only for the player. `Audio.flap()` applies `flap.min_gap` (0.2 s) and +-8% pitch; Black Back gets pitch 0.85 and +3 dB via `species.json` `flap`.
- The 079 audition (`sfx-audition.wav`) is no longer generated; the script writes `sfx-audition-2.wav` only (old voices, new voices per line man/woman/kid, screech_long, old bb, new bb, thwack, flaps, barks).
- Mistake worth knowing: running `python` with `APPDATA`/`LOCALAPPDATA` pointed at the scratch userdata folder made the Windows Python launcher download a Python 3.15 runtime (165 MB) into `.tools/userdata`. I deleted it straight away; it is in gitignored `.tools/` and nothing was installed system-wide. Python for `make_sfx.py` was run with the normal environment afterwards.

**Not done / unverified**: nothing sounds-checked; whether the voices read as words, whether the thwack onset is the right one, and whether the Black Back sounds "deeper" are for David's ear. Lifeguard/hook gating, rival flaps, music and ducking untouched (out of scope).

Branch `sonnet/080-sfx-round-2`, last commit: see `git log -1`.


## Review notes
<!-- Filled in by the reviewer. -->
