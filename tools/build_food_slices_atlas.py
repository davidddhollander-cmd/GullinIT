"""Promotes the pizza slices and ice-cream cones from the Art Lab food preview atlas into a shipped atlas.

Usage:  python tools/build_food_slices_atlas.py
assets/lab/ is excluded from exports, so the art is copied (pixel-exact, no resampling) into
assets/sprites/food-slices-icecream-v1.png. Prints the sprite defs for data/sprites.json and data/food_art.json.
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/lab/food-icons-v1"
OUT = ROOT / "assets/sprites/food-slices-icecream-v1.png"
# manifest n -> food id (n 1..9 pizza slices, 28-31 and 33 ice-cream cones)
FOODS = {1: "pizza_slice_cheese", 2: "pizza_slice_pepperoni", 3: "pizza_slice_mushroom", 4: "pizza_slice_veggie",
	5: "pizza_slice_hawaiian", 6: "pizza_slice_white", 7: "pizza_slice_ham_corn", 8: "pizza_slice_rocket",
	9: "pizza_slice_basil", 28: "ice_cream_vanilla", 29: "ice_cream_chocolate", 30: "ice_cream_strawberry",
	31: "ice_cream_mint", 33: "ice_cream_swirl"}

items = {i["n"]: i for i in json.loads((SRC / "manifest.json").read_text())["items"]}
atlas = Image.open(SRC / "food-icons-atlas-v1.png").convert("RGBA")
cells = [(FOODS[n], items[n]["region"]) for n in FOODS]
out = Image.new("RGBA", (sum(r[2] + 1 for _, r in cells), max(r[3] for _, r in cells)), (0, 0, 0, 0))
sprites, x = {}, 0
for food, (sx, sy, w, h) in cells:
	out.paste(atlas.crop((sx, sy, sx + w, sy + h)), (x, 0))
	sprites["food_" + food] = {"file": "res://assets/sprites/" + OUT.name, "frame_w": w, "frame_h": h,
		"regions": [{"region": [x, 0, w, h], "offset": [0, 0]}], "animations": {"idle": {"frames": [0], "fps": 1, "loop": True}}}
	x += w + 1
out.save(OUT)
print(json.dumps(sprites, indent=2))
