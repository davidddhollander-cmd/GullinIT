"""Package real game render captures as a short review animation."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
paths = sorted((ROOT / "test-output/gull-tumble").glob("[0-9][0-9][0-9].png"))
assert len(paths) == 36, f"Expected 36 frames, found {len(paths)}"
frames = [Image.open(path).convert("RGB") for path in paths]
palette = frames[0].quantize(colors=192)
sequence = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
output = ROOT / "assets/previews"
sequence[0].save(output / "gull-tumble-v1.gif", save_all=True, append_images=sequence[1:], duration=50, loop=0, optimize=True)
frames[10].save(output / "gull-tumble-v1.png")
print("Packaged gull tumble preview: 36 frames at 20 fps.")
