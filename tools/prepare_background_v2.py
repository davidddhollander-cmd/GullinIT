import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "reference" / "background-v2"
RUNTIME = ROOT / "assets" / "sprites" / "background-v2"
PREVIEWS = ROOT / "assets" / "previews"


def quantize_fixed(image: Image.Image, colors: list[tuple[int, int, int]]) -> Image.Image:
    palette = Image.new("P", (1, 1))
    flat_palette: list[int] = []
    for color in colors:
        flat_palette.extend(color)
    flat_palette.extend([0] * (768 - len(flat_palette)))
    palette.putpalette(flat_palette)
    return image.convert("RGB").quantize(
        palette=palette,
        dither=Image.Dither.NONE,
    ).convert("RGBA")


def prepare_sky() -> Image.Image:
    source = Image.open(SOURCE / "sky-clouds-source.png").convert("RGBA")
    crop_height = source.width // 4
    cropped = source.crop((0, 0, source.width, crop_height))
    sky = cropped.resize((320, 80), Image.Resampling.NEAREST)
    sky = quantize_fixed(
        sky,
        [
            (78, 190, 210),
            (91, 199, 216),
            (144, 208, 225),
            (184, 221, 233),
            (240, 240, 212),
            (255, 244, 218),
        ],
    )
    cloud_layer = Image.new("RGBA", sky.size, (0, 0, 0, 0))
    cloud_pixels = cloud_layer.load()
    sky_pixels = sky.load()
    for y in range(sky.height):
        for x in range(sky.width):
            pixel = sky_pixels[x, y]
            if pixel[0] >= 130:
                cloud_pixels[x, y] = pixel

    shifted_clouds = Image.new("RGBA", sky.size, (0, 0, 0, 0))
    shifted_source = cloud_layer.crop((0, 8, cloud_layer.width, cloud_layer.height))
    shifted_clouds.paste(shifted_source, (0, 0), shifted_source)
    sky = Image.new("RGBA", sky.size, (91, 199, 216, 255))
    sky = Image.alpha_composite(sky, shifted_clouds)
    sky.save(RUNTIME / "sky-clouds-320x80.png")
    return sky


def prepare_sun() -> Image.Image:
    source = Image.open(SOURCE / "sun-source.png").convert("RGBA")
    binary_alpha = source.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    bbox = binary_alpha.getbbox()
    if bbox is None:
        raise RuntimeError("Generated sun source has no opaque pixels")

    source = source.crop(bbox)
    binary_alpha = binary_alpha.crop(bbox)
    side = max(source.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    alpha_square = Image.new("L", (side, side), 0)
    offset = ((side - source.width) // 2, (side - source.height) // 2)
    square.paste(source, offset)
    alpha_square.paste(binary_alpha, offset)

    square = square.resize((34, 34), Image.Resampling.NEAREST)
    alpha_square = alpha_square.resize((34, 34), Image.Resampling.NEAREST)
    sun = Image.new("RGBA", square.size, (255, 226, 154, 255))
    sun.putalpha(alpha_square)
    sun.save(RUNTIME / "sun-34x34.png")
    return sun


# Sea palette, light to dark; sampled from the generated sea-source-v2 plate.
FAR = (96, 191, 190, 255)
NEAR_FAR = (78, 179, 179, 255)
TRANSITION = (52, 161, 161, 255)
BASE = (27, 143, 147, 255)
DEEP = (16, 121, 132, 255)
FOAM = (137, 207, 194, 255)
SEA_RAMP = (FOAM, FAR, NEAR_FAR, TRANSITION, BASE, DEEP)

# (first row, last row, colour). The far rows sit close to the sky's value.
SEA_BANDS = ((0, 1, FAR), (2, 3, NEAR_FAR), (4, 6, TRANSITION), (7, 18, BASE), (19, 39, DEEP))

# Shoal stage per frame: absent, quick growth, slower split and recession.
SHOAL_STAGES = (0, 0, 0, 0, 1, 2, 3, 4, 4, 5, 5, 5, 6, 6, 6, 0)
# Segments per stage as (left, right) offsets from the centre, and whether bright.
SHOAL_SHAPES = {
    1: (((-1, 1),), False),
    2: (((-2, 2),), False),
    3: (((-3, 3),), True),
    4: (((-5, -3), (-1, 1), (3, 5)), True),
    5: (((-4, -3), (0, 0), (3, 4)), False),
    6: (((-1, 0),), False),
}
# (centre x, row, phase offset) for 320 x 40 frames; offsets keep them out of step.
SHOALS = ((34, 2, 0), (98, 3, 6), (161, 2, 11), (228, 4, 3), (289, 3, 9))

# Dash brightness per frame: 0 absent, 1 muted, 2 mid, 3 bright.
DASH_LEVELS = (0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 2, 2, 1, 1, 0)
DASH_COUNT = 20


def band_color(y: int) -> tuple[int, int, int, int]:
    for first, last, color in SEA_BANDS:
        if first <= y <= last:
            return color
    raise ValueError(y)


def lighter(color: tuple[int, int, int, int], steps: int) -> tuple[int, int, int, int]:
    return SEA_RAMP[max(0, SEA_RAMP.index(color) - steps)]


def place_dashes() -> list[tuple[int, int, int, int]]:
    rng = random.Random(7)
    dashes: list[tuple[int, int, int, int]] = []
    while len(dashes) < DASH_COUNT:
        # Bias toward the lower sea; distant dashes are shorter.
        y = 8 + int(31 * rng.random() ** 0.7)
        length = 2 if y < 16 else rng.choice((3, 4))
        x = rng.randrange(0, 320 - length)
        if any(abs(y - oy) < 3 and abs(x - ox) < 14 for ox, oy, _, _ in dashes):
            continue
        phase = (len(dashes) * 16 // DASH_COUNT + rng.randrange(3)) % 16
        dashes.append((x, y, length, phase))
    return dashes


def prepare_sea() -> list[Image.Image]:
    base = Image.new("RGBA", (320, 40))
    base_draw = ImageDraw.Draw(base)
    for first, last, color in SEA_BANDS:
        base_draw.rectangle((0, first, 319, last), fill=color)

    dashes = place_dashes()
    frames: list[Image.Image] = []
    for frame_index in range(16):
        frame = base.copy()
        draw = ImageDraw.Draw(frame)

        for x, y, length, phase in dashes:
            age = (frame_index + phase) % 16
            level = DASH_LEVELS[age]
            if level == 0:
                continue
            # Short when muted, full length otherwise; drifts one pixel late in its life.
            shown = max(1, length - 1) if level == 1 else length
            dx = 1 if age >= 11 else 0
            left = x + dx + (length - shown) // 2
            draw.line((left, y, left + shown - 1, y), fill=lighter(band_color(y), level))

        for center, y, phase in SHOALS:
            stage = SHOAL_STAGES[(frame_index + phase) % 16]
            if stage == 0:
                continue
            segments, bright = SHOAL_SHAPES[stage]
            color = FOAM if bright else lighter(band_color(y), 1)
            for left, right in segments:
                draw.line((center + left, y, center + right, y), fill=color)

        frames.append(frame)

    for index, frame in enumerate(frames, start=1):
        frame.save(RUNTIME / f"sea-frame-{index:02d}.png")

    sheet = Image.new("RGBA", (1280, 160))
    for index, frame in enumerate(frames):
        sheet.paste(frame, ((index % 4) * 320, (index // 4) * 40))
    sheet.save(RUNTIME / "sea-4x4.png")
    return frames


def compose(sky: Image.Image, sun: Image.Image, sea_frames: list[Image.Image]) -> None:
    source_frames: list[Image.Image] = []
    for sea in sea_frames:
        composite = Image.new("RGBA", (320, 120), (0, 0, 0, 255))
        composite.paste(sky, (0, 0))
        composite.alpha_composite(sun, (250, 12))
        composite.paste(sea, (0, 80))
        source_frames.append(composite)

    source_frames[0].save(PREVIEWS / "background-v2-composite-320x120.png")
    display_frames = [
        frame.resize((1280, 480), Image.Resampling.NEAREST).convert("RGB")
        for frame in source_frames
    ]
    display_frames[0].save(PREVIEWS / "background-v2-composite.png")
    display_frames[0].save(
        PREVIEWS / "background-v2-composite.gif",
        save_all=True,
        append_images=display_frames[1:],
        duration=150,
        loop=0,
        disposal=2,
        optimize=False,
    )


def main() -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    sky = prepare_sky()
    sun = prepare_sun()
    sea_frames = prepare_sea()
    compose(sky, sun, sea_frames)
    print(f"Prepared background assets in {RUNTIME}")
    print(f"Prepared composite previews in {PREVIEWS}")


if __name__ == "__main__":
    main()
