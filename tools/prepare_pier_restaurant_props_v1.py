from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "reference" / "pier-restaurant-props-v1"
SPRITE_DIR = ROOT / "assets" / "sprites" / "pier-restaurant-props-v1"
PREVIEW_DIR = ROOT / "assets" / "previews"

# Exact union used by the existing pier, food-stand, and beach-chair runtime art.
PALETTE = (
    (24, 59, 78),
    (40, 102, 123),
    (64, 143, 168),
    (75, 136, 183),
    (97, 119, 130),
    (142, 155, 158),
    (117, 74, 57),
    (155, 102, 80),
    (170, 112, 71),
    (185, 77, 78),
    (213, 154, 94),
    (198, 154, 104),
    (238, 183, 127),
    (232, 197, 142),
    (239, 114, 92),
    (255, 244, 218),
)

ASSETS = (
    ("pier-wire-fence-source.png", "pier-wire-fence-v1.png", (72, 24)),
    ("two-counter-restaurant-source.png", "two-counter-restaurant-v1.png", (132, 88)),
    ("restaurant-table-chairs-source.png", "restaurant-table-chairs-v1.png", (60, 34)),
)


def nearest_palette(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    r, g, b = rgb
    return min(
        PALETTE,
        key=lambda color: (
            2 * (r - color[0]) ** 2
            + 4 * (g - color[1]) ** 2
            + 3 * (b - color[2]) ** 2
        ),
    )


def prepare_sprite(source_name: str, output_name: str, target: tuple[int, int]) -> Image.Image:
    source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"Source has no visible pixels: {source_name}")

    cropped = source.crop(bbox)
    available_w = target[0] - 2
    available_h = target[1] - 2
    scale = min(available_w / cropped.width, available_h / cropped.height)
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.NEAREST,
    )

    output = Image.new("RGBA", target, (0, 0, 0, 0))
    x_offset = (target[0] - resized.width) // 2
    y_offset = target[1] - resized.height - 1
    output.alpha_composite(resized, (x_offset, y_offset))

    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            r, g, b, a = pixels[x, y]
            if a < 128:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                nr, ng, nb = nearest_palette((r, g, b))
                pixels[x, y] = (nr, ng, nb, 255)

    output.save(SPRITE_DIR / output_name, optimize=True)
    return output


def build_composition(sprites: dict[str, Image.Image]) -> None:
    background_path = PREVIEW_DIR / "background-v2-composite-320x120.png"
    if background_path.exists():
        scene = Image.open(background_path).convert("RGBA")
    else:
        scene = Image.new("RGBA", (320, 120), (90, 194, 211, 255))

    if scene.size != (320, 120):
        scene = scene.resize((320, 120), Image.Resampling.NEAREST)

    composed = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    composed.alpha_composite(scene, (0, 0))
    draw = ImageDraw.Draw(composed)
    draw.rectangle((0, 120, 319, 179), fill=(232, 197, 142, 255))
    draw.rectangle((0, 120, 319, 122), fill=(155, 102, 80, 255))
    draw.rectangle((0, 173, 319, 176), fill=(117, 74, 57, 255))
    draw.rectangle((0, 177, 319, 179), fill=(213, 154, 94, 255))
    for x, y, width in ((15, 147, 7), (48, 165, 4), (84, 137, 6), (201, 153, 5), (294, 163, 8)):
        draw.rectangle((x, y, x + width, y + 1), fill=(213, 154, 94, 255))

    fence = sprites["pier-wire-fence-v1.png"]
    restaurant = sprites["two-counter-restaurant-v1.png"]
    furniture = sprites["restaurant-table-chairs-v1.png"]
    composed.alpha_composite(fence, (4, 109))
    composed.alpha_composite(fence, (244, 109))
    composed.alpha_composite(restaurant, (78, 84))
    composed.alpha_composite(furniture, (242, 138))

    native_path = PREVIEW_DIR / "pier-restaurant-props-v1-composition-320x180.png"
    composed.save(native_path, optimize=True)
    composed.resize((1280, 720), Image.Resampling.NEAREST).save(
        PREVIEW_DIR / "pier-restaurant-props-v1-composition.png",
        optimize=True,
    )


def main() -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    sprites = {
        output_name: prepare_sprite(source_name, output_name, target)
        for source_name, output_name, target in ASSETS
    }
    build_composition(sprites)


if __name__ == "__main__":
    main()
