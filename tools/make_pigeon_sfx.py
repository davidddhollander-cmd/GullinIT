"""Cut pigeon cues from David's 5ro4 Freesound downloads (CC0) in Desktop/GAssets/SoundsFX.
Writes mono .ogg cues to assets/audio, each peak-normalised to -3 dBFS. Run: python tools/make_pigeon_sfx.py"""
import os, subprocess, tempfile, wave
import numpy as np

SRC = os.path.expanduser("~/Desktop/GAssets/SoundsFX")
COO = os.path.join(SRC, "701282__5ro4__pigeon-walking-and-cooing.wav")
WING = os.path.join(SRC, "611106__5ro4__pigeon-flying-wing-whistle.wav")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SR = 44100
# name: (source, start s, end s, speed); speed > 1 raises pitch and shortens (the startled yelps)
CUTS = {
    "coo_1": (COO, 21.70, 22.40, 1.0),
    "coo_2": (COO, 23.54, 24.08, 1.0),
    "coo_3": (COO, 17.77, 18.33, 1.0),
    "yelp_1": (COO, 17.77, 18.20, 1.7),
    "yelp_2": (COO, 23.54, 23.95, 1.55),
    "wing_a": (WING, 0.05, 0.95, 1.0),
    "wing_b": (WING, 0.60, 1.50, 1.0),
}
# cue: [(cut, start offset s, gain dB), ...] mixed together
CUES = {
    "pigeon_coo_1": [("coo_1", 0.0, 0.0)],
    "pigeon_coo_2": [("coo_2", 0.0, 0.0)],
    "pigeon_coo_3": [("coo_3", 0.0, 0.0)],
    "pigeon_scared_1": [("yelp_1", 0.0, 0.0), ("wing_b", 0.04, -3.0)],  # bumped: yelp over a burst of wings
    "pigeon_scared_2": [("yelp_2", 0.0, 0.0), ("wing_a", 0.04, -3.0)],
    "pigeon_takeoff": [("wing_a", 0.0, 0.0), ("yelp_2", 0.06, -5.0), ("yelp_1", 0.30, -8.0)],  # flock flies off, startled coos in it
}

def cut(src, start, end, speed):
    length = (end - start) / speed
    chain = f"atrim={start}:{end},asetpts=PTS-STARTPTS"
    if speed != 1.0:
        chain += f",asetrate={SR}*{speed},aresample={SR}"
    chain += f",afade=t=in:d=0.015,afade=t=out:st={max(0.0, length - 0.09):.3f}:d=0.09"
    tmp = os.path.join(tempfile.gettempdir(), "pigeon_cut.wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "1", "-ar", str(SR), "-af", chain, tmp], check=True)
    with wave.open(tmp) as w:
        return np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float) / 32768.0

cuts = {name: cut(*spec) for name, spec in CUTS.items()}
for cue, layers in CUES.items():
    length = max(int(off * SR) + len(cuts[name]) for name, off, _ in layers)
    mix = np.zeros(length)
    for name, off, db in layers:
        start = int(off * SR)
        mix[start:start + len(cuts[name])] += cuts[name] * 10 ** (db / 20)
    mix *= 10 ** (-3 / 20) / max(np.abs(mix).max(), 1e-9)
    tmp = os.path.join(tempfile.gettempdir(), cue + ".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", os.path.join(OUT, cue + ".ogg")], check=True)
    print(f"{cue}: {length / SR:.2f}s")
