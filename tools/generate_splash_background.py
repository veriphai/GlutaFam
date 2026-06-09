#!/usr/bin/env python3
"""Render the CosmicBackground (login screen backdrop) as a static PNG for
the native splash screen.

Replicates lib/screens/home/career/cosmicBackground.dart:
  - vertical gradient bgTop #081B3F -> bgMid #07162F -> bgBottom #0B1028
  - purple glow (#7C4DFF @ 22%) top-left, blue glow (#00B8FF @ 16%) right
  - field of small white stars at varying opacity

Output: assets/splash-background.png (1440x3120 portrait; flutter_native_splash
crops it to fill each device screen).

Usage: python3 tools/generate_splash_background.py
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/splash-background.png"

W, H = 1440, 3120

BG_TOP = (0x08, 0x1B, 0x3F)
BG_MID = (0x07, 0x16, 0x2F)
BG_BOTTOM = (0x0B, 0x10, 0x28)
PURPLE = (0x7C, 0x4D, 0xFF)
BLUE = (0x00, 0xB8, 0xFF)


def base() -> np.ndarray:
    """Vertical 3-stop gradient + two radial glows, as float RGB [0..1]."""
    t = np.linspace(0.0, 1.0, H)[:, None]  # 0 at top, 1 at bottom
    top, mid, bot = (np.array(c, dtype=float) / 255 for c in (BG_TOP, BG_MID, BG_BOTTOM))
    upper = top + (mid - top) * np.clip(t * 2, 0, 1)
    lower = mid + (bot - mid) * np.clip(t * 2 - 1, 0, 1)
    grad = np.where(t < 0.5, upper, lower)  # (H, 3)
    img = np.broadcast_to(grad[:, None, :], (H, W, 3)).copy()

    yy, xx = np.mgrid[0:H, 0:W].astype(float)

    def glow(cx, cy, radius, color, alpha):
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        a = np.clip(1 - d / radius, 0, 1) * alpha  # linear falloff like RadialGradient
        c = np.array(color, dtype=float) / 255
        img[:] = img * (1 - a[..., None]) + c * a[..., None]

    # Same anchors as _CosmicPainter (fractions of width/height).
    glow(W * 0.12, H * 0.10, W * 0.55, PURPLE, 0.22)
    glow(W * 0.95, H * 0.30, W * 0.50, BLUE, 0.16)
    return img


def main() -> None:
    img = Image.fromarray((base() * 255).round().astype(np.uint8), "RGB")

    # Star field — same distribution as _CosmicBackgroundState (70 stars on a
    # phone-sized canvas; scale count up for the taller splash canvas).
    draw = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(42)
    for _ in range(170):
        x, y = rnd.random() * W, rnd.random() * H
        radius = (rnd.random() * 1.4 + 0.5) * (W / 390)  # logical px -> image px
        opacity = (rnd.random() * 0.5 + 0.3) * (0.4 + rnd.random() * 0.6)
        a = int(255 * min(opacity, 1.0))
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=(255, 255, 255, a))

    img.save(OUT, optimize=True)
    print(f"wrote {OUT.relative_to(ROOT)} ({W}x{H})")


if __name__ == "__main__":
    main()
