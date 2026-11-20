#!/usr/bin/env python3
"""Stage the 40 owner-approved Night Garden release PNGs without touching live Xcode assets.

Dry run: python3 Tools/stage_night_garden_40.py /path/to/master.zip
Apply:   python3 Tools/stage_night_garden_40.py /path/to/master.zip --apply

A source import is NOT alpha cleanup, artwork routing, CI acceptance, or a public release.
"""
import argparse
import csv
import hashlib
import io
import json
import re
import sys
import zipfile
from pathlib import Path

from PIL import Image

EXPECTED_ARCHIVE_SHA256 = "3d4785171fe9ffe5ca019b814bfeb4ceba0663e33362496b1782db5f7f0f807c"
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "ArtSource" / "NightGarden" / "Approved_40_Icon_Batches"
PACK = "Berry_Berry_Blast_Night_Garden_40_Approved/"
ITEMS_DIR = PACK + "01_Original_Approved_PNG/"
DOCS_DIR = PACK + "00_README/"
PREVIEWS_DIR = PACK + "02_Previews/"
EXPECTED_GROUP_COUNTS = {1:4,2:4,3:4,4:4,5:6,6:6,7:6,8:6}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def stage_file(path, data, apply):
    if path.exists():
        if path.read_bytes() != data:
            raise ValueError(f"REFUSING TO OVERWRITE: {path}")
        return False
    if apply:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    return True

def classify_background(image):
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    min_alpha, max_alpha = alpha.getextrema()
    if min_alpha < 255:
        return "REAL_RGBA_ALPHA_REVIEW_EDGES"
    w, h = image.size
    corners = [rgba.getpixel(p)[:3] for p in ((0,0),(w-1,0),(0,h-1),(w-1,h-1))]
    if all(max(p) < 42 for p in corners):
        return "OPAQUE_DARK_MATTE_REQUIRES_REVIEW"
    if all(min(p) > 180 for p in corners):
        return "OPAQUE_LIGHT_OR_BAKED_CHECKERBOARD_REQUIRES_REVIEW"
    return "OPAQUE_PAINTED_OR_MIXED_BACKGROUND_REQUIRES_REVIEW"

def run(archive_path, apply):
    raw_archive = archive_path.read_bytes()
    actual_archive_digest = sha256(raw_archive)
    if actual_archive_digest != EXPECTED_ARCHIVE_SHA256:
        raise ValueError(f"Unexpected GitHub V1 release ZIP digest: {actual_archive_digest}")
    with zipfile.ZipFile(io.BytesIO(raw_archive)) as z:
        if z.testzip():
            raise ValueError("Corrupt release archive")
        manifest = json.loads(z.read(DOCS_DIR + "ARTWORK_MANIFEST.json"))
        items = manifest.get("items", [])
        if len(items) != 40 or manifest.get("count") != 40:
            raise ValueError("Expected exactly 40 approved images")
        if manifest.get("repository") != "https://github.com/ValentineBSAA/IPhone-Apps":
            raise ValueError("Unexpected manifest repository")
        counts = {k:0 for k in EXPECTED_GROUP_COUNTS}
        seen_names, planned, rows, tracked = set(), [], [], set()
        for item in items:
            name = item["asset_name"]
            batch = item["batch"]
            file_path = item["original_file"]
            if not re.fullmatch(r"Night_[A-Za-z0-9_]+", name):
                raise ValueError(f"Invalid asset name: {name}")
            if batch not in EXPECTED_GROUP_COUNTS:
                raise ValueError(f"Invalid batch: {batch}")
            if name in seen_names:
                raise ValueError(f"Duplicate asset: {name}")
            if item.get("owner_visual_approval") != "APPROVED":
                raise ValueError(f"Not approved: {name}")
            if not file_path.startswith(f"01_Original_Approved_PNG/Batch_{batch:02}_") or not file_path.endswith("/"+name+".png"):
                raise ValueError(f"Manifest file path doesn't match {name}")
            source_zip_path = PACK + file_path
            if source_zip_path not in z.namelist():
                raise ValueError(f"Missing PNG: {source_zip_path}")
            data = z.read(source_zip_path)
            if not data.startswith(PNG_SIGNATURE) or sha256(data) != item["sha256"]:
                raise ValueError(f"PNG signature or SHA mismatch: {name}")
            with Image.open(io.BytesIO(data)) as image:
                image.load()
                dims = image.size
                mode = image.mode
                bg_class = classify_background(image)
            if dims != (1254,1254):
                raise ValueError(f"Unexpected dimensions for {name}: {dims}")
            original_destination = DEST / file_path.removeprefix("01_Original_Approved_PNG/")
            planned.append((original_destination,data))
            tracked.add(source_zip_path)
            counts[batch] += 1
            seen_names.add(name)
            rows.append({
                "batch":batch,"asset_name":name,"original_path":str(original_destination.relative_to(ROOT)),
                "original_sha256":sha256(data),"dimensions":"1254x1254","source_mode":mode,
                "alpha_review":bg_class,"source_approved":"YES","rgba_converted":"NO",
                "xcode_imported":"NO","runtime_routed":"NO","iphone16e_verified":"NO"})
        if counts != EXPECTED_GROUP_COUNTS:
            raise ValueError(f"Wrong batch counts: {counts}")
        actual_pngs = {p for p in z.namelist() if p.startswith(ITEMS_DIR) and p.lower().endswith(".png")}
        if actual_pngs != tracked:
            raise ValueError("Unmanifested or missing original PNG files")
        for name in ("ARTWORK_MANIFEST.json","GITHUB_ASSET_IMPORT_LEDGER.csv",
                     "SHA256SUMS_Original_PNG.txt","BATCH_INDEX.txt","README_START_HERE.md"):
            planned.append((DEST / "_Provenance" / name,z.read(DOCS_DIR + name)))
        for path in z.namelist():
            if path.startswith(PREVIEWS_DIR) and path.endswith(".jpg"):
                planned.append((DEST / "_Previews" / path.rsplit("/",1)[1],z.read(path)))
        report = io.StringIO()
        writer=csv.DictWriter(report,fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
        planned.append((DEST / "_RGBA_Preflight" / "SOURCE_ALPHA_AUDIT.csv",report.getvalue().encode()))
        notes = (
            "# Approved Night Garden 40 / RGBA preparation gate\n\n"
            "Source GitHub Release: V1 / Night Garden Master Artwork Pack.\n"
            f"Master SHA-256: {EXPECTED_ARCHIVE_SHA256}\n\n"
            "These 40 PNGs are ORIGINAL, unchanged owner-approved AI artwork.\n"
            "None are automatically ready as a transparent overlay solely because they are PNG.\n"
            "Real source RGBA alpha, dark matte, baked checkerboard and painted backgrounds\n"
            "must be reviewed separately. SOURCE_ALPHA_AUDIT.csv records the first-pass class.\n\n"
            "ALPHA WORKFLOW: review at 100% over light AND dark backgrounds; generate\n"
            "lossless separate RGBA derivative; inspect antialias fringe, translucent\n"
            "gold/glass, leaves, highlights and small-size readability; obtain owner QA;\n"
            "only then create separate Xcode .imageset and route a visible use-site.\n"
            "Do NOT remove black/dark pixels indiscriminately, cut shadows, replace\n"
            "day assets, touch Night Market storefront, or make automatic changes to\n"
            "the existing 30 Night_ Xcode image sets.\n"
        )
        planned.append((DEST / "_RGBA_Preflight" / "README.md",notes.encode()))
        new_files=sum(1 for path,_ in planned if not path.exists())
        print(f"PASS: 40 images / 8 batches / {len(planned)} staged files / {new_files} new, "
              f"release SHA-256 {actual_archive_digest}")
        if apply:
            for path,data in planned:
                stage_file(path,data,True)
            print(f"STAGED: {DEST} (originals untouched, Xcode assets unchanged)")
        else:
            for path,data in planned:
                stage_file(path,data,False)
            print("DRY RUN ONLY. Use --apply on staging branch.")

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",type=Path)
    parser.add_argument("--apply",action="store_true")
    args=parser.parse_args()
    try:
        run(args.archive,args.apply)
    except (OSError,ValueError,KeyError,zipfile.BadZipFile, json.JSONDecodeError) as e:
        print("NIGHT 40 STAGING ERROR:",e,file=sys.stderr)
        sys.exit(1)
