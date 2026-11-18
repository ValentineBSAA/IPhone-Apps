#!/usr/bin/env python3
"""Install exact v0.5.12 approved image files into the native Xcode catalog.

This script is strict. It never replaces a missing frame, toolbar or reward
with generic images. Before a reproducible GitHub rebuild, upload the provided
BerryBerryBlast_0512_Production_Assets.zip to BuildPayload/.
"""
from pathlib import Path
import hashlib
import json
import zipfile

project = Path(__file__).resolve().parents[1]
repo = project.parent
source = repo / "BuildPayload" / "BerryBerryBlast_0512_Production_Assets.zip"
assets = project / "BerryBlockBlast" / "Assets.xcassets"
expected_zip = "eb874b9de8d757fdb6451275dd8d2d9cca9f34aca0cc57c54f6cffdc859d75ad"

if not source.is_file():
    raise SystemExit(f"MISSING ART: {source}; upload the complete 48-PNG Production Assets ZIP to BuildPayload/")
actual = hashlib.sha256(source.read_bytes()).hexdigest()
if actual != expected_zip:
    raise SystemExit(f"Incorrect 0.5.12 artwork archive SHA-256: {actual}")
with zipfile.ZipFile(source) as z:
    damaged = z.testzip()
    if damaged: raise SystemExit(f"Broken image ZIP member: {damaged}")
    manifest = json.loads(z.read("Manifest.json"))["assets"]
    if len(manifest) != 48 or len({a["name"] for a in manifest}) != 48:
        raise SystemExit("Expected exactly 48 unique approved/derived PNG assets")
    expected_names = {"Manifest.json"} | {a["filename"] for a in manifest}
    if set(z.namelist()) != expected_names:
        raise SystemExit("Art archive has extra or missing members")
    for item in manifest:
        name = item["name"]
        data = z.read(item["filename"])
        if hashlib.sha256(data).hexdigest() != item["sha256"]:
            raise SystemExit(f"Damaged artwork: {name}")
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise SystemExit(f"Not a PNG: {name}")
        if "/" in name or "\\" in name or name.startswith("."):
            raise SystemExit(f"Unsafe asset name: {name}")
        folder = assets / (name + ".imageset")
        folder.mkdir(parents=True, exist_ok=True)
        (folder / (name + ".png")).write_bytes(data)
        (folder / "Contents.json").write_text(json.dumps({
            "images": [{"filename": name + ".png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1}
        }, indent=2), encoding="utf-8")
        print("PASS:", name)
print("PASS: installed 48 exact 0.5.12 images into Xcode assets. Original puzzle, audio and saves untouched.")
