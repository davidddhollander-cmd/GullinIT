#!/usr/bin/env python3
"""Build art_manifest.json for gullinit_audit.py from Gullin' It's data files.
Run from the project root: python build_manifest.py > art_manifest.json
Scales that live in code (not data) are noted inline; update them if the code changes."""
import json
import os
import sys
from collections import Counter

from PIL import Image

S = json.load(open("data/sprites.json"))
F = json.load(open("data/foods.json"))
G = json.load(open("data/gull_art.json"))
V = json.load(open("data/vendor_art.json"))
m = []


def add(id, file, group, scale, fw=None, fh=None, region=None, outline=True, lineup=True, note=""):
    e = dict(id=id, file=file.replace("res://", ""), group=group, scale=scale, frame_w=fw, frame_h=fh,
             region=region, outline=outline, lineup=lineup, note=note)
    m.append({k: v for k, v in e.items() if v is not None and v != ""})


# Gulls: data/gull_art.json visual_scale
for k in ["gull_herring", "gull_kittiwake", "gull_great_black_backed", "rival_gull"]:
    e = G[k]
    add(k, e["file"], "gull", e["visual_scale"], e["frame_w"], e["frame_h"])
    c = e.get("carry")
    if c:
        add(k + "_carry", c["file"], "gull", c["visual_scale"], c["frame_w"], c["frame_h"])
        add(k + "_carry_beak", c["overlay_file"], "gull", c["visual_scale"], c["frame_w"], c["frame_h"], outline=False, lineup=False)
h = G["gull_herring"]
scr = h.get("animations", {}).get("screech", {}).get("file", "assets/sprites/gull-herring-screech-v1.png")
add("gull_screech", scr, "gull", h["visual_scale"], h["frame_w"], h["frame_h"])  # screech uses the species frame size

# People and animals with visual_scale in data/sprites.json
for k in ["kiosk_customer", "shopper_mullet", "shopper_sundress", "old_man"]:
    e = S[k]
    add(k, e["file"], "people", e.get("visual_scale", 1.0), e["frame_w"], e["frame_h"])
for k, e in S.items():
    f = e.get("file", "")
    if any(x in f for x in ["lifeguard", "dog-owner", "off-lead-dog", "market-cleaner", "toddler-diner", "crab-"]):
        grp = "animals" if ("off-lead-dog" in f or "crab" in f) else "people"
        add(k, f, grp, e.get("visual_scale", 1.0), e["frame_w"], e["frame_h"])
# Bench poses are animations inside the shopper entries (128 px frames, scale 0.5)
for f, id in [("shopper-yellow-bench-v1", "bench_yellow"), ("shopper-mullet-bench-v1", "bench_mullet"),
              ("shopper-sundress-bench-v1", "bench_sundress")]:
    add(id, "assets/sprites/" + f + ".png", "people", 0.5, 128, 128)
# Sunbathers and picnic mum: AdultPixelArt.DISPLAY_SCALE = 0.5 in scripts/adult_pixel_art.gd
for g in ["male", "female"]:
    for c in ["red", "blue"]:
        add(f"sunbather_{g}_{c}", f"assets/sprites/retro-sunbather-{g}-{c}-32bit.png", "people", 0.5, 128, 128)
add("mum_picnic", "assets/sprites/retro-mum-32bit.png", "people", 0.5, 128, 128)
add("toddler_polished", "assets/sprites/toddler_polished.png", "unused", 0.075, 362, 362, note="only in data/toddler_art.json, which Config never loads")
add("shopper_walk_mullet_v2", "assets/sprites/shopper-mullet-walk-v2.png", "people", 0.5, 128, 128, lineup=False)
add("shopper_walk_sundress_v2", "assets/sprites/shopper-sundress-walk-v2.png", "people", 0.5, 128, 128, lineup=False)

# Vendors: data/vendor_art.json
for k, e in V.items():
    for fk in ("file", "base_atlas"):
        if fk in e and "reference" not in e[fk]:
            add(f"vendor_{k}_{fk}", e[fk], "vendors", e.get("visual_scale", 0.5), e.get("frame_w", 128),
                e.get("frame_h", 128), lineup=(fk == "file"))
for f in ["vendor-hotdog-full-body-v3", "vendor-ice-cream-full-body-v3", "vendor-fish-chips-full-body-v1",
          "vendor-hotdog-full-body-v2", "vendor-ice-cream-full-body-v2", "vendor-fish-chips-full-body-v1-base"]:
    if not any(x["file"].endswith(f + ".png") for x in m):
        add(f, "assets/sprites/" + f + ".png", "vendors", 0.5, 128, 128, lineup=False)

# Pier diners: old set (400 px frames at 0.11) and B set (128 px at 0.5)
for base in ["pier_diner", "pier_diner_b"]:
    for suffix in ["", "_motion", "_reactions"]:
        e = S.get(base + suffix)
        if e:
            add(base + suffix, e["file"], "diner", e.get("visual_scale", 1.0), e["frame_w"], e["frame_h"], lineup=(suffix == ""))

# Food: drawn to data/foods.json size (scale = size / texture), scale given for height
for fid, fd in F.items():
    sp = S.get(fd.get("sprite", ""))
    if not sp or fid == "crab":
        continue
    f = sp["file"].replace("res://", "")
    if not f.endswith(".png"):
        continue  # e.g. cookie.svg
    if "regions" in sp:
        r = sp["regions"][0]["region"]
        add("food_" + fid, f, "food", round(fd["size"][1] / r[3], 4), region=r, note="non-uniform scale")
    else:
        h = Image.open(f).size[1]
        add("food_" + fid, f, "food", round(fd["size"][1] / h, 4))
for f in ["chips", "cone", "fish_chips", "hot_dog", "ice_cream", "sandwich", "seafood"]:
    if not any(x["file"].endswith("/" + f + ".png") for x in m):
        add("legacy_" + f, "assets/sprites/" + f + ".png", "unused", 1.0, note="8x8 placeholder in sprites.json; no food or target uses it")

# Props
for k, e in S.items():
    f = e.get("file", "")
    is_prop = ("retro-" in f and any(x in f for x in ["beach", "bin", "kiosk", "hotdog-stand", "fish-chips-stand",
                                                         "tower", "umbrella", "picnic", "wheelie"])) or f.endswith("pier.png")
    if is_prop and not any(x["file"] == f.replace("res://", "") for x in m):
        add(k, f, "props", e.get("visual_scale", 1.0), e.get("frame_w"), e.get("frame_h"))

# VFX (scripts/effects.gd), signs (stand_sign.gd WIDTH 64; beach_sign_art.gd 8 px rows), UI
for f in ["vfx-crumb-flecks-v1", "vfx-dust-puff-v1", "vfx-impact-wedge-v1", "vfx-peck-star-v1",
          "vfx-snatch-slash-v1", "vfx-speed-streak-v1"]:
    add(f, "assets/sprites/" + f + ".png", "vfx", 1.0, outline=False)
for f in ["feather-down-v1", "feather-gray-v1", "feather-tip-v1", "feather-fluff-v1"]:
    add(f, "assets/sprites/" + f + ".png", "vfx", 0.25, outline=False, note="28 px drawn 5-9 px and rotated")
for f in ["stand-sign-hot-dogs-runtime-v2", "stand-sign-ice-cream-runtime-v2", "stand-sign-fish-chips-runtime-v1"]:
    add(f, "assets/sprites/" + f + ".png", "signs", 0.25)
add("beach_sign_arrow", "assets/sprites/beach-sign-arrow-v4.png", "signs", 0.4, note="stretched to board width x 8 px")
add("beach_sign_arrow_left", "assets/sprites/beach-sign-arrow-left-v4.png", "signs", 0.4, lineup=False)
add("beach_sign_post", "assets/sprites/beach-sign-post-v1.png", "signs", 0.75, outline=False, note="4 px wide drawn 3 px wide")
for f in ["retro-picnic-bag-coral-32bit", "retro-picnic-bag-teal-32bit", "retro-picnic-bag-woven-32bit"]:
    add(f, "assets/sprites/" + f + ".png", "props", 1.0)
for f in ["beach-arcade-font-sprite-sheet-v2", "beach-arcade-font-sprite-sheet-v3"]:
    add(f, "assets/" + f + ".png", "fonts", 1.0, outline=False, lineup=False, note="font page: source checks only")
add("title_logo", "assets/sprites/title-logo.png", "ui", round(175 / 525, 4), outline=False)
add("loading_backdrop", "assets/sprites/loading-backdrop-v2.png", "ui", round(320 / 1672, 4), outline=False, lineup=False)

seen, out = set(), []
for e in m:
    key = (e["file"], e["scale"], str(e.get("region")))
    if key not in seen:
        seen.add(key)
        out.append(e)
json.dump(out, sys.stdout, indent=1)
print(f"{len(out)} entries: {dict(Counter(e['group'] for e in out))}", file=sys.stderr)
