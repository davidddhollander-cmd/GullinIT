"""Make a looping review GIF from the generated screech atlas."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
ATLAS = ROOT / "assets/sprites/gull-herring-screech-v1.png"
OUTPUT = ROOT / "assets/previews/gull-herring-screech-v1.gif"


def main() -> None:
    atlas = Image.open(ATLAS).convert("RGBA")
    frames = []
    for index in range(6):
        cell = atlas.crop(((index % 3) * 256, (index // 3) * 256,
                           (index % 3 + 1) * 256, (index // 3 + 1) * 256))
        cell = cell.resize((768, 768), Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (320, 300), "#a9d5ce")
        draw = ImageDraw.Draw(canvas)
        draw.rectangle((0, 245, 319, 299), fill="#e5c68c")
        canvas.alpha_composite(cell, (-234, -180))
        frames.append(canvas.convert("RGB"))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(OUTPUT, save_all=True, append_images=frames[1:],
                   duration=[180, 140, 140, 180, 230, 160], loop=0,
                   optimize=False)


if __name__ == "__main__":
    main()
