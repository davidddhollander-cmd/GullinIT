#!/usr/bin/env python3
"""
gullinit_audit.py - project-specific pixel-art consistency audit for Gullin' It.

Extends pixel_audit.py for how this project actually draws art: many sprites are
large painted sheets that Godot shrinks at runtime (visual_scale), while props are
hand-pixelled at 1:1. So every runtime sprite is checked twice:

  Source file   P2 alpha, P3 stored-upscaled, P8 import settings
  On screen     sprite re-rendered at its in-game size (nearest-neighbour, like Godot)
                D1 pixel density   source px per screen px (1.0 = native pixel art)
                D2 palette drift   on-screen pixels far from the prop palette
                D3 colour count    distinct colours on screen vs the prop budget
                D4 outline         share of silhouette edge drawn in dark outline colours
  Project       G1 project.godot pixel settings

Inputs: art_manifest.json (every runtime sprite: file, first-frame rect, scale) and
art/palette.hex. Outputs: art_audit/report.md, art_audit/findings.json and two lineup
images (viewport render and the current canvas_items render at 1280x720).

Usage (from the project root):
  python tools/art_audit/build_manifest.py > tools/art_audit/art_manifest.json
  python tools/art_audit/gullinit_audit.py --project . --manifest tools/art_audit/art_manifest.json \
      --palette tools/art_audit/palette.hex --out test-output/art_audit
Exit code 1 when any S1 finding exists.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SEV = {"S1": 0, "S2": 1, "S3": 2, "S4": 3}


def hex_rgb(h):
    h = h.strip().lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def load_palette(p: Path):
    cols = [hex_rgb(m.group(1)) for line in p.read_text().splitlines()
            if (m := re.search(r"([0-9a-fA-F]{6})", line))]
    return np.array(cols, dtype=np.int32)


def nearest_resample(img: np.ndarray, scale: float) -> np.ndarray:
    """Point-sample like Godot's nearest filter: screen pixel centre -> source texel."""
    h, w = img.shape[:2]
    oh, ow = max(1, int(round(h * scale))), max(1, int(round(w * scale)))
    ys = np.minimum(((np.arange(oh) + 0.5) / scale).astype(int), h - 1)
    xs = np.minimum(((np.arange(ow) + 0.5) / scale).astype(int), w - 1)
    return img[ys][:, xs]


def first_frame(sheet: np.ndarray, entry: dict) -> np.ndarray:
    if entry.get("region"):
        x, y, w, h = (int(round(v)) for v in entry["region"])
        return sheet[y:y + h, x:x + w]
    fw, fh = entry.get("frame_w"), entry.get("frame_h")
    if not fw or not fh:
        return sheet
    fw, fh = int(fw), int(fh)
    for r in range(sheet.shape[0] // fh):
        for c in range(sheet.shape[1] // fw):
            fr = sheet[r * fh:(r + 1) * fh, c * fw:(c + 1) * fw]
            if fr[..., 3].any():
                return fr
    return sheet[:fh, :fw]


def crop_alpha(a: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(a[..., 3] > 0)
    if not len(ys):
        return a
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def edge_mask(alpha: np.ndarray) -> np.ndarray:
    pad = np.pad(alpha, 1, constant_values=False)
    inner = pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    return alpha & ~inner


def palette_distance(px: np.ndarray, pal: np.ndarray) -> np.ndarray:
    d = px[:, None, :].astype(np.int32) - pal[None, :, :]
    return np.sqrt((d * d).sum(-1)).min(1)


def check_project(godot: Path, findings):
    t = godot.read_text(encoding="utf-8", errors="ignore")
    def val(k):
        m = re.search(rf"^{re.escape(k)}\s*=\s*(.+)$", t, re.M)
        return m.group(1).strip().strip('"') if m else None
    rules = [
        ("rendering", "textures/canvas_textures/default_texture_filter", "0", "S1",
         "Default texture filter must be Nearest (0)"),
        ("display", "window/stretch/mode", "canvas_items", "S1",
         "The 0.5 character standard needs canvas_items: viewport mode renders at 320x180 and "
         "the 0.5-scale sheets lose half their pixels"),
        ("display", "window/stretch/scale_mode", "integer", "S2",
         "Scale mode not integer: at window sizes that are not a multiple of 320x180 (e.g. 1366x768) "
         "pixels get uneven widths. integer scale keeps every art pixel the same size"),
        ("rendering", "2d/snap/snap_2d_transforms_to_pixel", "true", "S2",
         "Transforms not snapped to pixel: sprites shimmer while moving"),
        ("rendering", "2d/snap/snap_2d_vertices_to_pixel", "true", "S3",
         "Vertices not snapped to pixel: edges wobble on moving sprites"),
    ]
    for _, key, want, sev, msg in rules:
        got = val(key)
        if got != want:
            findings.append({"severity": sev, "check": "G1 project", "file": "project.godot",
                             "detail": f"{key} = {got or '(default)'}; want {want}. {msg}"})


def check_filters(root: Path, findings):
    """G2: code or scenes that switch a sprite to smooth (linear) filtering."""
    pats = [(r"TEXTURE_FILTER_LINEAR", "*.gd"), (r"^texture_filter\s*=\s*[1357]\b", "*.tscn")]
    for pat, glob in pats:
        for f in sorted(root.rglob(glob)):
            if "addons" in f.parts or ".godot" in f.parts:
                continue
            for i, line in enumerate(f.read_text(errors="ignore").splitlines(), 1):
                if re.search(pat, line.strip()):
                    findings.append({"severity": "S1", "check": "G2 filter", "file": f"{f.relative_to(root).as_posix()}:{i}",
                                     "detail": f"linear (smooth) filtering: `{line.strip()[:70]}`; pixel art must use Nearest"})


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=".")
    ap.add_argument("--manifest", default="tools/art_audit/art_manifest.json")
    ap.add_argument("--palette", default="tools/art_audit/palette.hex")
    ap.add_argument("--out", default="test-output/art_audit")
    ap.add_argument("--window-scale", type=int, default=4, help="window/viewport ratio, 1280/320 = 4")
    ap.add_argument("--max-colours", type=int, default=16, help="on-screen colour budget per sprite")
    ap.add_argument("--drift", type=float, default=40.0, help="RGB distance counted as off-palette")
    ap.add_argument("--art-scale", type=float, default=0.5,
                    help="the project's standard visual_scale (task 033: characters at 0.5)")
    ap.add_argument("--strict-groups", default="props,vfx",
                    help="groups held to the prop palette and colour budget in absolute terms")
    args = ap.parse_args(argv)

    root = Path(args.project)
    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    pal = load_palette(Path(args.palette))
    outline = pal[:1]  # first palette entry is the outline colour
    manifest = json.loads(Path(args.manifest).read_text())
    findings, rows, lineup, chunky = [], [], [], []
    seen_files = set()

    check_project(root / "project.godot", findings)
    check_filters(root, findings)

    for e in manifest:
        f = e["file"]; path = root / f
        if not path.exists():
            findings.append({"severity": "S1", "check": "P0 missing", "file": f, "detail": "wired in data but file not found"})
            continue
        name = e.get("id", Path(f).stem)
        if e.get("group") == "unused":
            findings.append({"severity": "S4", "check": "U1 unused", "file": f"{f} [{name}]",
                             "detail": f"loaded but not drawn: {e.get('note', '')}. Remove the entry so it cannot creep back in"})
            continue
        sheet = np.array(Image.open(path).convert("RGBA"))
        s = float(e.get("scale", 1.0))

        # ---- source-file checks, once per file
        if f not in seen_files:
            seen_files.add(f)
            a = sheet[..., 3]
            op = int((a > 0).sum())
            partial = int(((a > 0) & (a < 255)).sum())
            if partial and op:
                share = partial / op
                sev = "S1" if share > 0.05 else "S2"
                findings.append({"severity": sev, "check": "P2 alpha", "file": f,
                                 "detail": f"{share:.0%} of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255"})
            imp = path.with_suffix(path.suffix + ".import")
            if imp.exists():
                it = imp.read_text(errors="ignore")
                if 'importer="skip"' not in it:
                    m = re.search(r"compress/mode=(\d+)", it)
                    if m and m.group(1) != "0":
                        findings.append({"severity": "S1", "check": "P8 import", "file": f, "detail": f"compress/mode={m.group(1)}; set Lossless"})
                    if re.search(r"mipmaps/generate=true", it):
                        findings.append({"severity": "S2", "check": "P8 import", "file": f, "detail": "mipmaps on; turn off for pixel art"})

        if e.get("group") == "fonts":
            continue
        # ---- on-screen checks per use
        frame = crop_alpha(first_frame(sheet, e))
        screen = crop_alpha(nearest_resample(frame, s))
        ratio = 1 / s
        alpha = screen[..., 3] > 0
        opx = screen[alpha][:, :3]
        n_col = len(np.unique(opx, axis=0)) if len(opx) else 0
        dist = palette_distance(opx, pal) if len(opx) else np.array([0])
        drift = float((dist > args.drift).mean()) if len(opx) else 0.0
        em = edge_mask(alpha)
        epx = screen[em][:, :3]
        if len(epx):
            dark = (epx.astype(int) @ np.array([299, 587, 114]) / 1000) < 70
            near_ol = palette_distance(epx, outline) < 45
            ol_share = float((dark | near_ol).mean())
        else:
            ol_share = 0.0
        h_screen = screen.shape[0]

        where = f"{f} [{name}]"
        k = args.art_scale / s  # source texels per standard art pixel
        if abs(k - 1) > 0.01:
            if k > 1 and abs(k - round(k)) < 0.01:
                sev, why = "S2", f"{k:.0f} texels per art pixel: finer detail than the standard, dropped evenly"
            elif k < 1 and abs(1 / k - round(1 / k)) < 0.01:
                chunky.append(name)  # reported once, as a style decision
                sev = None
            else:
                sev, why = "S1", f"{k:.2f} texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion"
            if sev:
                findings.append({"severity": sev, "check": "D1 density", "file": where,
                                 "detail": f"visual_scale {s:g} vs standard {args.art_scale:g}; {why}. "
                                           f"Re-export so it draws at {args.art_scale:g} ({round(h_screen / args.art_scale)} px tall in the file)"})
        strict = e.get("group") in args.strict_groups.split(",")
        if strict and drift > 0.25:
            findings.append({"severity": "S2", "check": "D2 palette", "file": where,
                             "detail": f"{drift:.0%} of on-screen pixels are off the prop palette"})
        if strict and n_col > args.max_colours:
            findings.append({"severity": "S2", "check": "D3 colours", "file": where,
                             "detail": f"{n_col} colours on screen (prop budget {args.max_colours})"})
        rows.append({"id": name, "file": f, "group": e.get("group", ""), "scale": s, "src_per_screen": round(ratio, 2),
                     "screen_h": h_screen, "colours": n_col, "off_palette": round(drift, 2), "outline": round(ol_share, 2)})
        if e.get("lineup", True):
            lineup.append((name, e.get("group", ""), frame, s))
        rows[-1]["_where"] = where
        rows[-1]["_outline_rule"] = bool(e.get("outline", True))

    if chunky:
        findings.append({"severity": "S3", "check": "D1 density", "file": f"{len(chunky)} props/VFX at visual_scale 1",
                         "detail": "each texel covers 2x2 art pixels, so props are chunkier than the 0.5-scale characters. "
                                   "Style decision: accept as a deliberate 'chunky world, finer cast' look, or redraw props at "
                                   "double resolution. Sprites: " + ", ".join(chunky)})
    # Peer outliers: compare each sprite with the median of its own group
    groups = {}
    for r in rows:
        groups.setdefault(r["group"], []).append(r)
    for g, rs in groups.items():
        if g in args.strict_groups.split(",") or len(rs) < 3:
            continue
        med_c = float(np.median([r["colours"] for r in rs]))
        med_o = float(np.median([r["outline"] for r in rs if r["_outline_rule"]] or [0]))
        for r in rs:
            if r["colours"] > 2 * med_c and r["colours"] - med_c > 30:
                findings.append({"severity": "S3", "check": "D3 colours", "file": r["_where"],
                                 "detail": f"{r['colours']} colours on screen vs {med_c:.0f} median for {g}: busier than its peers"})
            if r["_outline_rule"] and r["screen_h"] >= 10 and med_o >= 0.6 and r["outline"] < med_o - 0.3:
                findings.append({"severity": "S2", "check": "D4 outline", "file": r["_where"],
                                 "detail": f"{r['outline']:.0%} of the silhouette is dark outline vs {med_o:.0%} median for {g}"})
    char = [r for r in rows if r["group"] in ("people", "vendors", "diner", "gull")]
    prop = [r for r in rows if r["group"] == "props"]
    if char and prop:
        findings.append({"severity": "S2", "check": "D5 style gap", "file": "characters vs props",
                         "detail": f"characters average {np.mean([r['colours'] for r in char]):.0f} colours on screen and "
                                   f"{np.mean([r['off_palette'] for r in char]):.0%} off the prop palette; props average "
                                   f"{np.mean([r['colours'] for r in prop]):.0f} colours, 0% off. Decide whether props get a "
                                   f"painted pass or characters get a palette-snap pass"})
    for r in rows:
        r.pop("_where", None); r.pop("_outline_rule", None)
    findings.sort(key=lambda x: (SEV[x["severity"]], x["check"], x["file"]))
    (out / "findings.json").write_text(json.dumps({"findings": findings, "sprites": rows}, indent=1))

    counts = {k: sum(1 for x in findings if x["severity"] == k) for k in SEV}
    md = ["# Gullin' It pixel art audit", "",
          f"Sprites checked: {len(rows)} uses of {len(seen_files)} files  ",
          "Findings: " + ", ".join(f"{k} {v}" for k, v in counts.items()), "",
          "## Sprites on screen", "",
          "| Sprite | Group | Scale | Src px per screen px | Height on screen | Colours | Off-palette | Outline |",
          "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    for r in sorted(rows, key=lambda r: (r["group"], r["id"])):
        md.append(f"| {r['id']} | {r['group']} | {r['scale']:g} | {r['src_per_screen']} | {r['screen_h']} | {r['colours']} | {r['off_palette']:.0%} | {r['outline']:.0%} |")
    md += ["", "## Findings", "", "| Severity | Check | Where | Detail |", "| --- | --- | --- | --- |"]
    md += [f"| {x['severity']} | {x['check']} | `{x['file']}` | {x['detail']} |" for x in findings]
    (out / "report.md").write_text("\n".join(md) + "\n")

    render_lineup(lineup, out / "lineup_viewport.png", args.window_scale, canvas_items=False)
    render_lineup(lineup, out / "lineup_canvas_items.png", args.window_scale, canvas_items=True)
    print(f"{len(rows)} sprite uses | " + " ".join(f"{k}:{v}" for k, v in counts.items()) + f" | {out/'report.md'}")
    return 1 if counts["S1"] else 0


def render_lineup(items, out: Path, k: int, canvas_items: bool, width: int = 1600):
    """Sprites on one ground line. viewport: render at 320x180 then blow up by k.
    canvas_items: render each sprite straight at window resolution (scale * k), as Godot does now."""
    sand, sky, text = (232, 211, 162, 255), (169, 215, 210, 255), (24, 59, 78)
    imgs = []
    for name, group, frame, s in items:
        if canvas_items:
            im = crop_alpha(nearest_resample(frame, s * k))
        else:
            im = crop_alpha(nearest_resample(crop_alpha(nearest_resample(frame, s)), k))
        imgs.append((name, group, im))
    pad, rows, x, row, rh = 10, [], pad if False else 10, [], 0
    for it in imgs:
        w = it[2].shape[1]
        if x + w + pad > width and row:
            rows.append((row, rh)); row, x, rh = [], 10, 0
        row.append((x, it)); x += w + pad; rh = max(rh, it[2].shape[0])
    if row:
        rows.append((row, rh))
    H = sum(r[1] + 40 for r in rows) + 10
    canvas = Image.new("RGBA", (width, H), sky)
    d = ImageDraw.Draw(canvas)
    y = 10
    for row, rh in rows:
        d.rectangle([0, y + rh, width, y + rh + 30], fill=sand)
        for x0, (name, group, im) in row:
            canvas.alpha_composite(Image.fromarray(im), (x0, y + rh - im.shape[0]))
            d.text((x0, y + rh + 4), name[:max(4, im.shape[1] // 6)], fill=text)
        y += rh + 40
    canvas.save(out)


if __name__ == "__main__":
    sys.exit(main())
