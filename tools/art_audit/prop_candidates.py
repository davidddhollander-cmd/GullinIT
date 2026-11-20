#!/usr/bin/env python3
"""Measure unused prop candidates against in-use props (docs/PROP_ART_AUDIT.md).
Run from the project root: python tools/art_audit/prop_candidates.py > test-output/prop_audit/metrics.md
Per sprite, first frame only, after nearest resampling to its in-game size:
  block    stored upscale (run-length GCD); art px on the 320x180 grid = block * scale
  density  art px per logical px (1.0 = prop standard, 2.0 = cast standard, else mixed)
  cols     distinct colours on screen; pal = share within 40 RGB of tools/art_audit/palette.hex
  sat/val  mean HSV saturation / value of opaque pixels
  outline  share of silhouette edge in dark colour (luma < 70); weight = dark share one px inward
  light    luma(left - right), luma(top - bottom) of the opaque area: + = lit from left / top
  gap      transparent rows under the art (prop sits frame_h*scale/2 above its base y)
  soft     share of alpha values strictly between 0 and 255
"""
import json
import re
from math import gcd
from pathlib import Path

import numpy as np
from PIL import Image

S = json.load(open("data/sprites.json"))
PAL = np.array([[int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4)]
                for line in Path("tools/art_audit/palette.hex").read_text().splitlines()
                if (m := re.search(r"([0-9a-fA-F]{6})", line))])

IN_USE = ["bin", "wheelie_bin", "beach_bench", "beach_palm", "beach_parasol", "beach_lamp", "beach_hut",
          "beach_rocks", "kiosk", "hotdog_stand", "fish_chips_stand", "beach_castle", "beach_chair_blue", "umbrella"]
CANDIDATES = ["tower", "pier", "beach_chair", "beach_sign", "beach_boards", "beach_ball", "beach_bucket",
              "beach_shells", "beach_jet_ski", "beach_lifebuoy_flat", "beach_lifebuoy_hung", "lifeguard"]
EXTRA = [("ground_pier", "assets/sprites/beach-ground-v1/pier-320x22.png", 1.0),
         ("ground_promenade", "assets/sprites/beach-ground-v1/promenade-320x14.png", 1.0),
         ("ground_sand (in use)", "assets/sprites/beach-ground-v1/sand-320x40.png", 1.0)]
EXTRA += [(p.stem, str(p).replace("\\", "/"), 1.0) for p in sorted(Path("assets/sprites").glob("retro-trash-*.png"))]
EXTRA += [(n, "assets/sprites/" + n + ".png", 1.0) for n in
          ["Colourful Pixel-Art Litter Sprite Sheet", "Three Pixel-Art Bags Collection", "Ultimate Pizza and Fast-Food Sticker Atlas"]]


def runs_gcd(a):
    g = 0
    for row in (a, a.transpose(1, 0, 2)):
        for line in row:
            change = np.any(line[1:] != line[:-1], axis=1)
            idx = np.flatnonzero(change)
            lens = np.diff(np.concatenate([[-1], idx, [len(line) - 1]]))
            for n in lens:
                g = gcd(g, int(n))
                if g == 1:
                    return 1
    return g or 1


def nearest(img, s):
    h, w = img.shape[:2]
    oh, ow = max(1, round(h * s)), max(1, round(w * s))
    ys = np.minimum(((np.arange(oh) + 0.5) / s).astype(int), h - 1)
    xs = np.minimum(((np.arange(ow) + 0.5) / s).astype(int), w - 1)
    return img[ys][:, xs]


def measure(name, file, scale, fw=None, fh=None):
    im = np.array(Image.open(file).convert("RGBA")).astype(int)
    if fw:
        im = im[:int(fh), :int(fw)]
    a = im[..., 3]
    soft = float(((a > 0) & (a < 255)).sum()) / max(1, (a > 0).sum())
    block = runs_gcd(im[..., :3] * (a[..., None] > 127))
    scr = nearest(im, scale)
    op = scr[..., 3] > 127
    rgb = scr[..., :3][op]
    if not len(rgb):
        return None
    cols = len({tuple(c) for c in rgb})
    pal = float((np.min(np.linalg.norm(rgb[:, None, :] - PAL[None], axis=2), axis=1) < 40).mean())
    mx, mn = rgb.max(1), rgb.min(1)
    sat = float(np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0).mean())
    luma = scr[..., :3] @ [0.299, 0.587, 0.114]
    pad = np.pad(op, 1)
    edge = op & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    inner = op & ~edge
    pad2 = np.pad(inner, 1)
    ring2 = inner & ~(pad2[:-2, 1:-1] & pad2[2:, 1:-1] & pad2[1:-1, :-2] & pad2[1:-1, 2:])
    outline = float((luma[edge] < 70).mean()) if edge.any() else 0
    weight = float((luma[ring2] < 70).mean()) if ring2.any() else 0
    ys, xs = np.nonzero(op)
    cx, cy = xs.mean(), ys.mean()
    lr = float(luma[op & (np.arange(op.shape[1])[None] < cx)].mean() - luma[op & (np.arange(op.shape[1])[None] >= cx)].mean())
    tb = float(luma[op & (np.arange(op.shape[0])[:, None] < cy)].mean() - luma[op & (np.arange(op.shape[0])[:, None] >= cy)].mean())
    gap = int(scr.shape[0] - 1 - ys.max())
    return dict(name=name, src=f"{im.shape[1]}x{im.shape[0]}", scale=scale, block=block,
                density=round(block * scale, 3), screen=f"{xs.max() - xs.min() + 1}x{ys.max() - ys.min() + 1}",
                cols=cols, pal=round(pal, 2), sat=round(sat, 2), val=round(float(mx.mean()) / 255, 2),
                outline=round(outline, 2), weight=round(weight, 2), lr=round(lr), tb=round(tb), gap=gap, soft=round(soft, 2))


def row(r):
    return "| " + " | ".join(str(r[k]) for k in ["name", "src", "scale", "block", "density", "screen", "cols", "pal", "sat", "val", "outline", "weight", "lr", "tb", "gap", "soft"]) + " |"


print("| sprite | source | scale | block | art px/px | on screen | cols | pal | sat | val | outline | wt | light L-R | light T-B | gap | soft alpha |")
print("|" + "---|" * 16)
for group, ids in (("in use", IN_USE), ("candidate", CANDIDATES)):
    print(f"| **{group}** |" + " |" * 15)
    for k in ids:
        e = S[k]
        print(row(measure(k, e["file"].replace("res://", ""), float(e.get("visual_scale", 1.0)), e["frame_w"], e["frame_h"])))
print("| **ground strips, litter, user sheets (scale 1.0 shown)** |" + " |" * 15)
for name, f, s in EXTRA:
    r = measure(name, f, s)
    if r:
        print(row(r))
