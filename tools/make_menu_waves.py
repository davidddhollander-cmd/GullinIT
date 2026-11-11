"""Task 082: cut the seamless menu waves loop from the Pixabay ocean/gull recording.

    python tools/make_menu_waves.py

Writes assets/audio/menu_waves.ogg (mono, ~52 s, about -20 LUFS, peak <= -3 dBFS). The tail is
equal-power crossfaded into the head so the loop has no seam. The start is the stretch whose gull
calls (1.5-5 kHz bursts) are the least prominent, so no call lands on the seam.
"""
import os

import numpy as np

import make_sfx as m

SRC = os.path.join(os.environ.get("USERPROFILE", ""), "Desktop", "GAssets", "SoundsFX",
                   "freesound_community-gentle-ocean-waves-birdsong-and-gull-7109.mp3")
OUT = os.path.join(m.AUDIO, "menu_waves.ogg")
LOOP, XFADE, TARGET_LUFS, PEAK_DB = 52.0, 3.0, -20.0, -3.0


def band_burst(x):
    """Largest 0.2 s RMS in the gull band relative to its median: high means a distinct call."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / m.SR)
    spec[(f < 1500) | (f > 5000)] = 0
    b = np.fft.irfft(spec, len(x))
    n = int(0.2 * m.SR)
    r = np.sqrt(np.mean(b[:len(b) // n * n].reshape(-1, n) ** 2, axis=1)) + 1e-9
    return r.max() / np.median(r)


def main():
    x = m.load(SRC)
    L, X = int(LOOP * m.SR), int(XFADE * m.SR)
    starts = range(0, len(x) - L - X, m.SR)
    start = min(starts, key=lambda s: band_burst(x[s:s + L + X]))
    seg = x[start:start + L + X]
    t = np.linspace(0, np.pi / 2, X)
    loop = seg[:L].copy()
    loop[:X] = seg[:X] * np.sin(t) + seg[L:L + X] * np.cos(t)
    loop -= loop.mean()
    # David's lab note: "less sharp". Gentle high shelf, 0 dB at 3 kHz easing to -6 dB from 5 kHz up.
    # The FFT filter is circular, so the crossfaded loop still closes on itself.
    f = np.fft.rfftfreq(len(loop), 1 / m.SR)
    gain = 10 ** (-6 * np.clip((f - 3000) / 2000, 0, 1) / 20)
    loop = np.fft.irfft(np.fft.rfft(loop) * gain, len(loop))
    loop = m.peak_to(loop, -10)
    loop *= 10 ** ((TARGET_LUFS - m.lufs(loop)) / 20)
    peak = 20 * np.log10(np.max(np.abs(loop)))
    if peak > PEAK_DB:
        loop *= 10 ** ((PEAK_DB - peak) / 20)
    m.write_ogg(OUT, loop)
    y = m.load(OUT)
    h = int(0.5 * m.SR)
    rms = lambda a: 20 * np.log10(np.sqrt(np.mean(a ** 2)))
    print("start %.0f s, %.1f s, peak %.2f dBFS, %.1f LUFS" % (start / m.SR, len(y) / m.SR, 20 * np.log10(np.max(np.abs(y))), m.lufs(y)))
    print("seam RMS last 0.5 s %.2f dB, first 0.5 s %.2f dB, diff %.2f dB" % (rms(y[-h:]), rms(y[:h]), rms(y[-h:]) - rms(y[:h])))
    print("jump across the seam: %.4f (loop rms %.4f)" % (abs(y[0] - y[-1]), np.sqrt(np.mean(y ** 2))))


if __name__ == "__main__":
    main()
