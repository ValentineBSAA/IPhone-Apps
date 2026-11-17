#!/usr/bin/env python3
"""Import the ten original fictional character portraits into the iOS asset catalog.

Usage:
  cd LastSeen
  python3 Tools/import_contacts.py --zip ContactPhotos.zip

The ZIP is deliberately a single easy-to-upload GitHub file. XcodeGen finds all
generated Contact_*.imageset folders when the project is compiled.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from zipfile import ZipFile, BadZipFile

ASSET_NAMES = {
    "nora_01.jpg": "Contact_Nora_01",
    "nora_02.jpg": "Contact_Nora_02",
    "nora_03.jpg": "Contact_Nora_03",
    "nora_04.jpg": "Contact_Nora_04",
    "eli_01.jpg": "Contact_Eli_01",
    "eli_02.jpg": "Contact_Eli_02",
    "eli_03.jpg": "Contact_Eli_03",
    "unit7_01.jpg": "Contact_Unit7_01",
    "unit7_02.jpg": "Contact_Unit7_02",
    "unit7_03.jpg": "Contact_Unit7_03",
}


def import_photos(zip_path: Path, assets_path: Path, *, required: bool) -> int:
    if not zip_path.is_file():
        if required:
            raise FileNotFoundError(f"Missing contact ZIP: {zip_path}")
        print("ContactPhotos.zip is not uploaded yet: keeping initial-based fallback avatars.")
        return 0

    try:
        with ZipFile(zip_path) as archive:
            available = set(archive.namelist())
            missing = set(ASSET_NAMES) - available
            if missing:
                raise ValueError("Missing required portraits: " + ", ".join(sorted(missing)))
            extra_images = {
                Path(n).name for n in available
                if Path(n).suffix.lower() in (".jpg", ".jpeg", ".png")
                and n not in ASSET_NAMES
            }
            if extra_images:
                raise ValueError("Unexpected contact image filenames: " + ", ".join(sorted(extra_images)))
            for filename, asset_name in ASSET_NAMES.items():
                image = archive.read(filename)
                if len(image) < 1024 or not image.startswith(b"\xff\xd8\xff") or not image.endswith(b"\xff\xd9"):
                    raise ValueError(f"{filename} is not a valid complete JPEG")
                target = assets_path / (asset_name + ".imageset")
                target.mkdir(parents=True, exist_ok=True)
                (target / "portrait.jpg").write_bytes(image)
                contents = {
                    "images": [{"filename": "portrait.jpg", "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1},
                }
                (target / "Contents.json").write_text(
                    json.dumps(contents, indent=2) + "\n",
                    encoding="utf-8",
                )
    except BadZipFile as exc:
        raise ValueError("ContactPhotos.zip is corrupt") from exc
    print(f"Imported {len(ASSET_NAMES)} square images; circular crop happens in SwiftUI.")
    return len(ASSET_NAMES)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", default="ContactPhotos.zip", type=Path)
    parser.add_argument("--assets", default="LastSeenApp/Assets.xcassets", type=Path)
    parser.add_argument("--required", action="store_true")
    arguments = parser.parse_args()
    try:
        count = import_photos(arguments.zip, arguments.assets, required=arguments.required)
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
    sys.exit(0)
