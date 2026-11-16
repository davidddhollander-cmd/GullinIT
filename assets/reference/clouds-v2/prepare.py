"""Technical preparation only: crop generated art, clean alpha/palette, pack.

Run from any directory with Python + Pillow. No sprite is resized or painted.
"""
from collections import deque
from pathlib import Path
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / "assets/sprites/background-v2"
PALETTE = [(255, 244, 218), (142, 155, 158)]
SPECS = [
    ("fair-wisp-01", "fair", "small", (25, 20, 110, 80), .5),
    ("fair-wisp-02", "fair", "small", (225, 35, 285, 80), .5),
    ("fair-wisp-03", "fair", "small", (380, 35, 440, 80), .5),
    ("fair-medium-01", "fair", "medium", (535, 30, 625, 85), .5),
    ("fair-medium-02", "fair", "medium", (55, 110, 140, 170), .5),
    ("fair-medium-03", "fair", "medium", (200, 110, 300, 170), .5),
    ("fair-large-01", "fair", "large", (420, 150, 650, 270), .5),
    ("fair-large-02", "fair", "large", (495, 100, 655, 175), .5),
    ("wind-streak-01", "windy", "streak", (35, 205, 150, 250), .5),
    ("wind-streak-02", "windy", "streak", (180, 205, 320, 250), .5),
    ("wind-streak-03", "windy", "streak", (335, 205, 485, 250), .5),
    ("wind-streak-04", "windy", "streak", (495, 205, 665, 250), .5),
]


def clean(crop):
    # Binary alpha removes generated translucent fringe. Keep the largest
    # 8-connected cloud component; detached generation specks are not artwork.
    points = {(x, y) for y in range(crop.height) for x in range(crop.width)
              if crop.getpixel((x, y))[3] >= 128}
    components = []
    while points:
        seed = points.pop()
        component = {seed}
        todo = deque([seed])
        while todo:
            x, y = todo.popleft()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    at = (x + dx, y + dy)
                    if at in points:
                        points.remove(at)
                        component.add(at)
                        todo.append(at)
        components.append(component)
    cloud = max(components, key=len)
    result = Image.new("RGBA", crop.size)
    for x, y in cloud:
        rgb = crop.getpixel((x, y))[:3]
        color = min(PALETTE, key=lambda c: sum((a-b)**2 for a,b in zip(rgb,c)))
        result.putpixel((x, y), (*color, 255))
    return result.crop(result.getbbox())


def main():
    source = Image.open(HERE / "clouds-source.png").convert("RGBA")
    large = Image.open(HERE / "clouds-large-source.png").convert("RGBA")
    wisp = Image.open(HERE / "clouds-wisp-source.png").convert("RGBA")
    cell_w, cell_h, padding = 192, 112, 8
    atlas = Image.new("RGBA", (cell_w * 4, cell_h * 3))
    entries = []
    for i, (name, group, size, box, scale) in enumerate(SPECS):
        original = large if name == "fair-large-01" else wisp if name == "fair-wisp-01" else source
        sprite = clean(original.crop(box))
        assert sprite.width <= cell_w - 2 * padding
        assert sprite.height <= cell_h - 2 * padding
        # Even top-left positions help consumers drawing at half scale.
        x = i % 4 * cell_w + ((cell_w - sprite.width) // 4) * 2
        y = i // 4 * cell_h + ((cell_h - sprite.height) // 4) * 2
        atlas.paste(sprite, (x, y))
        entry = dict(id=name, set=group, size=size,
                     region=[x, y, sprite.width, sprite.height],
                     recommended_scale=scale,
                     display_size=[sprite.width * scale, sprite.height * scale],
                     source="clouds-large-source.png" if original is large else "clouds-wisp-source.png" if original is wisp else "clouds-source.png",
                     source_crop=list(box))
        entries.append(entry)
    OUT.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT / "clouds-v2.png")
    metadata = dict(version=1, image="clouds-v2.png", size=list(atlas.size),
                    grid=dict(columns=4, rows=3, cell_size=[cell_w, cell_h], minimum_padding=padding),
                    region_format="[x,y,width,height], top-left origin, tightly cropped, unscaled source pixels",
                    palette=["#fff4da", "#8e9b9e"],
                    alpha="binary: 0 or 255", clouds=entries)
    (OUT / "clouds-v2.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    # Structural acceptance checks, independent of the game's runtime tests.
    assert len(entries) == len({c['id'] for c in entries}) == 12
    assert sum(c['set'] == 'fair' for c in entries) == 8
    assert sum(c['set'] == 'windy' for c in entries) == 4
    assert set(atlas.getchannel('A').get_flattened_data()) == {0, 255}
    assert {p[:3] for p in atlas.get_flattened_data() if p[3]} <= set(PALETTE)
    for entry in entries:
        print(entry['id'], entry['region'][2:], 'display', entry['display_size'])
    print('Atlas checks passed: 12 unique IDs, 8 fair + 4 windy, gutters, binary alpha, exact palette.')


if __name__ == '__main__':
    main()
