"""Import the creator-approved Nora artwork, then replace legacy portrait aliases."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

PACK_SHA = "5df2e321ae6cd4e07c1abe3d9a7f2e5157a7d3c59a6d1d603aaf6e650b772e4e"
EXPECTED = {"Nora_Profile", "Photo_Locked_Texture"} | {f"Nora_Photo_{i:02}" for i in range(1, 13)} | {"Nora_Collage_01", "Nora_Collage_02"}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write_asset(root, name, data, filename="photo.jpg"):
    target = root / (name + ".imageset")
    target.mkdir(parents=True, exist_ok=True)
    for old in target.glob("*"):
        if old.is_file():
            old.unlink()
    (target / filename).write_bytes(data)
    (target / "Contents.json").write_text(json.dumps({
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1}
    }, indent=2) + "\n")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", required=True, type=Path)
    parser.add_argument("--assets", default=Path("LastSeenApp/Assets.xcassets"), type=Path)
    args = parser.parse_args()
    if sha(args.zip.read_bytes()) != PACK_SHA:
        raise SystemExit("Nora archive SHA-256 mismatch")
    with ZipFile(args.zip) as z:
        if z.testzip() is not None:
            raise SystemExit("Nora archive corrupt")
        manifest = json.loads(z.read("manifest.json"))
        if len(manifest) != 16 or {m["id"] for m in manifest} != EXPECTED:
            raise SystemExit("Nora manifest identity mismatch")
        if set(z.namelist()) != {name + ".jpg" for name in EXPECTED} | {"manifest.json"}:
            raise SystemExit("Unexpected archive entries")
        for m in manifest:
            data = z.read(m["id"] + ".jpg")
            if sha(data) != m["sha256"] or not data.startswith(b"\xff\xd8\xff") or not data.endswith(b"\xff\xd9"):
                raise SystemExit("Nora asset corrupt: " + m["id"])
            write_asset(args.assets, m["id"], data)
        profile = z.read("Nora_Profile.jpg")
        # Existing saved legacy portrait indices remain valid without exposing gated photos.
        for i in range(1, 5):
            write_asset(args.assets, f"Contact_Nora_{i:02}", profile, "portrait.jpg")
    print("Verified all 16 Nora assets; replaced all four legacy Nora portrait aliases with the canonical profile.")

if __name__ == "__main__":
    main()
