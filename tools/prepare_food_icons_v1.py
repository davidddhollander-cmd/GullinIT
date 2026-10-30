"""Cuts the 81 items out of the Retro Pixel Food Icon Collection sheet, reduces each to a small pixel-art
cell and adds one Art Lab comparison per item (titles start with "FOOD ").

Usage:  python tools/prepare_food_icons_v1.py ["path/to/sheet.png"]
Needs only numpy and Pillow. Safe to re-run: it replaces the earlier "FOOD NN ..." entries in data/art_lab.json.

How an item is made
  1. Background: dark outline pixels are walls, the background is flood-filled in from the sheet border.
  2. Items are the connected blobs left over (found on a 1/3 scale mask).
  3. Each item is palette-quantised, then reduced block by block: majority colour per block, but the dark
     outline wins a block when it covers a fifth of it, so outlines stay one clean pixel wide.
  4. Scale follows the live foods: the hot dog on the sheet becomes a 32 px wide cell, shown at 0.25 as 8 px
     wide (4x art, so the pixels land on single screen pixels at the 1280x720 window).
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SHEET = Path(sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\david\Desktop\GAssets\Retro Pixel Food Icon Collection.png")
OUT_DIR = ROOT / "assets" / "lab" / "food-icons-v1"  # assets/lab is imported by Godot and excluded from exports
ATLAS = OUT_DIR / "food-icons-atlas-v1.png"
RES_ATLAS = "res://assets/lab/food-icons-v1/food-icons-atlas-v1.png"
LAB = ROOT / "data" / "art_lab.json"

WALL_LUMA = 55  # outline pixels block the background fill
ART_SCALE = 4  # art px per game px: the cell is drawn at 4x and shown at 0.25, so 1 art px = 1 screen px at the 1280x720 window
HOTDOG_ART_WIDTH = 8.0 * ART_SCALE  # px the sheet's hot dog (item 54) becomes in the art cell
OUTLINE_SHARE = 0.20  # a block turns into outline when this share of its opaque pixels is outline
OUTLINE_LUMA = 36  # palette colours darker than this are outline; chocolate and coffee browns stay fill
PALETTE_COLOURS = 20
LIVE_SHEET_ITEM = 54

# index -> (name, live food it is compared against, True when that food is a real match)
PIZZA, DOUGHNUT, SANDWICH = "food_half_eaten_pizza", "food_half_eaten_doughnut", "food_half_eaten_sandwich"
CREAM, BAG, BOX, FISH, DOG = "food_ice_cream", "food_crisps_bag", "food_crisps_box", "food_fried_fish", "food_hotdog"
ITEMS = [
	("PIZZA SLICE CHEESE", PIZZA, True), ("PIZZA SLICE PEPPERONI", PIZZA, True), ("PIZZA SLICE MUSHROOM", PIZZA, True),
	("PIZZA SLICE VEGGIE", PIZZA, True), ("PIZZA SLICE HAWAIIAN", PIZZA, True), ("PIZZA SLICE WHITE", PIZZA, True),
	("PIZZA SLICE HAM CORN", PIZZA, True), ("PIZZA SLICE ROCKET", PIZZA, True), ("PIZZA SLICE BASIL", PIZZA, True),
	("PIZZA BOX", PIZZA, False),
	("PIZZA BASIL", PIZZA, True), ("PIZZA PEPPERONI", PIZZA, True), ("PIZZA MUSHROOM", PIZZA, True), ("PIZZA VEGGIE", PIZZA, True),
	("PIZZA HAWAIIAN", PIZZA, True), ("PIZZA ROCKET", PIZZA, True), ("PIZZA MARGHERITA", PIZZA, True),
	("DOUGHNUT PINK SPRINKLES", DOUGHNUT, True), ("DOUGHNUT CHOC SPRINKLES", DOUGHNUT, True), ("DOUGHNUT WHITE SPRINKLES", DOUGHNUT, True),
	("DOUGHNUT PLAIN", DOUGHNUT, True), ("DOUGHNUT CHOC DRIZZLE", DOUGHNUT, True), ("DOUGHNUT PINK DRIZZLE", DOUGHNUT, True),
	("DOUGHNUT SUGAR", DOUGHNUT, True), ("DOUGHNUT CHOC NUTS", DOUGHNUT, True), ("DOUGHNUT BERRY", DOUGHNUT, True),
	("DOUGHNUT BOX", DOUGHNUT, False),
	("CONE VANILLA", CREAM, True), ("CONE CHOCOLATE", CREAM, True), ("CONE STRAWBERRY", CREAM, True), ("CONE MINT", CREAM, True),
	("CONE STRAWBERRY SWIRL", CREAM, True), ("CONE CHOC VANILLA SWIRL", CREAM, True), ("CONE CHOC STRAWB SCOOPS", CREAM, True),
	("CONE VANILLA MINT SCOOPS", CREAM, True),
	("LOLLY CHOC NUT", CREAM, True), ("LOLLY CHOCOLATE", CREAM, True), ("LOLLY STRAWBERRY", CREAM, True),
	("LOLLY ORANGE", CREAM, True), ("LOLLY ROCKET", CREAM, True), ("LOLLY CHOCOLATE 2", CREAM, True),
	("ICE CREAM CART", CREAM, False), ("ICE CREAM SIGN", CREAM, False),
	("FRIES CHECK CUP", BAG, True), ("FRIES WHITE CONE", BAG, True), ("FRIES BLUE CONE", BAG, True), ("FRIES PAPER CONE", BAG, True),
	("ONION RING BUCKET", BAG, True), ("NUGGET BUCKET", BAG, True), ("POPCORN BUCKET", BAG, True),
	("FISH AND CHIPS TRAY", FISH, True), ("CHIPS AND DIP TRAY", BOX, True), ("ONION RING TRAY", BOX, True), ("ONION RING TRAY SMALL", BOX, True),
	("HOT DOG MUSTARD", DOG, True), ("HOT DOG RELISH", DOG, True), ("HOT DOG KETCHUP MUSTARD", DOG, True), ("HOT DOG LOADED", DOG, True),
	("BURGER 1", SANDWICH, True), ("BURGER 2", SANDWICH, True), ("BURGER 3", SANDWICH, True),
	("WRAP", SANDWICH, True), ("SUB HAM SALAD", SANDWICH, True), ("PANINI", SANDWICH, True),
	("CAN RED", BOX, False), ("CAN BLUE", BOX, False), ("CAN GREEN", BOX, False), ("CAN ORANGE", BOX, False),
	("BOTTLE KETCHUP", BOX, False), ("BOTTLE MUSTARD", BOX, False), ("BOTTLE MAYO", BOX, False),
	("COFFEE CUP", BOX, False), ("COLA GLASS", BOX, False), ("MILKSHAKE", BOX, False), ("ORANGE JUICE", BOX, False),
	("WATER BOTTLE", BOX, False), ("COCONUT DRINK", BOX, False), ("SALT SHAKER", BOX, False), ("PEPPER SHAKER", BOX, False),
	("NAPKIN DISPENSER", BOX, False), ("CUTLERY CRATE", BOX, False),
]


def dilate(mask: np.ndarray, radius: int = 1) -> np.ndarray:
	out = mask.copy()
	for _ in range(radius):
		p = np.pad(out, 1)
		out = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:] | p[1:-1, 1:-1]
	return out


def item_mask(rgb: np.ndarray) -> np.ndarray:
	luma = rgb.astype(float) @ [0.299, 0.587, 0.114]
	free = ~dilate(luma < WALL_LUMA, 2)
	seed = np.zeros_like(free)
	seed[0, :] = seed[-1, :] = seed[:, 0] = seed[:, -1] = True
	background = seed & free
	while True:  # flood the background in from the border, stopping at outlines
		p = np.pad(background, 1)
		grown = (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:] | background) & free
		if (grown == background).all():
			break
		background = grown
	mask = ~background  # everything the fill did not reach
	mask = ~dilate(~mask, 2)  # the fill stops 2 px short of every outline, so shrink the item mask back by 2
	for edge in (slice(0, 8), slice(-8, None)):
		mask[edge, :] = False
		mask[:, edge] = False
	return mask


def label(mask: np.ndarray) -> np.ndarray:
	h, w = mask.shape
	big = 10 ** 12
	lab = np.where(mask, np.arange(1, h * w + 1).reshape(h, w), 0).astype(np.int64)
	while True:  # min-label propagation; fine on the 1/3 scale mask
		p = np.pad(lab, 1)
		best = np.where(mask, lab, big)
		for dy in (0, 1, 2):
			for dx in (0, 1, 2):
				q = p[dy:dy + h, dx:dx + w]
				best = np.minimum(best, np.where(q > 0, q, big))
		new = np.where(mask, best, 0)
		if (new == lab).all():
			return lab
		lab = new


def find_items(mask: np.ndarray) -> list[tuple[tuple[int, int, int, int], np.ndarray]]:
	scale = 3
	h, w = mask.shape[0] // scale * scale, mask.shape[1] // scale * scale
	small = mask[:h, :w].reshape(h // scale, scale, w // scale, scale).mean(axis=(1, 3)) > 0.35
	lab = label(small)
	found = []
	for i in np.unique(lab):
		if i == 0:
			continue
		blob = lab == i
		if blob.sum() < 25:
			continue
		full = np.kron(dilate(blob, 1), np.ones((scale, scale), dtype=bool))
		pad = np.zeros(mask.shape, dtype=bool)
		pad[:full.shape[0], :full.shape[1]] = full
		own = pad & mask
		ys, xs = np.where(own)
		found.append(((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), own))
	found.sort(key=lambda f: (f[0][1] + f[0][3]) // 2)
	rows: list[list] = []
	for f in found:
		cy = (f[0][1] + f[0][3]) / 2
		if rows and abs(cy - np.mean([(r[0][1] + r[0][3]) / 2 for r in rows[-1]])) < 55:
			rows[-1].append(f)
		else:
			rows.append([f])
	return [f for row in rows for f in sorted(row, key=lambda f: f[0][0])]


def reduce_item(rgb: np.ndarray, own: np.ndarray, box: tuple[int, int, int, int], factor: float) -> np.ndarray:
	x0, y0, x1, y1 = box
	crop = rgb[y0:y1, x0:x1]
	m = own[y0:y1, x0:x1]
	flat = crop.copy()
	flat[~m] = (255, 0, 255)
	quant = Image.fromarray(flat).quantize(colors=PALETTE_COLOURS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
	idx = np.array(quant)
	pal = np.array(quant.getpalette()[:PALETTE_COLOURS * 3], dtype=np.uint8).reshape(-1, 3)
	luma = pal.astype(float) @ [0.299, 0.587, 0.114]
	dark = luma < OUTLINE_LUMA  # outline colours, never the magenta background key
	dark &= ~((pal[:, 0] > 200) & (pal[:, 1] < 60) & (pal[:, 2] > 200))
	outline = pal[dark][np.argmin(luma[dark])] if dark.any() else pal[np.argmin(luma)]
	h, w = m.shape
	aw, ah = max(4, round(w * factor)), max(4, round(h * factor))
	xs = np.linspace(0, w, aw + 1).round().astype(int)
	ys = np.linspace(0, h, ah + 1).round().astype(int)
	out = np.zeros((ah, aw, 4), dtype=np.uint8)
	for j in range(ah):
		for i in range(aw):
			bm = m[ys[j]:ys[j + 1], xs[i]:xs[i + 1]]
			if bm.size == 0 or bm.mean() < 0.5:
				continue
			bi = idx[ys[j]:ys[j + 1], xs[i]:xs[i + 1]][bm]
			is_dark = dark[bi]
			if is_dark.mean() >= OUTLINE_SHARE:
				colour = outline
			else:
				light = bi[~is_dark] if (~is_dark).any() else bi
				colour = pal[np.bincount(light).argmax()]
			out[j, i] = (*colour, 255)
	return out


def pack(cells: list[np.ndarray], width: int = 1024) -> tuple[np.ndarray, list[tuple[int, int]]]:
	spots, x, y, shelf = [], 2, 2, 0
	for c in cells:
		h, w = c.shape[:2]
		if x + w + 2 > width:
			x, y, shelf = 2, y + shelf + 2, 0
		spots.append((x, y))
		x += w + 2
		shelf = max(shelf, h)
	atlas = np.zeros((y + shelf + 2, width, 4), dtype=np.uint8)
	for c, (px, py) in zip(cells, spots):
		atlas[py:py + c.shape[0], px:px + c.shape[1]] = c
	return atlas, spots


def main() -> None:
	rgb = np.array(Image.open(SHEET).convert("RGB"))
	found = find_items(item_mask(rgb))
	if len(found) != len(ITEMS):
		sys.exit(f"found {len(found)} items on the sheet but the name list has {len(ITEMS)}: check segmentation before naming")
	hotdog_w = found[LIVE_SHEET_ITEM][0][2] - found[LIVE_SHEET_ITEM][0][0]
	factor = HOTDOG_ART_WIDTH / hotdog_w
	cells = [reduce_item(rgb, own, box, factor) for box, own in found]
	atlas, spots = pack(cells)
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	Image.fromarray(atlas).save(ATLAS)

	lab = json.loads(LAB.read_text(encoding="utf-8-sig"))
	comparisons = [c for c in lab["comparisons"] if not c["title"].startswith("FOOD ") or "SELF-TEST" in c["title"]]
	manifest = []
	for n, ((name, live, match), cell, (px, py)) in enumerate(zip(ITEMS, cells, spots), start=1):
		h, w = cell.shape[:2]
		size = [w / ART_SCALE, h / ART_SCALE]
		comparisons.append({
			"title": f"FOOD {n:02d} {name}",
			"description": ("NEW ART VS LIVE " if match else "NEW ITEM. SIZE REF: ") + live.replace("food_", "").replace("half_eaten_", "").replace("_", " ").upper(),
			"current": live,
			"candidate": {"clone": live, "file": RES_ATLAS, "frame_w": w, "frame_h": h,
				"regions": [{"region": [px, py, w, h], "offset": [0, 0]}]},
			"motion": "on_sand",
			"size": size,
		})
		manifest.append({"n": n, "name": name, "live": live, "live_match": match, "cell": [w, h], "shown": size, "region": [px, py, w, h]})
	lab["comparisons"] = comparisons
	LAB.write_text(json.dumps(lab, indent=2) + "\n", encoding="utf-8")
	(OUT_DIR / "manifest.json").write_text(json.dumps({"source": SHEET.name, "art_per_sheet_px": factor, "items": manifest}, indent=1), encoding="utf-8")
	print(f"{len(cells)} items, atlas {atlas.shape[1]}x{atlas.shape[0]}, art factor {factor:.4f}")


if __name__ == "__main__":
	main()
