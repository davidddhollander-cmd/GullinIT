"""Thin the outer outline of the live pier diner A sheets to about one game pixel.

The sheets use 400 px frames shown at visual_scale 0.11, so one game pixel is ~9 source px.
Outer near-black pixels further than KEEP source px from the coloured fill are made
transparent. Interior lines and all fills are untouched; nothing is drawn. Re-running is a no-op.
Run from the project root: python -I tools/thin_diner_a_outline.py
"""
from collections import deque
from PIL import Image

SHEETS = ["pier-diner-retro-clean.png", "pier-diner-motion-v2.png", "pier-diner-reactions-v1.png"]
KEEP = 9  # source px of outline kept against the fill (1 / 0.11)
DARK = 77  # max channel of an outline pixel


def thin(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    dark = [[px[x, y][3] > 0 and max(px[x, y][:3]) < DARK for x in range(w)] for y in range(h)]
    # Chebyshev distance from the fill, spreading through dark pixels only.
    dist = [[-1] * w for _ in range(h)]
    queue = deque()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0 and not dark[y][x]:
                dist[y][x] = 0
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and dark[ny][nx] and dist[ny][nx] < 0:
                    dist[ny][nx] = dist[y][x] + 1
                    queue.append((nx, ny))
    # Drop only the far outline that is reachable from outside, never enclosed dark detail.
    far = lambda x, y: dark[y][x] and (dist[y][x] < 0 or dist[y][x] > KEEP)
    seen = set()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and far(nx, ny):
                        seen.add((nx, ny))
                        queue.append((nx, ny))
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and far(nx, ny):
                seen.add((nx, ny))
                queue.append((nx, ny))
    for x, y in seen:
        px[x, y] = (0, 0, 0, 0)
    im.save(path)
    print(f"{path}: cleared {len(seen)} outline px")


if __name__ == "__main__":
    for sheet in SHEETS:
        thin("assets/sprites/" + sheet)
