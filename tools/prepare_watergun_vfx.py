from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "reference" / "watergun-teen-v1"
SPRITE_DIR = ROOT / "assets" / "sprites" / "watergun-teen-v1"
PREVIEW_DIR = ROOT / "assets" / "previews" / "watergun-teen-v1"

ALPHA_CUTOFF = 128
HIGHLIGHT = (0xE8, 0xFB, 0xFF, 255)
MID_BLUE = (0x6E, 0xC6, 0xF0, 255)
TRANSPARENT = (0, 0, 0, 0)

SHEETS = {
    "water-stream-v1.png": {
        "source": "water-stream-source.png",
        "frames": 4,
        "cell": (20, 12),
        "max_visible": (16, 6),
        "alignment": "center",
    },
    "water-muzzle-v1.png": {
        "source": "water-muzzle-source.png",
        "frames": 3,
        "cell": (16, 12),
        "max_visible": (12, 7),
        "alignment": "left",
    },
    "water-splash-v1.png": {
        "source": "water-splash-source.png",
        "frames": 5,
        "cell": (24, 24),
        "max_visible": (22, 17),
        "alignment": "bottom",
    },
}


def hard_palette(image: Image.Image) -> Image.Image:
    """Reduce generated pixels to the approved two-colour water palette."""
    output = Image.new("RGBA", image.size, TRANSPARENT)
    source = image.convert("RGBA")
    src = source.load()
    dst = output.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = src[x, y]
            if alpha < ALPHA_CUTOFF:
                continue
            # The source's pale cores remain highlights; all cyan edge shades
            # collapse to the placeholder's approved mid blue.
            brightness = red * 0.22 + green * 0.68 + blue * 0.10
            dst[x, y] = HIGHLIGHT if brightness >= 205 else MID_BLUE
    return output


def split_frames(source: Image.Image, count: int) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for index in range(count):
        left = round(index * source.width / count)
        right = round((index + 1) * source.width / count)
        frame = hard_palette(source.crop((left, 0, right, source.height)))
        bbox = frame.getchannel("A").getbbox()
        if bbox is None:
            raise ValueError(f"Generated frame {index} has no visible pixels")
        frames.append(frame.crop(bbox))
    return frames


def prepare_sheet(details: dict) -> Image.Image:
    source = Image.open(SOURCE_DIR / details["source"]).convert("RGBA")
    frames = split_frames(source, details["frames"])
    max_width = max(frame.width for frame in frames)
    max_height = max(frame.height for frame in frames)
    target_width, target_height = details["max_visible"]
    scale = min(target_width / max_width, target_height / max_height)
    cell_width, cell_height = details["cell"]
    sheet = Image.new(
        "RGBA", (cell_width * len(frames), cell_height), TRANSPARENT
    )
    for index, frame in enumerate(frames):
        resized = frame.resize(
            (
                max(1, round(frame.width * scale)),
                max(1, round(frame.height * scale)),
            ),
            Image.Resampling.NEAREST,
        )
        resized = hard_palette(resized)
        if details["alignment"] == "left":
            x = 1
            y = (cell_height - resized.height) // 2
        elif details["alignment"] == "bottom":
            x = (cell_width - resized.width) // 2
            y = cell_height - resized.height - 1
        else:
            x = (cell_width - resized.width) // 2
            y = (cell_height - resized.height) // 2
        sheet.alpha_composite(resized, (index * cell_width + x, y))
    return sheet


def main() -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    prepared: list[tuple[str, Image.Image]] = []
    for filename, details in SHEETS.items():
        sheet = prepare_sheet(details)
        sheet.save(SPRITE_DIR / filename, optimize=True)
        prepared.append((filename, sheet))

    preview_height = 12 + sum(sheet.height * 4 + 6 for _name, sheet in prepared)
    preview = Image.new("RGBA", (160, preview_height), (90, 194, 211, 255))
    y = 12
    for _filename, sheet in prepared:
        enlarged = sheet.resize(
            (sheet.width * 4, sheet.height * 4), Image.Resampling.NEAREST
        )
        x = (preview.width - enlarged.width) // 2
        preview.alpha_composite(enlarged, (x, y))
        y += enlarged.height + 6
    preview.save(PREVIEW_DIR / "watergun-vfx-v1-preview.png", optimize=True)


if __name__ == "__main__":
    main()
