#!/usr/bin/env python3
"""
One-off asset processor for Activity 9 (Satellite Doctor).

The kit shipped FLATTENED (hasAlpha:no). A border-brightness probe showed nearly
every file sits on flat WHITE (br~247, corners ~248) — including the FX glows
(scanner, pulse, signal waves, sun, nebula). Only two exceptions:
  • space_starfield_bg.png  -> midtone opaque BASE layer (keep opaque)
  • solar_panel_restored_glow.png -> on flat BLACK (render additive, no strip)

So:
  • LIGHT  (almost everything) -> border flood-fill (white->alpha) + trim + 512
  • ENV    (earth/sun/nebula/stars/ambient) -> same flood-fill, downscale 768
  • BASE   (starfield) -> downscale 1024, kept opaque
  • DARK   (restored_glow) -> downscale 512, kept opaque (render additive)

Run:  python3 tools/process_satellite_doctor_assets.py
"""
import os, glob
from collections import deque
from PIL import Image

SRC = "/Users/Sahu/Downloads/Satellite Engineer Activities/activity_9_satellite_doctor_image_assets"
OUT = "/Users/Sahu/Desktop/Work/GlutaFam/assets/images/satellite_doctor"

BASE_OPAQUE = {"08_environment/space_starfield_bg.png"}
DARK_KEEP = {"02_part_states/solar_panel/solar_panel_restored_glow.png"}
ENV_768 = {
    "08_environment/soft_nebula_overlay.png",
    "08_environment/distant_star_cluster.png",
    "08_environment/ambient_space_particles.png",
    "08_environment/earth_horizon_bg.png",
    "08_environment/sun_glow_orb.png",
}

MIN_BRIGHT = 226
NEUTRAL_TOL = 22


def build_bg_mask(im):
    w, h = im.size
    px = im.load()
    visited = bytearray(w * h)
    mask = bytearray(w * h)
    dq = deque()

    def is_bg(r, g, b):
        return min(r, g, b) >= MIN_BRIGHT and (max(r, g, b) - min(r, g, b)) <= NEUTRAL_TOL

    for x in range(w):
        dq.append((x, 0)); dq.append((x, h - 1))
    for y in range(h):
        dq.append((0, y)); dq.append((w - 1, y))
    while dq:
        x, y = dq.popleft()
        idx = y * w + x
        if visited[idx]:
            continue
        visited[idx] = 1
        r, g, b, _ = px[x, y]
        if not is_bg(r, g, b):
            continue
        mask[idx] = 1
        if x > 0: dq.append((x - 1, y))
        if x < w - 1: dq.append((x + 1, y))
        if y > 0: dq.append((x, y - 1))
        if y < h - 1: dq.append((x, y + 1))
    return mask


def downscale(im, target):
    w, h = im.size
    s = target / max(w, h)
    if s < 1:
        im = im.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
    return im


def flood_strip(im):
    mask = build_bg_mask(im)
    w, h = im.size
    px = im.load()
    for i in range(w * h):
        if mask[i]:
            x, y = i % w, i // w
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, 0)
    bbox = im.getbbox()  # alpha-only trim (Pillow>=9.2 default)
    if bbox:
        im = im.crop(bbox)
    return im


def main():
    files = sorted(glob.glob(os.path.join(SRC, "**/*.png"), recursive=True))
    counts = {"light": 0, "env": 0, "base": 0, "dark": 0}
    rows = []
    for path in files:
        rel = os.path.relpath(path, SRC)
        if rel.startswith("00_reference_views") or "/extras/" in rel:
            continue
        out_path = os.path.join(OUT, rel)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        im = Image.open(path).convert("RGBA")

        if rel in BASE_OPAQUE:
            im = downscale(im, 1024)
            kind = "base"
        elif rel in DARK_KEEP:
            im = downscale(im, 512)
            kind = "dark"
        elif rel in ENV_768:
            im = downscale(flood_strip(im), 768)
            kind = "env"
        else:
            im = downscale(flood_strip(im), 512)
            kind = "light"
        im.save(out_path)
        counts[kind] += 1

        a = im.split()[3]
        t = sum(1 for v in a.getdata() if v == 0) / (im.size[0] * im.size[1])
        flag = "  <-- CHECK low-transp" if kind in ("light", "env") and t < 0.04 else ""
        rows.append(f"{kind[0]} {t*100:5.1f}%t {str(im.size):11} {rel}{flag}")
    print("\n".join(rows))
    print(f"\nDONE  {counts}")


if __name__ == "__main__":
    main()
