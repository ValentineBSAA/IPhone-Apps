#!/usr/bin/env python3
"""Import the exact approved POTS PNG icon pack into the repository.

Usage:
  python3 POTSTracker/tools/import_icons.py path/to/POTS_13_Color_Matched_Icons.zip --repo-root . [--replace]
"""
import argparse
import io
import struct
from pathlib import Path
from zipfile import ZipFile, BadZipFile
from zlib import crc32

NAMES = (
    "00_App_Icon.png", "01_Heart_Rate.png", "02_Blood_Pressure.png",
    "03_Symptoms.png", "04_Hydration.png", "05_Medications.png",
    "06_Sleep.png", "07_Calendar.png", "08_Reports.png",
    "09_Journal.png", "10_Posture.png", "11_Reminders.png", "12_Settings.png",
)
PREFIX = "POTS_Icon_Set_13_Colors/"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MAX_SINGLE_IMAGE = 12 * 1024 * 1024

def validate_png(data: bytes, name: str) -> None:
    if len(data) < 33 or not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{name}: invalid PNG signature/header")
    ihdr_len = struct.unpack(">I", data[8:12])[0]
    if data[12:16] != b"IHDR" or ihdr_len != 13:
        raise ValueError(f"{name}: invalid PNG IHDR chunk")
    expected_crc = struct.unpack(">I", data[29:33])[0]
    if crc32(data[12:29]) & 0xFFFFFFFF != expected_crc:
        raise ValueError(f"{name}: corrupted PNG IHDR checksum")
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (1024, 1024):
        raise ValueError(f"{name}: expected 1024x1024, got {width}x{height}")
    if len(data) > MAX_SINGLE_IMAGE:
        raise ValueError(f"{name}: file unexpectedly large")

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("archive", type=Path)
    ap.add_argument("--repo-root", type=Path, default=Path("."))
    ap.add_argument("--replace", action="store_true", help="Overwrite existing approved assets")
    args = ap.parse_args()
    dest = args.repo_root.resolve() / "POTSTracker" / "Resources" / "Icons"
    if not args.archive.is_file():
        ap.error(f"Archive not found: {args.archive}")
    payloads = {}
    try:
        with ZipFile(args.archive) as z:
            for name in NAMES:
                matches = [v for v in z.infolist() if v.filename == PREFIX + name]
                if len(matches) != 1:
                    raise ValueError(f"Expected exactly one {PREFIX + name} in ZIP")
                entry = matches[0]
                if entry.file_size > MAX_SINGLE_IMAGE:
                    raise ValueError(f"{name}: image too large")
                payload = z.read(entry)
                validate_png(payload, name)
                payloads[name] = payload
    except BadZipFile as e:
        raise ValueError("Archive is invalid or corrupt") from e
    if not args.replace:
        existing = [name for name in NAMES if (dest / name).exists()]
        if existing:
            raise ValueError(f"Destination files already exist: {existing}. Use --replace.")
    dest.mkdir(parents=True, exist_ok=True)
    for name, data in payloads.items():
        (dest / name).write_bytes(data)
        print(f"OK {name} ({len(data):,} bytes)")
    print(f"Validated and imported all {len(NAMES)} original 1024x1024 images into {dest}")

if __name__ == "__main__":
    main()
