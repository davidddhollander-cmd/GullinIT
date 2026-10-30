"""Cuts five background props (bucket and spade, beach ball, two lifebuoys, shells, jet ski) out of the 36-prop
beach sheet, reduces each to game-scale pixel art and adds Art Lab entries in the "bgprops" category.

Usage:  python tools/prepare_beach_props_v1.py
Needs numpy and Pillow. Safe to re-run: it replaces the earlier "BG PROP ..." entries in data/art_lab.json.
Items are found as connected opaque blobs of the sheet's alpha (the sheet is a clean cut-out); the reduction is
prepare_food_icons_v1.reduce_item (one clean outline, flat colours). Cells are drawn at 4x and shown at visual_scale 0.25.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

import prepare_food_icons_v1 as food  # reduce_item, label

ROOT = Path(__file__).resolve().parent.parent
SHEET = ROOT / "assets" / "reference" / "beach-props-sheet-v1" / "source.png"
OUT_DIR = ROOT / "assets" / "lab" / "beach-props-v1"  # imported by Godot, excluded from exports; promote to assets/sprites when accepted
LAB = ROOT / "data" / "art_lab.json"
ALPHA_MIN = 100  # the sheet's opaque pixels sit at 249-254, its halo at 1-3
GRID = 6  # the sheet is a 6x6 grid of props
ART_SCALE = 4  # art px per game px: cells are drawn at 4x and shown at visual_scale 0.25

# name, (row, col) on the sheet, width in game px (the cell is ART_SCALE times wider), live prop shown beside it, why that one
PROPS = [
	("BUCKET AND SPADE", (3, 4), 20, "beach_castle", "SAND TOY SIZE REF"),
	("BEACH BALL", (3, 5), 12, "beach_castle", "SIZE REF"),
	("LIFEBUOY HUNG", (3, 0), 16, "beach_chair", "SIZE REF"),
	("LIFEBUOY FLAT", (3, 1), 26, "beach_chair", "SIZE REF"),
	("SHELLS", (5, 5), 18, "beach_rocks", "GROUND CLUTTER SIZE REF"),
	("JET SKI", (4, 5), 44, "beach_rocks", "SIZE REF"),
]


def blobs(mask: np.ndarray) -> list[tuple[int, int, int, int]]:
	"""Bounding boxes of the connected opaque blobs, found on a 1/4 scale mask joined by a 3 px dilation."""
	small = mask[::4, ::4]
	grown = small.copy()
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			grown |= np.roll(np.roll(small, dy, 0), dx, 1)
	lab = food.label(grown)
	boxes = []
	for n in range(1, lab.max() + 1):
		ys, xs = np.nonzero((lab == n) & small)
		if len(ys) > 40:
			boxes.append((xs.min() * 4, ys.min() * 4, xs.max() * 4 + 4, ys.max() * 4 + 4))
	return boxes


def main() -> None:
	rgba = np.array(Image.open(SHEET).convert("RGBA"))
	mask = rgba[:, :, 3] >= ALPHA_MIN
	rgb = rgba[:, :, :3]
	boxes = blobs(mask)
	cell = rgba.shape[0] / GRID
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	lab = json.loads(LAB.read_text(encoding="utf-8-sig"))
	comparisons = [c for c in lab["comparisons"] if not c["title"].startswith("BG PROP ")]
	for name, (row, col), width, live, why in PROPS:
		# the sheet's items drift off the grid a little, so a blob belongs to the cell holding its centre
		mine = [b for b in boxes if int((b[1] + b[3]) / 2 // cell) == row and int((b[0] + b[2]) / 2 // cell) == col]
		if not mine:
			raise SystemExit(f"{name}: no blob in sheet cell row {row} col {col}")
		box = (min(b[0] for b in mine), min(b[1] for b in mine), max(b[2] for b in mine), max(b[3] for b in mine))
		own = np.zeros_like(mask)
		own[box[1]:box[3], box[0]:box[2]] = mask[box[1]:box[3], box[0]:box[2]]
		art = food.reduce_item(rgb, own, box, width * ART_SCALE / (box[2] - box[0]))
		h, w = art.shape[:2]
		slug = name.lower().replace(" ", "-")
		path = OUT_DIR / f"{slug}-v1.png"
		Image.fromarray(art).save(path)
		comparisons.append({
			"title": f"BG PROP {name}",
			"description": f"NEW BACKGROUND PROP. {why}: " + live.replace("beach_", "").replace("_", " ").upper(),
			"current": live,
			"candidate": {"clone": live, "file": f"res://assets/lab/beach-props-v1/{slug}-v1.png", "frame_w": w, "frame_h": h, "visual_scale": 1 / ART_SCALE},
			"reference": "shopper_mullet",
			"motion": "static",
			"category": "bgprops",
		})
		print(f"{name}: {w}x{h} from sheet box {box}")
	lab["comparisons"] = comparisons
	LAB.write_text(json.dumps(lab, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
