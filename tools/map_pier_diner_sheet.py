"""Map the untouched retro pier-diner sheet into aligned Godot atlas frames."""
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/sprites/pier-diner-retro-large-pixels.png"
MOTION = ROOT / "assets/sprites/pier-diner-motion-large-pixels.png"
SPRITES = ROOT / "data/sprites.json"
CURATED = ROOT / "data/pier_diner_art.json"
FRAME_W = 400
FRAME_H = 400


def animation(frames, fps=1, loop=True):
    return {"frames": frames, "fps": fps, "loop": loop}


def map_regions(source):
    image = Image.open(source).convert("RGBA")
    regions = []
    for index in range(12):
        col, row = index % 4, index // 4
        left = round(col * image.width / 4)
        top = round(row * image.height / 3)
        right = round((col + 1) * image.width / 4)
        bottom = round((row + 1) * image.height / 3)
        cell = image.crop((left, top, right, bottom))
        bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0).getbbox()
        if bounds is None:
            raise ValueError(f"Empty pier diner frame {index}")
        x, y, x2, y2 = bounds
        # A fixed cell centre preserves pose-to-pose body movement; every foot
        # rests on the same logical baseline. Source pixels are not changed.
        regions.append({
            "region": [left + x, top + y, x2 - x, y2 - y],
            "offset": [round(FRAME_W / 2 + x - cell.width / 2), FRAME_H + y - y2],
        })
    return regions

entry = {
    "file": "res://assets/sprites/pier-diner-retro-large-pixels.png",
    "frame_w": FRAME_W,
    "frame_h": FRAME_H,
    "visual_scale": 0.11,
    "regions": map_regions(SOURCE),
    "animations": {
        "idle": animation([0, 1, 2, 3], 3),
        "notice": animation([4], 1),
        "watch": animation([5], 1),
        "alert": animation([6], 1),
        "brace": animation([7], 1),
        "windup": animation([8], 1),
        "swat": animation([9, 10], 9, False),
        "angry": animation([11], 1),
    },
    "food_anchors": {
        "idle": [[14, -22], [11, -25], [14, -22], [14, -22]],
        "notice": [[14, -22]],
        "watch": [[14, -22]],
        "alert": [[-8, -24]],
        "brace": [[17, -26]],
        "windup": [[14, -22]],
        "swat": [[-10, -24], [-9, -24]],
        "angry": [[9, -19]],
    },
}

motion = {
    "file": "res://assets/sprites/pier-diner-motion-large-pixels.png",
    "frame_w": FRAME_W,
    "frame_h": FRAME_H,
    "visual_scale": 0.11,
    "regions": map_regions(MOTION),
    "animations": {
        "walk": animation([0, 1, 2, 3], 7),
        "run": animation([4, 5, 6, 7], 10),
        "eat": animation([8, 9, 10, 11], 5),
    },
    "food_anchors": {
        "walk": [[10, -22], [10, -22], [10, -22], [10, -22]],
        "run": [[16, -24], [15, -24], [16, -24], [15, -24]],
        "eat": [[14, -22], [7, -31], [7, -31], [14, -22]],
    },
}

sprites = json.loads(SPRITES.read_text(encoding="utf-8-sig"))
sprites["pier_diner"] = entry
sprites["pier_diner_motion"] = motion
SPRITES.write_text(json.dumps(sprites, indent=2) + "\n", encoding="utf-8")
CURATED.write_text(json.dumps({"pier_diner": entry, "pier_diner_motion": motion}, indent=2) + "\n", encoding="utf-8")
print("Mapped retro pier diner pose and motion frames without altering source pixels.")
