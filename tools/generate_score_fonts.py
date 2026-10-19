"""Build Godot BMFont descriptors from the generated arcade score sheets.

The source sheets contain uppercase letters, digits, and punctuation in four
separate rows.  We derive glyph rectangles from the alpha channel so the
descriptors remain reproducible if either color treatment is regenerated with
the same layout.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
SHEETS = (
    ("ArcadeScoreBlue", "beach-arcade-font-sprite-sheet-v2.png", "arcade_score_blue.fnt"),
    ("ArcadeScoreHot", "beach-arcade-font-sprite-sheet-v3.png", "arcade_score_hot.fnt"),
)
ROW_GLYPHS = (
    "ABCDEFGHIJKLM",
    "NOPQRSTUVWXYZ",
    "0123456789",
    ".!?,:;+-×/=()[]'\"",
)


def contiguous_runs(values: list[int]) -> list[tuple[int, int]]:
    runs: list[list[int]] = []
    for value in values:
        if not runs or value > runs[-1][-1] + 1:
            runs.append([value])
        else:
            runs[-1].append(value)
    return [(run[0], run[-1]) for run in runs]


def glyph_rects(image: Image.Image) -> list[tuple[str, tuple[int, int, int, int]]]:
    alpha = image.getchannel("A")
    width, height = image.size
    pixels = alpha.load()
    occupied_rows = [
        y for y in range(height)
        if sum(pixels[x, y] > 32 for x in range(width)) > 5
    ]
    row_runs = contiguous_runs(occupied_rows)
    if len(row_runs) != len(ROW_GLYPHS):
        raise RuntimeError(f"Expected {len(ROW_GLYPHS)} rows, found {row_runs}")

    result: list[tuple[str, tuple[int, int, int, int]]] = []
    for (top, bottom), glyphs in zip(row_runs, ROW_GLYPHS, strict=True):
        occupied_columns = [
            x for x in range(width)
            if any(pixels[x, y] > 32 for y in range(top, bottom + 1))
        ]
        column_runs = contiguous_runs(occupied_columns)
        if len(column_runs) != len(glyphs):
            raise RuntimeError(
                f"Expected {len(glyphs)} glyphs in row {top}-{bottom}, found {column_runs}"
            )
        for glyph, (left, right) in zip(glyphs, column_runs, strict=True):
            result.append((glyph, (left, top, right - left + 1, bottom - top + 1)))
    return result


def build_font(face: str, image_name: str, output_name: str) -> None:
    image_path = ASSETS / image_name
    image = Image.open(image_path).convert("RGBA")
    rects = glyph_rects(image)
    line_height = max(rect[3] for _, rect in rects)
    lines = [
        f'info face="{face}" size={line_height} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0',
        f"common lineHeight={line_height} base={line_height} scaleW={image.width} scaleH={image.height} pages=1 packed=0",
        f'page id=0 file="{image_name}"',
        f"chars count={len(rects) + 1}",
        "char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=54 page=0 chnl=15",
    ]
    for glyph, (x, y, width, height) in rects:
        lines.append(
            "char id={code} x={x} y={y} width={width} height={height} "
            "xoffset=0 yoffset=0 xadvance={advance} page=0 chnl=15".format(
                code=ord(glyph), x=x, y=y, width=width, height=height, advance=width + 8
            )
        )
    (ASSETS / output_name).write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    for font in SHEETS:
        build_font(*font)
