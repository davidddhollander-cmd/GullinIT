#!/usr/bin/env python3
"""Prepare generated beach-ground plates into native, validated runtime tiles."""

from __future__ import annotations

import json
import math
import random
from collections import Counter, deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "reference" / "beach-ground-v1"
RUNTIME = ROOT / "assets" / "sprites" / "beach-ground-v1"
PREVIEWS = ROOT / "assets" / "previews"

# Shared fixed palette: 18 colours across all four runtime files.
COLORS: dict[str, tuple[int, int, int, int]] = {
    "SAND": (232, 197, 142, 255),
    "SAND_HIGHLIGHT": (255, 241, 204, 255),
    "SAND_LEGACY_SHADE": (212, 173, 120, 255),
    "SAND_LIGHT": (240, 207, 155, 255),
    "SAND_SHADE": (221, 184, 132, 255),
    "FOAM": (137, 207, 194, 255),
    "SHALLOW": (96, 191, 190, 255),
    "WET": (205, 174, 126, 255),
    "WET_DARK": (184, 148, 99, 255),
    "PROMENADE": (193, 142, 104, 255),
    "WOOD_JOINT": (165, 123, 92, 255),
    "PROMENADE_LIGHT": (211, 160, 122, 255),
    "PIER_LIP": (239, 185, 132, 255),
    "PIER_BODY": (155, 102, 80, 255),
    "PIER_LIGHT": (181, 128, 95, 255),
    "PIER_DARK": (133, 85, 63, 255),
    "SEA_DEEP": (16, 121, 132, 255),
    "SEA_BASE": (27, 143, 147, 255),
}
PALETTE = list(COLORS.values())
TRANSPARENT = (0, 0, 0, 0)


def rgb_distance(a: tuple[int, ...], b: tuple[int, ...]) -> int:
    return sum((a[index] - b[index]) ** 2 for index in range(3))


def nearest(pixel: tuple[int, ...], choices: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    return min(choices, key=lambda color: rgb_distance(pixel, color))


def quantize_fixed(image: Image.Image, choices: list[tuple[int, int, int, int]]) -> Image.Image:
    source = image.convert("RGBA")
    alpha = source.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    output = Image.new("RGBA", source.size)
    output.putdata([nearest(pixel, choices) for pixel in source.get_flattened_data()])
    output.putalpha(alpha)
    return output


def centered_crop(image: Image.Image, aspect: float, centre_y: float = 0.5) -> Image.Image:
    width, height = image.size
    wanted_height = min(height, round(width / aspect))
    top = round(height * centre_y - wanted_height / 2)
    top = max(0, min(height - wanted_height, top))
    return image.crop((0, top, width, top + wanted_height))


def row_average(image: Image.Image, y: int) -> tuple[int, int, int]:
    pixels = [image.getpixel((x, y)) for x in range(0, image.width, max(1, image.width // 128))]
    return tuple(round(sum(pixel[channel] for pixel in pixels) / len(pixels)) for channel in range(3))


def source_boundary(source: Image.Image) -> tuple[list[int], list[int]]:
    """Extract generated foam and wet/dry boundary motion, normalised to native rows."""
    reduced = source.resize((320, 96), Image.Resampling.NEAREST).convert("RGB")
    row_colours = [row_average(reduced, y) for y in range(reduced.height)]
    # The generated plate is ordered sea -> foam -> wet sand -> dry sand.
    foam_hint = min(range(20, 75), key=lambda y: rgb_distance(row_colours[y], COLORS["SAND_HIGHLIGHT"]))
    dry_hint = min(range(foam_hint + 3, 95), key=lambda y: rgb_distance(row_colours[y], COLORS["SAND"]))
    foam: list[int] = []
    dry: list[int] = []
    for x in range(320):
        column = [reduced.getpixel((x, y)) for y in range(96)]
        foam_candidates = [y for y in range(max(0, foam_hint - 10), min(95, foam_hint + 11)) if nearest(column[y], [COLORS["SHALLOW"], COLORS["SAND_HIGHLIGHT"], COLORS["WET"]]) == COLORS["SAND_HIGHLIGHT"]]
        wet_candidates = [y for y in range(max(foam_hint + 1, dry_hint - 10), min(96, dry_hint + 11)) if nearest(column[y], [COLORS["WET"], COLORS["WET_DARK"], COLORS["SAND"]]) == COLORS["SAND"]]
        foam.append(foam_candidates[0] if foam_candidates else foam_hint)
        dry.append(wet_candidates[0] if wet_candidates else dry_hint)
    return foam, dry


def normalise_motion(values: list[int], centre: int, amplitude: int = 1) -> list[int]:
    median = sorted(values)[len(values) // 2]
    smoothed: list[int] = []
    for x in range(len(values)):
        window = [values[(x + delta) % len(values)] for delta in range(-8, 9)]
        local = round(sum(window) / len(window))
        delta = max(-amplitude, min(amplitude, round((local - median) / 3)))
        smoothed.append(centre + delta)
    return smoothed


def extract_foam_runs(source: Image.Image) -> list[tuple[int, int, int]]:
    reduced = source.resize((320, 96), Image.Resampling.NEAREST).convert("RGB")
    runs: list[tuple[int, int, int]] = []
    for y in range(18, 58):
        x = 0
        while x < 320:
            is_foam = nearest(reduced.getpixel((x, y)), [COLORS["FOAM"], COLORS["SHALLOW"], COLORS["SEA_BASE"]]) == COLORS["FOAM"]
            if not is_foam:
                x += 1
                continue
            start = x
            while x < 320 and nearest(reduced.getpixel((x, y)), [COLORS["FOAM"], COLORS["SHALLOW"], COLORS["SEA_BASE"]]) == COLORS["FOAM"]:
                x += 1
            length = x - start
            if 1 <= length <= 14:
                runs.append((start, y, length))
    # Stable de-duplication gives a source-derived but quiet set.
    selected: list[tuple[int, int, int]] = []
    for start, y, length in sorted(runs, key=lambda item: (item[0], item[1])):
        native_length = max(2, min(6, round(length / 2)))
        if all(abs(start - prior[0]) > 10 for prior in selected):
            selected.append((start, 4 + (y % 5), native_length))
        if len(selected) >= 18:
            break
    if len(selected) < 8:
        raise RuntimeError("Shoreline source did not yield enough foam-lacing marks")
    return selected


def prepare_shoreline() -> Image.Image:
    source = Image.open(SOURCE / "shoreline-source.png").convert("RGBA")
    foam_source, dry_source = source_boundary(source)
    foam_line = normalise_motion(foam_source, 11, 1)
    dry_line = normalise_motion(dry_source, 17, 1)
    output = Image.new("RGBA", (320, 20), TRANSPARENT)
    pixels = output.load()
    for x in range(320):
        edge = foam_line[x]
        dry = max(edge + 4, dry_line[x])
        for y in range(9, edge + 1):
            pixels[x, y] = COLORS["SHALLOW"]
        pixels[x, min(12, edge + 1)] = COLORS["SAND_HIGHLIGHT"]
        for y in range(min(13, edge + 2), min(17, dry)):
            pixels[x, y] = COLORS["WET"]
        pixels[x, min(16, max(13, dry - 2))] = COLORS["WET_DARK"]
        for y in range(max(13, dry - 1), 18):
            pixels[x, y] = COLORS["WET"]
        pixels[x, 18] = COLORS["SAND_LIGHT"]
        pixels[x, 19] = COLORS["SAND"]
    for x, y, length in extract_foam_runs(source):
        if x + length >= 319:
            continue
        for dx in range(length):
            pixels[x + dx, y] = COLORS["FOAM"]
    return output


def components(image: Image.Image, base: tuple[int, int, int, int], max_area: int, max_width: int, max_height: int) -> list[Image.Image]:
    pixels = image.load()
    visited: set[tuple[int, int]] = set()
    results: list[Image.Image] = []
    for y in range(image.height):
        for x in range(image.width):
            if (x, y) in visited or pixels[x, y] == base:
                continue
            queue = deque([(x, y)])
            visited.add((x, y))
            points: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                points.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < image.width and 0 <= ny < image.height and (nx, ny) not in visited and pixels[nx, ny] != base:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
            left = min(point[0] for point in points)
            right = max(point[0] for point in points)
            top = min(point[1] for point in points)
            bottom = max(point[1] for point in points)
            width, height = right - left + 1, bottom - top + 1
            if len(points) <= max_area and width <= max_width and height <= max_height:
                stamp = Image.new("RGBA", (width, height), TRANSPARENT)
                for px, py in points:
                    stamp.putpixel((px - left, py - top), pixels[px, py])
                results.append(stamp)
    return results


def paste_wrapped(target: Image.Image, stamp: Image.Image, x: int, y: int) -> None:
    target.alpha_composite(stamp, (x, y))
    if x < 0:
        target.alpha_composite(stamp, (x + target.width, y))
    if x + stamp.width > target.width:
        target.alpha_composite(stamp, (x - target.width, y))


def detail_count(image: Image.Image, base: tuple[int, int, int, int], rows: range | None = None) -> int:
    use_rows = rows if rows is not None else range(image.height)
    return sum(1 for y in use_rows for x in range(image.width) if image.getpixel((x, y)) != base)


def prepare_sand() -> Image.Image:
    source = Image.open(SOURCE / "sand-source.png").convert("RGBA")
    reduced = centered_crop(source, 8.0).resize((320, 40), Image.Resampling.NEAREST)
    reduced = quantize_fixed(reduced, [COLORS[name] for name in ("SAND", "SAND_HIGHLIGHT", "SAND_LEGACY_SHADE", "SAND_LIGHT", "SAND_SHADE")])
    stamps = components(reduced, COLORS["SAND"], 10, 8, 3)
    if len(stamps) < 8:
        raise RuntimeError(f"Sand source yielded only {len(stamps)} usable marks")
    output = Image.new("RGBA", (320, 40), COLORS["SAND"])
    rng = random.Random(551)
    occupied: list[tuple[int, int, int, int]] = []
    attempts = 0
    target_detail = 520
    while detail_count(output, COLORS["SAND"]) < target_detail and attempts < 4000:
        attempts += 1
        stamp = rng.choice(stamps)
        quiet = rng.random() < 0.16
        if quiet and stamp.width > 4:
            continue
        if quiet:
            y = rng.randint(12, max(12, 28 - stamp.height + 1))
        elif rng.random() < 0.48:
            y = rng.randint(0, max(0, 10 - stamp.height + 1))
        else:
            y = rng.randint(29, max(29, 39 - stamp.height + 1))
        x = rng.randint(2, max(2, 317 - stamp.width))
        rect = (x - 2, y - 1, x + stamp.width + 2, y + stamp.height + 1)
        if any(not (rect[2] <= old[0] or rect[0] >= old[2] or rect[3] <= old[1] or rect[1] >= old[3]) for old in occupied):
            continue
        paste_wrapped(output, stamp, x, y)
        occupied.append(rect)
    return output


def find_non_background_band(source: Image.Image) -> Image.Image:
    rgb = source.convert("RGB")
    background = row_average(rgb, 0)
    active: list[int] = []
    for y in range(rgb.height):
        average = row_average(rgb, y)
        if math.sqrt(rgb_distance(average, background)) > 24:
            active.append(y)
    if not active:
        raise RuntimeError("Generated wood plate has no detectable subject band")
    top, bottom = max(0, min(active) - 2), min(rgb.height, max(active) + 3)
    return source.crop((0, top, source.width, bottom))


def wood_stamps(source_file: str, choices: list[tuple[int, int, int, int]], height: int) -> list[Image.Image]:
    source = Image.open(SOURCE / source_file).convert("RGBA")
    band = find_non_background_band(source).resize((320, height), Image.Resampling.NEAREST)
    quantized = quantize_fixed(band, choices)
    base = Counter(quantized.get_flattened_data()).most_common(1)[0][0]
    found = components(quantized, base, 8, 4, 2)
    return found or [Image.new("RGBA", (2, 1), choices[1])]


def prepare_promenade() -> Image.Image:
    stamps = wood_stamps("promenade-source.png", [COLORS["PROMENADE"], COLORS["WOOD_JOINT"], COLORS["PROMENADE_LIGHT"]], 14)
    output = Image.new("RGBA", (320, 14), COLORS["PROMENADE"])
    pixels = output.load()
    rng = random.Random(552)
    for x in range(320):
        pixels[x, 0] = COLORS["PROMENADE_LIGHT"]
        pixels[x, 13] = COLORS["WOOD_JOINT"]
    for plank in range(20):
        start = plank * 16
        if plank == 11:
            for y in range(1, 13):
                for x in range(start + 1, start + 16):
                    pixels[x, y] = COLORS["PROMENADE_LIGHT"]
        for y in range(1, 13):
            pixels[start, y] = COLORS["WOOD_JOINT"]
        pixels[start + 2, 3] = COLORS["WOOD_JOINT"]
        variant = plank % 4
        for mark in range(2 + variant % 3):
            stamp = stamps[(variant * 3 + mark) % len(stamps)]
            if stamp.width > 3 or stamp.height > 2:
                continue
            x = start + 4 + ((variant * 3 + mark * 5) % max(1, 10 - stamp.width))
            y = 2 + ((variant * 2 + mark * 3) % (5 if mark < 3 else 9))
            if 8 <= y <= 12 and mark > 1:
                continue
            paste_wrapped(output, stamp, x, y)
    return quantize_fixed(output, [COLORS["PROMENADE"], COLORS["WOOD_JOINT"], COLORS["PROMENADE_LIGHT"]])


def prepare_pier() -> Image.Image:
    # Structural proportions and two-tone treatment are extracted from the generated plate,
    # then aligned to the task's exact 16/32/64 px runtime phases.
    source = Image.open(SOURCE / "pier-source.png").convert("RGBA")
    band = find_non_background_band(source).resize((320, 22), Image.Resampling.NEAREST)
    quantize_fixed(band, [COLORS[name] for name in ("PIER_LIP", "PIER_BODY", "PIER_LIGHT", "PIER_DARK", "SAND", "SAND_SHADE")])
    output = Image.new("RGBA", (320, 22), TRANSPARENT)
    pixels = output.load()
    for x in range(320):
        pixels[x, 0] = COLORS["PIER_LIP"]
        pixels[x, 1] = COLORS["PIER_LIP"]
        for y in range(2, 7):
            pixels[x, y] = COLORS["PIER_BODY"]
        pixels[x, 3] = COLORS["PIER_LIGHT"]
    for x in range(0, 320, 16):
        pixels[x, 0] = COLORS["PIER_DARK"]
        pixels[x, 1] = COLORS["PIER_BODY"]
    for x in range(2, 320, 32):
        pixels[x, 5] = COLORS["PIER_DARK"]
    for centre in range(32, 320, 64):
        left = centre - 3
        for x in range(left - 1, left + 7):
            pixels[x, 7] = COLORS["PIER_LIGHT"] if x < centre else COLORS["PIER_DARK"]
        for y in range(8, 19):
            for x in range(left, left + 6):
                pixels[x, y] = COLORS["PIER_LIGHT"] if x < centre else COLORS["PIER_DARK"]
        pixels[left + 1, 12] = COLORS["PIER_BODY"]
        pixels[left + 4, 15] = COLORS["PIER_BODY"]
        for y, half_width in ((18, 5), (19, 5), (20, 3)):
            for x in range(centre - half_width, centre + half_width):
                pixels[x, y] = COLORS["SAND_LEGACY_SHADE"]
    return output


def load_frame(path: str, frame_w: int, frame_h: int, index: int, scale: float) -> Image.Image:
    sheet = Image.open(ROOT / path.removeprefix("res://")).convert("RGBA")
    columns = max(1, sheet.width // frame_w)
    left = (index % columns) * frame_w
    top = (index // columns) * frame_h
    frame = sheet.crop((left, top, left + frame_w, top + frame_h))
    frame = frame.resize((max(1, round(frame.width * scale)), max(1, round(frame.height * scale))), Image.Resampling.NEAREST)
    bbox = frame.getbbox()
    return frame.crop(bbox) if bbox else frame


def paste_baseline(canvas: Image.Image, sprite: Image.Image, x: int, baseline: int = 160) -> None:
    canvas.alpha_composite(sprite, (round(x - sprite.width / 2), baseline - sprite.height))


def background() -> Image.Image:
    canvas = Image.new("RGBA", (320, 180), (91, 199, 216, 255))
    art = ROOT / "assets" / "sprites" / "background-v2"
    canvas.alpha_composite(Image.open(art / "sky-clouds-320x80.png").convert("RGBA"), (0, 14))
    canvas.alpha_composite(Image.open(art / "sun-34x34.png").convert("RGBA"), (233, 26))
    canvas.alpha_composite(Image.open(art / "sea-frame-01.png").convert("RGBA"), (0, 94))
    return canvas


def old_ground(canvas: Image.Image, kind: str) -> None:
    pixels = canvas.load()
    for y in range(130, 180):
        for x in range(320):
            pixels[x, y] = COLORS["SAND"]
    for y in range(130, 133):
        for x in range(320):
            pixels[x, y] = COLORS["SAND_HIGHLIGHT"]
    for x in range(7, 320, 71):
        pixels[x, 148 + (x % 25)] = COLORS["SAND_LEGACY_SHADE"]
        if x + 1 < 320:
            pixels[x + 1, 148 + (x % 25)] = COLORS["SAND_LEGACY_SHADE"]
    if kind in ("promenade", "pier"):
        end = 320 if kind == "promenade" else 160
        for y in range(151, 165):
            for x in range(end):
                pixels[x, y] = COLORS["PROMENADE"]
        for x in range(0, end, 16):
            for y in range(151, 165):
                pixels[x, y] = COLORS["WOOD_JOINT"]
    if kind == "pier":
        for y in range(158, 163):
            for x in range(160, 320):
                pixels[x, y] = COLORS["PIER_BODY"]
        for y in range(157, 159):
            for x in range(160, 320):
                pixels[x, y] = COLORS["PIER_LIP"]


def new_ground(canvas: Image.Image, kind: str, shoreline: Image.Image, sand: Image.Image, promenade: Image.Image, pier: Image.Image) -> None:
    canvas.alpha_composite(shoreline, (0, 120))
    canvas.alpha_composite(sand, (0, 140))
    if kind in ("promenade", "pier"):
        end = 320 if kind == "promenade" else 160
        for x in range(0, end, 320):
            canvas.alpha_composite(promenade.crop((0, 0, min(320, end - x), 14)), (x, 151))
    if kind == "pier":
        canvas.alpha_composite(pier.crop((0, 0, 160, 22)), (160, 157))


def add_cast(canvas: Image.Image, kind: str) -> None:
    shopper = load_frame("assets/sprites/shopper-diner-style-v2-bite-panic-v1.png", 128, 128, 0, 0.5)
    gull = load_frame("assets/sprites/gull-herring-diner-style.png", 256, 256, 0, 0.375)
    stand = load_frame("assets/sprites/retro-hotdog-stand-32bit.png", 52, 56, 0, 1.0)
    bin_sprite = load_frame("assets/sprites/retro-wheelie-bin-green-32bit.png", 28, 38, 0, 0.8)
    if kind == "beach":
        paste_baseline(canvas, gull, 88)
        paste_baseline(canvas, shopper, 205)
    else:
        paste_baseline(canvas, stand, 54)
        paste_baseline(canvas, shopper, 145)
        paste_baseline(canvas, bin_sprite, 252)


def save_scene(name: str, kind: str, before: bool, shoreline: Image.Image, sand: Image.Image, promenade: Image.Image, pier: Image.Image) -> None:
    scene = background()
    if before:
        old_ground(scene, kind)
    else:
        new_ground(scene, kind, shoreline, sand, promenade, pier)
    add_cast(scene, kind)
    file = PREVIEWS / f"beach-ground-v1-{'before-' if before else ''}{name}-320x180.png"
    scene.convert("RGB").save(file)
    scene.resize((1280, 720), Image.Resampling.NEAREST).convert("RGB").save(PREVIEWS / f"beach-ground-v1-{'before-' if before else ''}{name}-1280x720.png")


def previews(shoreline: Image.Image, sand: Image.Image, promenade: Image.Image, pier: Image.Image) -> None:
    save_scene("composite", "beach", False, shoreline, sand, promenade, pier)
    save_scene("composite", "beach", True, shoreline, sand, promenade, pier)
    save_scene("promenade", "promenade", False, shoreline, sand, promenade, pier)
    save_scene("promenade", "promenade", True, shoreline, sand, promenade, pier)
    save_scene("pier", "pier", False, shoreline, sand, promenade, pier)
    save_scene("pier", "pier", True, shoreline, sand, promenade, pier)
    tile_check = Image.new("RGBA", (960, 180), (0, 0, 0, 255))
    for index in range(3):
        panel = background()
        panel.alpha_composite(shoreline, (0, 120))
        panel.alpha_composite(sand, (0, 140))
        tile_check.alpha_composite(panel, (index * 320, 0))
    tile_check.convert("RGB").save(PREVIEWS / "beach-ground-v1-tile-check.png")


def colour_set(image: Image.Image) -> set[tuple[int, int, int]]:
    return {pixel[:3] for pixel in image.convert("RGBA").get_flattened_data() if pixel[3] != 0}


def validate(name: str, image: Image.Image, expected: tuple[int, int], max_colours: int, matching_edges: bool) -> None:
    if image.size != expected:
        raise RuntimeError(f"{name}: expected {expected}, got {image.size}")
    alphas = {pixel[3] for pixel in image.get_flattened_data()}
    if not alphas.issubset({0, 255}):
        raise RuntimeError(f"{name}: non-binary alpha {sorted(alphas)}")
    colours = colour_set(image)
    if len(colours) > max_colours:
        raise RuntimeError(f"{name}: {len(colours)} colours exceeds {max_colours}")
    if (255, 255, 255) in colours:
        raise RuntimeError(f"{name}: pure white is forbidden")
    # Natural textures use matching edge columns. Wood uses an intentional joint at
    # x=0, so x=319 and x=0 are valid adjacent phases rather than identical columns.
    if matching_edges:
        for y in range(image.height):
            if image.getpixel((0, y)) != image.getpixel((319, y)):
                raise RuntimeError(f"{name}: discontinuous edge at row {y}")
    elif name.startswith("promenade"):
        for y in range(1, 13):
            if image.getpixel((0, y)) != COLORS["WOOD_JOINT"] or image.getpixel((319, y)) != COLORS["PROMENADE"]:
                raise RuntimeError(f"{name}: invalid plank phase at row {y}")
    elif name.startswith("pier"):
        if image.getpixel((0, 0)) != COLORS["PIER_DARK"] or image.getpixel((319, 0)) != COLORS["PIER_LIP"]:
            raise RuntimeError(f"{name}: invalid deck-lip phase")
    print(f"{name}: {image.size[0]}x{image.size[1]}, colours={len(colours)}, alpha={sorted(alphas)}")


def metrics(shoreline: Image.Image, sand: Image.Image, promenade: Image.Image, pier: Image.Image) -> None:
    sand_detail = detail_count(sand, COLORS["SAND"]) / (320 * 40)
    quiet = detail_count(sand, COLORS["SAND"], range(12, 29)) / (320 * 17)
    promenade_detail_pixels = sum(
        1
        for y in range(1, 13)
        for x in range(320)
        if x % 16 != 0 and promenade.getpixel((x, y)) != COLORS["PROMENADE"]
    )
    promenade_detail = promenade_detail_pixels / (320 * 14)
    pier_detail_pixels = sum(1 for x in range(320) if pier.getpixel((x, 5)) == COLORS["PIER_DARK"])
    pier_detail_pixels += sum(
        1
        for y in range(7, 19)
        for x in range(320)
        if pier.getpixel((x, y)) == COLORS["PIER_BODY"]
    )
    pier_detail = pier_detail_pixels / (320 * 22)
    foam = sum(1 for y in range(4, 9) for x in range(320) if shoreline.getpixel((x, y)) == COLORS["FOAM"]) / (320 * 5)
    print(f"sand detail={sand_detail:.2%} (cap 8%), quiet rows 152-168={quiet:.2%} (cap 3%)")
    print(f"promenade non-base={promenade_detail:.2%} (cap 10%)")
    print(f"pier non-transparent structure/detail={pier_detail:.2%} (cap 10%)")
    print(f"shoreline foam lacing={foam:.2%} (cap 25%)")
    if sand_detail > 0.08 or quiet > 0.03 or promenade_detail > 0.10 or pier_detail > 0.10 or foam > 0.25:
        raise RuntimeError("Detail-density cap exceeded")
    combined = set().union(*(colour_set(image) for image in (shoreline, sand, promenade, pier)))
    print(f"shared palette={len(combined)} colours: {sorted(combined)}")
    if len(combined) > 20:
        raise RuntimeError("Shared palette exceeds 20 colours")


def main() -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    shoreline = prepare_shoreline()
    sand = prepare_sand()
    promenade = prepare_promenade()
    pier = prepare_pier()
    outputs = {
        "shoreline-320x20.png": (shoreline, (320, 20), 9, True),
        "sand-320x40.png": (sand, (320, 40), 6, True),
        "promenade-320x14.png": (promenade, (320, 14), 6, False),
        "pier-320x22.png": (pier, (320, 22), 8, False),
    }
    for filename, (image, size, max_colours, matching_edges) in outputs.items():
        validate(filename, image, size, max_colours, matching_edges)
        image.save(RUNTIME / filename)
    metrics(shoreline, sand, promenade, pier)
    previews(shoreline, sand, promenade, pier)
    print(f"Prepared runtime tiles in {RUNTIME}")
    print(f"Prepared review previews in {PREVIEWS}")


if __name__ == "__main__":
    main()
