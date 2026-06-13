#!/usr/bin/env python3
"""strip_bg.py — give sprite art a real alpha channel, then trim + downscale.

WHY: AI-generated sprites often ship with NO alpha channel — the "transparent"
background is a flattened grey/white checkerboard (hasAlpha: no). Rendered in
Flutter/Flame those squares show as solid pixels. A naive white colour-key would
punch holes in white parts of the art (a white robot, bright highlights), so we
instead FLOOD-FILL the background from the image BORDERS: only the light/neutral
region connected to the edges is removed, so enclosed light art is preserved.

USAGE
  Single file (writes in place unless -o is given):
    python3 strip_bg.py hero.png --preview
    python3 strip_bg.py hero.png -o assets/images/hero.png --target-long 1400
  Batch a folder:
    python3 strip_bg.py --src ./raw --out assets/images/<activity_id> --target-long 512 --preview

  --preview also writes <name>_preview.png composited on dark navy so you can
  eyeball the cutout (confirm no art got eaten).

TUNING
  --min-bright 228     background = min(R,G,B) >= this (bright)
  --neutral-tol 14     ...AND max-min <= this (near-neutral grey/white)
  --erode 1            shrink the opaque mask Npx to kill the anti-aliased fringe
  --feather 1.0        gaussian-blur the alpha edge before downscale
  --pad-frac 0.0       transparent padding around trimmed content (0 = tight)
  --min-hole-area 0    clear ENCLOSED light holes >= N px (e.g. a camera-bay cutout); 0 keeps all
  --target-long 0      downscale longest side to N px (0 = keep original size)
  --no-trim            keep the original canvas (don't crop to the content bbox)

Requires: Pillow, numpy, scipy.
"""
import argparse
import os
import sys

import numpy as np
import scipy.ndimage as ndi
from PIL import Image, ImageFilter


def build_alpha(rgb, min_bright, neutral_tol, min_hole_area, erode):
    """Return a uint8 alpha (0 = transparent) for an HxWx3 RGB array."""
    mn = rgb.min(axis=2)
    mx = rgb.max(axis=2)
    candidate = (mn >= min_bright) & ((mx - mn) <= neutral_tol)

    # Keep only candidate regions connected to the border -> the real background.
    labels, _ = ndi.label(candidate)
    border = np.concatenate([labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]])
    border_ids = set(np.unique(border)) - {0}
    background = np.isin(labels, list(border_ids))

    # Enclosed light holes stay part of the object unless big enough to be a
    # real cut-out (per --min-hole-area).
    if min_hole_area and min_hole_area > 0:
        interior = candidate & ~background
        hole_labels, n = ndi.label(interior)
        if n:
            sizes = ndi.sum(np.ones_like(hole_labels), hole_labels, range(1, n + 1))
            big = [i + 1 for i, s in enumerate(sizes) if s >= min_hole_area]
            if big:
                background |= np.isin(hole_labels, big)

    opaque = ~background
    if erode > 0:
        opaque = ndi.binary_erosion(opaque, iterations=erode)
    return (opaque.astype(np.uint8)) * 255


def process_one(src, dst, a):
    had_alpha = Image.open(src).mode in ("RGBA", "LA")
    img = Image.open(src).convert("RGB")
    rgb = np.asarray(img)
    h, w, _ = rgb.shape

    alpha = build_alpha(rgb, a.min_bright, a.neutral_tol, a.min_hole_area, a.erode)
    out = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")
    if a.feather > 0:
        out.putalpha(out.getchannel("A").filter(ImageFilter.GaussianBlur(a.feather)))

    center_norm = None
    if not a.no_trim:
        bbox = out.getchannel("A").getbbox()
        if bbox is None:
            print(f"  !! {os.path.basename(src)}: nothing left after removal", file=sys.stderr)
            return
        l, t, r, b = bbox
        cw, ch = r - l, b - t
        pad = int(round(max(cw, ch) * a.pad_frac))
        l, t = max(0, l - pad), max(0, t - pad)
        r, b = min(w, r + pad), min(h, b + pad)
        out = out.crop((l, t, r, b))
        center_norm = [round((l + r) / 2 / w, 4), round((t + b) / 2 / h, 4)]

    if a.target_long > 0:
        cw, ch = out.size
        scale = a.target_long / max(cw, ch)
        if scale < 1.0:
            out = out.resize((max(1, round(cw * scale)), max(1, round(ch * scale))), Image.LANCZOS)

    os.makedirs(os.path.dirname(os.path.abspath(dst)) or ".", exist_ok=True)
    out.save(dst)

    tpct = round(100 * float((np.asarray(out)[:, :, 3] == 0).mean()), 1)
    extra = f"  center_norm={center_norm}" if center_norm else ""
    print(f"  {os.path.basename(src):32s} hadAlpha={str(had_alpha):5s} -> {out.size} ({tpct}% transparent){extra}")

    if a.preview:
        arr = np.asarray(out)
        H, W = arr.shape[:2]
        base = np.zeros((H, W, 3), np.uint8)
        base[:] = (24, 36, 79)  # dark navy card colour
        al = arr[:, :, 3:4].astype(float) / 255
        comp = (arr[:, :, :3] * al + base * (1 - al)).astype(np.uint8)
        prev = os.path.splitext(dst)[0] + "_preview.png"
        Image.fromarray(comp).save(prev)
        print(f"      preview -> {prev}")


def main():
    ap = argparse.ArgumentParser(description="Add real alpha transparency to sprite art (flood-fill from borders).")
    ap.add_argument("input", nargs="?", help="single image to process")
    ap.add_argument("-o", "--output", help="output path (default: overwrite input)")
    ap.add_argument("--src", help="batch: source folder")
    ap.add_argument("--out", help="batch: output folder")
    ap.add_argument("--min-bright", type=int, default=228)
    ap.add_argument("--neutral-tol", type=int, default=14)
    ap.add_argument("--erode", type=int, default=1)
    ap.add_argument("--feather", type=float, default=1.0)
    ap.add_argument("--pad-frac", type=float, default=0.0)
    ap.add_argument("--min-hole-area", type=int, default=0)
    ap.add_argument("--target-long", type=int, default=0)
    ap.add_argument("--no-trim", action="store_true")
    ap.add_argument("--preview", action="store_true")
    a = ap.parse_args()

    if a.src and a.out:
        src = os.path.expanduser(a.src)
        files = [f for f in sorted(os.listdir(src)) if f.lower().endswith((".png", ".webp"))]
        if not files:
            ap.error(f"no .png/.webp files in {src}")
        for f in files:
            process_one(os.path.join(src, f), os.path.join(os.path.expanduser(a.out), f), a)
        print(f"\nProcessed {len(files)} file(s) -> {a.out}")
    elif a.input:
        process_one(os.path.expanduser(a.input), os.path.expanduser(a.output or a.input), a)
    else:
        ap.error("provide an input image, or --src and --out for batch mode")


if __name__ == "__main__":
    main()
