"""Cuts the Crumb Lady sheet and the two pigeon sheets (assets/reference/{crumb-lady-v2,pigeon-v1,pigeon-v2}/source.png)
into clean Art Lab sprite sheets (assets/lab/) and adds "CHARACTERS" comparisons to data/art_lab.json.

Usage:  python tools/prepare_lab_characters_v1.py
Needs numpy and Pillow. Safe to re-run: it replaces the earlier "CRUMB LADY ..." / "PIGEON ..." entries.
The sources are transparent sheets whose figures drift a little off their grid cells, so each figure is found as a
connected blob, owned by the cell holding its centre, and copied into an equal frame with its own cell's alignment kept.
Each smooth sheet (source resolution, shown by visual_scale) also gets a "-light" twin: the pre-shrunk art at 4 art px per
game px (1 art px = 1 screen px at 1280x720, so nothing is shrunk at draw time), alpha made crisp and the colours gently
reduced to one shared palette per sheet. Outlines, shading and detail stay; it is a clean-up, not pixelation.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

import prepare_food_icons_v1 as food  # label

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "assets" / "reference"
LAB_DIR = ROOT / "assets" / "lab"
LAB = ROOT / "data" / "art_lab.json"
ALPHA_SEED = 100  # opaque art sits near 255, the sheets' halo is faint
ALPHA_KEEP = 16  # below this a pixel is cleared (anti-aliased edges stay)
CATEGORY = "characters"
LIGHT_FACTOR_LADY = 0.6  # 256 px cell drawn at 0.15 becomes 154 px drawn at 0.25: same size, 1 art px = 1 screen px
LIGHT_FACTOR_PIGEON = 0.3  # 0.075 -> 0.25


def owned_labels(alpha: np.ndarray, cols: int, rows: int) -> dict[tuple[int, int], np.ndarray]:
	"""Per grid cell, a full-size mask of the figure pieces whose centre lies in that cell."""
	small = alpha[::4, ::4] >= ALPHA_SEED
	grown = small.copy()
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			grown |= np.roll(np.roll(small, dy, 0), dx, 1)
	lab = food.label(grown)
	h, w = alpha.shape
	cell_w, cell_h = w / cols, h / rows
	owner = np.zeros(lab.shape, dtype=np.int32)  # 1 + row * cols + col per blob pixel
	for n in np.unique(lab):
		if n == 0:
			continue
		ys, xs = np.nonzero((lab == n) & small)
		if len(ys) < 2:
			continue  # specks
		col = int((xs.mean() * 4) // cell_w)
		row = int((ys.mean() * 4) // cell_h)
		owner[lab == n] = 1 + row * cols + col
	big = np.kron(owner, np.ones((4, 4), dtype=np.int32))[:h, :w]
	return {(r, c): big == 1 + r * cols + c for r in range(rows) for c in range(cols)}


def cut_sheet(src: Path, cols: int, rows: int, frame_w: int, frame_h: int, window_x, window_y, out: Path) -> list[tuple[int, int, int, int]]:
	"""window_x(col, cell_w) / window_y(row, cell_h) give the source window origin for a frame; returns each frame's art box."""
	rgba = np.array(Image.open(src).convert("RGBA"))
	h, w = rgba.shape[:2]
	masks = owned_labels(rgba[:, :, 3], cols, rows)
	sheet = np.zeros((rows * frame_h, cols * frame_w, 4), dtype=np.uint8)
	boxes = []
	for r in range(rows):
		for c in range(cols):
			own = masks[(r, c)] & (rgba[:, :, 3] >= ALPHA_KEEP)
			x0, y0 = window_x(c, w / cols), window_y(r, h / rows)
			frame = np.zeros((frame_h, frame_w, 4), dtype=np.uint8)
			sx0, sy0 = max(x0, 0), max(y0, 0)
			sx1, sy1 = min(x0 + frame_w, w), min(y0 + frame_h, h)
			piece = np.where(own[sy0:sy1, sx0:sx1, None], rgba[sy0:sy1, sx0:sx1], 0)
			frame[sy0 - y0:sy1 - y0, sx0 - x0:sx1 - x0] = piece
			ys, xs = np.nonzero(frame[:, :, 3] >= ALPHA_SEED)
			if not len(ys):
				raise SystemExit(f"{src.parent.name}: no figure in row {r} col {c}")
			boxes.append((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
			if xs.min() == 0 or ys.min() == 0 or xs.max() == frame_w - 1 or ys.max() == frame_h - 1:
				print(f"  WARNING {src.parent.name} frame {r * cols + c}: art touches the frame edge")
			sheet[r * frame_h:(r + 1) * frame_h, c * frame_w:(c + 1) * frame_w] = frame
	LAB_DIR.mkdir(parents=True, exist_ok=True)
	Image.fromarray(sheet).save(out, optimize=True)
	return boxes


def light_touch(smooth: Path, cols: int, rows: int, fw: int, fh: int, factor: float, colours: int, out: Path) -> tuple[int, int]:
	"""Shrinks every frame by `factor` (area filter, premultiplied alpha), makes alpha binary and quantises the sheet to
	`colours` colours without dithering. Returns the new frame size."""
	new_w, new_h = round(fw * factor), round(fh * factor)
	src = Image.open(smooth).convert("RGBA")
	sheet = Image.new("RGBA", (cols * new_w, rows * new_h))
	for r in range(rows):
		for c in range(cols):
			frame = src.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh)).resize((new_w, new_h), Image.LANCZOS)
			sheet.paste(frame, (c * new_w, r * new_h))
	arr = np.array(sheet)
	solid = arr[:, :, 3] >= 128
	flat = Image.fromarray(np.where(solid[:, :, None], arr[:, :, :3], 0).astype(np.uint8))
	pal = np.array(flat.quantize(colors=colours + 1, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB"))
	result = np.zeros_like(arr)
	result[solid, :3] = pal[solid]
	result[solid, 3] = 255
	Image.fromarray(result).save(out, optimize=True)
	return new_w, new_h


def anim(frames: list[int], fps: float, loop: bool = True) -> dict:
	return {"frames": [float(f) for f in frames], "fps": fps, "loop": loop}


def main() -> None:
	lab = json.loads(LAB.read_text(encoding="utf-8-sig"))
	comparisons = [c for c in lab["comparisons"] if not (c["title"].startswith("CRUMB LADY ") or c["title"].startswith("PIGEON "))]

	# Crumb Lady: 6 x 4 cells of 256 px, rows = walk, hit, panic run, sow. Frames stop 6 px under the boots (feet at y 244 of 256).
	lady_h = 250
	boxes = cut_sheet(REF / "crumb-lady-v2" / "source.png", 6, 4, 256, lady_h, lambda c, cw: round(c * cw), lambda r, ch: round(r * ch), LAB_DIR / "crumb-lady-v2-sheet.png")
	print("crumb lady frame boxes (x0,y0,x1,y1):", boxes[:3], "...")
	lady_anims = {"idle": anim([0], 4), "walk": anim([0, 1, 2, 3, 4, 5], 8), "swat": anim([6, 7, 8, 9, 10, 11], 10, False),
		"run": anim([12, 13, 14, 15, 16, 17], 10), "sow": anim([18, 19, 20, 21, 22, 23], 8, False)}
	lady_steps = {}  # name -> sprite def: light = 4 art px per game px, medium = 3 (the chosen level)
	for name, factor, colours, scale in [("light", LIGHT_FACTOR_LADY, 128, 0.25), ("medium", 0.45, 64, 1 / 3)]:
		lw, lh = light_touch(LAB_DIR / "crumb-lady-v2-sheet.png", 6, 4, 256, lady_h, factor, colours, LAB_DIR / f"crumb-lady-v2-{name}.png")
		lady_steps[name] = {"file": f"res://assets/lab/crumb-lady-v2-{name}.png", "frame_w": lw, "frame_h": lh, "visual_scale": scale, "animations": lady_anims}
	for title, why, motion, animation in [
		("CRUMB LADY WALK", "NEW CHARACTER. LIGHT LEFT. MEDIUM PIXELS RIGHT. SHOPPER BETWEEN.", "walk_across", "walk"),
		("CRUMB LADY PANIC RUN", "NEW CHARACTER. PANIC RUN. LIGHT LEFT. MEDIUM RIGHT.", "walk_across", "run"),
		("CRUMB LADY HIT", "NEW CHARACTER. ANGRY SWAT. LIGHT LEFT. MEDIUM RIGHT.", "idle", "swat"),
		("CRUMB LADY SOW CRUMBS", "NEW CHARACTER. CRUMB THROW. LIGHT LEFT. MEDIUM RIGHT.", "idle", "sow"),
	]:
		comparisons.append({"title": title, "description": why, "current": "shopper_mullet", "current_override": lady_steps["light"], "candidate": lady_steps["medium"],
			"reference": "shopper_mullet", "motion": motion, "animation": animation, "category": CATEGORY})


	# Pigeons: 4 x 5 cells (384 x 204.8). Frames are 416 x 280 windows starting 60 px above each cell so wingtips that
	# spill over the grid are kept; masked to the owning figure so neighbours never leak in.
	pigeon_w, pigeon_h = 416, 280
	pigeons = {}
	for version in ("v1", "v2"):
		out = LAB_DIR / f"pigeon-{version}-sheet.png"
		boxes = cut_sheet(REF / f"pigeon-{version}" / "source.png", 4, 5, pigeon_w, pigeon_h, lambda c, cw: round(c * cw) - 16, lambda r, ch: round(r * ch) - 60, out)
		print(f"pigeon {version} frame boxes:", boxes)
		pigeon_anims = {"idle": anim([0], 4), "walk": anim([1, 2, 3, 4, 5, 6, 7], 10), "flap": anim([8, 9, 10, 11], 8),
			"glide": anim([12, 13, 14, 15], 4, False), "act": anim([16, 17, 18, 19], 3, False)}
		pw, ph = light_touch(out, 4, 5, pigeon_w, pigeon_h, LIGHT_FACTOR_PIGEON, 128, LAB_DIR / f"pigeon-{version}-light.png")
		pigeons[version] = {"file": f"res://assets/lab/pigeon-{version}-sheet.png", "frame_w": pigeon_w, "frame_h": pigeon_h, "visual_scale": 0.075, "animations": pigeon_anims}
		pigeons[version + "L"] = {"file": f"res://assets/lab/pigeon-{version}-light.png", "frame_w": pw, "frame_h": ph, "visual_scale": 0.25, "animations": pigeon_anims}
	for title, why, motion, animation in [
		("PIGEON WALK V1 V2", "NEW PIGEON. V1 LEFT. V2 RIGHT. LIGHT PIXEL PASS. SHOPPER BETWEEN.", "walk_across", "walk"),
		("PIGEON FLAP V1 V2", "NEW PIGEON. V1 LEFT. V2 RIGHT. WINGBEAT ROW. GROUNDED FOR REVIEW.", "idle", "flap"),
		("PIGEON GLIDE DIVE V1 V2", "NEW PIGEON. V1 LEFT. V2 RIGHT. GLIDE. DIVE PREP. DIVE. PULL UP.", "idle", "glide"),
		("PIGEON SNATCH PECK V1 V2", "NEW PIGEON. V1 LEFT. V2 RIGHT. SNATCH. PECK. LAND. STUNNED.", "idle", "act"),
	]:
		comparisons.append({"title": title, "description": why, "current": "shopper_mullet", "current_override": pigeons["v1L"],
			"candidate": pigeons["v2L"], "reference": "shopper_mullet", "motion": motion, "animation": animation, "category": CATEGORY})

	comparisons.append({"title": "PIGEON V2 SMOOTH VS LIGHT", "description": "NEW PIGEON. SMOOTH LEFT. LIGHT PIXEL PASS RIGHT. SHOPPER BETWEEN.", "current": "shopper_mullet",
		"current_override": pigeons["v2"], "candidate": pigeons["v2L"], "reference": "shopper_mullet", "motion": "walk_across", "animation": "walk", "category": CATEGORY})
	lab["comparisons"] = comparisons
	LAB.write_text(json.dumps(lab, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
