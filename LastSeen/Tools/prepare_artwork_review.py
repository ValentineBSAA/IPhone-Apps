#!/usr/bin/env python3
"""Prepare a private, offline visual review. Never import into runtime."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

from PIL import Image, ImageDraw, ImageOps

PACKS = (
    ("Last-Seen-Build27-Recovered-Images.zip",
     "48928fdc8d8a01631eccac01e1ab0aaa6ef30ca579ce67feb5d2369b6ae2a317",
     64724308, "Recovered_B27_", 29),
    ("Last-Seen-World-Photos-Expansion-01.zip",
     "0d7b45bc6bc2ec65d77c2fb47c41ed9879fb79da0e610bfd5a07fa9d30ab0e10",
     46400998, "WorldPhoto_E01_", 18),
)
ASSIGNED = {f"Recovered_B27_{i:02}" for i in (1, 2, 3, 13, 14, 18, 21, 23, 24, 25, 26, 27, 28, 29)} | {"WorldPhoto_E01_05","WorldPhoto_E01_08"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inspect_pack(root, pack):
    filename, expected_hash, expected_size, prefix, count = pack
    path = root / filename
    archive = path.read_bytes()
    require(len(archive) == expected_size and digest(archive) == expected_hash,
            f"{filename}: archive identity mismatch")
    expected = {f"{prefix}{i:02}" for i in range(1, count + 1)}
    entries = []
    with zipfile.ZipFile(io.BytesIO(archive)) as z:
        names = z.namelist()
        require(len(names) == len(set(names)), f"{filename}: duplicate archive names")
        require(z.testzip() is None, f"{filename}: CRC failure")
        records = json.loads(z.read("manifest.json"))["assets"]
        require(len(records) == count and {r["asset_id"] for r in records} == expected,
                f"{filename}: manifest inventory mismatch")
        for record in records:
            asset = record["asset_id"]
            name = asset + ".png"
            require(record["filename"] == name and name in names,
                    f"{asset}: unexpected source filename")
            data = z.read(name)
            require(digest(data) == record["sha256"], f"{asset}: original hash mismatch")
            with Image.open(io.BytesIO(data)) as original:
                require(original.format == "PNG", f"{asset}: non-PNG source")
                original.load()
                require(original.size == (record["width"], record["height"]),
                        f"{asset}: dimensions mismatch")
            if asset not in ASSIGNED:
                entries.append((asset, data, {
                    "asset": asset, "source_archive": filename,
                    "original_sha256": record["sha256"],
                    "dimensions": [record["width"], record["height"]],
                    "status": "pending_visual_continuity_review",
                    "purpose": None, "chronology": None,
                    "provenance": None, "access_gate": None,
                    "cross_app_records": [], "text_equivalent": None,
                    "continuity_flags": [], "review_notes": None,
                }))
    return sorted(entries, key=lambda item: item[0])


def prepare(root, output):
    require(not output.exists(), "Choose a new output directory; existing reviews are never overwritten.")
    # Validate both complete archives before creating any review output.
    entries = [entry for pack in PACKS for entry in inspect_pack(root, pack)]
    require(len(entries) == 31, "Expected 31 outstanding originals")
    output.mkdir(parents=True)
    originals = output / "originals"
    originals.mkdir()
    for asset, data, _ in entries:
        (originals / (asset + ".png")).write_bytes(data)
    for start in range(0, len(entries), 8):
        page = entries[start:start + 8]
        sheet = Image.new("RGB", (1200, 840), "#202020")
        draw = ImageDraw.Draw(sheet)
        for index, (asset, data, _) in enumerate(page):
            x, y = (index % 4) * 300, (index // 4) * 420
            with Image.open(io.BytesIO(data)) as original:
                thumb = ImageOps.contain(original.convert("RGB"), (280, 370))
            sheet.paste(thumb, (x + (300-thumb.width)//2, y + 10 + (370-thumb.height)//2))
            draw.text((x+10, y+390), asset, fill="white")
        sheet.save(output / f"review-{start//8+1:02}.png")
    (output / "review-ledger.json").write_text(
        json.dumps({"review_complete": False, "runtime_import": False,
                    "assets": [record for _, _, record in entries]},
                   indent=2) + "\n", encoding="utf-8")
    print(f"Prepared {len(entries)} pending originals, {(len(entries)+7)//8} contact sheets and a private ledger.")
    print("No gameplay assignment or runtime import has been performed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--packs", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    require(not args.output.resolve().is_relative_to(Path(__file__).resolve().parents[2]),
            "Keep private review output outside the entire repository.")
    prepare(args.packs, args.output)


if __name__ == "__main__":
    main()
