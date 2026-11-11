#!/usr/bin/env python3
"""SFX Lab: browse a project's sounds, approve/reject them. Stdlib only. See README.md."""
import argparse, hashlib, json, os, re, sys, tempfile, threading, webbrowser
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
STATUSES = ("approved", "rejected", "unreviewed")
LOCK = threading.Lock()


class Lab:
    def __init__(self, project, config):
        self.root = os.path.realpath(project)
        with open(os.path.join(self.root, config), encoding="utf-8") as f:
            self.cfg = json.load(f)
        self.exts = tuple(e.lower() for e in self.cfg.get("extensions", [".ogg", ".wav", ".mp3"]))
        self.cats = [(c["name"], re.compile(c["match"])) for c in self.cfg.get("categories", [])] or [("All", re.compile(".*"))]
        self.approvals_path = os.path.join(self.root, self.cfg.get("approvals_file", "sfx_approvals.json"))

    def approvals(self):
        try:
            with open(self.approvals_path, encoding="utf-8") as f:
                return json.load(f).get("sounds", {})
        except (OSError, ValueError):
            return {}

    def files(self):
        out = []
        for d in self.cfg.get("audio_dirs", ["."]):
            base = os.path.join(self.root, d)
            walk = os.walk(base) if self.cfg.get("recursive") else [(base, [], os.listdir(base) if os.path.isdir(base) else [])]
            for dirpath, _, names in walk:
                for n in sorted(names):
                    p = os.path.join(dirpath, n)
                    if n.lower().endswith(self.exts) and os.path.isfile(p):
                        out.append(os.path.relpath(p, self.root).replace("\\", "/"))
        return out

    def sha1(self, rel):
        with open(os.path.join(self.root, rel), "rb") as f:
            return hashlib.sha1(f.read()).hexdigest()

    def category(self, rel):
        stem = os.path.splitext(os.path.basename(rel))[0]
        return next((n for n, rx in self.cats if rx.search(stem)), "Other")

    def listing(self):
        known = self.approvals()
        sounds = []
        for rel in self.files():
            sha, v = self.sha1(rel), known.get(rel, {})
            sounds.append({"path": rel, "category": self.category(rel), "size": os.path.getsize(os.path.join(self.root, rel)),
                           "sha1": sha, "status": v.get("status", "unreviewed"), "note": v.get("note", ""),
                           "changed": bool(v) and v.get("sha1") != sha})
        return {"config": self.cfg, "sounds": sounds}

    def verdict(self, path, status, note):
        if status not in STATUSES or path not in self.files():
            raise ValueError("bad verdict")
        with LOCK:
            sounds = self.approvals()
            if status == "unreviewed" and not note:
                sounds.pop(path, None)
            else:
                sounds[path] = {"status": status, "note": note, "sha1": self.sha1(path),
                                "reviewed": datetime.now().isoformat(timespec="seconds")}
            os.makedirs(os.path.dirname(self.approvals_path), exist_ok=True)
            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(self.approvals_path), suffix=".tmp")
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"version": 1, "sounds": dict(sorted(sounds.items()))}, f, indent=1)
            os.replace(tmp, self.approvals_path)


def make_handler(lab):
    class H(BaseHTTPRequestHandler):
        def send(self, code, body, ctype="application/json"):
            body = body if isinstance(body, bytes) else json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            path = unquote(urlparse(self.path).path)
            if path == "/":
                with open(os.path.join(HERE, "sfx_lab.html"), "rb") as f:
                    return self.send(200, f.read(), "text/html; charset=utf-8")
            if path == "/api/sounds":
                return self.send(200, lab.listing())
            if path.startswith("/audio/"):
                rel = path[len("/audio/"):]
                if rel in lab.files():  # allow-list: only configured audio files, so no traversal
                    with open(os.path.join(lab.root, rel), "rb") as f:
                        return self.send(200, f.read(), "audio/ogg" if rel.endswith(".ogg") else "application/octet-stream")
            self.send(404, {"error": "not found"})

        def do_POST(self):
            if urlparse(self.path).path != "/api/verdict":
                return self.send(404, {"error": "not found"})
            try:
                d = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
                lab.verdict(d["path"], d["status"], str(d.get("note", "")))
            except (ValueError, KeyError, OSError) as e:
                return self.send(400, {"error": str(e)})
            self.send(200, {"ok": True})

        def log_message(self, *a):
            pass
    return H


class Server(ThreadingHTTPServer):
    allow_reuse_address = False  # on Windows SO_REUSEADDR lets a second lab bind the same port


def serve(lab, port=8777):
    return Server(("127.0.0.1", port), make_handler(lab))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=".")
    ap.add_argument("--config", default="sfx_lab.json")
    ap.add_argument("--port", type=int, default=8777)
    ap.add_argument("--no-browser", action="store_true")
    a = ap.parse_args()
    try:
        srv = serve(Lab(a.project, a.config), a.port)
    except OSError:  # port taken: most likely the lab is already open
        url = "http://127.0.0.1:%d/" % a.port
        print("Port %d is busy; the SFX Lab may already be running at %s" % (a.port, url))
        if not a.no_browser:
            webbrowser.open(url)
        sys.exit(0)
    url = "http://127.0.0.1:%d/" % srv.server_address[1]
    print("SFX Lab at", url, "(Ctrl+C to stop)")
    if not a.no_browser:
        webbrowser.open(url)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
