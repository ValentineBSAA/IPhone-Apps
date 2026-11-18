#!/usr/bin/env python3
"""Build gate for all 48 actual approved 0.5.12 Xcode PNGs.

Unlike the old raw IPA patch, every asset must live in Assets.xcassets
in GitHub and be compiled by actool into Assets.car. Fail closed if one
image is missing, corrupt, or different from the user-approved PNG.
"""
import hashlib
import json
from pathlib import Path
import struct

root = Path(__file__).resolve().parents[1]
assets = root / "BerryBlockBlast" / "Assets.xcassets"
manifest = json.loads((root / "Tools" / "berry_art_0512_manifest.json").read_text())
items = manifest["assets"]
assert len(items) == 48, "Expected exactly 48 approved assets"
assert len({item["name"] for item in items}) == 48, "Duplicate art names"

for item in items:
    name = item["name"]
    folder = assets / (name + ".imageset")
    png = folder / (name + ".png")
    metadata = folder / "Contents.json"
    assert png.is_file(), "Missing committed PNG: " + str(png)
    assert metadata.is_file(), "Missing Xcode Contents.json: " + str(metadata)
    data = png.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "Not a PNG: " + name
    assert hashlib.sha256(data).hexdigest() == item["sha256"], "Changed PNG: " + name
    assert len(data) == item["bytes"], "Changed PNG byte length: " + name
    dims = struct.unpack(">II", data[16:24])
    assert list(dims) == item["size"], "Changed image dimensions: " + name
    image = json.loads(metadata.read_text())
    assert image["images"] == [{"filename": name + ".png", "idiom": "universal"}], \
        "Xcode image catalog points to wrong filename: " + name

# A complete archive is not sufficient if gameplay ignores the real icon
# assets. Require the routing and original stable helper images in source.
game = (root / "BerryBlockBlast" / "BerryGameView.swift").read_text()
for icon in ("BBBIconShop", "BBBIconTools", "UndoIcon",
             "ShuffleIcon", "BerryHint", "StatsChart"):
    assert icon in game, "Gameplay helper icon not routed: " + icon
for icon in ("UndoIcon", "ShuffleIcon", "BerryHint", "StatsChart"):
    assert (assets / (icon + ".imageset")).is_dir(), \
        "Original polished helper image catalog missing: " + icon

print("PASS: all 48 approved PNGs match source checksums in Xcode catalogs.")
print("PASS: Undo, Shuffle, Hint, Stats, Tools and Boutique use bundled image assets.")
