#!/usr/bin/env python3
"""Validate and optionally import 30 approved Night Edition PNG image sets.

Usage:
  python3 Tools/import_night_assets.py path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip
  python3 Tools/import_night_assets.py path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip --apply

Dry-run by default; --apply copies *only* the 30 Night_*.imageset directories.
Refuses to replace an existing different asset or modify daytime files.
"""
import argparse
import json
import struct
import sys
from pathlib import Path
from zipfile import ZipFile

EXPECTED = {
    "Night_Approved_Night_Market_Storefront",
    "Night_Blossom_Decoration",
    "Night_Blossom_Gate",
    "Night_Blossom_Glass_Board_8x8_Concept",
    "Night_Blossom_Glass_Frame_Transparent_Center",
    "Night_Board_Theme_Icon",
    "Night_Developer_Mode_Strawberry_Lock",
    "Night_Flower",
    "Night_Garden_Mode",
    "Night_Help",
    "Night_Home",
    "Night_Moonberry_Currency",
    "Night_Pause",
    "Night_Rocket",
    "Night_Rotate",
    "Night_Seed",
    "Night_Settings",
    "Night_Special_Tools",
    "Night_Storage",
    "Night_Strawberry_Blossom_Decoration",
    "Night_Strawberry_Currency",
    "Night_Sweet_Endless",
    "Night_Tile_Empty",
    "Night_Tile_Green",
    "Night_Tile_Pink",
    "Night_Tile_Purple",
    "Night_Tile_Sparkle",
    "Night_Tile_Strawberry",
    "Night_Tile_Teal",
    "Night_Tile_Yellow",
}
ASSET_ROOT = Path(__file__).resolve().parents[1] / "BerryBlockBlast" / "Assets.xcassets"
ZIP_ROOT = "Night_Edition.xcassets/"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def png_details(data: bytes):
    if not data.startswith(PNG_SIGNATURE) or len(data) < 33 or data[12:16] != b"IHDR":
        raise ValueError("Missing valid PNG IHDR")
    width, height = struct.unpack(">II", data[16:24])
    if width == 0 or height == 0 or data[25] != 6:
        raise ValueError("PNG must have nonzero dimensions and RGBA transparency")
    return width, height


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path, help="Night Edition Xcode asset catalog zip")
    parser.add_argument("--apply", action="store_true", help="Copy after checking all 30 image sets")
    args = parser.parse_args()
    if not args.zip.is_file():
        parser.error("The Night Edition ZIP was not found")
    queued = []
    with ZipFile(args.zip) as archive:
        if archive.testzip():
            raise ValueError("ZIP integrity check failed")
        names = set(archive.namelist())
        image_sets = {
            p[len(ZIP_ROOT):].split("/")[0].removesuffix(".imageset")
            for p in names
            if p.startswith(ZIP_ROOT) and ".imageset/" in p and not p.endswith("/")
        }
        if image_sets != EXPECTED:
            raise ValueError(
                f"Expected exactly 30 night image sets; missing={sorted(EXPECTED-image_sets)}, "
                f"unexpected={sorted(image_sets-EXPECTED)}"
            )
        for asset in sorted(EXPECTED):
            parent = ZIP_ROOT + asset + ".imageset/"
            png_name = asset + ".png"
            paths = {parent + png_name, parent + "Contents.json"}
            if not paths.issubset(names):
                raise ValueError(f"Missing PNG or Contents.json for {asset}")
            doc = json.loads(archive.read(parent + "Contents.json"))
            entries = doc.get("images", [])
            if len(entries) != 1 or entries[0].get("filename") != png_name:
                raise ValueError(f"Invalid Xcode Contents.json for {asset}")
            night_png = archive.read(parent + png_name)
            night_size = png_details(night_png)
            day_name = asset.removeprefix("Night_")
            day_image_set = ASSET_ROOT / (day_name + ".imageset")
            day_png = day_image_set / (day_name + ".png")
            if not day_png.is_file():
                raise ValueError(f"Missing existing daytime asset: {day_png}")
            if png_details(day_png.read_bytes()) != night_size:
                raise ValueError(f"Night/day image dimensions mismatch for {asset}")
            for filename in (png_name, "Contents.json"):
                target = ASSET_ROOT / (asset + ".imageset") / filename
                data = archive.read(parent + filename)
                if target.exists() and target.read_bytes() != data:
                    raise ValueError(f"Refusing to overwrite different existing file: {target}")
                queued.append((target, data))
    if args.apply:
        for target, data in queued:
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.exists():
                target.write_bytes(data)
        print("Imported 30 separate Night Edition image sets; daytime originals unchanged.")
    else:
        print("PASS: 30 RGBA, valid Xcode image sets, matching daytime dimensions.")
        print("Dry run only. Rerun with --apply to import on the development branch.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"Night Edition import failed: {exc}", file=sys.stderr)
        sys.exit(1)
