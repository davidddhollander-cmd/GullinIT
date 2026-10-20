"""Crop and resize generated feather artwork; preserve the complete source RGBA."""
from pathlib import Path
import json

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/reference/gull-feathers-v1/source.png"
NAMES = ["down", "gray", "tip", "fluff"]
image = Image.open(SOURCE).convert("RGBA")
regions = []
for index, name in enumerate(NAMES):
    x = (index % 2) * (image.width // 2)
    y = (index // 2) * (image.height // 2)
    part = image.crop((x, y, x + image.width // 2, y + image.height // 2))
    # Use the solid feather's bounds, retaining the original alpha within the crop.
    bounds = part.getchannel("A").point(lambda a: 255 if a >= 192 else 0).getbbox()
    assert bounds is not None
    part = part.crop(bounds)
    part.thumbnail((24, 24), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (28, 28))
    canvas.paste(part, ((28 - part.width) // 2, (28 - part.height) // 2))
    output = ROOT / f"assets/sprites/feather-{name}-v1.png"
    canvas.save(output)
    regions.append({"file": str(output.relative_to(ROOT)), "source_bounds": [x+bounds[0], y+bounds[1], x+bounds[2], y+bounds[3]]})
(SOURCE.parent / "crops.json").write_text(json.dumps(regions, indent=2) + "\n")
print("Prepared four generated feather textures; source alpha preserved.")
