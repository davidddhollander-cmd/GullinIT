# 079 — SFX pass: air dive, Black Back voice, snatch reward, character reactions

Status: merged
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-11-10

## Goal
The game's most repeated moments get sounds with character: a dive is a rush of air, the Black Back sounds huge and unlike the other gulls, a snatch pays off with a short reward, and people audibly react to the gull without the beach turning into a wall of voices.

## Context
- Audio lives in `scripts/autoload/audio.gd`. Cues are loaded into `Audio.streams` and played with `Audio.play(cue, pitch, volume_db)`.
- Web audio rule: every player must use `PLAYBACK_TYPE_STREAM` and the SFX bus. Route new sounds through `Audio.play()` so this stays true.
- Offline audio generation follows `tools/compose_music.py`: Python, numpy, `wave`, ffmpeg. scipy is not installed. Do not add dependencies.
- No downloads. Every sound is either synthesised or derived from audio already in `assets/audio/`.
- Gameplay tuning belongs in `data/*.json`.
- Nobody on this task can listen to the output. Use the measurements in the acceptance list, and produce the audition file so David can judge the sound.

## Requirements

### 1. One generator
Create `tools/make_sfx.py`. One deterministic run (fixed seeds) writes every asset below, and the audition file. Keep the DSP helpers small. Every cue gets 2–5 ms edge fades so nothing clicks.

### 2. Dive swoosh
- Overwrite `assets/audio/dive.wav` (44.1 kHz mono, 0.45–0.60 s). Band-passed noise, no tonal content: the band centre sweeps up as the air rushes in and falls away at the end, with an asymmetric swell. It must read as air moving, not a laser or a pitched zip.
- `game.gd:234` plays it on `player.dive_started`, which is the windup. Move it to `dive_released` (strike start) if the windup is longer than about 0.12 s, so the rush matches the fall. Confirm `dive_released` fires on every dive path first.
- Add about ±6% random pitch per play, using a non-gameplay RNG.

### 3. Black Back sound set
All derived or synthesised as listed. `bb_` files are `.ogg` in `assets/audio/`, registered in `Audio.streams`.
- `bb_screech_long`, `bb_screech_short`: from `screech_long.ogg` / `screech_short.ogg`. Resample to about 0.72 speed (roughly −5.5 semitones), layer a copy an octave lower at about −10 dB, saturate with `tanh`, boost around 180–400 Hz, roll off above about 5 kHz. Trim the long one to at most 4.5 s with a 150 ms fade. Integrated loudness within 1.5 LU of the original. It must be a heavy, throaty bellow, clearly a large gull and not a slowed-down tape.
- `bb_dive`: heavier, lower variant of the swoosh, 0.6–0.75 s.
- `bb_stun`: low croak plus body thump, about 0.3 s.
- `bb_hit`: short heavy impact for Shakedown hits.
- `bb_shakedown`: power-fire bellow from the screech chain with extra low end, replacing `gang_call` at 0.75 pitch in `data/species.json`.
- `bb_slam`: deep drop plus noise crack, 0.5–0.9 s, played from `BeachShakedown._slam()`.
- `bb_stomp`: short soft thud, played in the `landed` branch of `BeachShakedown._stomp()` at about −8 dB.

Wiring: add a `"sfx"` map to the `great-black-backed` entry in `data/species.json`, e.g. `{"screech_long":"bb_screech_long","screech_short":"bb_screech_short","dive":"bb_dive","stun":"bb_stun"}`, and one small lookup in `game.gd` that returns the mapped cue or the default. Use it at the screech, dive and player-stun call sites. Set that species' `screech_pitch` to `1.0` because the drop is baked in, and check nothing else depends on the old value. `brashness.gd:175` uses `bb_hit` while Shakedown is active.

### 4. Snatch reward
- Overwrite `assets/audio/snatch.wav` (44.1 kHz mono, 0.18–0.28 s): a tiny beak "tk" transient, then two quick soft bell notes rising a fifth, exponential decay, warm rather than piercing. Existing tier pitch scaling stays.
- Stop using the reward for bad or neutral events. `game.gd:392` (the player gets bumped) and `game.gd:1131` (BONK) switch to the existing `gull_hit_1..3`. Grep every `Audio.play("snatch"` and keep it only where the player earned something.

### 5. Character reactions
Generated cartoon gibberish voices, not attempts at real speech: source-filter synthesis (glottal pulse train with slight vibrato and jitter through moving vowel formants, noise for consonants). Write `.ogg` cues, peak about −6 dBFS, each 0.15–0.5 s, except where noted:
`voice_hey`, `voice_oi`, `voice_whoa`, `voice_aah`, `voice_huh`, `voice_aww`, `voice_hah`, `voice_wah` (toddler, up to 0.7 s).

Also generate:
- `dog_bark` (short "arf"), replacing the `Audio.play("click")` at `game.gd:171`.
- `whistle` (two-tone pea-whistle trill, about 0.4 s), replacing the `Audio.play("gust")` in `_whistle` at `game.gd:1105`.

Add `Audio.react(event: String, kind: String, speaker: Object) -> AudioStreamPlayer`, driven by a new `"voices"` block in `data/tuning.json`:
```json
"voices": {
  "volume_db": -11.0,
  "speaker_gap": 3.5,
  "pitch": {"default": [0.92, 1.08], "toddler": [1.3, 1.5], "old_man": [0.72, 0.85]},
  "events": {
    "theft":   {"cues": ["voice_hey","voice_oi","voice_whoa"], "chance": 1.0,  "gap": 0.3},
    "notice":  {"cues": ["voice_huh","voice_whoa"],            "chance": 0.8,  "gap": 0.9},
    "warning": {"cues": ["voice_huh","voice_hey"],             "chance": 0.3,  "gap": 1.5},
    "swat":    {"cues": ["voice_hah"],                         "chance": 0.8,  "gap": 0.9},
    "give_up": {"cues": ["voice_aww"],                         "chance": 0.5,  "gap": 1.5},
    "panic":   {"cues": ["voice_aah","voice_whoa"],            "chance": 1.0,  "gap": 4.0},
    "cry":     {"cues": ["voice_wah"],                         "chance": 1.0,  "gap": 1.0}
  }
}
```
- `gap` is the minimum time since any voice last played. `speaker_gap` is per speaker. At most one voice plays at a time, except that `theft` may cut in after its own gap. Use `Time.get_ticks_msec()` and key speakers by instance id. Add per-kind pitch ranges for the real cast so men, women, teens and children differ.
- `Audio` must use its own `RandomNumberGenerator`. Never consume the level-seeded `rng`, or level determinism breaks.
- Hooks, each firing once per transition rather than per frame:
  - `AdultReaction.theft` after its early returns, only on a new reaction: `theft` (`notice` for sunbathers).
  - `AdultReaction.tick` when entering `warning`: `warning`, except lifeguards, who have the whistle.
  - `AdultReaction._hit` when the swat connects: `swat`.
  - `AdultReaction.tick` when entering `give_up`: `give_up`.
  - `CrowdPanic.stampede`: one `panic` call per stampede, not one per target. `pulse` plays nothing.
  - `BeachGame._cry`: `cry`.
  - Watergun teen `spotted` and sweeper `warned`: `warning`.

### 6. Audition
`make_sfx.py` also writes `test-output/sfx-audition.wav`: every new cue in the order above with 0.5 s of silence between them, plus the old `dive.wav` and `snatch.wav` from `git show main:` first for comparison, and `screech_long` immediately before `bb_screech_long`. Copy it to `C:\Users\david\Documents\ChatGPT\GullinIt\test-output\sfx-audition.wav`.

### 7. Licence note
Add `assets/audio/generated_SOURCES.txt` listing each new file and how it was made.

## Out of scope
- Rival gull sounds, music, ambience, UI sounds, the settings menu, an SFX pool.

## Done when (acceptance)
- [x] `python tools/make_sfx.py` regenerates everything, byte-identical across two runs for the WAVs (md5 checked; oggs differ in bytes only because libvorbis stamps a random stream serial).
- [x] Measured with ffmpeg/ffprobe and listed in the Report: duration, peak and integrated loudness per cue. No clipping (peak at or below −1 dBFS).
- [x] Measured evidence the swoosh is noise-like (spectral flatness or similar) and that `bb_screech_long` has more energy below 500 Hz than `screech_long`.
- [x] Black Back uses its own screech, dive, stun, power, slam, stomp and hit. Other species are unchanged.
- [x] Bump and BONK no longer play the reward.
- [x] Tests in `tests/integration.gd`: new cues load; species map resolves for Black Back and falls back for another species; `Audio.react` respects `gap`, `speaker_gap`, and `chance: 0`; a stampede of many targets produces at most one voice; `Audio.react` does not advance the level `rng`.
- [x] Headless integration passes with no new failures.
- [x] README audio notes updated if tuning keys changed.

## Report
Nothing could be listened to; everything below is measured, not judged by ear.

**Files changed**: `tools/make_sfx.py` (new), `assets/audio/{dive,snatch}.wav` (overwritten, 44.1 kHz mono), new `.ogg` + `.import` for 8 `bb_*`, 8 `voice_*`, `dog_bark`, `whistle`, `assets/audio/generated_SOURCES.txt`, `scripts/autoload/audio.gd` (cue loading, `fx_rng`, `react()`), `scripts/game.gd`, `scripts/brashness.gd`, `scripts/shakedown.gd`, `scripts/crowd_panic.gd`, `scripts/adult_reaction.gd`, `scripts/target.gd` (`voice_kind()`), `data/species.json`, `data/tuning.json` (`voices`), `tests/sfx_checks.gd` (+ `.uid`, hooked from `tests/integration.gd`), `tests/shakedown_checks.gd` (one expectation), `README.md`. Audition: `test-output/sfx-audition.wav`, copied to `GullinIt/test-output/`.

**Tests**: baseline (before any change) 17137 checks, 2 failures; final 17181 checks, 2 failures. The same two failures both times, pre-existing: "nobody teleports across the beach while running off (1 jumps)" and "data/demo.json enables the four-level demo". 44 new checks in `tests/sfx_checks.gd`.

**Measurements** (shipped files, decoded; LUFS for cues under 0.4 s is zero-padded to 400 ms and reads low; `flat` = mean per-frame spectral flatness 200 Hz-9 kHz; `30-500` = mean-square power in dBFS)
| cue | dur s | peak dBFS | LUFS | flat | 30-500 Hz dB |
|---|---|---|---|---|---|
| old dive (main) | 0.200 | -13.2 | - | 0.0015 | -24.6 |
| old snatch (main) | 0.180 | -13.2 | - | 0.0000 | -46.6 |
| dive | 0.520 | -3.0 | -15.8 | 0.3343 | -48.8 |
| snatch | 0.240 | -3.0 | (-16.5 pad) | 0.0000 | -60.6 |
| screech_long (orig) | 3.892 | +1.97 | -20.8 | 0.0461 | -22.9 |
| bb_screech_long | 4.500 | -7.3 | -21.0 | 0.0027 | -21.5 |
| screech_short (orig) | 1.451 | -2.0 | -16.0 | 0.0502 | -43.9 |
| bb_screech_short | 2.016 | -8.0 | -16.2 | 0.0089 | -37.8 |
| gang_call (orig) | 4.824 | -3.1 | -16.9 | 0.0836 | -43.5 |
| bb_shakedown | 3.200 | -6.6 | -17.4 | 0.0060 | -18.5 |
| bb_dive | 0.677 | -3.3 | -15.3 | 0.2317 | -30.1 |
| bb_stun | 0.297 | -3.0 | pad | 0.0000 | -12.4 |
| bb_hit | 0.202 | -2.9 | pad | 0.0395 | -9.9 |
| bb_slam | 0.797 | -1.5 | -13.2 | 0.0436 | -11.0 |
| bb_stomp | 0.157 | -6.7 | pad | 0.0054 | -17.2 |
| voice_hey / oi / whoa / aah | 0.337 / 0.357 / 0.497 / 0.497 | -6.0 / -6.0 / -5.9 / -5.9 | - | <=0.0006 | about -14 |
| voice_huh / aww / hah / wah | 0.197 / 0.497 / 0.357 / 0.697 | -8.0 / -6.0 / -5.9 / -6.0 | - | <=0.0012 | -12.6 to -16.4 |
| dog_bark | 0.200 | -2.9 | pad | 0.0296 | -12.1 |
| whistle | 0.401 | -2.7 | pad | 0.0037 | -62.2 |
Reference: a pure sine sweep over the same range has flatness 0.0000 and the old dive 0.0015, versus 0.334 for the new dive, so the new dive is noise-like. Every shipped cue peaks at or below -1.5 dBFS after ogg decode. bb_screech_long is -0.2 LU from screech_long and bb_screech_short +0.2 LU from screech_short (needed within 1.5).

**Decisions / deviations**
- `screech_long.ogg` clips (+1.97 dBFS decoded) and has about 85% of its power below 20 Hz. The "energy below 500 Hz" comparison therefore uses 30-500 Hz, and I high-pass the source at 30 Hz before processing. bb_screech_long wins by only +1.4 dB (the original is already bass-heavy); bb_screech_short wins by +6.1 dB. I used boost +15 dB at 280 Hz and a -5 dB octave-lower layer on the long one, versus +6 / -10 dB on the short. The growl is a 38 Hz amplitude modulation I added to read as throaty rather than tape-slowed.
- bb_shakedown is made from `screech_long` (3.2 s), not gang_call, and sits 0.5 LU below gang_call. Its `pitch` in species.json is now 1.0 (was 0.75 on gang_call).
- Dive moved to `dive_released` (windup is 0.15 s, over the 0.12 s threshold). `dive_released` fires once at the single windup-to-strike transition in `gull.gd` for every dive caller; a windup that ends in a landing never strikes, so no swoosh plays on a crash. `dive_started` still calls `_dive_began`.
- The rival and the dog-bumped checks are untouched. Other `Audio.play("snatch"` sites (dog outrun, collect, quest, scrap swallowed, mug, stash raid) are earned rewards and kept; only bump (game.gd:392) and BONK (:1131) switched to `gull_hit_1..3` via `_hit_sound()`.
- Added kinds `man`, `woman`, `teen` to `voices.pitch` besides the three in the task. `BeachTarget.voice_kind()` maps toddler, mum (woman), sunbather by sex, kiosk customer by appearance (old_man / sundress / other), everything else default. Watergun teen passes `teen`, sweeper `default`.
- A cut-in voice is freed with `queue_free()` (stop() would skip the finished signal). Gap and chance are checked before any state is stored, so a failed chance roll does not consume the gap.
- `screech_pitch` was only read in `game.gd`; the one test expecting 0.8 (`shakedown_checks.gd`) now expects 1.0.
- A bare-fixture lifeguard test was dropped (needs a full art setup); the lifeguard exclusion is a one-line `owner.kind != "lifeguard"` guard in `adult_reaction.gd`, not covered by a test.
- OGG files get random stream serials from libvorbis, so only the WAVs and the audition are byte-identical across runs (verified).

**Not done / unverified**: nothing sounds-checked (David to listen to the audition). Voice hooks were exercised in tests only for theft, stampede and pulse; warning, swat, give_up, cry, teen and sweeper hooks are wired but not asserted.

Branch `sonnet/079-sfx-pass`, last commit: see `git log -1` (hash below).

## Review notes
Reviewed by Claude Opus 2026-11-11: diff and hooks read; integration 17181 checks, same 2 pre-existing failures as baseline (sunbather run-off teleport, demo lock off). Agents cannot hear audio; David auditions in game. Merged into main at f80f043.
