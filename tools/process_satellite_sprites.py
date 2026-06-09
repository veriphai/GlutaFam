#!/usr/bin/env python3
"""Clean the "Build Your Satellite" prototype sprites for production use.

The generated sprites ship at 1254x1254 with a BAKED, OPAQUE checkerboard
background (hasAlpha: no). Rendered in Flame they would look like checkerboard
squares. This script:

  1. Strips the checkerboard -> true alpha transparency, using CONNECTIVITY
     (flood from the borders) rather than a global colour key, so the
     satellite's own bright-white highlights are preserved.
  2. Optionally clears large ENCLOSED holes (e.g. the camera octagon on the
     body) via a per-sprite minimum-hole-area override.
  3. De-fringes (1px erosion) + feathers the alpha edge.
  4. Trims to the content bounding box (+ small transparent pad).
  5. Downscales the long side to a mobile-safe size (LANCZOS anti-aliases the
     alpha edge).
  6. Writes transparent PNGs + asset_meta.json to assets/images/build_satellite/.

Run from the repo root:  python3 tools/process_satellite_sprites.py
Requires: Pillow, numpy, scipy (all already present in this environment).
"""

import json
import os

import numpy as np
import scipy.ndimage as ndi
from PIL import Image, ImageFilter

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SRC_DIR = "/Users/Sahu/Downloads/build_your_satellite_sprites"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "images", "build_satellite")

# ---------------------------------------------------------------------------
# Background detection tuning
# ---------------------------------------------------------------------------
# The checkerboard is two near-neutral light-grey shades (~242 and ~254).
# A "background candidate" pixel is bright AND near-neutral (low channel spread)
# so coloured art (blue panels, gold trim, glows) is never matched.
BG_MIN_BRIGHTNESS = 228      # min(R,G,B) must be at least this
NEUTRAL_TOL = 14             # max(R,G,B) - min(R,G,B) must be <= this

# Per-sprite overrides. Anything not listed uses DEFAULTS.
DEFAULTS = dict(
    target_long=512,         # longest output side in px
    erode=1,                 # px to shrink the opaque mask (kills light fringe)
    feather=1.0,             # gaussian radius applied to alpha before downscale
    pad_frac=0.03,           # transparent padding around trimmed content
    min_hole_area=None,      # None = keep all enclosed holes (solid object)
)
OVERRIDES = {
    # Canonical body: larger, and clear the enclosed camera-bay octagon so the
    # camera part (and space behind) shows through instead of checkerboard.
    "satellite_body_empty.png": dict(target_long=820, min_hole_area=12000),
    # Ring / halo / wave effects: clear the enclosed faint-grey interior so only
    # the coloured glow survives (rendered additively in Flame). Small enclosed
    # bright sparkles stay (below min_hole_area).
    "drop_zone_ring.png":          dict(target_long=512, min_hole_area=2000),
    "correct_slot_glow.png":       dict(target_long=512, min_hole_area=2000),
    "wrong_slot_warning.png":      dict(target_long=512, min_hole_area=2000),
    "signal_wave_effect.png":      dict(target_long=512, min_hole_area=2000),
    # Solid bright cores: keep interior intact (min_hole_area off).
    "snap_flash.png":              dict(target_long=512),
    "energy_flow_line.png":        dict(target_long=512),
    "thruster_flame.png":          dict(target_long=384),
    "energy_particle.png":         dict(target_long=192),
    "solar_panel_glow_overlay.png": dict(target_long=512),
}

# We deliberately SKIP the four *_slot_empty files: they are alternate
# full-body renders from different camera angles, not overlay decals, so they
# are never composited onto the canonical body.
SKIP = {
    "camera_slot_empty.png",
    "antenna_socket_empty.png",
    "battery_slot_empty.png",
    "computer_core_slot_empty.png",
    "sprite_manifest.json",
}


def remove_background(rgb: np.ndarray, min_hole_area):
    """Return a uint8 alpha array (0 = transparent) for an HxWx3 RGB image."""
    h, w, _ = rgb.shape
    mn = rgb.min(axis=2)
    mx = rgb.max(axis=2)
    candidate = (mn >= BG_MIN_BRIGHTNESS) & ((mx - mn) <= NEUTRAL_TOL)

    # Keep only candidate regions that touch the border -> the real background.
    labels, _ = ndi.label(candidate)  # 4-connectivity (checker is edge-connected)
    border = np.concatenate([labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]])
    border_ids = set(np.unique(border)) - {0}
    background = np.isin(labels, list(border_ids))

    # Enclosed holes (candidate but not border-connected) are kept as part of
    # the object UNLESS they are large enough to be a real cut-out (e.g. the
    # camera bay) per the sprite's min_hole_area.
    if min_hole_area is not None:
        interior = candidate & ~background
        hole_labels, n = ndi.label(interior)
        if n:
            sizes = ndi.sum(np.ones_like(hole_labels), hole_labels, range(1, n + 1))
            big = {i + 1 for i, s in enumerate(sizes) if s >= min_hole_area}
            if big:
                background |= np.isin(hole_labels, list(big))

    opaque = ~background
    return opaque


def process(filename: str, cfg: dict):
    src = os.path.join(SRC_DIR, filename)
    img = Image.open(src).convert("RGB")
    rgb = np.asarray(img)
    h, w, _ = rgb.shape

    opaque = remove_background(rgb, cfg["min_hole_area"])

    # De-fringe: shrink the opaque mask slightly to drop the anti-aliased
    # light halo left where the object met the checkerboard.
    if cfg["erode"] > 0:
        opaque = ndi.binary_erosion(opaque, iterations=cfg["erode"])

    alpha = (opaque.astype(np.uint8)) * 255

    # Build RGBA, feather the alpha edge for smoothness.
    rgba = np.dstack([rgb, alpha])
    out = Image.fromarray(rgba, "RGBA")
    if cfg["feather"] > 0:
        a = out.getchannel("A").filter(ImageFilter.GaussianBlur(cfg["feather"]))
        out.putalpha(a)

    # Trim to the content bounding box (+ pad).
    bbox = out.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"{filename}: nothing left after background removal")
    l, t, r, b = bbox
    cw, ch = r - l, b - t
    pad = int(round(max(cw, ch) * cfg["pad_frac"]))
    l, t = max(0, l - pad), max(0, t - pad)
    r, b = min(w, r + pad), min(h, b + pad)
    out = out.crop((l, t, r, b))

    # Downscale the long side.
    cw, ch = out.size
    scale = cfg["target_long"] / max(cw, ch)
    if scale < 1.0:
        out = out.resize((max(1, round(cw * scale)), max(1, round(ch * scale))),
                         Image.LANCZOS)

    os.makedirs(OUT_DIR, exist_ok=True)
    out.save(os.path.join(OUT_DIR, filename))

    return {
        "orig_size": [w, h],
        "content_bbox": [int(l), int(t), int(r), int(b)],
        # Normalised position of the content centre within the ORIGINAL canvas
        # (handy when deriving slot anchors from the source renders).
        "content_center_norm": [round((l + r) / 2 / w, 4), round((t + b) / 2 / h, 4)],
        "output_size": list(out.size),
        "transparent_pct": round(100 * float((np.asarray(out)[:, :, 3] == 0).mean()), 1),
    }


def main():
    files = [f for f in sorted(os.listdir(SRC_DIR))
             if f.endswith(".png") and f not in SKIP]
    meta = {}
    for f in files:
        cfg = {**DEFAULTS, **OVERRIDES.get(f, {})}
        info = process(f, cfg)
        meta[f] = info
        print(f"  {f:34s} -> {info['output_size']}  "
              f"(alpha {info['transparent_pct']}% transparent)")

    with open(os.path.join(OUT_DIR, "asset_meta.json"), "w") as fh:
        json.dump(meta, fh, indent=2)
    print(f"\nWrote {len(files)} sprites + asset_meta.json to {OUT_DIR}")


if __name__ == "__main__":
    main()
