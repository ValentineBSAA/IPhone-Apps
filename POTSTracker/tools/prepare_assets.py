#!/usr/bin/env python3
"""Prepare the exact 13 approved POTS PNGs for a native Xcode asset catalog.

Run after importing POTS_13_Color_Matched_Icons.zip:
  python3 POTSTracker/tools/prepare_assets.py

Requires Pillow only to render the required opaque 1024px iOS Home Screen icon.
The 12 in-app feature icons are copied without modifying their pixels.
"""
import json
import hashlib
import shutil
from pathlib import Path
from PIL import Image
from import_icons import NAMES, validate_png

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "Resources" / "Icons"
CATALOG = ROOT / "Resources" / "Assets.xcassets"

def main():
    expected = {f"{name}" for name in NAMES}
    available = {p.name for p in ICON_DIR.glob("*.png")} if ICON_DIR.exists() else set()
    if available != expected:
        missing = sorted(expected - available)
        extra = sorted(available - expected)
        raise SystemExit(
            f"Approved icon assets missing or inconsistent. Missing: {missing}; unexpected: {extra}. "
            "Upload POTS_13_Color_Matched_Icons.zip as POTSTracker/assets/approved-icon-pack.zip "
            "and let the import workflow run. Do not substitute generic icons."
        )

    CATALOG.mkdir(parents=True, exist_ok=True)
    image_hashes = set()
    for name in NAMES:
        path = ICON_DIR / name
        data = path.read_bytes()
        validate_png(data, name)
        sha = hashlib.sha256(data).hexdigest()
        if sha in image_hashes:
            raise SystemExit(f"Duplicate PNG content detected: {name}")
        image_hashes.add(sha)

        stem = path.stem
        image_dir = CATALOG / f"{stem}.imageset"
        image_dir.mkdir(exist_ok=True)
        shutil.copyfile(path, image_dir / name)
        (image_dir / "Contents.json").write_text(
            json.dumps({
                "images": [{"filename": name, "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1}
            }, indent=2) + "\n", encoding="utf-8"
        )
        print(f"Ready: {stem}, SHA256 {sha[:12]}")

    # Apple app icons must be square and opaque. Keep the approved artwork
    # unchanged in its imageset; flatten ONLY the Home Screen app-icon copy.
    appicon_set = CATALOG / "AppIcon.appiconset"
    appicon_set.mkdir(exist_ok=True)
    with Image.open(ICON_DIR / NAMES[0]) as image:
        img = image.convert("RGBA")
        background = Image.new("RGBA", img.size, (13, 111, 145, 255))
        background.alpha_composite(img)
        opaque = background.convert("RGB")
        opaque.save(appicon_set / "AppIcon-1024.png", "PNG", optimize=True)
    (appicon_set / "Contents.json").write_text(
        json.dumps({
            "images": [
                {"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}
            ],
            "info": {"author": "xcode", "version": 1}
        }, indent=2) + "\n", encoding="utf-8"
    )
    print("All 13 original icon imagesets + an opaque iOS AppIcon generated. No fallback assets.")

if __name__ == "__main__":
    main()
