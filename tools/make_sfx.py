"""Generate the task-079 sound effects (numpy + wave + ffmpeg, deterministic seeds).

    python tools/make_sfx.py

Writes assets/audio/{dive,snatch}.wav, the bb_*, voice_*, dog_bark and whistle .ogg
cues, and test-output/sfx-audition.wav (old dive/snatch, screech_long, then every new cue).
Voices are cartoon gibberish: a glottal pulse train through moving vowel formants.
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
AUDIO = os.path.join(ROOT, "assets", "audio")
AUDITION = os.path.join(ROOT, "test-output", "sfx-audition.wav")


# ---------------------------------------------------------------- io
def load(path=None, data=None):
    """Any audio file (or bytes) -> float32 mono 44.1 kHz."""
    cmd = ["ffmpeg", "-v", "error", "-i", path or "pipe:0", "-ar", str(SR), "-ac", "1", "-f", "f32le", "-"]
    out = subprocess.run(cmd, input=data, stdout=subprocess.PIPE, check=True).stdout
    return np.frombuffer(out, dtype="<f4").astype(np.float64)


def write_wav(path, x):
    pcm = np.round(np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def write_ogg(path, x):
    pcm = np.round(np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "pipe:0",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=pcm, check=True)


def lufs(x):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "pipe:0",
                          "-af", "ebur128=peak=true", "-f", "null", "-"], input=x.astype("<f4").tobytes(),
                         stderr=subprocess.PIPE, check=True).stderr.decode()
    summary = out[out.rfind("Summary"):]
    return float(summary.split("I:")[1].split("LUFS")[0])


# ---------------------------------------------------------------- dsp helpers
def t_axis(dur):
    return np.arange(int(round(dur * SR))) / SR


def fade(x, ms=3.0):
    n = min(int(SR * ms / 1000), len(x) // 2)
    x = x.copy()
    ramp = np.linspace(0, 1, n)
    x[:n] *= ramp
    x[len(x) - n:] *= ramp[::-1]
    return x


def peak_to(x, db):
    return x * (10 ** (db / 20) / np.max(np.abs(x)))


def fft_eq(x, gain):
    """Zero-phase EQ: gain(freqs_hz) -> linear gain curve."""
    spec = np.fft.rfft(x)
    spec *= gain(np.fft.rfftfreq(len(x), 1 / SR))
    return np.fft.irfft(spec, len(x))


def bell(f, centre, width, db):
    return 1 + (10 ** (db / 20) - 1) * np.exp(-0.5 * (np.log2(np.maximum(f, 1) / centre) / width) ** 2)


def lowpass(x, fc, order=2):
    return fft_eq(x, lambda f: 1 / np.sqrt(1 + (f / fc) ** (2 * order)))


def highpass(x, fc, order=2):
    return fft_eq(x, lambda f: 1 / np.sqrt(1 + (fc / np.maximum(f, 1e-3)) ** (2 * order)))


def svf_bandpass(x, fc, q):
    """State-variable band-pass with a per-sample centre frequency array."""
    f = 2 * np.sin(np.pi * np.minimum(fc, SR / 6) / SR)
    damp = 1.0 / q
    lo = bp = 0.0
    out = np.empty(len(x))
    for i in range(len(x)):
        lo += f[i] * bp
        hi = x[i] - lo - damp * bp
        bp += f[i] * hi
        out[i] = bp
    return out


def resonators(src, tracks):
    """Cascade-free parallel formant bank. tracks: list of (freq_array, bw_array, gain)."""
    out = np.zeros(len(src))
    for freq, bw, gain in tracks:
        r = np.exp(-np.pi * bw / SR)
        b = 2 * r * np.cos(2 * np.pi * freq / SR)
        c = -r * r
        a = 1 - b - c
        y1 = y2 = 0.0
        y = np.empty(len(src))
        for i in range(len(src)):
            y0 = a[i] * src[i] + b[i] * y1 + c[i] * y2
            y[i] = y0
            y2, y1 = y1, y0
        out += gain * y
    return out


def speed(x, factor):
    """Resample so playback runs at `factor` speed (0.72 -> slower and lower)."""
    n = int(len(x) / factor)
    return np.interp(np.arange(n) * factor, np.arange(len(x)), x)


def exp_env(t, tau, attack=0.002):
    return np.minimum(1, t / attack) * np.exp(-t / tau)


def sweep_sine(t, f0, f1, tau_sweep):
    freq = f1 + (f0 - f1) * np.exp(-t / tau_sweep)
    return np.sin(2 * np.pi * np.cumsum(freq) / SR)


def pad_to(x, n):
    return np.pad(x, (0, max(0, n - len(x))))[:n]


# ---------------------------------------------------------------- air swoosh
def swoosh(seed, dur, f_lo, f_hi, f_end, q, peak_at, rumble=0.0):
    rng = np.random.default_rng(seed)
    t = t_axis(dur)
    u = t / dur
    # centre rises to f_hi at peak_at, then falls to f_end
    rise = np.clip(u / peak_at, 0, 1) ** 1.4
    fall = np.clip((u - peak_at) / (1 - peak_at), 0, 1) ** 1.2
    fc = np.where(u < peak_at, f_lo + (f_hi - f_lo) * rise, f_hi + (f_end - f_hi) * fall)
    # asymmetric swell: slow build, quicker release
    env = np.where(u < peak_at, np.sin(0.5 * np.pi * np.clip(u / peak_at, 0, 1)) ** 2,
                   np.cos(0.5 * np.pi * np.clip((u - peak_at) / (1 - peak_at), 0, 1)) ** 1.5)
    x = svf_bandpass(rng.standard_normal(len(t)), fc, q) * env
    if rumble:
        x += rumble * lowpass(rng.standard_normal(len(t)), 180) * env
    return fade(peak_to(x, -3.0), 4)


# ---------------------------------------------------------------- snatch reward
def snatch():
    rng = np.random.default_rng(79)
    t = t_axis(0.24)
    tk = highpass(rng.standard_normal(len(t)), 1500) * exp_env(t, 0.004, 0.0005) * 0.55
    x = tk.copy()
    for start, f in ((0.012, 880.0), (0.085, 1318.5)):   # A5 then E6, a fifth up
        s = np.maximum(t - start, 0)
        env = np.where(t >= start, exp_env(s, 0.05, 0.002), 0)
        note = np.sin(2 * np.pi * f * t) + 0.22 * np.sin(2 * np.pi * 2.0 * f * t) * np.exp(-s / 0.03) \
            + 0.08 * np.sin(2 * np.pi * 2.76 * f * t) * np.exp(-s / 0.02)
        x += 0.6 * note * env
    return fade(peak_to(lowpass(x, 4500), -3.0), 5)


# ---------------------------------------------------------------- Black Back
def tanh_sat(x, drive):
    return np.tanh(drive * x) / np.tanh(drive)


def bellow(src, dur_max, drive, low_boost_db, low_layer_db, growl, fade_ms, seed, target_lufs):
    x = speed(highpass(src, 30), 0.72)         # about -5.7 semitones; the source has a sub-30 Hz rumble we drop
    low = pad_to(speed(x, 0.5), len(x))        # an octave lower
    x = x + low * 10 ** (low_layer_db / 20)
    x = x[: int(dur_max * SR)]
    t = t_axis(len(x) / SR)
    rng = np.random.default_rng(seed)
    wob = 1 + growl * np.sin(2 * np.pi * (38 + 4 * np.cumsum(rng.standard_normal(len(t))) / 600) * t)
    x = tanh_sat(x / np.max(np.abs(x)) * wob, drive)
    x = fft_eq(x, lambda f: bell(f, 280, 0.45, low_boost_db) / np.sqrt(1 + (f / 5000.0) ** 4))
    x = fade(x, 3)
    n = int(fade_ms / 1000 * SR)
    x[len(x) - n:] *= np.linspace(1, 0, n) ** 1.5
    ceil = 10 ** (-2.0 / 20)                   # soft ceiling leaves headroom for the ogg encoder
    for _ in range(4):
        x *= 10 ** ((target_lufs - lufs(x)) / 20)
        x = ceil * np.tanh(x / ceil)
    return x


def bb_stun():
    rng = np.random.default_rng(31)
    t = t_axis(0.3)
    f0 = 62 - 18 * t / 0.3
    phase = np.cumsum(f0) / SR
    src = ((1 - (phase % 1)) ** 2 - 0.33) * (1 + 0.04 * rng.standard_normal(len(t)))
    croak = resonators(src, [(np.full(len(t), 260.0), np.full(len(t), 120.0), 1.0),
                             (580 - 200 * t / 0.3, np.full(len(t), 160.0), 0.7)])
    croak = croak / np.max(np.abs(croak)) * np.minimum(1, t / 0.01) * np.exp(-t / 0.16)
    thump = sweep_sine(t, 140, 45, 0.05) * exp_env(t, 0.07, 0.001)
    return fade(peak_to(tanh_sat(0.8 * croak + 0.9 * thump, 2.0), -3.0), 4)


def bb_hit():
    rng = np.random.default_rng(32)
    t = t_axis(0.18)
    thump = sweep_sine(t, 150, 50, 0.04) * exp_env(t, 0.06, 0.001)
    crack = lowpass(rng.standard_normal(len(t)), 1800) * exp_env(t, 0.02, 0.0005)
    return fade(peak_to(tanh_sat(1.0 * thump + 0.5 * crack, 2.5), -3.0), 3)


def bb_slam():
    rng = np.random.default_rng(33)
    t = t_axis(0.8)
    drop = sweep_sine(t, 170, 28, 0.22) * exp_env(t, 0.3, 0.002)
    crack = highpass(rng.standard_normal(len(t)), 400) * exp_env(t, 0.045, 0.0005)
    rumble = lowpass(rng.standard_normal(len(t)), 260) * exp_env(t, 0.3, 0.005)
    return fade(peak_to(tanh_sat(1.0 * drop + 0.55 * crack + 0.6 * rumble, 2.0), -3.0), 5)


def bb_stomp():
    rng = np.random.default_rng(34)
    t = t_axis(0.16)
    thud = sweep_sine(t, 95, 50, 0.04) * exp_env(t, 0.05, 0.003)
    dust = lowpass(rng.standard_normal(len(t)), 500) * exp_env(t, 0.03, 0.002)
    return fade(peak_to(thud + 0.25 * dust, -6.0), 5)


# ---------------------------------------------------------------- voices
VOWEL = {"a": (800, 1200, 2600), "e": (500, 1800, 2500), "i": (300, 2300, 3000),
         "o": (500, 900, 2500), "u": (320, 800, 2400), "ae": (700, 1700, 2500)}


def contour(t, points):
    """Piecewise-linear value over time from [(t, v), ...]."""
    return np.interp(t, [p[0] for p in points], [p[1] for p in points])


def voice(seed, dur, f0_pts, vowel_pts, amp_pts, vib=0.012, jit=0.01, breath=0.03, h_ms=0.0, bw_scale=1.0):
    """f0_pts [(t,Hz)], vowel_pts [(t,'a')], amp_pts [(t,0..1)]; h_ms adds an aspirated 'h' onset."""
    rng = np.random.default_rng(seed)
    t = t_axis(dur)
    f0 = contour(t, f0_pts)
    f0 = f0 * (1 + vib * np.sin(2 * np.pi * 5.6 * t)) * (1 + jit * np.convolve(rng.standard_normal(len(t)), np.ones(200) / 200, "same") * 12)
    phase = np.cumsum(f0) / SR % 1
    src = np.where(phase < 0.6, 0.5 * (1 - np.cos(np.pi * phase / 0.6)), np.cos(0.5 * np.pi * (phase - 0.6) / 0.4)) - 0.35
    src = np.diff(src, prepend=0) * 40                     # glottal flow derivative
    src += breath * rng.standard_normal(len(t))
    form = [contour(t, [(p[0], VOWEL[p[1]][k]) for p in vowel_pts]) for k in range(3)]
    out = resonators(src, [(form[0], np.full(len(t), 90.0 * bw_scale), 1.0),
                           (form[1], np.full(len(t), 110.0 * bw_scale), 0.7),
                           (form[2], np.full(len(t), 160.0 * bw_scale), 0.35)])
    out *= contour(t, amp_pts)
    if h_ms:
        n = int(h_ms / 1000 * SR)
        hiss = rng.standard_normal(len(t))
        hiss = resonators(hiss, [(form[1], np.full(len(t), 400.0), 1.0), (form[2], np.full(len(t), 500.0), 0.6)])
        hn = np.zeros(len(t))
        hn[:n] = np.minimum(1, np.arange(n) / max(1, n * 0.3)) * np.linspace(1, 0.2, n)
        out += hiss * hn * 0.25 * np.max(np.abs(out)) / max(1e-9, np.max(np.abs(hiss)))
    return fade(peak_to(out, -6.0), 4)


def voices():
    v = {}
    v["voice_hey"] = voice(1, 0.34, [(0, 190), (0.08, 230), (0.2, 260), (0.34, 200)], [(0, "e"), (0.14, "e"), (0.26, "i")],
                           [(0, 0.4), (0.06, 1), (0.25, 0.9), (0.34, 0)], h_ms=55)
    v["voice_oi"] = voice(2, 0.36, [(0, 200), (0.12, 250), (0.36, 190)], [(0, "o"), (0.16, "o"), (0.28, "i")],
                          [(0, 0.2), (0.05, 1), (0.28, 0.9), (0.36, 0)])
    v["voice_whoa"] = voice(3, 0.5, [(0, 180), (0.15, 260), (0.3, 250), (0.5, 170)], [(0, "u"), (0.12, "o"), (0.3, "a"), (0.5, "o")],
                            [(0, 0.2), (0.12, 1), (0.38, 0.9), (0.5, 0)], vib=0.02)
    v["voice_aah"] = voice(4, 0.5, [(0, 250), (0.12, 290), (0.5, 220)], [(0, "a"), (0.5, "a")],
                           [(0, 0.3), (0.06, 1), (0.4, 0.9), (0.5, 0)], vib=0.03, breath=0.05)
    v["voice_huh"] = voice(5, 0.2, [(0, 170), (0.08, 210), (0.2, 190)], [(0, "ae"), (0.2, "a")],
                           [(0, 0.5), (0.04, 1), (0.14, 0.8), (0.2, 0)], h_ms=40)
    v["voice_aww"] = voice(6, 0.5, [(0, 260), (0.12, 250), (0.5, 160)], [(0, "a"), (0.25, "o"), (0.5, "u")],
                           [(0, 0.3), (0.08, 1), (0.38, 0.8), (0.5, 0)], vib=0.025)
    ha = voice(7, 0.17, [(0, 220), (0.17, 180)], [(0, "a"), (0.17, "a")], [(0, 0.5), (0.03, 1), (0.1, 0.7), (0.17, 0)], h_ms=40)
    v["voice_hah"] = fade(peak_to(np.concatenate([ha, np.zeros(int(0.02 * SR)), 0.8 * ha]), -6.0), 4)
    v["voice_wah"] = voice(8, 0.7, [(0, 330), (0.1, 420), (0.35, 450), (0.7, 330)], [(0, "u"), (0.12, "a"), (0.55, "a"), (0.7, "o")],
                           [(0, 0.3), (0.1, 1), (0.55, 0.9), (0.7, 0)], vib=0.06, jit=0.015, breath=0.04)
    return v


def dog_bark():
    rng = np.random.default_rng(9)
    t = t_axis(0.2)
    ar = voice(10, 0.2, [(0, 420), (0.05, 380), (0.2, 250)], [(0, "a"), (0.1, "ae"), (0.2, "o")],
               [(0, 0.5), (0.01, 1), (0.1, 0.5), (0.2, 0)], vib=0.0, jit=0.03, breath=0.25, bw_scale=1.6)
    rf = lowpass(highpass(rng.standard_normal(len(t)), 800), 3500) * np.exp(-((t - 0.1) / 0.06) ** 2) * 0.2
    return fade(peak_to(tanh_sat(ar / np.max(np.abs(ar)) + rf, 1.5), -3.0), 3)


def whistle():
    rng = np.random.default_rng(11)
    t = t_axis(0.4)
    tone = (np.sin(2 * np.pi * 22 * t) > 0)               # trill between two pitches
    freq = np.where(tone, 3350.0, 2800.0)
    car = np.sin(2 * np.pi * np.cumsum(freq) / SR)
    pea = 0.75 + 0.25 * np.sin(2 * np.pi * 44 * t)         # the pea rattling in the chamber
    breath = svf_bandpass(rng.standard_normal(len(t)), np.full(len(t), 3100.0), 3.0)
    breath *= 0.25 / np.max(np.abs(breath))
    env = np.minimum(1, t / 0.015) * np.minimum(1, (0.4 - t) / 0.05)
    return fade(peak_to((car * pea + breath) * env, -3.0), 4)


# ---------------------------------------------------------------- stats
def flatness(x, lo=200, hi=9000):
    """Mean per-frame spectral flatness (geometric/arithmetic mean of the power spectrum) in [lo, hi]."""
    n = 2048
    freqs = np.fft.rfftfreq(n, 1 / SR)
    band = (freqs >= lo) & (freqs <= hi)
    vals = []
    for s in range(0, len(x) - n, n // 2):
        p = np.abs(np.fft.rfft(x[s:s + n] * np.hanning(n))) ** 2 + 1e-12
        if p[band].sum() > 1e-6 * n:
            vals.append(np.exp(np.mean(np.log(p[band]))) / np.mean(p[band]))
    return float(np.mean(vals)) if vals else float("nan")


def low_band(x, lo=30, cut=500):
    """Mean-square power (dBFS) in lo..cut Hz; the sub-30 Hz rumble in the original screech is ignored."""
    p = np.abs(np.fft.rfft(x)) ** 2 / len(x) ** 2 * 2
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return 10 * math.log10(p[(f >= lo) & (f < cut)].sum() + 1e-12)


def stats(name, x):
    pk = 20 * math.log10(max(np.max(np.abs(x)), 1e-9))
    li = lufs(np.pad(x, (0, max(0, int(0.4 * SR) - len(x)))))  # ebur128 needs 400 ms; short cues are zero-padded (reads low)
    print(f"{name:18s} {len(x) / SR:6.3f} s  peak {pk:6.2f} dBFS  {li:7.1f} LUFS  flat {flatness(x):.4f}  30-500Hz {low_band(x):6.1f} dB")


# ---------------------------------------------------------------- main
def main():
    out = {}
    old_dive = load(data=git_show("assets/audio/dive.wav"))
    old_snatch = load(data=git_show("assets/audio/snatch.wav"))
    screech_long = load(os.path.join(AUDIO, "screech_long.ogg"))
    screech_short = load(os.path.join(AUDIO, "screech_short.ogg"))
    gang_call = load(os.path.join(AUDIO, "gang_call.ogg"))
    ll, ls, lg = lufs(screech_long), lufs(screech_short), lufs(gang_call)

    wavs = {"dive": swoosh(1, 0.52, 450, 3400, 800, 1.1, 0.62), "snatch": snatch()}
    for k, x in wavs.items():
        write_wav(os.path.join(AUDIO, k + ".wav"), x)

    oggs = {
        "bb_screech_long": bellow(screech_long, 4.5, 2.2, 15, -5, 0.25, 150, 21, ll),
        "bb_screech_short": bellow(screech_short, 4.5, 2.2, 6, -10, 0.25, 150, 22, ls),
        "bb_dive": swoosh(2, 0.68, 220, 1500, 350, 0.9, 0.58, rumble=0.9),
        "bb_stun": bb_stun(),
        "bb_hit": bb_hit(),
        "bb_shakedown": bellow(screech_long, 3.2, 3.0, 9, -6, 0.35, 150, 23, lg),
        "bb_slam": bb_slam(),
        "bb_stomp": bb_stomp(),
    }
    oggs.update(voices())
    oggs["dog_bark"] = dog_bark()
    oggs["whistle"] = whistle()
    shipped = {}
    for k, x in oggs.items():
        p = os.path.join(AUDIO, k + ".ogg")
        write_ogg(p, x)
        shipped[k] = load(p)                               # what the game actually plays
        while np.max(np.abs(shipped[k])) > 10 ** (-1.5 / 20):   # lossy overshoot: back off and re-encode
            x = x * 0.9
            write_ogg(p, x)
            shipped[k] = load(p)

    order = ["bb_screech_long", "bb_screech_short", "bb_dive", "bb_stun", "bb_hit", "bb_shakedown", "bb_slam", "bb_stomp",
             "voice_hey", "voice_oi", "voice_whoa", "voice_aah", "voice_huh", "voice_aww", "voice_hah", "voice_wah",
             "dog_bark", "whistle"]
    gap = np.zeros(SR // 2)
    parts = [old_dive, gap, old_snatch, gap, wavs["dive"], gap, wavs["snatch"], gap, screech_long, gap]
    for k in order:
        parts += [shipped[k], gap]
    os.makedirs(os.path.dirname(AUDITION), exist_ok=True)
    write_wav(AUDITION, np.concatenate(parts))

    print("--- measurements (shipped files, decoded)")
    stats("old dive", old_dive)
    stats("old snatch", old_snatch)
    stats("screech_long", screech_long)
    stats("screech_short", screech_short)
    stats("gang_call", gang_call)
    for k in ("dive", "snatch"):
        stats(k, load(os.path.join(AUDIO, k + ".wav")))
    for k in order:
        stats(k, shipped[k])
    t = t_axis(0.52)
    stats("ref: sine sweep", sweep_sine(t, 450, 3400, 0.2) * np.hanning(len(t)))


def git_show(path):
    return subprocess.run(["git", "show", "main:" + path], cwd=ROOT, stdout=subprocess.PIPE, check=True).stdout


if __name__ == "__main__":
    sys.exit(main())
