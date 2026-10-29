"""Cuts the platform icon sizes from the layers in assets/icon/.

Run `flutter test tool/generate_icon_test.dart` first, then:

    python tool/build_icons.py
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "icon"
full = Image.open(SRC / "skycast_icon.png").convert("RGBA")
foreground = Image.open(SRC / "skycast_icon_foreground.png").convert("RGBA")
background = Image.open(SRC / "skycast_icon_background.png").convert("RGBA")


def resized(image, px):
    return image.resize((px, px), Image.LANCZOS)


# --- iOS: opaque squares (the system applies the corner mask) ---------------
ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
contents = json.loads((ios / "Contents.json").read_text())
for entry in contents["images"]:
    size = float(entry["size"].split("x")[0])
    px = round(size * int(entry["scale"].rstrip("x")))
    resized(full, px).convert("RGB").save(ios / entry["filename"])

# --- Android -----------------------------------------------------------------
res = ROOT / "android/app/src/main/res"
densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def rounded(image, radius_fraction=0.22):
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, *image.size), radius=int(image.width * radius_fraction), fill=255
    )
    out = image.copy()
    out.putalpha(mask)
    return out


for name, scale in densities.items():
    folder = res / f"mipmap-{name}"
    folder.mkdir(parents=True, exist_ok=True)
    # Legacy launchers (API < 26): 48dp rounded square.
    rounded(resized(full, round(48 * scale))).save(folder / "ic_launcher.png")
    # Adaptive icon layers (API 26+): 108dp each.
    layer = round(108 * scale)
    resized(foreground, layer).save(folder / "ic_launcher_foreground.png")
    resized(background, layer).convert("RGB").save(
        folder / "ic_launcher_background.png"
    )

adaptive = res / "mipmap-anydpi-v26"
adaptive.mkdir(parents=True, exist_ok=True)
(adaptive / "ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    "</adaptive-icon>\n"
)
print("icons written")
