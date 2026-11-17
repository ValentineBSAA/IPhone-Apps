#!/usr/bin/env python3
"""Strict Berry Block Blast 0.5.8 source-art and product-version gate."""
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
assets_root = root / "BerryBlockBlast" / "Assets.xcassets"
names = [
    "StrawberryCandyBlock", "RaspberryRubyBlock",
    "LemonGlazeBlock", "ChocolateTruffleBlock",
    "StrawberryCottage", "BerryFlowerbed", "StrawberryGardenGate",
    "JamMarketSign", "VillageFountain", "RoseAndStrawberryFence",
    "JamMarketStall", "RoseTrellis", "CottageBakery",
    "CottageGardenBackground", "MintFrostBlock", "BlackberryJamBlock"
]
for name in names:
    folder = assets_root / (name + ".imageset")
    manifest = json.loads((folder / "Contents.json").read_text())
    file = folder / manifest["images"][0]["filename"]
    data = file.read_bytes()
    assert data[:8] == b"\\x89PNG\\r\\n\\x1a\\n", file
    width, height = struct.unpack(">II", data[16:24])
    assert width >= 128 and height >= 128, (name, width, height)
project = (root / "project.yml").read_text()
assert 'MARKETING_VERSION: "0.5.8"' in project
assert 'IPHONEOS_DEPLOYMENT_TARGET: "16.0"' in project
assert 'PRODUCT_BUNDLE_IDENTIFIER: com.valentinebsaa.berryblockblast' in project
src = (root / "BerryBlockBlast" / "BerryGameView.swift").read_text()
assert 'private var isTimedMode:' in src
assert 'private var timedDuration:' in src
assert 'BerryCottageGardenView(session: session)' in src
assert '"\\(piece.points.count)"' in src
print("BERRY 0.5.8 PASS: 16 PNG image catalogs, build version, iOS16, timed rules, cottage, and piece counters")
