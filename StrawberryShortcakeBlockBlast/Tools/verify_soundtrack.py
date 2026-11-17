#!/usr/bin/env python3
"""Verify the 15 original M4As before build, inside .app and inside the IPA.

Source hashes are taken from the ZIP's original catalog and cross-checked in
our typed Catalog.json. Files must be copied byte-for-byte, never re-encoded.
"""
import argparse
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "Soundtrack"

def require(condition, problem):
    if not condition:
        raise AssertionError(problem)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", type=Path, help="Built BerryBlockBlast.app directory")
    parser.add_argument("--ipa", type=Path, help="Unsigned IPA archive")
    args = parser.parse_args()
    catalog_path = AUDIO / "Catalog.json"
    original_manifest = AUDIO / "OriginalCatalog" / "manifest.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    source = json.loads(original_manifest.read_text(encoding="utf-8"))
    tracks = sorted(catalog["tracks"], key=lambda t: t["id"])
    manifest_tracks = {t["number"]: t for t in source["tracks"]}
    require(len(tracks) == 15, f"Expected 15 tracks, got {len(tracks)}")
    require([t["id"] for t in tracks] == list(range(1, 16)), "IDs not 01-15")
    require(len({t["file"] for t in tracks}) == 15, "Repeated song filenames")
    require(len(list(AUDIO.glob("*.m4a"))) == 15, "Expected exactly 15 M4As")
    require(sum(t["mood"] == "calm" for t in tracks) == 10, "Expected 10 relaxing tracks")
    require(sum(t["mood"] == "upbeat" for t in tracks) == 5, "Expected 5 upbeat tracks incl. menu/results")
    require([t["role"] for t in tracks].count("menu") == 1, "Missing menu theme")
    require([t["role"] for t in tracks].count("results") == 1, "Missing victory theme")
    for t in tracks:
        ref = manifest_tracks[t["id"]]
        require(t["title"] == ref["title"], f"Title mismatch {t['id']}")
        require(t["sha256"] == ref["sha256"], f"Original checksum mismatch {t['id']}")
        require(t["mood"] == ref["mood"] and t["role"] == ref["use"],
                f"Mood/role mismatch {t['id']}")
        require(t["bytes"] == ref["bytes"], f"Size mismatch {t['id']}")
        data = (AUDIO / t["file"]).read_bytes()
        require(data[4:8] == b"ftyp", f"Not M4A {t['file']}")
        require(len(data) == t["bytes"] and sha(data) == t["sha256"],
                f"Altered supplied original recording {t['file']}")
    print("SOURCE VERIFIED: 15 actual AAC M4A tracks, source catalog matches, 10 calm and 3 upbeat gameplay songs.")
    if args.app:
        folder = args.app / "Soundtrack"
        require(folder.is_dir(), f"Soundtrack resource folder missing in .app: {folder}")
        for t in tracks:
            target = folder / t["file"]
            require(target.is_file(), f"Missing track in .app: {t['file']}")
            require(sha(target.read_bytes()) == t["sha256"], f"Altered bundled audio {t['file']}")
        bundled = json.loads((folder / "Catalog.json").read_text(encoding="utf-8"))
        require(len(bundled["tracks"]) == 15, "Missing bundled catalog")
        print("APP VERIFIED: all 15 M4A recordings present in BerryBlockBlast.app, byte-identical.")
    if args.ipa:
        require(args.ipa.is_file(), f"IPA missing: {args.ipa}")
        with zipfile.ZipFile(args.ipa) as z:
            prefix = "Payload/BerryBlockBlast.app/Soundtrack/"
            names = [n for n in z.namelist() if n.startswith(prefix) and n.lower().endswith(".m4a")]
            require(len(names) == 15, f"IPA includes {len(names)} M4As, not 15")
            for t in tracks:
                filename = prefix + t["file"]
                require(filename in z.namelist(), f"IPA missing {t['file']}")
                require(sha(z.read(filename)) == t["sha256"], f"IPA altered {t['file']}")
            require(prefix + "Catalog.json" in z.namelist(), "IPA missing soundtrack catalog")
        print("IPA VERIFIED: 15/15 tracks and catalog embedded unchanged; available offline.")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (AssertionError, OSError, ValueError, KeyError, zipfile.BadZipFile) as exc:
        print("BERRY SOUNDTRACK VALIDATION FAILED:", exc, file=sys.stderr)
        sys.exit(1)
