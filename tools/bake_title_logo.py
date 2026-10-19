"""Bake the title logo from the arcade font sheet: python tools/bake_title_logo.py [text] [scale]"""
import sys
import numpy as np
from PIL import Image

SHEET = "assets/beach-arcade-font-sprite-sheet-v2.png"
OUT = "assets/sprites/title-logo.png"
ROWS = ["ABCDEFGHIJKLM", "NOPQRSTUVWXYZ", "0123456789", ".!?,:;+-x/=()[]'\""]
DISPLAY_H = 26
KERN, WORD_GAP = -3, 60  # source px; the outlines overlap a little for a tight look

def bands(mask, min_gap=1):
	runs, start = [], None
	for i, on in enumerate(mask):
		if on and start is None:
			start = i
		elif not on and start is not None:
			runs.append((start, i)); start = None
	if start is not None:
		runs.append((start, len(mask)))
	return runs

def glyphs(sheet):
	alpha = np.array(sheet)[:, :, 3] > 20
	table = {}
	for (y0, y1), chars in zip(bands(alpha.any(axis=1)), ROWS):
		cols = bands(alpha[y0:y1].any(axis=0))
		assert len(cols) == len(chars), (len(cols), len(chars))
		for (x0, x1), ch in zip(cols, chars):
			table[ch] = sheet.crop((x0, y0, x1, y1))
	return table

def main():
	text = sys.argv[1] if len(sys.argv) > 1 else "GULLIN' IT"
	scale = float(sys.argv[2]) if len(sys.argv) > 2 else 3
	table = glyphs(Image.open(SHEET).convert("RGBA"))
	cap = max(g.height for g in table.values())
	width = sum(WORD_GAP if c == " " else table[c].width + KERN for c in text) + 8
	canvas = Image.new("RGBA", (width, cap + 8))
	x = 4
	for c in text:
		if c == " ":
			x += WORD_GAP; continue
		g = table[c]
		canvas.alpha_composite(g, (x, 4))
		x += g.width + KERN
	box = canvas.getbbox()
	canvas = canvas.crop(box)
	h = round(DISPLAY_H * scale)
	canvas = canvas.resize((round(canvas.width * h / canvas.height), h), Image.LANCZOS)
	canvas.save(OUT)
	print(OUT, canvas.size, "display", (round(canvas.width / scale), DISPLAY_H))

main()
