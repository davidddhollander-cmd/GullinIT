"""Builds assets/fonts/gull_speech.fnt/.png for the trainer pop-ups.

GullPixel is capitals only (its lowercase codes alias the capitals) and has no comma, semicolon,
brackets or double quote. This keeps every GullPixel capital, digit and mark, and adds a real
lowercase set plus , ; ( ) " on a 10 px line (caps rows 1-7, x-height rows 3-7, descenders 8-9).
Run from the project root:  python tools/build_speech_font.py
"""
import re
from PIL import Image

LINE_HEIGHT = 10
BASE = 8
CAP_TOP = 1

# (top row, rows). '#' is a lit pixel.
NEW = {
	"a": (3, [".##.", "...#", ".###", "#..#", ".###"]),
	"b": (1, ["#...", "#...", "###.", "#..#", "#..#", "#..#", "###."]),
	"c": (3, [".##.", "#..#", "#...", "#..#", ".##."]),
	"d": (1, ["...#", "...#", ".###", "#..#", "#..#", "#..#", ".###"]),
	"e": (3, [".##.", "#..#", "####", "#...", ".###"]),
	"f": (1, [".##", "#..", "###", "#..", "#..", "#..", "#.."]),
	"g": (3, [".###", "#..#", "#..#", ".###", "...#", "#..#", ".##."]),
	"h": (1, ["#...", "#...", "###.", "#..#", "#..#", "#..#", "#..#"]),
	"i": (1, ["#", ".", "#", "#", "#", "#", "#"]),
	"j": (1, ["..#", "...", "..#", "..#", "..#", "..#", "..#", "#.#", ".#."]),
	"k": (1, ["#...", "#..#", "#.#.", "##..", "#.#.", "#..#", "#..#"]),
	"l": (1, ["##.", ".#.", ".#.", ".#.", ".#.", ".#.", ".##"]),
	"m": (3, ["##.#.", "#.#.#", "#.#.#", "#.#.#", "#.#.#"]),
	"n": (3, ["###.", "#..#", "#..#", "#..#", "#..#"]),
	"o": (3, [".##.", "#..#", "#..#", "#..#", ".##."]),
	"p": (3, ["###.", "#..#", "#..#", "###.", "#...", "#...", "#..."]),
	"q": (3, [".###", "#..#", "#..#", ".###", "...#", "...#", "...#"]),
	"r": (3, ["#.##", "##..", "#...", "#...", "#..."]),
	"s": (3, [".###", "#...", ".##.", "...#", "###."]),
	"t": (2, ["#..", "###", "#..", "#..", "#..", ".##"]),
	"u": (3, ["#..#", "#..#", "#..#", "#..#", ".###"]),
	"v": (3, ["#...#", "#...#", "#...#", ".#.#.", "..#.."]),
	"w": (3, ["#...#", "#...#", "#.#.#", "#.#.#", ".#.#."]),
	"x": (3, ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"]),
	"y": (3, ["#..#", "#..#", "#..#", ".###", "...#", "#..#", ".##."]),
	"z": (3, ["####", "...#", ".##.", "#...", "####"]),
	",": (6, [".#", ".#", "#."]),
	";": (3, [".#", ".#", "..", ".#", ".#", "#."]),
	"(": (1, ["..#", ".#.", "#..", "#..", "#..", "#..", "#..", ".#.", "..#"]),
	")": (1, ["#..", ".#.", "..#", "..#", "..#", "..#", "..#", ".#.", "#.."]),
	'"': (1, ["#.#", "#.#"]),
}


def main() -> None:
	source = Image.open("assets/fonts/gull_pixel.png").convert("RGBA")
	glyphs = []  # (code, bitmap Image, yoffset, xadvance)
	for line in open("assets/fonts/gull_pixel.fnt"):
		if not line.startswith("char id"):
			continue
		d = {k: int(v) for k, v in re.findall(r"(\w+)=(-?\d+)", line)}
		code = d["id"]
		if 97 <= code <= 122:
			continue  # aliases of the capitals; replaced by real lowercase
		crop = source.crop((d["x"], d["y"], d["x"] + d["width"], d["y"] + d["height"]))
		glyphs.append((code, crop, CAP_TOP + d["yoffset"], d["xadvance"]))
	for char, (top, rows) in NEW.items():
		width = len(rows[0])
		bitmap = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
		for y, row in enumerate(rows):
			assert len(row) == width, (char, row)
			for x, cell in enumerate(row):
				if cell == "#":
					bitmap.putpixel((x, y), (255, 255, 255, 255))
		glyphs.append((ord(char), bitmap, top, width + 1))
	glyphs.sort(key=lambda g: g[0])

	atlas_w = 128
	x = y = row_h = 0
	placed = []
	for code, bitmap, yoffset, advance in glyphs:
		w, h = bitmap.size
		if x + w + 1 > atlas_w:
			x = 0
			y += row_h + 1
			row_h = 0
		placed.append((code, bitmap, x, y, yoffset, advance))
		x += w + 1
		row_h = max(row_h, h)
	atlas_h = 8
	while atlas_h < y + row_h:
		atlas_h *= 2
	atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
	lines = [
		'info face="GullSpeech" size=10 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
		"common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % (LINE_HEIGHT, BASE, atlas_w, atlas_h),
		'page id=0 file="gull_speech.png"',
		"chars count=%d" % len(placed),
	]
	for code, bitmap, px, py, yoffset, advance in placed:
		atlas.paste(bitmap, (px, py))
		lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15" % (code, px, py, bitmap.width, bitmap.height, yoffset, advance))
	atlas.save("assets/fonts/gull_speech.png")
	open("assets/fonts/gull_speech.fnt", "w", newline="\n").write("\n".join(lines) + "\n")
	print("glyphs:", len(placed), "atlas:", atlas.size)


if __name__ == "__main__":
	main()
