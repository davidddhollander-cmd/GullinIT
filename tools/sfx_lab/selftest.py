"""Selftest for sfx_lab.py: python tools/sfx_lab/selftest.py"""
import json, os, struct, sys, tempfile, threading, urllib.error, urllib.request, wave
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sfx_lab


def wav(path, n=800):
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(8000)
        w.writeframes(struct.pack("<%dh" % n, *([100] * n)))


tmp = tempfile.mkdtemp()
os.makedirs(os.path.join(tmp, "snd"))
for n in ("voice_hey_man", "voice_hey_kid", "dog_bark_1", "zzz"):
    wav(os.path.join(tmp, "snd", n + ".wav"))
open(os.path.join(tmp, "secret.txt"), "w").write("nope")
json.dump({"audio_dirs": ["snd"], "approvals_file": "data/a.json",
           "categories": [{"name": "Man", "match": "_man$"}, {"name": "Kid", "match": "_kid$"},
                          {"name": "Dog", "match": "^dog_"}, {"name": "Other", "match": ".*"}]},
          open(os.path.join(tmp, "sfx_lab.json"), "w"))
srv = sfx_lab.serve(sfx_lab.Lab(tmp, "sfx_lab.json"), 0)
threading.Thread(target=srv.serve_forever, daemon=True).start()
base = "http://127.0.0.1:%d" % srv.server_address[1]


def get(p):
    return urllib.request.urlopen(base + p).read()


def post(d):
    return urllib.request.urlopen(urllib.request.Request(base + "/api/verdict", json.dumps(d).encode()))


def sounds():
    return {s["path"]: s for s in json.loads(get("/api/sounds"))["sounds"]}


cats = {os.path.basename(k)[:-4]: v["category"] for k, v in sounds().items()}
assert cats == {"voice_hey_man": "Man", "voice_hey_kid": "Kid", "dog_bark_1": "Dog", "zzz": "Other"}, cats
p = "snd/voice_hey_man.wav"
post({"path": p, "status": "rejected", "note": "robotic"})
s = sounds()[p]
assert (s["status"], s["note"], s["changed"]) == ("rejected", "robotic", False), s
saved = json.load(open(os.path.join(tmp, "data", "a.json")))  # atomic write leaves valid JSON
assert saved["version"] == 1 and saved["sounds"][p]["sha1"] == s["sha1"]
assert not [f for f in os.listdir(os.path.join(tmp, "data")) if f.endswith(".tmp")]
for bad in ("/audio/../secret.txt", "/audio/..%2fsecret.txt", "/audio/snd/../secret.txt", "/audio//etc/passwd"):
    try:
        get(bad)
        raise SystemExit("traversal allowed: " + bad)
    except urllib.error.HTTPError as e:
        assert e.code == 404
try:
    post({"path": "../secret.txt", "status": "approved"})
    raise SystemExit("bad verdict path accepted")
except urllib.error.HTTPError as e:
    assert e.code == 400
assert len(get("/audio/" + p)) > 100
wav(os.path.join(tmp, p), 1200)  # regenerate the file
s = sounds()[p]
assert s["changed"] and s["status"] == "rejected", s
import subprocess  # a second lab on a busy port exits 0 with the "already running" line
r = subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "sfx_lab.py"), "--project", tmp,
                    "--port", str(srv.server_address[1]), "--no-browser"], capture_output=True, text=True, timeout=30)
assert r.returncode == 0 and "may already be running" in r.stdout, (r.returncode, r.stdout, r.stderr)
print("selftest ok")
