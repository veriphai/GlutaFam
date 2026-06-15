#!/usr/bin/env python3
"""Prep the Hunter-Gatherer sprite pack for Ember.

The pack is already RGBA with backgrounds removed, but the sprites are 1254x1254
with large transparent margins (wrong anchoring/scale) and ~223MB total (too heavy
for the app). This makes them game-ready:
  1. (rare) remove a still-solid background via border flood-fill (only if corners
     are near-opaque, alpha>200 — leaves intentional translucent overlays alone),
  2. kill faint alpha dust (alpha<6 -> 0),
  3. auto-crop to the alpha bounding box (+small pad) so the sprite anchors/scales right,
  4. downscale so the longest edge <= TARGET (LANCZOS),
  5. flatten into assets/ember/sprites/<name>.png (category-prefixed names kept).

Usage: python3 tools/ember_prep_sprites.py
"""
import glob, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "/Users/Sahu/Downloads/hunter_gatherer_sprite_pack_v1/assets"
DST = "/Users/Sahu/Desktop/Work/GlutaFam/assets/ember/sprites"
TARGET = 512          # max longest edge after downscale
ALPHA_DUST = 6        # alpha <= this -> fully transparent
ALPHA_BBOX = 12       # alpha > this counts as content for the crop bbox
PAD = 4               # px padding around the cropped content

os.makedirs(DST, exist_ok=True)

def remove_solid_bg(im):
    """Flood-fill the border-connected near-corner-colour region to transparent.
    Only called when corners are near-opaque (a real baked bg)."""
    arr = np.array(im)  # HxWx4
    rgb = arr[:, :, :3].astype(np.int16)
    h, w = arr.shape[:2]
    corners = np.array([arr[0, 0, :3], arr[0, w-1, :3], arr[h-1, 0, :3], arr[h-1, w-1, :3]], dtype=np.int16)
    bg = np.median(corners, axis=0)
    dist = np.abs(rgb - bg).sum(axis=2)
    near_bg = dist < 40
    # keep only the bg-coloured region connected to the image border
    lbl, n = ndimage.label(near_bg)
    border = set(lbl[0, :]).union(lbl[-1, :]).union(lbl[:, 0]).union(lbl[:, -1]) - {0}
    bg_mask = np.isin(lbl, list(border))
    arr[bg_mask, 3] = 0
    return Image.fromarray(arr, "RGBA")

def prep(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    a = im.split()[3]
    corners = [a.getpixel((1, 1)), a.getpixel((w-2, 1)), a.getpixel((1, h-2)), a.getpixel((w-2, h-2))]
    removed = False
    if min(corners) > 200:            # a genuine still-solid baked background
        im = remove_solid_bg(im); removed = True
    arr = np.array(im)
    arr[arr[:, :, 3] <= ALPHA_DUST, 3] = 0     # kill dust/halo
    # autocrop to alpha bbox
    ys, xs = np.where(arr[:, :, 3] > ALPHA_BBOX)
    if len(xs) == 0:
        return None, removed, "empty-after-alpha"
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    x0 = max(0, x0 - PAD); y0 = max(0, y0 - PAD)
    x1 = min(arr.shape[1]-1, x1 + PAD); y1 = min(arr.shape[0]-1, y1 + PAD)
    im = Image.fromarray(arr, "RGBA").crop((x0, y0, x1+1, y1+1))
    # downscale
    cw, ch = im.size
    scale = TARGET / max(cw, ch)
    if scale < 1.0:
        im = im.resize((max(1, round(cw*scale)), max(1, round(ch*scale))), Image.LANCZOS)
    return im, removed, f"{w}x{h}->{im.size[0]}x{im.size[1]}"

def main():
    files = sorted(glob.glob(os.path.join(SRC, "**", "*.png"), recursive=True))
    n_removed = n_ok = 0
    for f in files:
        name = os.path.basename(f)
        im, removed, info = prep(f)
        if im is None:
            print("SKIP", name, info); continue
        im.save(os.path.join(DST, name), optimize=True)
        n_ok += 1
        if removed: n_removed += 1
    out_files = glob.glob(os.path.join(DST, "*.png"))
    total = sum(os.path.getsize(p) for p in out_files)
    print(f"\nDONE: {n_ok} sprites -> {DST}")
    print(f"  bg-removed (flood-fill): {n_removed}")
    print(f"  output total size: {total/1e6:.1f} MB ({len(out_files)} files)")

if __name__ == "__main__":
    main()
