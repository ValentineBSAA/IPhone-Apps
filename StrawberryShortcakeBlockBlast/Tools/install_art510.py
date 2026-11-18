#!/usr/bin/env python3
"""Prepare the verified 0.5.8 + 0.5.9 Berry art catalogs for Xcode.

No network use and no source edits. Used by the 0.5.10 macOS build.
Keep the art ZIPs byte-for-byte and extract in the approved layering order.
"""
from pathlib import Path
import base64
import json
import shutil
import zipfile

project = Path(__file__).resolve().parents[1]
repo = project.parent.resolve()
assets = project / "BerryBlockBlast" / "Assets.xcassets"

packs = [
    "Berry_Block_Blast_0.5.8_19_ArtCatalogs_CloudReady.zip",
    "Berry_Berry_Blast_0.5.9_Art_Integration_Cloud.zip",
    "BerryBerryBlast_0.5.9_PolishedPlayfield_CloudReady.zip",
    "Berry_Berry_Blast_GoldenStrawberry_CloudPatch.zip"
]
for filename in packs:
    path = repo / "BuildPayload" / filename
    if not path.exists():
        raise SystemExit("Missing approved artwork pack: " + str(path))
    with zipfile.ZipFile(path) as archive:
        damaged = archive.testzip()
        if damaged:
            raise SystemExit("Corrupted art: " + filename + " / " + damaged)
        for name in archive.namelist():
            dest = (repo / name).resolve()
            if not dest.is_relative_to(repo):
                raise SystemExit("Unsafe art ZIP entry: " + name)
        archive.extractall(repo)
    print("PASS artwork:", filename)

# The early authentic berry icon remains available to optional cosmetics.
encoded = repo / "BuildPayload" / "BerryRealStrawberry.png.base64"
raw = base64.b64decode("".join(encoded.read_text().splitlines()), validate=True)
directory = assets / "BerryRealStrawberry.imageset"
directory.mkdir(parents=True, exist_ok=True)
(directory / "BerryRealStrawberry.png").write_bytes(raw)
(directory / "Contents.json").write_text(json.dumps({
    "images": [{"filename": "BerryRealStrawberry.png", "idiom": "universal"}],
    "info": {"author": "xcode", "version": 1}
}))

# 0.5.9 originals were replaced by final PNGs: avoid duplicate unassigned JPGs.
for name in ("BerryCharacterPortrait", "BerryCharacterStanding",
             "BerryCharacterCelebrate"):
    (assets / (name + ".imageset") / (name + ".jpg")).unlink(missing_ok=True)

centered = assets / "BerryMascotCenteredCircle.imageset" / "BerryMascotCenteredCircle.png"
portrait = assets / "BerryCharacterPortrait.imageset" / "BerryCharacterPortrait.png"
if not centered.is_file():
    raise SystemExit("Missing approved original transparent centered mascot portrait")
shutil.copyfile(centered, portrait)
print("PASS: 0.5.10 Xcode art catalogs, original mascot, and optional fruits")
