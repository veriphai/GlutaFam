#!/usr/bin/env python3
"""Generate Android mipmap + iOS AppIcon sizes from the master logo.

Usage: python3 tools/generate_app_icons.py [path/to/logo.png]

Flattens the (transparent) logo onto a solid background with padding so
launcher masks (rounded squares / circles) don't clip the artwork, then
exports every required size. iOS icons are saved without an alpha
channel (App Store requirement).
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "assets/howwow-icon.png"

BG_COLOR = (0x13, 0x1F, 0x24)  # matches splash background #131F24
LOGO_SCALE = 0.72  # logo occupies 72% of the canvas -> ~14% padding each side
TRIM = True  # auto-crop the logo's transparent margins before fitting

ANDROID_RES = ROOT / "android/app/src/main/res"
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

IOS_ICONSET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
# filename -> pixel size (pt * scale), mirrors Contents.json
IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def build_master(size: int = 1024) -> Image.Image:
    """Logo centered on a solid background, flattened to RGB."""
    logo = Image.open(LOGO).convert("RGBA")
    if TRIM:
        bbox = logo.getbbox()  # tight box around non-transparent pixels
        if bbox:
            logo = logo.crop(bbox)
    target = int(size * LOGO_SCALE)
    logo.thumbnail((target, target), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), BG_COLOR + (255,))
    offset = ((size - logo.width) // 2, (size - logo.height) // 2)
    canvas.alpha_composite(logo, offset)
    return canvas.convert("RGB")  # drop alpha (required for iOS)


def main() -> None:
    master = build_master()

    for folder, px in ANDROID_SIZES.items():
        out = ANDROID_RES / folder / "logo.png"
        master.resize((px, px), Image.LANCZOS).save(out, optimize=True)
        print(f"android  {out.relative_to(ROOT)}  {px}x{px}")

    for name, px in IOS_SIZES.items():
        out = IOS_ICONSET / name
        master.resize((px, px), Image.LANCZOS).save(out, optimize=True)
        print(f"ios      {out.relative_to(ROOT)}  {px}x{px}")


if __name__ == "__main__":
    main()
