#!/usr/bin/env python3
"""Prevent another IPA from silently shipping the wrong art assets."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "BerryBlockBlast" / "Assets.xcassets"
EXPECTED = [
    ("AppIcon.appiconset", "AppIcon.png",
     "a7fe26700c3e344e0a054eb6783777283fcb5e5870842b36659ff3f34e377d35"),
    ("BerryMascot.imageset", "BerryMascot.png",
     "76d83ecf6c7649f19c4eead984ca97e8cba39ffb014d01922490568972bf710b"),
]
errors = []
for folder, filename, expected_hash in EXPECTED:
    directory = ASSETS / folder
    path = directory / filename
    if not path.is_file():
        errors.append(f"Missing approved artwork: {path.relative_to(ROOT)}")
        continue
    data = path.read_bytes()
    if not data.startswith(bytes.fromhex("89504e470d0a1a0a")):
        errors.append(f"File is not PNG: {path.relative_to(ROOT)}")
    if hashlib.sha256(data).hexdigest() != expected_hash:
        errors.append(f"Incorrect artwork: {path.relative_to(ROOT)}")
    try:
        images = json.loads((directory / "Contents.json").read_text())["images"]
        if not any(x.get("filename") == filename for x in images):
            errors.append(f"Asset metadata missing reference to {filename}")
    except (OSError, ValueError, KeyError) as error:
        errors.append(f"Invalid Contents.json in {folder}: {error}")
if errors:
    print("RELEASE BLOCKED: Approved icon and mascot must be committed to GitHub.")
    for item in errors:
        print(" -", item)
    print("Use the provided Berry Block Blast approved artwork ZIP.")
    sys.exit(1)
print("Approved icon and mascot verified.")
