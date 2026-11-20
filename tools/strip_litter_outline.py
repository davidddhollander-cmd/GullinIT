"""Strips the dark outline ring from the user-supplied litter cut-outs (docs/PROP_ART_AUDIT.md), like the in-use set.
Originals live in assets/reference/litter-cutouts-v1/; results go to assets/sprites/. Usage: python tools/strip_litter_outline.py
Each pass clears opaque pixels that touch transparency (4-neighbour) and are dark (luma < LUMA); the result is cropped.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "reference" / "litter-cutouts-v1"
LUMA = 70
PASSES = 2

for f in sorted(SRC.glob("retro-trash-*.png")):
	a = np.array(Image.open(f).convert("RGBA"))
	luma = a[..., :3] @ [0.299, 0.587, 0.114]
	for _ in range(PASSES):
		op = a[..., 3] > 0
		pad = np.pad(op, 1)
		edge = op & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
		a[edge & (luma < LUMA)] = 0
	ys, xs = np.nonzero(a[..., 3])
	Image.fromarray(a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]).save(ROOT / "assets" / "sprites" / f.name)
	print(f.name, a.shape[1], "x", a.shape[0], "->", xs.max() - xs.min() + 1, "x", ys.max() - ys.min() + 1)
