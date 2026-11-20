#!/usr/bin/env python3
"""Prepare the exact 13 approved POTS PNGs for a native Xcode asset catalog.

Run after importing POTS_13_Color_Matched_Icons.zip:
  python3 POTSTracker/tools/prepare_assets.py

Requires Pillow only to render the required opaque 1024px iOS Home Screen icon.
The 12 in-app feature icons are copied without modifying their pixels.
"""
import json
import base64
import io
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
        # The branded Home Screen icon is a compact WebP payload. Restore its
        # native 1024px PNG at build time; leave the other 12 icons untouched.
        if name == NAMES[0] and (ICON_DIR / "POTS_Posies_App_Icon.webp.b64").is_file():
            encoded = (ICON_DIR / "POTS_Posies_App_Icon.webp.b64").read_text().strip()
            raw = base64.b64decode(encoded, validate=True)
            with Image.open(io.BytesIO(raw)) as branded:
                branded.convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS).save(
                    image_dir / name, "PNG", optimize=True)
        else:
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
    branded_image = CATALOG / f"{Path(NAMES[0]).stem}.imageset" / NAMES[0]
    with Image.open(branded_image) as image:
        img = image.convert("RGBA")
        background = Image.new("RGBA", img.size, (246, 176, 199, 255))
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
