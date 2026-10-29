from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "reference" / "watergun-teen-v1"
SPRITE_DIR = ROOT / "assets" / "sprites" / "watergun-teen-v1"
PREVIEW_DIR = ROOT / "assets" / "previews" / "watergun-teen-v1"

FRAME_SIZE = 128
SHEET_COLUMNS = 8
BASELINE_Y = 116
TARGET_STANDING_HEIGHT = 80
ALPHA_CUTOFF = 128

SOURCES = {
    "idle": ("watergun-teen-idle-source.png", 4, 1),
    "locomotion": ("watergun-teen-locomotion-source.png", 6, 2),
    "actions": ("watergun-teen-actions-source.png", 6, 2),
    "reactions": ("watergun-teen-reactions-source.png", 6, 2),
    "seated": ("watergun-teen-seated-source.png", 4, 2),
    "shooting": ("watergun-teen-shooting-source.png", 3, 3),
}

# Source index is row-major within each generated sheet. Repeated/reversed entries
# intentionally reuse complete generated poses; no character pixels are drawn here.
FRAME_MAP = [
    *(('idle', index) for index in range(4)),
    *(('locomotion', index) for index in range(6)),
    *(('locomotion', index) for index in range(6, 12)),
    ('actions', 0),
    ('actions', 1),
    ('actions', 2), ('actions', 3), ('actions', 2),
    ('actions', 4), ('actions', 5),
    *(('actions', index) for index in range(6, 12)),
    *(('reactions', index) for index in range(6)),
    *(('reactions', index) for index in range(6, 12)),
    *(('seated', index) for index in range(4)),
    *(('seated', index) for index in range(4, 8)),
    ('seated', 3), ('seated', 2), ('seated', 1), ('seated', 0),
    *(('shooting', index) for index in range(9)),
]

ANIMATIONS = {
    "idle": ([0, 1, 2, 3], 3, True),
    "walk": (list(range(4, 10)), 8, True),
    "run": (list(range(10, 16)), 10, True),
    "alert": ([16], 2, True),
    "warning": ([17], 2, True),
    "angry": ([18, 19, 20], 4, False),
    "windup": ([21, 22], 4, True),
    "swat": (list(range(23, 29)), 10, False),
    "surprise": (list(range(29, 35)), 14, False),
    "fist_shake": (list(range(35, 41)), 7, False),
    "sit_down": (list(range(41, 45)), 8, False),
    "seated_idle": (list(range(45, 49)), 3, True),
    "stand_up": (list(range(49, 53)), 8, False),
    "shoot_high": ([53, 54, 55], 10, False),
    "shoot_level": ([56, 57, 58], 10, False),
    "shoot_low": ([59, 60, 61], 10, False),
}


def hard_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, 255 if a >= ALPHA_CUTOFF else 0)
    return image


def keep_main_figure(image: Image.Image) -> Image.Image:
    """Remove distant generated specks without redrawing any character pixels."""
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value else 0)
    pixels = mask.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(mask.height):
        for x in range(mask.width):
            if not pixels[x, y] or (x, y) in visited:
                continue
            stack = [(x, y)]
            visited.add((x, y))
            component: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if (
                        0 <= nx < mask.width
                        and 0 <= ny < mask.height
                        and pixels[nx, ny]
                        and (nx, ny) not in visited
                    ):
                        visited.add((nx, ny))
                        stack.append((nx, ny))
            components.append(component)

    if not components:
        return image
    main = max(components, key=len)
    main_box = (
        min(point[0] for point in main),
        min(point[1] for point in main),
        max(point[0] for point in main),
        max(point[1] for point in main),
    )

    def gap_to_main(component: list[tuple[int, int]]) -> int:
        box = (
            min(point[0] for point in component),
            min(point[1] for point in component),
            max(point[0] for point in component),
            max(point[1] for point in component),
        )
        horizontal = max(main_box[0] - box[2] - 1, box[0] - main_box[2] - 1, 0)
        vertical = max(main_box[1] - box[3] - 1, box[1] - main_box[3] - 1, 0)
        return max(horizontal, vertical)

    minimum_part_area = max(8, round(len(main) * 0.025))
    kept_components = [
        component
        for component in components
        if component is main
        or (len(component) >= minimum_part_area and gap_to_main(component) <= 4)
    ]
    keep = {point for component in kept_components for point in component}
    source = image.load()
    original_mask = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            if original_mask[x, y] and (x, y) not in keep:
                r, g, b, _ = source[x, y]
                source[x, y] = (r, g, b, 0)
    return image


def split_grid(
    image: Image.Image,
    columns: int,
    rows: int,
    row_boundaries: list[int] | None = None,
) -> list[Image.Image]:
    frames: list[Image.Image] = []
    boundaries = row_boundaries or [round(row * image.height / rows) for row in range(rows + 1)]
    for row in range(rows):
        top = boundaries[row]
        bottom = boundaries[row + 1]
        for column in range(columns):
            left = round(column * image.width / columns)
            right = round((column + 1) * image.width / columns)
            frames.append(hard_alpha(image.crop((left, top, right, bottom))))
    return frames


def prepare_source_frames() -> dict[str, list[Image.Image]]:
    raw: dict[str, list[Image.Image]] = {}
    for name, (filename, columns, rows) in SOURCES.items():
        image = Image.open(SOURCE_DIR / filename).convert("RGBA")
        if name == "shooting":
            # Image generation placed the row-one shoes below the mathematical
            # thirds. Use the actual transparent gutters so adjacent feet do
            # not leak into the next aiming row.
            row_boundaries = [0, round(image.height * 0.37), round(image.height * 0.70), image.height]
            raw[name] = split_grid(image, columns, rows, row_boundaries)
        else:
            raw[name] = split_grid(image, columns, rows)

    prepared: dict[str, list[Image.Image]] = {}
    for name, frames in raw.items():
        bboxes = [frame.getchannel("A").getbbox() for frame in frames]
        valid_heights = [bbox[3] - bbox[1] for bbox in bboxes if bbox is not None]
        if not valid_heights:
            raise ValueError(f"No visible figures found in {name}")
        reference_height = max(valid_heights)
        scale = TARGET_STANDING_HEIGHT / reference_height

        source_frames: list[Image.Image] = []
        for frame, bbox in zip(frames, bboxes):
            if bbox is None:
                source_frames.append(Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE)))
                continue
            figure = frame.crop(bbox)
            resized = figure.resize(
                (
                    max(1, round(figure.width * scale)),
                    max(1, round(figure.height * scale)),
                ),
                Image.Resampling.NEAREST,
            )
            cell = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
            x = (FRAME_SIZE - resized.width) // 2
            y = BASELINE_Y - resized.height
            cell.alpha_composite(resized, (x, y))
            source_frames.append(keep_main_figure(hard_alpha(cell)))
        prepared[name] = source_frames
    return prepared


def build_runtime_sheet(frames: dict[str, list[Image.Image]]) -> tuple[Image.Image, list[Image.Image]]:
    ordered = [frames[source][index] for source, index in FRAME_MAP]
    rows = (len(ordered) + SHEET_COLUMNS - 1) // SHEET_COLUMNS
    sheet = Image.new(
        "RGBA",
        (SHEET_COLUMNS * FRAME_SIZE, rows * FRAME_SIZE),
        (0, 0, 0, 0),
    )
    for index, frame in enumerate(ordered):
        sheet.alpha_composite(
            frame,
            ((index % SHEET_COLUMNS) * FRAME_SIZE, (index // SHEET_COLUMNS) * FRAME_SIZE),
        )
    sheet.save(SPRITE_DIR / "watergun-teen-v1.png", optimize=True)

    shooting = Image.new("RGBA", (3 * FRAME_SIZE, 3 * FRAME_SIZE), (0, 0, 0, 0))
    for index, frame in enumerate(ordered[53:62]):
        shooting.alpha_composite(
            frame,
            ((index % 3) * FRAME_SIZE, (index // 3) * FRAME_SIZE),
        )
    shooting.save(SPRITE_DIR / "watergun-teen-shooting-v1.png", optimize=True)
    return sheet, ordered


def beach_scene() -> Image.Image:
    background_path = ROOT / "assets" / "previews" / "background-v2-composite-320x120.png"
    if background_path.exists():
        scene = Image.open(background_path).convert("RGBA")
        scene = scene.resize((320, 120), Image.Resampling.NEAREST)
    else:
        scene = Image.new("RGBA", (320, 120), (90, 194, 211, 255))
    output = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    output.alpha_composite(scene, (0, 0))
    draw = ImageDraw.Draw(output)
    draw.rectangle((0, 120, 319, 179), fill=(232, 197, 142, 255))
    draw.rectangle((0, 172, 319, 176), fill=(117, 74, 57, 255))
    return output


def build_previews(sheet: Image.Image, frames: list[Image.Image]) -> None:
    contact = Image.new("RGBA", sheet.size, (171, 216, 211, 255))
    contact.alpha_composite(sheet)
    contact.save(PREVIEW_DIR / "watergun-teen-v1-contact-sheet.png", optimize=True)

    key_indices = [0, 4, 10, 23, 29, 53, 56, 59]
    still = beach_scene()
    for slot, frame_index in enumerate(key_indices):
        small = frames[frame_index].resize((64, 64), Image.Resampling.NEAREST)
        still.alpha_composite(small, (slot * 39, 108))
    still.resize((1280, 720), Image.Resampling.NEAREST).save(
        PREVIEW_DIR / "watergun-teen-v1-game-scale.png",
        optimize=True,
    )

    gif_frames: list[Image.Image] = []
    durations: list[int] = []
    preview_order = (
        ANIMATIONS["idle"][0]
        + ANIMATIONS["walk"][0]
        + ANIMATIONS["run"][0]
        + ANIMATIONS["surprise"][0]
        + ANIMATIONS["fist_shake"][0]
        + ANIMATIONS["shoot_high"][0]
        + ANIMATIONS["shoot_level"][0]
        + ANIMATIONS["shoot_low"][0]
    )
    for frame_index in preview_order:
        scene = beach_scene()
        character = frames[frame_index].resize((64, 64), Image.Resampling.NEAREST)
        scene.alpha_composite(character, (128, 106))
        gif_frames.append(scene.resize((640, 360), Image.Resampling.NEAREST).convert("P"))
        durations.append(120)
    gif_frames[0].save(
        PREVIEW_DIR / "watergun-teen-v1-animation.gif",
        save_all=True,
        append_images=gif_frames[1:],
        duration=durations,
        loop=0,
        disposal=2,
    )


def main() -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    frames = prepare_source_frames()
    sheet, ordered = build_runtime_sheet(frames)
    build_previews(sheet, ordered)
    print(f"Prepared {len(ordered)} generated full-body frames")


if __name__ == "__main__":
    main()
