#!/usr/bin/env python3
"""
pixel_audit.py - Tier 1 automated pixel-art consistency audit for Gullin' It.

Checks every PNG under an art folder against the locked Art Bible rules:
  P1 palette      every opaque pixel is an exact master-palette colour
  P2 alpha        alpha is only 0 or 255 (no soft / semi-transparent edges)
  P3 scale        asset is stored at 1x (not an upscaled copy) and has one pixel size
  P4 colours      unique colour count within the cap for its asset class
  P5 orphans      isolated single pixels (noise left by AI downscaling)
  P6 dimensions   width/height are multiples of the grid for its class
  P7 frames       spritesheet frames share one baseline (feet) row
  P8 import       Godot .import sidecar is lossless with no mipmaps
  P9 outline      silhouette edge uses outline colours (classes with outline_required)
Also writes a contact sheet (all sprites at the same scale on the sand colour)
for the Tier 3 lineup review.

Usage:
  pip install pillow numpy
  python pixel_audit.py --config art/audit_config.json
  python pixel_audit.py --root art --palette art/palette.hex   # quick mode

Exit code 1 when any S1 finding exists (use it as a CI gate).
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

DEFAULT_CLASS = {
    "max_colours": 12,
    "grid": 1,
    "outline_required": False,
    "frame_width": None,
    "frame_height": None,
    "max_orphans": 0,
}

SEVERITY_ORDER = {"S1": 0, "S2": 1, "S3": 2, "S4": 3}


@dataclass
class Finding:
    file: str
    check: str
    severity: str
    detail: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)
    files_checked: int = 0

    def add(self, file: str, check: str, severity: str, detail: str) -> None:
        self.findings.append(Finding(file, check, severity, detail))


# --------------------------------------------------------------------------- config

def load_palette(path: Path) -> set[tuple[int, int, int]]:
    """Read a .hex (one RRGGBB per line), .gpl (GIMP) or a palette .png."""
    if path.suffix.lower() == ".png":
        img = np.array(Image.open(path).convert("RGBA"))
        opaque = img[img[..., 3] > 0][:, :3]
        return {tuple(int(c) for c in px) for px in np.unique(opaque, axis=0)}
    colours = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.search(r"#?([0-9a-fA-F]{6})\b", line)
        if path.suffix.lower() == ".gpl":
            nums = line.split()
            if len(nums) >= 3 and all(n.isdigit() for n in nums[:3]):
                colours.add(tuple(int(n) for n in nums[:3]))
            continue
        if m:
            h = m.group(1)
            colours.add((int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)))
    if not colours:
        raise SystemExit(f"No colours read from palette {path}")
    return colours


def load_config(args) -> dict:
    cfg = {"root": "art", "palette": "art/palette.hex", "classes": {},
           "ignore": [], "contact_sheet": "art_audit/contact_sheet.png",
           "report": "art_audit/report.md", "sand_colour": "#e8d3a2"}
    if args.config:
        cfg.update(json.loads(Path(args.config).read_text(encoding="utf-8")))
    if args.root:
        cfg["root"] = args.root
    if args.palette:
        cfg["palette"] = args.palette
    return cfg


def class_for(rel: str, classes: dict) -> tuple[str, dict]:
    """First class whose glob matches the relative path wins."""
    for name, spec in classes.items():
        for pattern in spec.get("match", []):
            if fnmatch.fnmatch(rel, pattern):
                merged = dict(DEFAULT_CLASS)
                merged.update(spec)
                return name, merged
    return "default", dict(DEFAULT_CLASS)


# --------------------------------------------------------------------------- checks

def check_palette(img, palette, rel, rep):
    opaque = img[img[..., 3] > 0][:, :3]
    if opaque.size == 0:
        rep.add(rel, "P1 palette", "S3", "image is fully transparent")
        return
    uniq, counts = np.unique(opaque, axis=0, return_counts=True)
    off = [(tuple(int(c) for c in u), int(n)) for u, n in zip(uniq, counts)
           if tuple(int(c) for c in u) not in palette]
    if off:
        off_px = sum(n for _, n in off)
        share = off_px / len(opaque) * 100
        worst = sorted(off, key=lambda t: -t[1])[:5]
        sample = ", ".join(f"#{r:02x}{g:02x}{b:02x}\u00d7{n}" for (r, g, b), n in worst)
        sev = "S1" if share > 2 else "S2"
        rep.add(rel, "P1 palette", sev,
                f"{len(off)} off-palette colours on {off_px} px ({share:.1f}%): {sample}")


def check_alpha(img, rel, rep):
    a = img[..., 3]
    partial = int(np.count_nonzero((a > 0) & (a < 255)))
    if partial:
        rep.add(rel, "P2 alpha", "S1",
                f"{partial} semi-transparent px (soft edges/halo); threshold alpha to 0/255")


def detect_block_size(img) -> int:
    """Largest n such that the image is made of n\u00d7n blocks of identical pixels."""
    h, w = img.shape[:2]
    best = 1
    for n in range(2, min(h, w) // 2 + 1):
        if h % n or w % n:
            continue
        blocks = img.reshape(h // n, n, w // n, n, 4)
        if np.all(blocks == blocks[:, :1, :, :1, :]):
            best = n
    return best


def check_scale(img, rel, rep):
    n = detect_block_size(img)
    if n > 1:
        rep.add(rel, "P3 scale", "S1",
                f"stored upscaled \u00d7{n}; downscale with nearest-neighbour to 1\u00d7")
        return
    # Off-grid / doubled art heuristic: in true 1x art, colour edges fall on every pixel
    # column and row. If almost all edges land on one residue modulo n (2, 3 or 4), the art
    # (or part of it) is drawn at an n-pixel size, possibly shifted off the grid.
    key = img.astype(np.int64)
    key = (key[..., 0] << 24) | (key[..., 1] << 16) | (key[..., 2] << 8) | key[..., 3]
    col_edges = np.nonzero((key[:, 1:] != key[:, :-1]).any(axis=0))[0] + 1
    row_edges = np.nonzero((key[1:, :] != key[:-1, :]).any(axis=1))[0] + 1
    if len(col_edges) < 8 or len(row_edges) < 8:
        return  # too few edges to judge (flat tiles, tiny icons)
    for n in (4, 3, 2):
        cr = np.bincount(col_edges % n, minlength=n).max() / len(col_edges)
        rr = np.bincount(row_edges % n, minlength=n).max() / len(row_edges)
        if cr > 0.9 and rr > 0.9:
            rep.add(rel, "P3 scale", "S2",
                    f"{cr:.0%} of column edges and {rr:.0%} of row edges sit on a {n}-px grid; "
                    f"art looks drawn at {n}\u00d7 pixel size (or off-grid)")
            return


def check_colour_count(img, spec, cls, rel, rep):
    opaque = img[img[..., 3] > 0][:, :3]
    if opaque.size == 0:
        return
    n = len(np.unique(opaque, axis=0))
    cap = spec["max_colours"]
    if n > cap:
        sev = "S2" if n > cap * 1.5 else "S3"
        rep.add(rel, "P4 colours", sev, f"{n} colours, cap for '{cls}' is {cap}")


def check_orphans(img, spec, rel, rep):
    """Opaque pixels whose colour matches none of their 8 neighbours."""
    h, w = img.shape[:2]
    if h < 3 or w < 3:
        return
    rgba = img.astype(np.int32)
    key = (rgba[..., 0] << 24) | (rgba[..., 1] << 16) | (rgba[..., 2] << 8) | rgba[..., 3]
    pad = np.pad(key, 1, constant_values=-1)
    centre = pad[1:-1, 1:-1]
    match_any = np.zeros_like(centre, dtype=bool)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == dx == 0:
                continue
            match_any |= pad[1 + dy: 1 + dy + h, 1 + dx: 1 + dx + w] == centre
    orphans = (~match_any) & (img[..., 3] > 0)
    # eyes and highlights are legitimate single pixels: raise max_orphans per class to allow them
    count = int(orphans.sum())
    if count > spec["max_orphans"]:
        ys, xs = np.nonzero(orphans)
        where = ", ".join(f"({x},{y})" for x, y in list(zip(xs, ys))[:6])
        rep.add(rel, "P5 orphans", "S3", f"{count} isolated pixels, e.g. {where}")


def check_dimensions(img, spec, rel, rep):
    h, w = img.shape[:2]
    g = spec["grid"]
    if g > 1 and (w % g or h % g):
        rep.add(rel, "P6 dimensions", "S2", f"{w}\u00d7{h} is not a multiple of grid {g}")
    fw, fh = spec.get("frame_width"), spec.get("frame_height")
    if fw and fh and (w % fw or h % fh):
        rep.add(rel, "P6 dimensions", "S1", f"{w}\u00d7{h} does not divide into {fw}\u00d7{fh} frames")


def check_frames(img, spec, rel, rep):
    fw, fh = spec.get("frame_width"), spec.get("frame_height")
    if not (fw and fh) or spec.get("skip_baseline"):
        return
    h, w = img.shape[:2]
    if w % fw or h % fh:
        return
    for row in range(h // fh):
        baselines = []
        for col in range(w // fw):
            frame = img[row * fh:(row + 1) * fh, col * fw:(col + 1) * fw, 3]
            ys = np.nonzero(frame.max(axis=1))[0]
            if len(ys):
                baselines.append(int(ys.max()))
        if len(set(baselines)) > 1:
            rep.add(rel, "P7 frames", "S2",
                    f"row {row}: lowest opaque row differs across frames {baselines} "
                    "(sprite will bob; fix pivot unless the motion is intended)")


def check_outline(img, spec, outline_colours, rel, rep):
    if not spec.get("outline_required") or not outline_colours:
        return
    a = img[..., 3] > 0
    pad = np.pad(a, 1, constant_values=False)
    h, w = a.shape
    edge = a & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    edge_px = img[edge][:, :3]
    if edge_px.size == 0:
        return
    bad = sum(1 for p in edge_px if tuple(int(c) for c in p) not in outline_colours)
    share = bad / len(edge_px)
    if share > 0.15:
        rep.add(rel, "P9 outline", "S2",
                f"{share:.0%} of silhouette edge pixels are not outline colours")


def check_import(png: Path, rel, rep):
    imp = png.with_suffix(png.suffix + ".import")
    if not imp.exists():
        rep.add(rel, "P8 import", "S4", "no .import sidecar yet (open the project in Godot once)")
        return
    text = imp.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"compress/mode\s*=\s*(\d+)", text)
    if m and m.group(1) != "0":
        rep.add(rel, "P8 import", "S1", f"compress/mode={m.group(1)}; set to Lossless (0)")
    if re.search(r"mipmaps/generate\s*=\s*true", text):
        rep.add(rel, "P8 import", "S2", "mipmaps enabled; turn off for pixel art")


# --------------------------------------------------------------------------- contact sheet

def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def build_contact_sheet(items, out: Path, sand: str, scale: int = 3, max_w: int = 1600):
    if not items:
        return
    pad = 4
    x = y = pad
    row_h = 0
    placements = []
    for path, img in items:
        im = Image.fromarray(img)
        # show spritesheets as their first frame row only to keep the sheet readable
        w, h = im.size
        w2, h2 = w * scale, h * scale
        if x + w2 + pad > max_w and x > pad:
            x = pad
            y += row_h + pad
            row_h = 0
        placements.append((im, x, y, w2, h2))
        x += w2 + pad
        row_h = max(row_h, h2)
    sheet = Image.new("RGBA", (max_w, y + row_h + pad), hex_to_rgb(sand) + (255,))
    for im, px, py, w2, h2 in placements:
        sheet.alpha_composite(im.resize((w2, h2), Image.NEAREST), (px, py))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)


# --------------------------------------------------------------------------- main

def write_report(rep: Report, out: Path):
    out.parent.mkdir(parents=True, exist_ok=True)
    counts = {s: sum(1 for f in rep.findings if f.severity == s) for s in SEVERITY_ORDER}
    lines = ["# Pixel art audit report", "",
             f"Files checked: {rep.files_checked}  ",
             "Findings: " + ", ".join(f"{s} {n}" for s, n in counts.items()), "",
             "| Severity | Check | File | Detail |", "| --- | --- | --- | --- |"]
    for f in sorted(rep.findings, key=lambda f: (SEVERITY_ORDER[f.severity], f.check, f.file)):
        lines.append(f"| {f.severity} | {f.check} | `{f.file}` | {f.detail} |")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return counts


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config")
    ap.add_argument("--root")
    ap.add_argument("--palette")
    ap.add_argument("--no-sheet", action="store_true")
    args = ap.parse_args(argv)

    cfg = load_config(args)
    root = Path(cfg["root"])
    palette = load_palette(Path(cfg["palette"]))
    outline_colours = {hex_to_rgb(c) for c in cfg.get("outline_colours", [])}
    rep = Report()
    sheet_items = []

    pngs = sorted(p for p in root.rglob("*.png")
                  if not any(fnmatch.fnmatch(p.relative_to(root).as_posix(), g) for g in cfg["ignore"]))
    for png in pngs:
        rel = png.relative_to(root).as_posix()
        cls, spec = class_for(rel, cfg["classes"])
        try:
            img = np.array(Image.open(png).convert("RGBA"))
        except Exception as e:  # noqa: BLE001
            rep.add(rel, "P0 read", "S1", f"cannot open: {e}")
            continue
        rep.files_checked += 1
        check_alpha(img, rel, rep)
        check_palette(img, palette, rel, rep)
        check_scale(img, rel, rep)
        check_colour_count(img, spec, cls, rel, rep)
        check_orphans(img, spec, rel, rep)
        check_dimensions(img, spec, rel, rep)
        check_frames(img, spec, rel, rep)
        check_outline(img, spec, outline_colours, rel, rep)
        check_import(png, rel, rep)
        if spec.get("frame_width") and spec.get("frame_height"):
            sheet_items.append((png, img[: spec["frame_height"], : spec["frame_width"]]))
        elif cls != "background":
            sheet_items.append((png, img))

    counts = write_report(rep, Path(cfg["report"]))
    if not args.no_sheet:
        build_contact_sheet(sheet_items, Path(cfg["contact_sheet"]), cfg["sand_colour"])
    print(f"{rep.files_checked} files | " + " ".join(f"{s}:{n}" for s, n in counts.items())
          + f" | report: {cfg['report']}")
    return 1 if counts["S1"] else 0


if __name__ == "__main__":
    sys.exit(main())
