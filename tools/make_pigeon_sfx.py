"""Cut pigeon cues from David's 5ro4 Freesound downloads (CC0) in Desktop/GAssets/SoundsFX.
Writes mono .ogg cues to assets/audio, each peak-normalised to -3 dBFS. Run: python tools/make_pigeon_sfx.py"""
import os, subprocess, sys, tempfile, wave
import numpy as np

SRC = os.path.expanduser("~/Desktop/GAssets/SoundsFX")
COO = os.path.join(SRC, "701282__5ro4__pigeon-walking-and-cooing.wav")
WING = os.path.join(SRC, "611106__5ro4__pigeon-flying-wing-whistle.wav")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
# name: (source, start s, end s, speed); speed > 1 raises pitch and shortens (the scared yelps)
CUES = {
    "pigeon_coo_1": (COO, 21.70, 22.40, 1.0),
    "pigeon_coo_2": (COO, 23.54, 24.08, 1.0),
    "pigeon_coo_3": (COO, 17.77, 18.33, 1.0),
    "pigeon_scared_1": (COO, 17.77, 18.20, 1.7),
    "pigeon_scared_2": (COO, 23.54, 23.95, 1.55),
    "pigeon_takeoff": (WING, 0.0, 0.9, 1.0),
}

def peak_db(path):
    with wave.open(path) as w:
        d = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
    return 20 * np.log10(max(np.abs(d).max(), 1.0) / 32768.0)

for name, (src, start, end, speed) in CUES.items():
    length = (end - start) / speed
    chain = f"atrim={start}:{end},asetpts=PTS-STARTPTS"
    if speed != 1.0:
        chain += f",asetrate=44100*{speed},aresample=44100"
    chain += f",afade=t=in:d=0.015,afade=t=out:st={max(0.0, length - 0.09):.3f}:d=0.09"
    tmp = os.path.join(tempfile.gettempdir(), name + ".wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "1", "-af", chain, tmp], check=True)
    gain = -3.0 - peak_db(tmp)
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-af", f"volume={gain:.2f}dB", "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
    print(f"{name}: {length:.2f}s gain {gain:+.1f} dB")
