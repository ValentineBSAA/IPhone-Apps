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
    assert data[:8] == b"\x89PNG\r\n\x1a\n", file
    width, height = struct.unpack(">II", data[16:24])
    assert width >= 128 and height >= 128, (name, width, height)
# Three approved original character poses and the generated fruit-shaped
# replacement are mandatory. The game must not silently fall back to stickers.
for name in ("BerryCharacterPortrait", "BerryCharacterStanding", "BerryCharacterCelebrate"):
    folder = assets_root / (name + ".imageset")
    manifest = json.loads((folder / "Contents.json").read_text())
    image = folder / manifest["images"][0]["filename"]
    assert image.is_file() and image.stat().st_size > 10000, image
fruit = assets_root / "BerryRealStrawberry.imageset" / "BerryRealStrawberry.png"
assert fruit.read_bytes()[:8] == b"\\x89PNG\\r\\n\\x1a\\n"
assert struct.unpack(">II", fruit.read_bytes()[16:24]) == (128, 128)
project = (root / "project.yml").read_text()
assert 'CURRENT_PROJECT_VERSION: "2"' in project
assert 'MARKETING_VERSION: "0.5.8"' in project
assert 'IPHONEOS_DEPLOYMENT_TARGET: "16.0"' in project
assert 'PRODUCT_BUNDLE_IDENTIFIER: com.valentinebsaa.berryblockblast' in project
src = (root / "BerryBlockBlast" / "BerryGameView.swift").read_text()
assert 'private var isTimedMode:' in src
assert 'private var timedDuration:' in src
assert 'BerryCottageGardenView(session: session)' in src
assert '"\\(piece.points.count)"' in src
assert 'BerryRealStrawberry' in (root / "BerryBlockBlast" / "BerryStyle.swift").read_text()
assert 'BerryStoryNarrative.title' in src
assert 'BerryBoardPositionCache' in src
assert 'pauseTimedClock()' in src
assert 'BerryGirlView(pose: .celebrate)' in src
print("BERRY 0.5.8 BUILD 2 PASS: 16 base assets + 3 character images + genuine strawberry; iOS16, Story, timer, viewport, cottage")
