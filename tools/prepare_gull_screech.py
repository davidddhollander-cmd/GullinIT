"""Pack the six generated herring gull long-call poses without painting pixels."""

import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

from prepare_gull_species import components, isolated


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/reference/gull-screech-v1/herring-screech-source.png"
ATLAS = ROOT / "assets/sprites/gull-herring-screech-v1.png"
CELL = 256


def main() -> None:
    source = np.asarray(Image.open(SOURCE).convert("RGBA"))
    actors = [part for part in components(source[:, :, 3] >= 192) if len(part) > 10000]
    assert len(actors) == 6, f"Expected six complete gull poses, found {len(actors)}"
    rows = [sorted([part for part in actors if part[:, 1].mean() < 450], key=lambda p: p[:, 0].min()),
            sorted([part for part in actors if part[:, 1].mean() >= 450], key=lambda p: p[:, 0].min())]
    assert [len(row) for row in rows] == [3, 3]
    poses = [isolated(source, part) for row in rows for part in row]
    # Match the approved idle gull's 61-pixel atlas width. The same scale across
    # all six frames leaves the drawn neck extension intact.
    scale = 61 / poses[0].width
    atlas = Image.new("RGBA", (CELL * 3, CELL * 2))
    for index, pose in enumerate(poses):
        pose = pose.resize((round(pose.width * scale), round(pose.height * scale)), Image.Resampling.NEAREST)
        pixels = np.asarray(pose)
        pink = ((pixels[:, :, 0] > 110) &
                (pixels[:, :, 0] > pixels[:, :, 1] * 1.2) &
                (pixels[:, :, 0] > pixels[:, :, 2] * 1.2) &
                (pixels[:, :, 3] > 192))
        feet_y, feet_x = np.nonzero(pink)
        feet_x = feet_x[feet_y > pose.height * .7]
        assert len(feet_x) > 10, f"Pose {index} has no usable foot anchor"
        x = round(128 - float(np.median(feet_x)))
        y = 140 - pose.height
        assert 2 <= x and x + pose.width <= CELL - 2 and y >= 2
        atlas.paste(pose, ((index % 3) * CELL + x, (index // 3) * CELL + y))
    ATLAS.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(ATLAS)

    animation = {"frames": list(range(6)), "fps": 7, "loop": False,
                 "source_left": False, "file": "res://assets/sprites/gull-herring-screech-v1.png"}
    art_path = ROOT / "data/gull_art.json"
    art = json.loads(art_path.read_text(encoding="utf-8"))
    for key in ("gull_herring", "player_gull"):
        art[key]["animations"]["screech"] = animation
    art_path.write_text(json.dumps(art, indent=2) + "\n", encoding="utf-8")

    # The main registry mixes compact and expanded JSON. Insert only the two
    # herring clips so unrelated entries keep their established formatting.
    registry_path = ROOT / "data/sprites.json"
    text = registry_path.read_text(encoding="utf-8")
    clip = ('      "screech": {\n'
            '        "frames": [0, 1, 2, 3, 4, 5],\n'
            '        "fps": 7,\n'
            '        "loop": false,\n'
            '        "source_left": false,\n'
            '        "file": "res://assets/sprites/gull-herring-screech-v1.png"\n'
            '      }')
    for key in ("gull_herring", "player_gull"):
        pattern = re.compile(r'(?ms)(^  "' + key + r'": \{.*?^    "animations": \{.*?)(^      \}\n    \}\n  \})')
        match = pattern.search(text)
        assert match, f"Missing {key} animation block"
        if '"screech"' not in match.group(0):
            text = text[:match.start()] + match.group(1) + '      },\n' + clip + '\n    }\n  }' + text[match.end():]
    json.loads(text)
    registry_path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
