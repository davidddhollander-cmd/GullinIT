"""Assemble production-rendered frames. This never draws character artwork."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
prefix = "bench-snack-yellow-proof-v1" if "--yellow" in sys.argv else "bench-snack-v1"
paths = sorted((root / "test-output/bench-frames").glob("*.png"))
assert len(paths) == 220, "Run tools/bench_snack_preview.tscn first"
frames = [Image.open(path).convert("RGB").resize((640, 280), Image.Resampling.NEAREST) for path in paths]
output = root / "assets/previews"
frames[0].save(output / f"{prefix}.gif", save_all=True, append_images=frames[1:], duration=80, loop=0, optimize=False)
if "--yellow" not in sys.argv:
    for number, label in [(80, "seated"), (87, "standing-after-theft"), (97, "eat-and-chase"), (185, "resume")]:
        Image.open(paths[number]).save(output / f"bench-snack-{label}-v1.png")
    sheet = Image.new("RGB", (1280, 900), "#183b4e")
    draw = ImageDraw.Draw(sheet)
    for tile, (number, label) in enumerate([(10, "APPROACH"), (70, "SIT"), (80, "SEATED / REAL SNACK"), (87, "THEFT / STAND"), (97, "EAT LEFT / CHASE RIGHT"), (205, "DEPART / RESUME")]):
        x, y = (tile % 2) * 640, (tile // 2) * 300
        sheet.paste(frames[number], (x, y + 20))
        draw.text((x + 8, y + 4), f"{label} / {number * .08:.2f}s", fill="#fff4da")
    sheet.save(output / "bench-snack-contact-sheet-v1.png")
print(output / f"{prefix}.gif")
