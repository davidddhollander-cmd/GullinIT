"""Generate the task-079/080 sound effects (numpy + wave + ffmpeg, deterministic seeds).

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
AUDITION = os.path.join(ROOT, "test-output", "sfx-audition-2.wav")


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


BB_SPEED = 0.6                                 # task 080: about -8.8 semitones (079 used 0.72)


def bellow(src, dur_max, drive, low_boost_db, low_layer_db, growl, fade_ms, seed, target_lufs):
    x = speed(highpass(src, 30), BB_SPEED)     # the source has a sub-30 Hz rumble we drop
    low = pad_to(speed(x, 0.5), len(x))        # an octave lower
    x = x + low * 10 ** (low_layer_db / 20)
    x = x[: int(dur_max * SR)]
    t = t_axis(len(x) / SR)
    rng = np.random.default_rng(seed)
    wob = 1 + growl * np.sin(2 * np.pi * (38 + 4 * np.cumsum(rng.standard_normal(len(t))) / 600) * t)
    x = tanh_sat(x / np.max(np.abs(x)) * wob, drive)
    x = fft_eq(x, lambda f: bell(f, 280, 0.45, low_boost_db) / np.sqrt(1 + (f / 3500.0) ** 4))
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


# Register: (base f0 Hz, formant scale). Pitch lives in the render, so runtime pitch is jitter only.
REGISTERS = {"man": (112.0, 1.0), "woman": (205.0, 1.12), "kid": (320.0, 1.25)}
VOWEL.update({"w": (290, 610, 2150), "y": (270, 2200, 3000), "n": (250, 1100, 2300)})   # glide / nasal targets


def noise_burst(kind, rng, t0, n_total):
    """Unit-peak consonant noise (kind, start s, length n_total) for h, sh, s, f, ch, t, k, p."""
    n = n_total
    x = rng.standard_normal(n)
    band = {"h": (500, 5500), "sh": (2200, 7500), "s": (4500, 9500), "f": (1500, 9000), "ch": (2200, 7500),
            "t": (1800, 9000), "k": (900, 6000), "p": (60, 1800)}[kind]
    x = lowpass(highpass(x, band[0]), band[1])
    return x


def speak(seed, reg, dur, f0_pts, vowel_pts, amp_pts, noises=(), vib=0.012, jit=0.01, breath=0.03):
    """Cartoon word: f0_pts [(t, ratio)] times the register's base f0, vowel/consonant formant glides, noise consonants.
    noises: (kind, start s, length s, gain re the voiced peak). Formant bandwidths are ~0.7x the task-079 voices."""
    base, fs = REGISTERS[reg]
    rng = np.random.default_rng(seed)
    t = t_axis(dur)
    f0 = contour(t, f0_pts) * base
    f0 = f0 * (1 + vib * np.sin(2 * np.pi * 5.6 * t)) * (1 + jit * np.convolve(rng.standard_normal(len(t)), np.ones(200) / 200, "same") * 12)
    phase = np.cumsum(f0) / SR % 1
    src = np.where(phase < 0.6, 0.5 * (1 - np.cos(np.pi * phase / 0.6)), np.cos(0.5 * np.pi * (phase - 0.6) / 0.4)) - 0.35
    src = np.diff(src, prepend=0) * 40
    src += breath * rng.standard_normal(len(t))
    form = [contour(t, [(p[0], VOWEL[p[1]][k] * fs) for p in vowel_pts]) for k in range(3)]
    out = resonators(src, [(form[0], np.full(len(t), 63.0), 1.0), (form[1], np.full(len(t), 77.0), 0.75), (form[2], np.full(len(t), 112.0), 0.4)])
    out *= contour(t, amp_pts)
    pk = np.max(np.abs(out))
    for kind, t0, length, gain in noises:
        n = int(length * SR)
        i0 = int(t0 * SR)
        x = noise_burst(kind, rng, t0, n)
        u = np.arange(n) / n
        if kind in ("t", "k", "p", "ch"):
            env = np.exp(-np.arange(n) / SR / (length * 0.35)) * np.minimum(1, np.arange(n) / (0.001 * SR))
        else:
            env = np.sin(np.pi * np.clip(u, 0, 1)) ** 0.6
        x = x * env
        x *= gain * pk / max(1e-9, np.max(np.abs(x)))
        j = min(n, len(out) - i0)
        out[i0:i0 + j] += x[:j]
    out = fft_eq(out, lambda f: bell(f, 3000, 0.5, 5.0) * (f > 70))   # presence lift so the word cuts through the music
    return fade(peak_to(out, -6.0), 4)


# dur, f0 ratio contour, vowel/consonant glides, amplitude, noise consonants. Same timing in every register.
LINES = {
    "hey": dict(dur=0.40, f0=[(0, .92), (0.1, 1.15), (0.24, 1.4), (0.4, .95)], v=[(0, "e"), (0.2, "e"), (0.32, "i"), (0.4, "i")],
                a=[(0, .3), (0.07, 1), (0.32, .9), (0.4, 0)], n=[("h", 0.0, 0.09, 0.6)]),
    "oi": dict(dur=0.42, f0=[(0, .95), (0.14, 1.3), (0.3, 1.45), (0.42, .95)], v=[(0, "o"), (0.2, "o"), (0.34, "i"), (0.42, "i")],
               a=[(0, .25), (0.05, 1), (0.34, .9), (0.42, 0)], n=[]),
    "my_chips": dict(dur=0.78, f0=[(0, 1.0), (0.12, 1.15), (0.24, .95), (0.3, 1.5), (0.5, 1.6), (0.56, 1.1), (0.78, .8)],
                     v=[(0, "n"), (0.05, "a"), (0.17, "i"), (0.26, "i"), (0.5, "i"), (0.6, "i"), (0.78, "ae")],
                     a=[(0, .2), (0.05, .8), (0.2, .7), (0.25, .1), (0.3, 1.0), (0.5, 1.0), (0.55, .15), (0.6, .55), (0.7, .35), (0.78, 0)],
                     n=[("ch", 0.24, 0.06, 0.9), ("p", 0.55, 0.04, 0.5), ("s", 0.66, 0.12, 0.55)]),
    "no_no": dict(dur=0.78, f0=[(0, 1.0), (0.15, 1.05), (0.25, 1.1), (0.4, 1.2), (0.5, 1.45), (0.62, 1.6), (0.78, 1.1)],
                  v=[(0, "n"), (0.05, "o"), (0.2, "o"), (0.26, "n"), (0.3, "o"), (0.42, "o"), (0.48, "n"), (0.54, "o"), (0.78, "o")],
                  a=[(0, .2), (0.06, .8), (0.19, .7), (0.25, .25), (0.31, .85), (0.41, .75), (0.47, .25), (0.55, 1.0), (0.68, .95), (0.78, 0)], n=[]),
    "whoa": dict(dur=0.52, f0=[(0, .85), (0.15, 1.3), (0.3, 1.35), (0.52, .8)], v=[(0, "w"), (0.1, "u"), (0.2, "o"), (0.36, "a"), (0.52, "o")],
                 a=[(0, .25), (0.1, 1), (0.4, .9), (0.52, 0)], n=[]),
    "huh": dict(dur=0.30, f0=[(0, .95), (0.1, 1.1), (0.3, 1.4)], v=[(0, "ae"), (0.3, "a")],
                a=[(0, .4), (0.06, 1), (0.22, .8), (0.3, 0)], n=[("h", 0.0, 0.07, 0.6)]),
    "eek": dict(dur=0.42, f0=[(0, 1.2), (0.1, 1.6), (0.3, 1.75), (0.36, 1.5)], v=[(0, "i"), (0.4, "i")],
                a=[(0, .3), (0.06, 1), (0.32, 1), (0.36, .1), (0.42, 0)], n=[("k", 0.35, 0.07, 0.5)]),
    "shoo": dict(dur=0.48, f0=[(0, 1.1), (0.2, 1.35), (0.48, .95)], v=[(0, "u"), (0.12, "u"), (0.48, "u")],
                 a=[(0, 0), (0.12, .5), (0.18, 1), (0.4, .9), (0.48, 0)], n=[("sh", 0.0, 0.16, 0.7)]),
    "get_off": dict(dur=0.58, f0=[(0, 1.0), (0.15, 1.1), (0.3, 1.5), (0.52, 1.0)], v=[(0, "e"), (0.2, "e"), (0.26, "o"), (0.5, "o")],
                    a=[(0, .4), (0.04, 1), (0.18, .8), (0.2, .05), (0.27, 1.0), (0.46, .8), (0.52, .1), (0.58, 0)],
                    n=[("k", 0.0, 0.04, 0.4), ("t", 0.2, 0.05, 0.6), ("f", 0.5, 0.08, 0.5)]),
    "hah": dict(dur=0.42, f0=[(0, 1.2), (0.17, .9), (0.2, 1.2), (0.42, .85)], v=[(0, "a"), (0.42, "a")],
                a=[(0, .3), (0.04, 1), (0.14, .7), (0.18, .08), (0.24, .9), (0.34, .7), (0.42, 0)],
                n=[("h", 0.0, 0.07, 0.6), ("h", 0.18, 0.07, 0.6)]),
    "gotcha": dict(dur=0.62, f0=[(0, 1.0), (0.12, 1.15), (0.28, 1.45), (0.5, 1.0), (0.62, .8)], v=[(0, "o"), (0.2, "o"), (0.3, "a"), (0.62, "a")],
                   a=[(0, .5), (0.03, 1), (0.18, .8), (0.2, .05), (0.32, 1.0), (0.5, .8), (0.62, 0)],
                   n=[("k", 0.0, 0.04, 0.4), ("t", 0.19, 0.04, 0.5), ("ch", 0.27, 0.07, 0.9)]),
    "aww": dict(dur=0.58, f0=[(0, 1.3), (0.15, 1.2), (0.58, .75)], v=[(0, "a"), (0.25, "o"), (0.58, "u")],
                a=[(0, .3), (0.08, 1), (0.45, .8), (0.58, 0)], n=[]),
    "ugh": dict(dur=0.48, f0=[(0, 1.0), (0.3, .75), (0.48, .65)], v=[(0, "ae"), (0.3, "o"), (0.48, "u")],
                a=[(0, .3), (0.06, 1), (0.32, .8), (0.44, .3), (0.48, 0)], n=[("k", 0.38, 0.1, 0.35)]),
    "hmph": dict(dur=0.48, f0=[(0, 1.0), (0.2, 1.2), (0.3, 1.1)], v=[(0, "o"), (0.08, "n"), (0.3, "n")],
                 a=[(0, .2), (0.07, .8), (0.28, .8), (0.31, 0), (0.48, 0)],
                 n=[("h", 0.0, 0.07, 0.4), ("p", 0.3, 0.04, 0.7), ("f", 0.33, 0.14, 0.5)]),
    "aah": dict(dur=0.62, f0=[(0, 1.1), (0.12, 1.5), (0.5, 1.4), (0.62, 1.1)], v=[(0, "a"), (0.62, "a")],
                a=[(0, .3), (0.06, 1), (0.5, .9), (0.62, 0)], n=[]),
    "wah": dict(dur=0.72, f0=[(0, 1.0), (0.1, 1.3), (0.4, 1.4), (0.72, .9)], v=[(0, "w"), (0.1, "u"), (0.18, "a"), (0.58, "a"), (0.72, "o")],
                a=[(0, .3), (0.1, 1), (0.58, .9), (0.72, 0)], n=[], vib=0.06, jit=0.015, breath=0.04),
}


def voice_cues():
    """voice_<line>_<register> for every line and register (wah is kid only)."""
    out = {}
    for i, (line, d) in enumerate(LINES.items()):
        for j, reg in enumerate(REGISTERS):
            if line == "wah" and reg != "kid":
                continue
            out["voice_%s_%s" % (line, reg)] = speak(100 + i * 10 + j, reg, d["dur"], d["f0"], d["v"], d["a"], d["n"],
                                                     **{k: d[k] for k in ("vib", "jit", "breath") if k in d})
    return out


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


# ---------------------------------------------------------------- derived from the Pixabay files in SoundsFX (task 080)
SRC = "C:/Users/david/Desktop/GAssets/SoundsFX"


def rms_env(x, ms=5):
    h = int(SR * ms / 1000)
    return np.array([np.sqrt(np.mean(x[k:k + h] ** 2)) for k in range(0, len(x) - h, h)]), h


def rms_db(x):
    return 20 * math.log10(max(float(np.sqrt(np.mean(x ** 2))), 1e-9))


def swat_thwack(src, ref_rms_db):
    """Onset -> 0.75 s (thwack plus the start of its wobble), fade out, rms matched to the gull_hit cues, soft-limited."""
    env, h = rms_env(src)
    start = max(0, int(np.argmax(env >= 0.12 * env.max())) * h - int(0.01 * SR))
    x = src[start:start + int(0.75 * SR)]
    n = int(0.15 * SR)
    x = fade(x, 2)
    x[len(x) - n:] *= np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    x = np.tanh(1.5 * x / np.max(np.abs(x)))
    x *= 10 ** ((ref_rms_db - rms_db(x)) / 20)
    ceil = 10 ** (-2.0 / 20)
    return ceil * np.tanh(x / ceil)


def wing_flaps(src):
    """Single flaps cut at the energy valley of the source (it holds two strokes), peak -3 dBFS."""
    env, h = rms_env(src, 10)
    on = np.where(env > 0.1 * env.max())[0]
    lo, hi = on[0] * h - int(0.07 * SR), on[-1] * h + int(0.12 * SR)   # short quiet pre/post-roll keeps each flap >= 0.15 s
    seg = env[(on[0] + 8):(on[-1] - 8)]
    cut = (on[0] + 8 + int(np.argmin(seg))) * h
    return [fade(peak_to(fade(src[max(0, a):b], 8), -3.0), 4) for a, b in ((lo, cut), (cut, hi))]


def find_bark(src_dir=SRC):
    import glob
    hits = sorted(glob.glob(os.path.join(src_dir, "*dog*bark*")))
    return hits[0] if hits else None


def bark_slices(src, count=2):
    """The `count` loudest single barks: onset = rise through 15% of the peak after >=100 ms of quiet."""
    env, h = rms_env(src, 10)
    thr = 0.15 * env.max()
    onsets, quiet = [], 99
    for k, v in enumerate(env):
        if v >= thr and quiet >= 10:
            onsets.append(k)
        quiet = 0 if v >= thr else quiet + 1
    peaks = [env[o:o + 15].max() for o in onsets]
    pick = sorted(sorted(range(len(onsets)), key=lambda q: -peaks[q])[:count])
    out = []
    for q in pick:
        a = max(0, onsets[q] * h - int(0.008 * SR))
        b = a + int(0.3 * SR)
        if q + 1 < len(onsets):
            b = min(b, onsets[q + 1] * h - int(0.02 * SR))
        x = src[a:b]
        n = int(0.06 * SR)
        x = fade(x, 3)
        x[len(x) - n:] *= np.linspace(1, 0, n)
        out.append(peak_to(x, -3.0))
    return out


def f0_median(x, fmin=60, fmax=3000):
    """Median autocorrelation fundamental over the loud frames (first peak within 10% of the best)."""
    n, hop = 4096, 2048
    lo, hi = int(SR / fmax), int(SR / fmin)
    gate = 0.3 * max(np.sqrt(np.mean(x[k:k + n] ** 2)) for k in range(0, len(x) - n, hop))
    vals = []
    for k in range(0, len(x) - n, hop):
        if np.sqrt(np.mean(x[k:k + n] ** 2)) < gate:
            continue
        ac = np.fft.irfft(np.abs(np.fft.rfft(x[k:k + n] * np.hanning(n), 2 * n)) ** 2)[:hi + 1]
        seg = ac[lo:hi]
        good = np.where((seg[1:-1] > seg[:-2]) & (seg[1:-1] >= seg[2:]) & (seg[1:-1] >= 0.9 * seg.max()))[0]
        if len(good):
            vals.append(SR / (lo + 1 + good[0]))
    return float(np.median(vals))


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
def git_show(path):
    return subprocess.run(["git", "show", "main:" + path], cwd=ROOT, stdout=subprocess.PIPE, check=True).stdout


def encode(path, x):
    """Write the ogg and return what the game plays (decoded), backing off if the codec overshoots."""
    write_ogg(path, x)
    y = load(path)
    while np.max(np.abs(y)) > 10 ** (-1.5 / 20):
        x = x * 0.9
        write_ogg(path, x)
        y = load(path)
    return y


def peak_db(x):
    return 20 * math.log10(np.max(np.abs(x)))


def main():
    old_dive = load(data=git_show("assets/audio/dive.wav"))
    screech_long = load(os.path.join(AUDIO, "screech_long.ogg"))
    screech_short = load(os.path.join(AUDIO, "screech_short.ogg"))
    gang_call = load(os.path.join(AUDIO, "gang_call.ogg"))
    ll, ls, lg = lufs(screech_long), lufs(screech_short), lufs(gang_call)
    old_bb = load(data=git_show("assets/audio/bb_screech_long.ogg"))
    old_voice_names = ["hey", "oi", "whoa", "aah", "huh", "aww", "hah", "wah"]
    old_voices = {n: load(data=git_show("assets/audio/voice_%s.ogg" % n)) for n in old_voice_names}

    wavs = {"dive": swoosh(1, 0.52, 450, 3400, 800, 1.1, 0.62), "snatch": snatch()}
    for k, x in wavs.items():
        write_wav(os.path.join(AUDIO, k + ".wav"), x)

    oggs = {
        "bb_screech_long": bellow(screech_long, 4.5, 2.2, 15, -2, 0.25, 150, 21, ll),
        "bb_screech_short": bellow(screech_short, 4.5, 2.2, 6, -5, 0.25, 150, 22, ls),
        "bb_dive": swoosh(2, 0.68, 220, 1500, 350, 0.9, 0.58, rumble=0.9),
        "bb_stun": bb_stun(),
        "bb_hit": bb_hit(),
        "bb_shakedown": bellow(screech_long, 3.2, 3.0, 9, -3, 0.35, 150, 23, lg),
        "bb_slam": bb_slam(),
        "bb_stomp": bb_stomp(),
    }
    new_voices = voice_cues()
    oggs.update(new_voices)
    oggs["dog_bark"] = dog_bark()
    oggs["whistle"] = whistle()

    hits = [load(os.path.join(AUDIO, "gull_hit_%d.ogg" % i)) for i in (1, 2, 3)]
    thwack_src = load(os.path.join(SRC, "freesound_community-thwack-wobble-96509.mp3"))
    oggs["swat_thwack"] = swat_thwack(thwack_src, float(np.mean([rms_db(h) for h in hits])))
    for i, f in enumerate(wing_flaps(load(os.path.join(SRC, "freesound_community-wing-flap-1-6434.mp3")))):
        oggs["wing_flap_%d" % (i + 1)] = f

    for i in (1, 2):   # a stale slice from an earlier run must not survive a fallback run
        for ext in (".ogg", ".ogg.import"):
            stale = os.path.join(AUDIO, "dog_bark_%d%s" % (i, ext))
            if os.path.exists(stale):
                os.remove(stale)
    bark_file = find_bark()
    if bark_file:
        for i, b in enumerate(bark_slices(load(bark_file))):
            oggs["dog_bark_%d" % (i + 1)] = b
        print("dog bark: REAL path, sliced from %s" % os.path.basename(bark_file))
    else:
        print("NOTICE: no *dog*bark* file in %s; keeping the generated dog_bark.ogg. Put the Pixabay 'Small Dog Barking' mp3 there and re-run." % SRC)

    shipped = {k: encode(os.path.join(AUDIO, k + ".ogg"), x) for k, x in oggs.items()}

    # ---- audition 2: old voices, new voices per line (man, woman, kid), screech chain, thwack/flaps/barks
    gap = np.zeros(SR // 2)
    parts = []
    for n in old_voice_names:
        parts += [old_voices[n], gap]
    for line in LINES:
        for reg in REGISTERS:
            k = "voice_%s_%s" % (line, reg)
            if k in shipped:
                parts += [shipped[k], gap]
    parts += [screech_long, gap, old_bb, gap, shipped["bb_screech_long"], gap, shipped["swat_thwack"], gap]
    for k in sorted(shipped):
        if k.startswith(("wing_flap_", "dog_bark_")):
            parts += [shipped[k], gap]
    if not bark_file:
        parts += [shipped["dog_bark"], gap]
    os.makedirs(os.path.dirname(AUDITION), exist_ok=True)
    write_wav(AUDITION, np.concatenate(parts))

    print("--- measurements (shipped files, decoded; LUFS zero-padded to 400 ms; rms over the cue itself)")
    dive = load(os.path.join(AUDIO, "dive.wav"))
    snatch_x = load(os.path.join(AUDIO, "snatch.wav"))
    stats("old dive", old_dive)
    stats("dive", dive)
    stats("snatch", snatch_x)
    for i, h in enumerate(hits):
        stats("gull_hit_%d" % (i + 1), h)
    for k in ["bb_screech_long", "bb_screech_short", "bb_shakedown", "swat_thwack", "dog_bark"] + sorted(k for k in shipped if k.startswith(("wing_flap_", "dog_bark_"))):
        stats(k, shipped[k])
    stats("screech_long", screech_long)
    stats("old bb_screech_long", old_bb)
    print("--- fundamentals (autocorrelation, loud-frame median)")
    print("screech_long %.1f Hz | old bb_screech_long %.1f Hz | new bb_screech_long %.1f Hz" % (f0_median(screech_long), f0_median(old_bb), f0_median(shipped["bb_screech_long"])))
    print("screech_short %.1f Hz | new bb_screech_short %.1f Hz | gang_call %.1f Hz | bb_shakedown %.1f Hz" % (
        f0_median(screech_short), f0_median(shipped["bb_screech_short"]), f0_median(gang_call), f0_median(shipped["bb_shakedown"])))
    print("--- voices (%d cues)" % len(new_voices))
    for reg in REGISTERS:
        ks = [k for k in new_voices if k.endswith("_" + reg)]
        lf = [lufs(np.pad(shipped[k], (0, max(0, int(0.4 * SR) - len(shipped[k]))))) for k in ks]
        d = [len(shipped[k]) / SR for k in ks]
        print("%-6s n=%2d dur %.2f-%.2f s  peak %.1f..%.1f dBFS  rms %.1f..%.1f dBFS  LUFS %.1f..%.1f" % (
            reg, len(ks), min(d), max(d), min(peak_db(shipped[k]) for k in ks), max(peak_db(shipped[k]) for k in ks),
            min(rms_db(shipped[k]) for k in ks), max(rms_db(shipped[k]) for k in ks), min(lf), max(lf)))
    worst = max(new_voices, key=lambda k: rms_db(shipped[k]))
    print("loudest voice %s rms %.1f dBFS; at volume_db -7 -> %.1f. dive rms %.1f, snatch rms %.1f" % (
        worst, rms_db(shipped[worst]), rms_db(shipped[worst]) - 7, rms_db(dive), rms_db(snatch_x)))
    print("longest voice: %.2f s" % max(len(shipped[k]) / SR for k in new_voices))


if __name__ == "__main__":
    sys.exit(main())
