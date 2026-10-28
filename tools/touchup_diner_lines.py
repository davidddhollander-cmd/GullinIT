"""Soften the interior near-black lines of the pier diner sheets to match the shoppers.

Recolour only: every opaque pixel keeps its place and alpha. Near-black pixels more than
two layers inside the silhouette are re-tinted to a dark shade of the surrounding fill.
The outer outline and all fills are untouched. Nothing is drawn.
"""
from collections import deque
from PIL import Image

SPRITES = "assets/sprites/"
SHEETS = {
    "pier-diner-a-base-candidate-v1.png": "pier-diner-a-base-touchup-v1.png",
    "pier-diner-a-motion-candidate-v1.png": "pier-diner-a-motion-touchup-v1.png",
    "pier-diner-a-reactions-candidate-v1.png": "pier-diner-a-reactions-touchup-v1.png",
    "pier-diner-b-base-v1.png": "pier-diner-b-base-touchup-v1.png",
    "pier-diner-b-motion-v1.png": "pier-diner-b-motion-touchup-v1.png",
    "pier-diner-b-reactions-v1.png": "pier-diner-b-reactions-touchup-v1.png",
}
CELL = 128
KEEP_LAYERS = 2  # outer silhouette layers left exactly as drawn
LINE_LUMA = 30   # near-black, the outline colour family
FILL_LUMA = 45   # what counts as surrounding fill
SHADE = 0.33     # interior line = this fraction of the neighbouring fill


def luma(p):
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def touch_up_cell(cell):
    px = cell.load()
    layer = [[0] * CELL for _ in range(CELL)]
    queue = deque()
    for y in range(CELL):
        for x in range(CELL):
            if px[x, y][3] == 0:
                continue
            edge = any(not (0 <= x + dx < CELL and 0 <= y + dy < CELL) or px[x + dx, y + dy][3] == 0
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                layer[y][x] = 1
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < CELL and 0 <= ny < CELL and px[nx, ny][3] > 0 and layer[ny][nx] == 0:
                layer[ny][nx] = layer[y][x] + 1
                queue.append((nx, ny))
    out = cell.copy()
    out_px = out.load()
    changed = 0
    for y in range(CELL):
        for x in range(CELL):
            p = px[x, y]
            if p[3] == 0 or layer[y][x] <= KEEP_LAYERS or luma(p) >= LINE_LUMA:
                continue
            fills = [px[nx, ny] for ny in range(max(0, y - 3), min(CELL, y + 4))
                     for nx in range(max(0, x - 3), min(CELL, x + 4))
                     if px[nx, ny][3] > 0 and luma(px[nx, ny]) >= FILL_LUMA]
            if not fills:
                continue
            avg = [sum(f[i] for f in fills) / len(fills) for i in range(3)]
            out_px[x, y] = (round(avg[0] * SHADE), round(avg[1] * SHADE), round(avg[2] * SHADE), 255)
            changed += 1
    return out, changed


for src, dst in SHEETS.items():
    sheet = Image.open(SPRITES + src).convert("RGBA")
    result = sheet.copy()
    total = 0
    for fy in range(sheet.height // CELL):
        for fx in range(sheet.width // CELL):
            box = (fx * CELL, fy * CELL, (fx + 1) * CELL, (fy + 1) * CELL)
            cell, n = touch_up_cell(sheet.crop(box))
            result.paste(cell, box[:2])
            total += n
    result.save(SPRITES + dst)
    print(dst, "recoloured", total, "px")
