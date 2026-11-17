#!/usr/bin/env python3
"""Convert the original LAST SEEN photo pack into native iOS assets.

Publish the ZIP (LAST_SEEN_10_Story_Photos.zip) as a GitHub Release asset
at tag "story-photos-v1", or place it in LastSeen/StoryPhotos.zip before build.
No external image fetching at game runtime. All shipped photos are offline.
"""

import argparse
import json
import sys
from pathlib import Path
from zipfile import ZipFile, BadZipFile

PHOTOS = {
    "01_nora_hallway.jpg": "Story_01_Nora_Hallway",
    "02_elevator_reflection.jpg": "Story_02_Elevator_Reflection",
    "03_nora_front_door.jpg": "Story_03_Nora_Front_Door",
    "04_impossible_hallway.jpg": "Story_04_Impossible_Hallway",
    "05_eli_maintenance_room.jpg": "Story_05_Eli_Maintenance",
    "06_inside_elevator.jpg": "Story_06_Inside_Elevator",
    "07_eli_building_records.jpg": "Story_07_Building_Records",
    "08_unknown_your_door.jpg": "Story_08_Unknown_Your_Door",
    "09_empty_stairwell.jpg": "Story_09_Stairwell",
    "10_final_reveal.jpg": "Story_10_Final_Reveal",
}

def import_pack(zip_path: Path, asset_dir: Path, required: bool) -> int:
    if not zip_path.exists():
        if required:
            raise FileNotFoundError("Missing story-photo archive: " + str(zip_path))
        print("NOTICE: No story photos archive. Existing app fallback artwork remains.")
        return 0

    with ZipFile(zip_path) as archive:
        paths = set(archive.namelist())
        missing = set(PHOTOS) - paths
        if missing:
            raise ValueError("Archive is missing: " + ", ".join(sorted(missing)))
        for filename, asset in PHOTOS.items():
            photo = archive.read(filename)
            if len(photo) < 1024 or not photo.startswith(b"\xff\xd8\xff") or not photo.endswith(b"\xff\xd9"):
                raise ValueError("Not a complete JPEG: " + filename)
            target = asset_dir / (asset + ".imageset")
            target.mkdir(parents=True, exist_ok=True)
            (target / "photo.jpg").write_bytes(photo)
            (target / "Contents.json").write_text(
                json.dumps({
                    "images": [{"filename": "photo.jpg", "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1},
                }, indent=2) + "\n",
                encoding="utf-8",
            )
    print(f"Imported {len(PHOTOS)} offline story photographs for iOS.")
    return len(PHOTOS)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", type=Path, default=Path("StoryPhotos.zip"))
    parser.add_argument("--assets", type=Path, default=Path("LastSeenApp/Assets.xcassets"))
    parser.add_argument("--required", action="store_true")
    args = parser.parse_args()
    try:
        return import_pack(args.zip, args.assets, args.required)
    except (OSError, ValueError, BadZipFile) as err:
        print(f"ERROR: {err}", file=sys.stderr)
        raise SystemExit(1)

if __name__ == "__main__":
    main()
