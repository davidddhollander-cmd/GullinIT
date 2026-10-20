"""Package the rendered palm pilot, preserving its original speed and crisp pixels."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "test-output/palm-wind-pilot"
OUTPUT = ROOT / "assets/previews"
OUTPUT.mkdir(exist_ok=True)
paths = sorted(SOURCE.glob("[0-9][0-9][0-9].png"))
if len(paths) != 160:
    raise SystemExit(f"Expected 160 captured frames, found {len(paths)}")
frames = [Image.open(path).convert("RGB").resize((960,480),Image.Resampling.NEAREST) for path in paths]
palette = frames[0].quantize(colors=128)
gif = [frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
gif[0].save(OUTPUT / "palm-wind-pilot-v2.gif",save_all=True,append_images=gif[1:],duration=50,loop=0,optimize=True,disposal=1)
frames[40].save(OUTPUT / "palm-wind-pilot-v2.png")

# Capture checks are scoped to this reversible pilot: verify visible leaf
# movement and a pixel-identical trunk, ground, and still reference.
reference = frames[0]
leaf_changes = 0
for frame in frames[1:]:
    difference = ImageChops.difference(reference,frame)
    if difference.crop((380,145,580,304)).getbbox():
        leaf_changes += 1
    for box in [(0,0,320,480),(380,320,580,428),(750,360,850,428)]:
        if difference.crop(box).getbbox():
            raise SystemExit(f"Unexpected motion outside leaves in {box}")
if not leaf_changes:
    raise SystemExit("No visible leaf movement in pilot")

def review_frame(name):
    return Image.open(SOURCE / name).convert("RGB").resize((960,480),Image.Resampling.NEAREST)

calm = review_frame("calm.png")
still_crown = calm.crop((72,152,248,284))
calm_crown = calm.crop((392,152,568,284))
if ImageChops.difference(still_crown,calm_crown).getbbox():
    raise SystemExit("Calm crown differs from original still artwork")
if ImageChops.difference(reference,review_frame("loop-end.png")).getbbox():
    raise SystemExit("Eight-second loop endpoint differs from first frame")
if not ImageChops.difference(frames[40],review_frame("reverse.png")).getbbox():
    raise SystemExit("Reversing wind does not change leaf bend")
print(f"Pilot packaged: {leaf_changes} moving leaf frames; trunks and still reference fixed; calm, reversal and loop checks passed.")
