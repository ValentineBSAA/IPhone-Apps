#!/usr/bin/env python3
"""Create non-destructive RGBA *candidates* for the four owner-approved Night Garden Home icons.

Reads the exact Release V1 source PNGs already staged in ArtSource/NightGarden.
Only edge-connected near-black matte at the OUTSIDE of the rounded icon is removed;
moonlight, night garden scene, inner shadows, stars and gold remain untouched.
Dry-run by default. --apply writes separate candidates and preview QA evidence.
NOT a blanket background-removal tool for the remaining 36 icons.
"""
import argparse
import hashlib
import io
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "ArtSource" / "NightGarden"
SRC = ART / "Approved_40_Icon_Batches"
DST = ART / "RGBA_Candidates" / "Batch_01_Core_Home"
NAMES = (
    "Night_Berry_Classic", "Night_Berry_Story",
    "Night_Daily_Harvest", "Night_More_Adventures",
)
THRESHOLD = 9  # Only almost-black, edge-connected source matte pixels
FEATHER_SIGMA = 0.85  # Subpixel fringe antialias

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def derive(source):
    rgb = np.asarray(source.convert("RGB")).copy()
    dark = (np.max(rgb, axis=2) <= THRESHOLD).astype("uint8")
    _, labels = cv2.connectedComponents(dark, connectivity=8)
    border = np.unique(np.concatenate(
        (labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1])))
    border = border[border != 0]
    outside = np.isin(labels, border).astype("uint8")
    alpha = 255.0 * (1 - outside).astype("float32")
    alpha = cv2.GaussianBlur(alpha, (0, 0), sigmaX=FEATHER_SIGMA)
    alpha = np.rint(np.clip(alpha, 0, 255)).astype("uint8")
    masked_fraction = float((alpha == 0).sum()) / alpha.size
    # Prevent a coding change from unintentionally removing large areas of artwork.
    if not (0.035 <= masked_fraction <= 0.085):
        raise ValueError(f"Unexpected background mask fraction: {masked_fraction:.4f}")
    if any(alpha[y, x] > 0 for x, y in
           ((0, 0), (source.width-1, 0), (0, source.height-1),
            (source.width-1, source.height-1))):
        raise ValueError("Source corner is not fully transparent")
    rgba_arr = np.dstack((rgb, alpha))
    if not np.array_equal(rgba_arr[:, :, :3], rgb):
        raise ValueError("Original RGB pixels changed")
    return Image.fromarray(rgba_arr, "RGBA"), {
        "fully_transparent": int((alpha == 0).sum()),
        "partial_alpha": int(((alpha > 0) & (alpha < 255)).sum()),
        "fully_opaque": int((alpha == 255).sum()),
        "transparent_fraction": round(masked_fraction, 6),
    }

def check_and_write(path, data, apply):
    if path.exists() and path.read_bytes() != data:
        raise ValueError(f"Refusing to overwrite different file: {path}")
    if apply and not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

def composite(rgba, color, size=296):
    icon = rgba.resize((size, size), Image.Resampling.LANCZOS)
    if color == "checker":
        base = Image.new("RGB", (size, size), "#d8d7d6")
        dr = ImageDraw.Draw(base)
        for y in range(0, size, 20):
            for x in range(0, size, 20):
                if ((x//20)+(y//20))%2:
                    dr.rectangle((x, y, x+19, y+19), fill="#f5f5f4")
    else:
        base = Image.new("RGB", (size, size), color)
    base.paste(icon, (0, 0), icon)
    return base

def image_bytes(image, ext="PNG"):
    buffer = io.BytesIO()
    if ext == "PNG":
        image.save(buffer, format="PNG", optimize=True)
    else:
        image.save(buffer, format="JPEG", quality=93, subsampling=0)
    return buffer.getvalue()

def run(apply):
    manifest = json.loads((SRC / "_Provenance" / "ARTWORK_MANIFEST.json").read_text())
    items = {item["asset_name"]: item for item in manifest["items"]}
    expected = len(NAMES)
    report, originals, derived = [], [], []
    for name in NAMES:
        item = items[name]
        if item["batch"] != 1 or item["owner_visual_approval"] != "APPROVED":
            raise ValueError(f"Not an approved Batch 1 icon: {name}")
        source = SRC / item["original_file"].removeprefix("01_Original_Approved_PNG/")
        data = source.read_bytes()
        if sha256(data) != item["sha256"]:
            raise ValueError(f"Source checksum mismatch: {name}")
        with Image.open(io.BytesIO(data)) as img:
            img.load()
            if img.mode != "RGB" or img.size != (1254, 1254):
                raise ValueError(f"Unexpected original mode / size for {name}")
            result, alpha_stats = derive(img)
            originals.append(img.copy())
        output = image_bytes(result)
        with Image.open(io.BytesIO(output)) as check:
            check.load()
            if check.mode != "RGBA" or check.size != (1254, 1254):
                raise ValueError(f"Encoded derivative isn't RGBA: {name}")
        check_and_write(DST / (name + "_RGBA_CANDIDATE.png"), output, apply)
        derived.append(result)
        report.append({
            "name": name,
            "original_sha256": item["sha256"],
            "candidate_sha256": sha256(output),
            "size": [1254, 1254],
            "mode": "RGBA",
            "status": "candidate_unapproved",
            **alpha_stats,
        })

    wide, pad, label_h, block_h = 296 * 4, 3, 34, 340
    proof = Image.new("RGB", (wide, block_h * 4), "#ffffff")
    draw = ImageDraw.Draw(proof)
    for j, (name, orig, rgba) in enumerate(zip(NAMES, originals, derived)):
        y = j * block_h
        draw.text((8, y+8), name, fill="#242124")
        originals_tile = orig.resize((296, 296), Image.Resampling.LANCZOS)
        for i, tile in enumerate(
                (originals_tile, composite(rgba, "checker"),
                 composite(rgba, "#fff3ec"), composite(rgba, "#171024"))):
            proof.paste(tile, (i * 296, y + label_h))
    check_and_write(DST / "_QA" / "Batch_01_Original_Checker_Light_Dark.jpg",
                    image_bytes(proof, "JPEG"), apply)

    # Compare at common in-app icon sizes as a sanity review, not iPhone verification.
    tiny = Image.new("RGB", (640, 320), "#fff2ee")
    d = ImageDraw.Draw(tiny)
    for j, (name, rgba) in enumerate(zip(NAMES, derived)):
        for k, size in enumerate((64, 96)):
            x = j*160 + k*74
            y = 48 + (96-size)//2
            tile = rgba.resize((size, size), Image.Resampling.LANCZOS)
            tiny.paste(tile, (x, y), tile)
        d.text((j*160+3, 170), name.removeprefix("Night_").replace("_", " ")[:22], fill="#322335")
    check_and_write(DST / "_QA" / "Batch_01_Icon_64_96px.png",
                    image_bytes(tiny), apply)
    notes = (
        "# Batch 1 Night Garden RGBA candidates\n\n"
        "Four owner-approved original RGB images were kept unchanged in their"
        " ArtSource/Approved_40_Icon_Batches folder. This is a first alpha pass,"
        " NOT new AI drawings and NOT an integrated Xcode asset.\n\n"
        "Method: identify only near-black (max RGB <= 9) regions connected to"
        " the image edge, set those OUTSIDE rounded-square corner mattes to"
        " transparency, feather the boundary by 0.85 source pixels, and"
        " preserve every original RGB value even where alpha changes."
        " The inner moonlit sky/background is intentional artwork and is NOT removed.\n\n"
        "QA: manually compare the four-context preview, 64/96px mobile-size"
        " preview, full-resolution petals, transparent border and glow halos."
        " OWNER ACCEPTANCE AND iPhone 16e TESTING PENDING.\n"
        " This mask is specific to Batch 1; do not apply blindly to remaining batches.\n"
    )
    check_and_write(DST / "_QA" / "README.md", notes.encode(), apply)
    check_and_write(DST / "_QA" / "BATCH01_ALPHA_AUDIT.json",
                    json.dumps(report, indent=2).encode(), apply)
    print(json.dumps({"status": "PASS", "apply": apply,
                      "count": expected, "candidates": report}, indent=2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    a = parser.parse_args()
    try:
        run(a.apply)
    except (OSError, ValueError, KeyError) as exc:
        print(f"RGBA BATCH 1 ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
