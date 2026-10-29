"""Synthesize the extra soundtrack loops with numpy and encode them to OGG.

    python tools/compose_music.py [lounge|synth ...]

Everything renders into a buffer exactly one loop long; notes, reverb and delay
wrap around (circular FFT), so the files loop seamlessly.
"""
import os
import shutil
import subprocess
import sys
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "music")
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    pitch = NOTE[name[0]] + name[1:-1].count("#") - name[1:-1].count("b")
    return 12 * (int(name[-1]) + 1) + pitch


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def seq(text, start=0.0):
    """'E5:1 r:.5 D5:.5' -> [(beat, beats, midi)]"""
    out, beat = [], start
    for tok in text.replace("|", " ").split():
        name, dur = tok.split(":")
        if name != "r":
            out.append((beat, float(dur), midi(name)))
        beat += float(dur)
    return out


def env(n, a=0.005, d=0.1, s=0.7, r=0.05, gate=None):
    """ADSR over n samples; gate = seconds held before release."""
    t = np.arange(n) / SR
    gate = n / SR - r if gate is None else gate
    e = np.where(t < a, t / max(a, 1e-6), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-6)))
    rel = np.clip((t - gate) / max(r, 1e-6), 0, 1)
    return e * (1 - rel)


def additive(f, n, amps, phase=None):
    """Sum of harmonics k*f with amplitude amps(k); skips partials past 16 kHz."""
    phase = 2 * np.pi * f * np.arange(n) / SR if phase is None else phase
    out = np.zeros(n)
    for k in range(1, int(16000 / f) + 1):
        a = amps(k)
        if a:
            out += a * np.sin(k * phase)
    return out


def fft_filter(x, lo=0.0, hi=SR / 2):
    """Smooth band-pass by masking the spectrum (circular)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    mask = 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec * mask, len(x))


class Track:
    def __init__(self, bpm, bars, seed):
        self.spb = 60 / bpm
        self.n = int(round(bars * 4 * self.spb * SR))
        self.rng = np.random.default_rng(seed)
        self.buses = {}

    def at(self, beat):
        return int(round(beat * self.spb * SR))

    def add(self, bus, sig, beat, pan=0.0, gain=1.0, jitter=0.004):
        """Mix sig at beat onto a stereo bus, wrapping past the loop end."""
        buf = self.buses.setdefault(bus, np.zeros((2, self.n)))
        start = self.at(beat) + int(self.rng.normal(0, jitter) * SR)
        idx = (start + np.arange(len(sig))) % self.n
        buf[0, idx] += sig * gain * np.sqrt((1 - pan) / 2)
        buf[1, idx] += sig * gain * np.sqrt((1 + pan) / 2)

    def reverb(self, x, seconds, wet, tone=6000, gate=None):
        out = np.empty_like(x)
        n = int(seconds * 1.5 * SR)
        t = np.arange(n) / SR
        for ch in range(2):
            ir = self.rng.normal(0, 1, n) * np.exp(-t * 6.9 / seconds)
            if gate:
                ir[int(gate * SR):] = 0
            ir = fft_filter(np.pad(ir, (0, 1024)), 200, tone)[:n]
            ir /= np.sqrt(np.sum(ir ** 2))
            wetsig = np.fft.irfft(np.fft.rfft(x[ch]) * np.fft.rfft(ir, self.n), self.n)
            out[ch] = x[ch] + wet * wetsig
        return out

    def delay(self, x, beats, fb, wet, pingpong=True):
        d = self.at(beats)
        out = x.copy()
        for k in range(1, 7):
            src = x[::-1] if pingpong and k % 2 else x
            out += wet * fb ** (k - 1) * np.roll(src, d * k, axis=1)
        return out

    def master(self, path, fx, target_rms_db):
        mix = np.zeros((2, self.n))
        for bus, buf in self.buses.items():
            mix += fx.get(bus, lambda b: b)(buf)
        mix = fft_filter(mix[0], 30), fft_filter(mix[1], 30)
        mix = np.array(mix)
        mix *= 10 ** (target_rms_db / 20) / np.sqrt(np.mean(mix ** 2))
        mix = np.tanh(mix * 1.1) / np.tanh(1.1) * 0.9  # gentle soft clip
        pcm = (np.clip(mix.T, -1, 1) * 32767).astype("<i2")
        wav = path[:-4] + ".wav"
        with wave.open(wav, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        ffmpeg = shutil.which("ffmpeg") or "ffmpeg"
        subprocess.run([ffmpeg, "-y", "-v", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", path], check=True)
        os.remove(wav)
        print(f"wrote {path} ({self.n / SR:.2f}s)")


# --- instruments -----------------------------------------------------------

def kick(depth=1.0):
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 46 + 90 * depth * np.exp(-t / 0.035)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.22)
    click = np.random.default_rng(1).normal(0, 1, n) * np.exp(-t / 0.003) * 0.3
    return body + click


def snare(rng, tone=185, length=0.14):
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    noise = fft_filter(rng.normal(0, 1, n), 1500, 9000) * np.exp(-t / length)
    return 0.8 * noise + 0.6 * np.sin(2 * np.pi * tone * t) * np.exp(-t / 0.06)


def clap(rng):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    bursts = sum(np.exp(-np.clip(t - o, 0, None) / 0.006) * (t >= o) for o in (0, 0.011, 0.022))
    tail = np.exp(-np.clip(t - 0.03, 0, None) / 0.09) * (t >= 0.03)
    return fft_filter(rng.normal(0, 1, n), 900, 5000) * (bursts + tail)


def hat(rng, length=0.035):
    n = int(max(length * 6, 0.05) * SR)
    t = np.arange(n) / SR
    return fft_filter(rng.normal(0, 1, n), 7000, 16000) * np.exp(-t / length)


def rim(rng):
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 1700 * t) * 0.6 + fft_filter(rng.normal(0, 1, n), 2000, 8000)) * np.exp(-t / 0.012)


def shaker(rng):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    return fft_filter(rng.normal(0, 1, n), 5000, 12000) * np.sin(np.pi * t / t[-1]) ** 2


def saw(f, seconds, bright=1.0, detune=0.0, **adsr):
    n = int((seconds + adsr.get("r", 0.05)) * SR)
    f *= 2 ** (detune / 1200)
    sig = additive(f, n, lambda k: 1 / k * np.exp(-k * f / (2500 * bright)))
    return sig * env(n, gate=seconds, **adsr)


def square(f, seconds, bright=1.0, **adsr):
    n = int((seconds + adsr.get("r", 0.05)) * SR)
    sig = additive(f, n, lambda k: (k % 2) / k * np.exp(-k * f / (5000 * bright)))
    return sig * env(n, gate=seconds, **adsr)


def lead(f, seconds):
    """Bright saw/pulse lead with delayed vibrato."""
    n = int((seconds + 0.12) * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.005 * np.sin(2 * np.pi * 5.6 * t) * np.clip((t - 0.18) / 0.2, 0, 1)
    phase = 2 * np.pi * np.cumsum(f * vib) / SR
    sig = additive(f, n, lambda k: (1 / k) * (1.0 if k % 2 else 0.55) * np.exp(-k * f / 4500), phase)
    return sig * env(n, a=0.01, d=0.25, s=0.75, r=0.12, gate=seconds)


def steel_pan(f, seconds):
    n = int((seconds + 0.9) * SR)
    t = np.arange(n) / SR
    sig = (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.9)
           + 0.5 * np.sin(2 * np.pi * 2.005 * f * t) * np.exp(-t / 0.35)
           + 0.22 * np.sin(2 * np.pi * 2.99 * f * t) * np.exp(-t / 0.2)
           + 0.08 * np.sin(2 * np.pi * 4.02 * f * t) * np.exp(-t / 0.08))
    return sig * np.clip(t / 0.004, 0, 1) * np.clip((seconds + 0.9 - t) / 0.3, 0, 1)


def organ(f, seconds):
    n = int((seconds + 0.03) * SR)
    t = np.arange(n) / SR
    sig = additive(f, n, lambda k: {1: 1, 2: 0.7, 3: 0.35, 4: 0.25, 6: 0.1}.get(k, 0))
    return sig * (1 + 0.15 * np.sin(2 * np.pi * 6.5 * t)) * env(n, a=0.004, d=0.05, s=0.6, r=0.03, gate=seconds)


def round_bass(f, seconds):
    n = int((seconds + 0.06) * SR)
    sig = additive(f, n, lambda k: {1: 1, 2: 0.35, 3: 0.12}.get(k, 0))
    return sig * env(n, a=0.008, d=0.25, s=0.75, r=0.06, gate=seconds)


def chord(fn, notes, beat, tr, bus, strum=0.0, pans=None, gain=1.0, **kw):
    for i, m in enumerate(notes):
        pan = pans[i] if pans else 0.0
        tr.add(bus, fn(hz(m), **kw), beat + i * strum, pan, gain / len(notes))


# --- "Low Tide": upbeat steppers reggae, D major, 104 bpm ----------------------

def lounge():
    tr = Track(bpm=104, bars=24, seed=74)
    rng = tr.rng
    prog = [("D", [54, 57, 62], 38), ("G", [55, 59, 62], 43), ("Bm", [54, 59, 62], 47), ("A", [52, 57, 61], 45)]
    bass_a = [(0, .75, 0), (.75, .25, 0), (1, .5, 12), (1.5, .5, 7), (2, .75, 0), (2.75, .25, 0), (3, .5, 7), (3.5, .5, 12)]
    bass_b = [(0, .5, 0), (.5, .5, 7), (1, .5, 12), (1.5, .5, 7), (2, .5, 0), (2.5, .5, 5), (3, .5, 7), (3.5, .5, 12)]
    k, r = kick(0.6), rim(rng)
    for bar in range(24):
        b0 = bar * 4
        _, notes, root = prog[bar % 4]
        # steppers: kick on every beat, rim + light snare on 2 and 4, swung 16th hats
        for beat in range(4):
            tr.add("drums", k, b0 + beat, 0, 0.85 if beat % 2 == 0 else 0.55)
        for beat in (1, 3):
            tr.add("drums", r, b0 + beat, 0.1, 0.3)
            tr.add("drums", snare(rng, 220, 0.07), b0 + beat, 0.05, 0.25)
        for s in range(16):
            swing = 0.04 if s % 2 else 0
            tr.add("drums", hat(rng, 0.1 if s % 8 == 6 else 0.025), b0 + s * .25 + swing, 0.35,
                   (0.15, 0.06, 0.12, 0.08)[s % 4])
        for e in range(8):
            tr.add("perc", shaker(rng), b0 + e * .5 + .25, -0.4, 0.07)
        if bar % 4 == 3:  # rim fill into the next phrase
            for off in (3, 3.25, 3.5, 3.75):
                tr.add("drums", r, b0 + off, -0.2, 0.22)
        # guitar chop on every offbeat, organ bubble on the 16ths around it
        for beat in range(4):
            chord(saw, [m + 12 for m in notes], b0 + beat + .5, tr, "skank", 0.005, [-.5, -.45, -.4], 0.5,
                  seconds=0.07, bright=1.3, a=0.002, d=0.04, s=0.25, r=0.03)
            for off in (.25, .75):
                chord(organ, notes, b0 + beat + off, tr, "organ", 0, [.45, .5, .55], 0.16, seconds=0.08)
        for beat, dur, step in (bass_b if bar % 4 == 3 else bass_a):
            tr.add("bass", round_bass(hz(root + step), dur * tr.spb * 0.85), b0 + beat, 0, 0.7)
    melody_a = seq("A5:.5 F#5:.5 A5:.5 B5:.5 A5:.5 F#5:.5 D5:1 | r:.5 B5:.5 D6:.5 B5:.5 G5:.5 A5:.5 B5:1 | "
                   "F#5:.5 F#5:.5 B5:.5 A5:.5 F#5:.5 E5:.5 D5:.5 E5:.5 | C#5:.5 E5:.5 A5:1 r:.5 E5:.5 C#5:.5 E5:.5 | "
                   "F#5:.5 A5:.5 D6:.5 A5:.5 B5:.5 A5:.5 F#5:1 | G5:.5 B5:.5 D6:.5 E6:.5 D6:.5 B5:.5 G5:1 | "
                   "F#5:.5 A5:.5 B5:.5 D6:.5 B5:.5 A5:.5 F#5:.5 E5:.5 | E5:.75 F#5:.25 E5:.5 C#5:.5 A4:1 r:1")
    melody_b = seq("D6:.75 D6:.25 r:.5 A5:.5 B5:.5 A5:.5 F#5:1 | B5:.75 B5:.25 r:.5 G5:.5 A5:.5 B5:.5 D6:1 | "
                   "F#6:.5 E6:.5 D6:.5 B5:.5 D6:.5 B5:.5 A5:1 | E5:.5 F#5:.5 A5:.5 C#6:.5 E6:2 | "
                   "D6:.75 D6:.25 r:.5 A5:.5 B5:.5 D6:.5 E6:1 | D6:.5 B5:.5 G5:.5 B5:.5 D6:.5 E6:.5 D6:1 | "
                   "B5:.5 A5:.5 F#5:.5 A5:.5 B5:.5 D6:.5 F#5:.5 A5:.5 | E5:.5 C#5:.5 E5:.5 A5:.5 D5:2")
    for start, phrase in ((16, melody_a), (48, melody_b), (80, melody_a)):  # last pass cut at the loop end
        for beat, dur, m in phrase:
            if start + beat < 96:
                tr.add("pan", steel_pan(hz(m), dur * tr.spb), start + beat, 0.15, 0.3)
    tr.master(os.path.join(OUT, "lounge_loop.ogg"), {
        "skank": lambda b: tr.reverb(b, 1.0, 0.22),
        "organ": lambda b: tr.reverb(b, 1.0, 0.18),
        "pan": lambda b: tr.reverb(tr.delay(b, 0.75, 0.32, 0.25), 1.5, 0.25),
        "drums": lambda b: tr.reverb(b, 0.7, 0.1),
    }, target_rms_db=-15.5)


# --- "Neon Boardwalk": uptempo 80s synthpop, A minor, 124 bpm ---------------

def synth():
    tr = Track(bpm=124, bars=32, seed=124)
    rng = tr.rng
    prog = [([57, 60, 64], 45), ([53, 57, 60], 41), ([55, 60, 64], 48), ([55, 59, 62], 43)]
    k = kick(1.0)
    for bar in range(32):
        b0 = bar * 4
        notes, root = prog[bar % 4]
        for beat in range(4):
            tr.add("kick", k, b0 + beat, 0, 1.0, jitter=0.001)
        for beat in (1, 3):
            tr.add("snare", snare(rng, 200, 0.1), b0 + beat, 0, 0.6, jitter=0.001)
            tr.add("snare", clap(rng), b0 + beat, 0.1, 0.45, jitter=0.002)
        for s in range(16):
            open_hat = s % 4 == 2
            tr.add("hats", hat(rng, 0.11 if open_hat else 0.025), b0 + s * .25, 0.3,
                   0.14 if open_hat else (0.11 if s % 2 else 0.07), jitter=0.002)
        if bar % 8 == 7:  # tom-ish snare roll into each 8-bar section
            for s in range(12, 16):
                tr.add("snare", snare(rng, 140 + s * 12, 0.08), b0 + s * .25, -0.2, 0.25 + 0.06 * (s - 12))
        # octave-pumping bass
        for e in range(8):
            m = root + (12 if e % 2 else 0)
            tr.add("bass", saw(hz(m), 0.2 * tr.spb * 2, bright=0.5, a=0.003, d=0.08, s=0.5, r=0.03), b0 + e * .5, 0, 0.5,
                   jitter=0.001)
        # pad: detuned saw stack for the whole bar
        for det, pan in ((-8, -0.6), (0, 0), (8, 0.6)):
            chord(saw, notes, b0, tr, "pad", 0, [pan] * 3, 0.32, seconds=4 * tr.spb, bright=0.6, detune=det,
                  a=0.25, d=1.0, s=0.8, r=0.4)
        # 16th arp over chord tones
        arp = [notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[0] + 24]
        for s in range(16):
            tr.add("arp", square(hz(arp[[0, 1, 2, 3, 2, 1, 2, 3][s % 8]]), 0.18 * tr.spb, bright=0.8,
                                 a=0.002, d=0.06, s=0.25, r=0.04), b0 + s * .25, 0, 0.16 if bar >= 8 else 0.2,
                   jitter=0.0)
    lead_a = seq("E5:1 E5:.5 D5:.5 C5:1 A4:1 | C5:.5 D5:.5 E5:1 F5:1 E5:1 | G5:1.5 E5:.5 C5:1 E5:1 | "
                 "D5:2 r:1 B4:.5 D5:.5 | E5:1 E5:.5 D5:.5 C5:1 A4:.5 C5:.5 | F5:1 E5:.5 F5:.5 A5:1 G5:1 | "
                 "E5:1 G5:1 C6:1 B5:.5 A5:.5 | G5:3 r:1")
    lead_b = seq("A5:.5 G5:.5 E5:1 r:.5 E5:.5 G5:1 | A5:.5 C6:.5 A5:1 G5:1 F5:1 | E5:.5 G5:.5 C6:1.5 B5:.5 G5:1 | "
                 "B5:2 A5:1 G5:1 | A5:.5 G5:.5 E5:1 r:.5 E5:.5 D5:1 | C5:1 D5:1 F5:1 A5:1 | "
                 "G5:1.5 E5:.5 D5:1 C5:1 | B4:1 D5:1 E5:2")
    for start, phrase, octave in ((32, lead_a, 0), (64, lead_b, 0), (96, lead_a, 12)):
        for beat, dur, m in phrase:
            tr.add("lead", lead(hz(m + octave), dur * tr.spb * 0.92), start + beat, -0.1, 0.42 if octave else 0.5)
            if octave:  # doubled an octave down on the final pass
                tr.add("lead", lead(hz(m), dur * tr.spb * 0.92), start + beat, 0.1, 0.3)
    tr.master(os.path.join(OUT, "synth_loop.ogg"), {
        "snare": lambda b: tr.reverb(b, 1.5, 0.55, tone=7000, gate=0.24),  # gated 80s snare
        "pad": lambda b: tr.reverb(b, 2.5, 0.35),
        "arp": lambda b: tr.reverb(tr.delay(b, 0.75, 0.35, 0.3), 1.5, 0.2),
        "lead": lambda b: tr.reverb(tr.delay(b, 0.75, 0.3, 0.25), 2.0, 0.3),
    }, target_rms_db=-15)


if __name__ == "__main__":
    songs = {"lounge": lounge, "synth": synth}
    for name in sys.argv[1:] or songs:
        songs[name]()
