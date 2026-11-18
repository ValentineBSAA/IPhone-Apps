#!/usr/bin/env python3
"""Install the user-approved 0.5.11 icon/frame bundle into Xcode asset catalogs.

Run *after* install_art510.py, before xcodegen/xcodebuild. Never touch default
puzzle blocks, board geometry, Save/Wallet keys, or existing 0.5.8-0.5.10 assets.
Missing artwork is fatal, not a silent replacement with generic system icons.
"""
from pathlib import Path
from io import BytesIO
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[2]
assets = root / "StrawberryShortcakeBlockBlast" / "BerryBlockBlast" / "Assets.xcassets"
pack = root / "BuildPayload" / "BerryBerryBlast_0511_Approved_Art.zip"
digest = "8c523342aaa9bd1b9521b22bce45a77f80fbd4bc0b477232387eeda30622868c"
names = (
    "BBBFrameBirthday", "BBBFrameChristmas", "BBBFrameMidnight",
    "BBBFramePicnic", "BBBFrameSpring",
    "BBBIconBirthday", "BBBIconBlocks", "BBBIconBoard",
    "BBBIconHelp", "BBBIconHome", "BBBIconInventory",
    "BBBIconPause", "BBBIconRestore", "BBBIconSeasonal",
    "BBBIconSettings", "BBBIconShop", "BBBIconSparkle", "BBBIconTools",
)

if not pack.is_file():
    raise SystemExit(
        "Missing approved 0.5.11 artwork ZIP: " + str(pack) +
        "\nUpload BerryBerryBlast_0511_Approved_Art.zip to BuildPayload/ "
        "on the 0.5.11 GitHub feature branch; don't accept a fallback-only IPA."
    )
actual = hashlib.sha256(pack.read_bytes()).hexdigest()
if actual != digest:
    raise SystemExit("Approved 0.5.11 art checksum mismatch: " + actual)

with zipfile.ZipFile(pack) as archive:
    if archive.testzip() is not None:
        raise SystemExit("Approved art ZIP has damaged members")
    members = set(archive.namelist())
    if members != {*(n + ".png" for n in names), "Manifest.json"}:
        raise SystemExit("Approved art ZIP file list differs from review")
    manifest = json.loads(archive.read("Manifest.json"))
    indexed = {item["name"]: item for item in manifest}
    if set(indexed) != set(names):
        raise SystemExit("Artwork manifest does not match approved assets")
    for name in names:
        data = archive.read(name + ".png")
        if hashlib.sha256(data).hexdigest() != indexed[name]["sha256"]:
            raise SystemExit("Art file checksum mismatch: " + name)
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            raise SystemExit("Artwork isn't a PNG: " + name)
        # Basic PNG dimension check without adding another build dependency.
        import struct
        width, height = struct.unpack(">II", data[16:24])
        expected = 900 if name.startswith("BBBFrame") else 384
        if (width, height) != (expected, expected):
            raise SystemExit("Unexpected image dimensions for " + name)
        dest = assets / (name + ".imageset")
        dest.mkdir(parents=True, exist_ok=True)
        (dest / (name + ".png")).write_bytes(data)
        (dest / "Contents.json").write_text(
            json.dumps({"images":[{"filename":name + ".png", "idiom":"universal"}],
                        "info":{"author":"xcode","version":1}}, indent=2) + "\n",
            encoding="utf-8"
        )
        print("PASS 0.5.11 asset:", name, width, "x", height)
print("PASS: all 18 approved Board Studio PNGs installed; default gameplay untouched")
