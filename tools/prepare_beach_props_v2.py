"""beach-props v2: resize + palette pass on the six backdrop props (docs/PROP_ART_AUDIT.md, "Fixes (v2)").
Re-runs v1's reduction from the high-res sheet at a new target width (never resamples the v1 PNGs), then blends each
colour toward its nearest colour in tools/art_audit/palette.hex by a per-prop weight. Writes *-v2.png beside the v1 files
and repoints data/sprites.json and the "BG PROP" art_lab entries. Usage: python tools/prepare_beach_props_v2.py
"""
import colorsys
import json
import re

import numpy as np
from PIL import Image

import prepare_beach_props_v1 as v1

PAL = np.array([[int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4)] for line in (v1.ROOT / "tools/art_audit/palette.hex").read_text().splitlines()
				if (m := re.search(r"([0-9a-fA-F]{6})", line))], dtype=float)
SPRITES = v1.ROOT / "data" / "sprites.json"
FINE = {"BUCKET AND SPADE"}  # kept on the finer 4x grid (visual_scale 0.25): preferred less pixelated
ART_SCALE = 2  # art px per game px: 2x the world grid (same as the cast); v1 used 4, which read too fine next to the props
# name -> (sprite id, v2 width in game px, palette blend weight, soft outline)
V2 = {
	"BEACH BALL": ("beach_ball", 6, 0.45, False),
	"SHELLS": ("beach_shells", 7, 0.5, True),
	"JET SKI": ("beach_jet_ski", 36, 0.5, False),
	"LIFEBUOY HUNG": ("beach_lifebuoy_hung", 8, 0.5, False),
	"BUCKET AND SPADE": ("beach_bucket", 11, 0.8, False),
	"LIFEBUOY FLAT": ("beach_lifebuoy_flat", 14, 0.8, False),
}


def orange_to_red(c: np.ndarray) -> np.ndarray:
	h, s, v = colorsys.rgb_to_hsv(*(c / 255))
	if 0.03 < h < 0.15 and s > 0.4:  # orange (11-54 deg) -> the tower lifebuoy's red (~8 deg)
		h = 0.02
	return np.array(colorsys.hsv_to_rgb(h, s, v)) * 255


def blend(art: np.ndarray, weight: float, swap: bool) -> np.ndarray:
	out = art.copy()
	for c in {tuple(p[:3]) for p in art.reshape(-1, 4) if p[3]}:
		src = orange_to_red(np.array(c, float)) if swap else np.array(c, float)
		near = PAL[np.argmin(np.linalg.norm(PAL - src, axis=1))]
		new = np.clip(src + weight * (near - src), 0, 255).round().astype(np.uint8)
		m = (art[..., :3] == c).all(-1) & (art[..., 3] > 0)
		out[m, :3] = new
	return out


def colour_outline(art: np.ndarray, shade: float = 0.55) -> np.ndarray:
	"""Near-black outline pixels take a darkened copy of the nearest fill colour (dark red on red, brown on shell)."""
	out = art.copy()
	dark = (art[..., 3] > 0) & ((art[..., :3] @ [0.299, 0.587, 0.114]) < 70)
	ys, xs = np.nonzero((art[..., 3] > 0) & ~dark)
	for y, x in zip(*np.nonzero(dark)):
		i = np.argmin((ys - y) ** 2 + (xs - x) ** 2)
		out[y, x, :3] = (art[ys[i], xs[i], :3] * shade).astype(np.uint8)
	return out


def main() -> None:
	rgba = np.array(Image.open(v1.SHEET).convert("RGBA"))
	mask = rgba[:, :, 3] >= v1.ALPHA_MIN
	rgb = rgba[:, :, :3]
	boxes = v1.blobs(mask)
	cell = rgba.shape[0] / v1.GRID
	text = SPRITES.read_text(encoding="utf-8")
	lab = json.loads(v1.LAB.read_text(encoding="utf-8-sig"))
	for name, (row, col), _w, live, why in v1.PROPS:
		sid, width, weight, soft = V2[name]
		v1.food.OUTLINE_SHARE = 0.5 if soft else 0.20  # soft: a block is outline only when mostly outline
		mine = [b for b in boxes if int((b[1] + b[3]) / 2 // cell) == row and int((b[0] + b[2]) / 2 // cell) == col]
		box = (min(b[0] for b in mine), min(b[1] for b in mine), max(b[2] for b in mine), max(b[3] for b in mine))
		own = np.zeros_like(mask)
		own[box[1]:box[3], box[0]:box[2]] = mask[box[1]:box[3], box[0]:box[2]]
		# never upscale the sheet (it leaves gaps): the jet ski's source is 200 px wide, so it is drawn at native size and scaled in game
		art = v1.food.reduce_item(rgb, own, box, min(width * (4 if name in FINE else ART_SCALE), box[2] - box[0]) / (box[2] - box[0]))
		art = blend(art, weight, swap=name == "LIFEBUOY FLAT")
		if soft:
			art = colour_outline(art)
		h, w = art.shape[:2]
		scale = round(width / w, 4)
		slug = name.lower().replace(" ", "-")
		Image.fromarray(art).save(v1.OUT_DIR / f"{slug}-v2.png")
		res = f"res://assets/sprites/beach-props-v1/{slug}-v2.png"
		text = re.sub(rf'("{sid}": \{{\s*"file": )"[^"]*",(\s*"frame_w": )[\d.]+,(\s*"frame_h": )[\d.]+,(\s*"visual_scale": )[\d.]+', rf'\g<1>"{res}",\g<2>{w},\g<3>{h},\g<4>{scale}', text)  # keep the file's layout
		for c in lab["comparisons"]:
			if c["title"] == f"BG PROP {name}":
				c["candidate"].update(file=res, frame_w=w, frame_h=h, visual_scale=scale)
		print(f"{name}: {w}x{h} weight {weight}")
	SPRITES.write_text(text, encoding="utf-8")
	v1.LAB.write_text(json.dumps(lab, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
