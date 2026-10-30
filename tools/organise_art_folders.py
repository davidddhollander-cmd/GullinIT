"""One-off: sorts assets/ into wired (assets/sprites etc., untouched), assets/lab (Art Lab candidates under review)
and assets/archive (neither; Godot-ignored, not exported). Run from the repo root: python tools/organise_art_folders.py [--dry]
Moves tracked files with git mv (sidecar .import/.uid go along), rewrites path mentions in data, tests, tools, docs
and tasks/inbox, and writes assets/archive/MOVED.md. Rules and the audit behind them: assets/README.md."""
import json, os, re, subprocess, sys, collections
BS = chr(92)
DRY = "--dry" in sys.argv
audit = json.load(open(sys.argv[sys.argv.index("--audit") + 1]))
moves = {}  # old repo path -> (new repo path, reason)

def add(old, new, why):
    moves[old] = (new, why)

def tracked(path):
    return subprocess.run(["git", "ls-files", "--error-unmatch", path], capture_output=True).returncode == 0

def walk(top):
    for d, ds, fs in os.walk(top):
        for f in fs:
            if not f.endswith((".import", ".uid")):
                yield os.path.join(d, f).replace(BS, "/")

# --- lab: candidates the Art Lab shows; whole families stay together
for d in ("assets/previews/food-icons-v1", "assets/previews/beach-props-v1", "assets/sprites/pier-restaurant-props-v1"):
    for f in walk(d):
        add(f, "assets/lab/" + d.split("/", 2)[2] + f[len(d):], "Art Lab candidate family")
for f in audit["sprites|lab"] + audit["previews|lab"]:
    if f not in moves:
        add(f, "assets/lab/" + f.split("/", 2)[2], "only the Art Lab references it")
for f in walk("assets/previews"):
    if re.search(r"pier-wire-fence-v2-repeat-\dx\.png$", f) and f not in moves:
        add(f, "assets/lab/" + os.path.basename(f), "Art Lab candidate preview")

for f in walk("assets/sprites"):
    if f.count("/") == 2 and re.search(r"-(touchup|candidate)-", f) and f not in moves:
        add(f, "assets/lab/" + os.path.basename(f), "Art Lab candidate family")

# --- archive: no runtime reference
KEEP_SPRITE = re.compile(r"^assets/sprites/(retro-|[^/]+/)")  # retro-* are looked up by name in code; subfolders are loaded by directory
for key in ("sprites|none", "sprites|tooling-only"):
    for f in audit[key]:
        if f not in moves and not KEEP_SPRITE.match(f) and not f.endswith(".json"):
            add(f, "assets/archive/" + f[len("assets/"):], "no runtime reference (older or superseded sprite)")
for key in ("previews|none", "previews|tooling-only"):
    for f in audit[key]:
        if f not in moves:
            add(f, "assets/archive/" + f[len("assets/"):], "review or comparison picture no test or code needs")
for f in walk("assets/pilots"):
    add(f, "assets/archive/" + f[len("assets/"):], "early pilot experiment, superseded by production art")
for f in ("assets/reference/fonts/beach-arcade-font-sprite-sheet.png", "assets/reference/fonts/retro-brush-script-font-sheet.png"):
    if os.path.exists(f):
        add(f, "assets/reference/fonts/" + os.path.basename(f), "font source sheet, not loaded by the game")

# only tracked files move; untracked work belongs to whoever is writing it
moves = {o: v for o, v in moves.items() if tracked(o)}
print(collections.Counter(v[0].split("/")[1] for v in moves.values()), len(moves), "files")
if DRY:
    [print(o) for o in sorted(moves) if o.startswith("assets/sprites/")]
if DRY:
    sys.exit()

for old, (new, why) in moves.items():
    os.makedirs(os.path.dirname(new), exist_ok=True)
    subprocess.run(["git", "mv", old, new], check=True)
    for ext in (".import", ".uid"):
        if os.path.exists(old + ext):
            if new.startswith("assets/archive/") or new.startswith("assets/reference/"):
                subprocess.run(["git", "rm", "-q", "-f", old + ext], check=True)  # Godot-ignored folders are never imported
            else:
                subprocess.run(["git", "mv", old + ext, new + ext], check=True)

# --- rewrite mentions, longest path first
pairs = sorted(((o, v[0]) for o, v in moves.items()), key=lambda p: -len(p[0]))
dirs = collections.OrderedDict()
for o, n in pairs:  # directories that moved whole, for prose that names a folder
    pass
def rewrite(text):
    for o, n in pairs:
        if o in text:
            text = re.sub(re.escape(o) + r"(?![A-Za-z0-9_-])", n, text)
    return text
targets = ["data", "tests", "tools", "docs", "tasks/inbox", "scripts", "scenes"]
changed = 0
for t in targets:
    for f in walk(t) if False else [os.path.join(d, x).replace(BS, "/") for d, _, xs in os.walk(t) for x in xs]:
        if not f.endswith((".gd", ".json", ".py", ".md", ".ps1", ".sh", ".tscn", ".csv", ".txt", ".cfg")):
            continue
        s = open(f, encoding="utf-8", errors="surrogateescape", newline="").read()
        r = rewrite(s)
        if r != s:
            open(f, "w", encoding="utf-8", errors="surrogateescape", newline="").write(r)
            changed += 1
print("rewrote paths in", changed, "files")
# .import files that moved into imported folders point at their old source
for old, (new, why) in moves.items():
    imp = new + ".import"
    if os.path.exists(imp):
        s = open(imp, encoding="utf-8", newline="").read()
        open(imp, "w", encoding="utf-8", newline="").write(s.replace("res://" + old, "res://" + new))

with open("assets/archive/MOVED.md", "w", encoding="utf-8") as out:
    out.write("# Files moved by tools/organise_art_folders.py\n\nOld path, new path, why. `git log --follow` also tracks each file.\n\n| Old | New | Why |\n|---|---|---|\n")
    for old, (new, why) in sorted(moves.items()):
        out.write(f"| `{old}` | `{new}` | {why} |\n")
