"""Clean and pack generated Screeches McCrumbs art without drawing it.

Round 1 only removes the generated concept board's flat chroma background and
creates binary alpha. Round 2 removes the same chroma key from the five
generated portrait sources, scales with nearest-neighbour, aligns their shared
source canvases, and packs the production atlas and review preview.
"""

from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = ROOT / "assets/reference/trainer-v1"
CONCEPT_SOURCE = REFERENCE_DIR / "concept-board-source-v3-chroma.png"
CONCEPT_BOARD = REFERENCE_DIR / "trainer-screeches-concepts-v1.png"
PORTRAIT_SOURCES = [
    REFERENCE_DIR / "portrait-01-neutral-source.png",
    REFERENCE_DIR / "portrait-02-talking-source.png",
    REFERENCE_DIR / "portrait-03-amused-source.png",
    REFERENCE_DIR / "portrait-04-proud-source.png",
    REFERENCE_DIR / "portrait-05-wince-source.png",
]
ATLAS = ROOT / "assets/sprites/trainer-screeches-portraits-v1.png"
PREVIEW = ROOT / "assets/previews/trainer-screeches-portraits-v1.png"
CELL = 256
DISPLAY_SIZE = 56
PREVIEW_SCALE = 4


def without_chroma(source: Path) -> Image.Image:
    pixels = np.asarray(Image.open(source).convert("RGBA")).copy()
    red = pixels[:, :, 0].astype(np.int16)
    green = pixels[:, :, 1].astype(np.int16)
    blue = pixels[:, :, 2].astype(np.int16)
    chroma = (green >= 100) & (green >= red * 1.25) & (green >= blue * 1.25)
    pixels[:, :, 3] = 255
    pixels[chroma] = 0
    return Image.fromarray(pixels, "RGBA")


def assert_binary_alpha(image: Image.Image) -> None:
    alpha_values = set(np.unique(np.asarray(image)[:, :, 3]).tolist())
    assert alpha_values <= {0, 255}, f"Non-binary alpha values: {alpha_values}"


def write_concept_board() -> None:
    cleaned = without_chroma(CONCEPT_SOURCE)
    CONCEPT_BOARD.parent.mkdir(parents=True, exist_ok=True)
    cleaned.save(CONCEPT_BOARD)
    assert_binary_alpha(cleaned)
    assert cleaned.getbbox() is not None, "Concept board is empty"


def write_portrait_atlas() -> None:
    frames = [without_chroma(path).resize((CELL, CELL), Image.Resampling.NEAREST)
              for path in PORTRAIT_SOURCES]
    for frame in frames:
        assert_binary_alpha(frame)
        assert frame.getbbox() is not None, "Portrait frame is empty"

    # The generated talk source changes only the lower bill and cigar. Paste
    # that generated region over the neutral master so frames 1 and 2 are
    # literally identical everywhere else and cannot jitter when alternated.
    talking = frames[0].copy()
    talk_region = (0, 116, 112, 170)
    talking.paste(frames[1].crop(talk_region), talk_region[:2])
    frames[1] = talking

    atlas = Image.new("RGBA", (CELL * len(frames), CELL))
    for index, frame in enumerate(frames):
        atlas.paste(frame, (index * CELL, 0))
    assert_binary_alpha(atlas)
    ATLAS.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(ATLAS)

    game_scale = atlas.resize((DISPLAY_SIZE * len(frames), DISPLAY_SIZE),
                              Image.Resampling.NEAREST)
    enlarged = game_scale.resize((game_scale.width * PREVIEW_SCALE,
                                  game_scale.height * PREVIEW_SCALE),
                                 Image.Resampling.NEAREST)
    preview = Image.new("RGBA", (enlarged.width,
                                 game_scale.height + 16 + enlarged.height))
    preview.paste(game_scale, ((preview.width - game_scale.width) // 2, 0))
    preview.paste(enlarged, (0, game_scale.height + 16))
    assert_binary_alpha(preview)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def main() -> None:
    write_concept_board()
    write_portrait_atlas()
    print(f"Wrote {CONCEPT_BOARD.relative_to(ROOT)} with binary alpha")
    print(f"Wrote {ATLAS.relative_to(ROOT)} as five {CELL}x{CELL} cells")
    print(f"Wrote {PREVIEW.relative_to(ROOT)} at {DISPLAY_SIZE}px and {PREVIEW_SCALE}x")


if __name__ == "__main__":
    main()
