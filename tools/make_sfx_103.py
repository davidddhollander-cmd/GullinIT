"""Task 103 sound pass 2: point jingles, Black Back calls cut from real herring gull recordings, oh-no voice.

    python tools/make_sfx_103.py <extracted-kenney-interface-sounds-dir>

Reuses the helpers of tools/make_sfx.py. Reads sources from C:/Users/david/Desktop/GAssets/SoundsFX (never copied
into the repo) and writes assets/audio/{snatch_1..4,score_1..2,bb_screech_long_1..3,bb_screech_short_1..3,
bb_shakedown_1..2,voice_oh_no_man|woman|kid}.ogg. Deterministic. Existing cues are left untouched.
"""
import glob
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_sfx as m  # noqa: E402

SR, AUDIO, SRC = m.SR, m.AUDIO, m.SRC


# ---------------------------------------------------------------- measuring
def lufs_p(x):
    """Integrated loudness with the cue zero-padded to 500 ms (ebur128 needs 400 ms; short cues read low, equally for all)."""
    return m.lufs(np.pad(x, (0, max(0, int(0.5 * SR) - len(x)))))


def active_rms_db(x):
    """RMS (dBFS) over the 20 ms frames that reach a quarter of the loudest frame: the loudness of the call, not its silence."""
    n = int(0.02 * SR)
    fr = np.array([np.sqrt(np.mean(x[k:k + n] ** 2)) for k in range(0, len(x) - n, n)])
    keep = fr >= 0.25 * fr.max()
    return 20 * np.log10(np.sqrt(np.mean(fr[keep] ** 2)))


def centroid(x):
    sp = np.abs(np.fft.rfft(x))
    return float((sp * np.fft.rfftfreq(len(x), 1 / SR)).sum() / sp.sum())


def soft_ceiling(x, db):
    c = 10 ** (db / 20)
    return c * np.tanh(x / c)


def match_lufs(x, target, ceil_db=-3.0):
    x = x * 10 ** ((target - lufs_p(x)) / 20)
    return soft_ceiling(x, ceil_db) if np.max(np.abs(x)) > 10 ** (ceil_db / 20) else x


# ---------------------------------------------------------------- synthesised jingles
def tone(t, start, f, hold, square=0.25, bright=1.0):
    """One bell-ish note: triangle plus a little band-limited square, with a short inharmonic shimmer."""
    s = np.maximum(t - start, 0)
    env = np.where(t >= start, m.exp_env(s, hold, 0.003), 0)
    tri = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * t))
    sq = m.lowpass(np.sign(np.sin(2 * np.pi * f * t)), 5000)
    shimmer = (0.14 * np.sin(2 * np.pi * 2.76 * f * t) * np.exp(-s / 0.045) + 0.06 * np.sin(2 * np.pi * 5.4 * f * t) * np.exp(-s / 0.03)) * bright
    return (tri * (1 - square) + sq * square + shimmer) * env


def jingle(notes, step, dur, hold, square, last_hold=None):
    t = m.t_axis(dur)
    x = np.zeros(len(t))
    for i, f in enumerate(notes):
        x += tone(t, 0.004 + i * step, f, last_hold if (last_hold and i == len(notes) - 1) else hold, square)
    return m.fade(m.peak_to(m.lowpass(x, 6500), -3.0), 6)


def kenney(path, max_dur=0.4):
    x = m.load(path)
    x = x[max(0, int(np.argmax(np.abs(x) > 0.02 * np.max(np.abs(x)))) - int(0.002 * SR)):]
    x = x[: int(max_dur * SR)]
    n = int(0.03 * SR)
    x = m.fade(x, 2)
    x[len(x) - n:] *= np.linspace(1, 0, n)
    return m.peak_to(x, -3.0)


# ---------------------------------------------------------------- Black Back from the herring gull recordings
def cut(src, a, b):
    return src[int((a - 0.04) * SR): int((b + 0.06) * SR)]


def bb_call(src, spd, dur_max, drive, low_boost_db, low_layer_db, growl, fade_ms, seed, ref_db):
    """Same chain as make_sfx.bellow (slow down, octave-down layer, saturate, low-mid body, roll off the fizz), with the
    speed a parameter and loudness matched on the call's own active RMS (short cuts defeat ebur128)."""
    x = m.speed(m.highpass(src, 30), spd)
    x = x + m.pad_to(m.speed(x, 0.5), len(x)) * 10 ** (low_layer_db / 20)
    x = x[: int(dur_max * SR)]
    t = m.t_axis(len(x) / SR)
    rng = np.random.default_rng(seed)
    wob = 1 + growl * np.sin(2 * np.pi * (38 + 4 * np.cumsum(rng.standard_normal(len(t))) / 600) * t)
    x = m.tanh_sat(x / np.max(np.abs(x)) * wob, drive)
    x = m.fft_eq(x, lambda f: m.bell(f, 280, 0.45, low_boost_db) / np.sqrt(1 + (f / 3500.0) ** 4))
    x = m.fade(x, 4)
    n = int(fade_ms / 1000 * SR)
    x[len(x) - n:] *= np.linspace(1, 0, n) ** 1.5
    x *= 10 ** ((ref_db - active_rms_db(x)) / 20)
    return soft_ceiling(x, -2.0)


def shift(x, ratio):
    """Pitch shift with rubberband (duration kept, formants shifted with the pitch)."""
    out = subprocess.run(["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "pipe:0", "-af",
                          "rubberband=pitch=%f:tempo=1:pitchq=quality" % ratio, "-f", "f32le", "-"],
                         input=x.astype("<f4").tobytes(), stdout=subprocess.PIPE, check=True).stdout
    return np.frombuffer(out, dtype="<f4").astype(np.float64)


def report(name, x):
    pk = 20 * np.log10(np.max(np.abs(x)))
    try:
        f0 = m.f0_median(x, 60, 3000) if len(x) > 8192 else float("nan")
    except Exception:
        f0 = float("nan")
    print("%-22s %5.3f s peak %6.2f  LUFS(pad) %6.1f  actRMS %6.1f  f0 %6.0f Hz  centroid %5.0f Hz" % (
        name, len(x) / SR, pk, lufs_p(x), active_rms_db(x), f0, centroid(x)))


def main():
    kdir = sys.argv[1]
    out = {}
    ts = lufs_p(m.load(os.path.join(AUDIO, "snatch.wav")))
    tc = lufs_p(m.load(os.path.join(AUDIO, "score.ogg")))

    # point jingles: two synthesised, two trimmed from the Kenney interface pack (CC0)
    out["snatch_1"] = match_lufs(jingle([587.33, 739.99, 880.0], 0.055, 0.34, 0.07, 0.15, 0.11), ts)       # D5 F#5 A5
    out["snatch_2"] = match_lufs(jingle([698.46, 880.0, 1046.5], 0.045, 0.30, 0.06, 0.5, 0.09), ts)        # F5 A5 C6
    out["snatch_3"] = match_lufs(kenney(os.path.join(kdir, "Audio", "confirmation_003.ogg")), ts)
    out["snatch_4"] = match_lufs(kenney(os.path.join(kdir, "Audio", "glass_001.ogg")), ts)
    out["score_1"] = match_lufs(jingle([783.99, 1174.66, 1567.98], 0.08, 0.42, 0.10, 0.2, 0.16), tc)       # G5 D6 G6
    out["score_2"] = match_lufs(jingle([523.25, 659.25, 783.99, 1046.5], 0.06, 0.42, 0.08, 0.35, 0.15), tc)  # C5 E5 G5 C6

    # Black Back: herring gull 1 long calls + kyow/kek, herring gull 2 long phrases
    g1 = m.load(os.path.join(SRC, "freesound_community-herring-gull-1-27057.mp3"))
    g2 = m.load(os.path.join(SRC, "freesound_community-herring-gull-2-64026.mp3"))
    rl, rs, rg = (active_rms_db(m.load(os.path.join(AUDIO, k + ".ogg"))) for k in ("bb_screech_long", "bb_screech_short", "bb_shakedown"))
    out["bb_screech_long_1"] = bb_call(cut(g1, 8.44, 9.18), 0.60, 4.5, 2.2, 15, -2, 0.25, 150, 31, rl)
    out["bb_screech_long_2"] = bb_call(cut(g1, 10.30, 11.08), 0.55, 4.5, 2.4, 14, -2, 0.30, 150, 32, rl)
    out["bb_screech_long_3"] = bb_call(cut(g1, 14.60, 15.32), 0.68, 4.5, 2.0, 15, -3, 0.25, 150, 33, rl)
    out["bb_screech_short_1"] = bb_call(cut(g1, 9.36, 9.50), 0.60, 4.5, 2.2, 6, -5, 0.25, 120, 34, rs)
    out["bb_screech_short_2"] = bb_call(cut(g1, 15.78, 15.94), 0.55, 4.5, 2.4, 6, -5, 0.30, 120, 35, rs)
    out["bb_screech_short_3"] = bb_call(cut(g1, 11.92, 12.10), 0.65, 4.5, 2.0, 7, -4, 0.25, 120, 36, rs)
    out["bb_shakedown_1"] = bb_call(cut(g2, 12.74, 14.44), 0.58, 3.4, 3.0, 9, -3, 0.35, 150, 37, rg)
    out["bb_shakedown_2"] = bb_call(cut(g2, 14.60, 16.50), 0.62, 3.4, 3.0, 9, -3, 0.35, 150, 38, rg)

    # oh no: the whole phrase (0.12-1.66 s) at three pitch ratios, rms matched to the existing voices of each register
    src = m.load(os.path.join(SRC, "kalsstockmedia-human-voice-saying-oh-no-301694.mp3"))
    phrase = src[int(0.12 * SR): int(1.66 * SR)]
    print("source oh-no f0 median %.0f Hz (oh %.0f, no %.0f)" % (m.f0_median(phrase, 70, 700), m.f0_median(src[int(.16 * SR):int(.58 * SR)], 70, 700), m.f0_median(src[int(.86 * SR):int(1.66 * SR)], 70, 700)))
    for reg, ratio in (("man", 0.42), ("woman", 0.62), ("kid", 0.88)):
        refs = [active_rms_db(m.load(f)) for f in glob.glob(os.path.join(AUDIO, "voice_*_%s.ogg" % reg)) if "oh_no" not in f]
        y = m.fade(shift(phrase, ratio), 8)
        n = int(0.03 * SR)
        y[len(y) - n:] *= np.linspace(1, 0, n)
        y = m.peak_to(y, -3.0)
        y *= 10 ** ((float(np.mean(refs)) - active_rms_db(y)) / 20)
        out["voice_oh_no_" + reg] = soft_ceiling(y, -3.0)

    shipped = {k: m.encode(os.path.join(AUDIO, k + ".ogg"), x) for k, x in out.items()}

    print("--- references")
    for k in ("snatch.wav", "score.ogg", "screech_long.ogg", "screech_short.ogg", "bb_screech_long.ogg", "bb_screech_short.ogg", "bb_shakedown.ogg", "voice_hey_man.ogg", "voice_aww_woman.ogg", "voice_wah_kid.ogg"):
        report(k, m.load(os.path.join(AUDIO, k)))
    print("--- new (decoded)")
    for k in sorted(shipped):
        report(k, shipped[k])


if __name__ == "__main__":
    sys.exit(main())
