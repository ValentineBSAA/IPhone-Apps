"""Verify photo resources after import and before Xcode compilation.

The earlier recovered PNGs are standalone resources, while the Nora and
VEIL packs are asset catalog images. Held world artwork and unapproved
voice candidates must not accidentally become runtime resources.
"""
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "LastSeenApp"
CATALOG = APP / "Assets.xcassets"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def require(condition, message):
    if not condition:
        raise SystemExit(message)

def verify_catalog(name, filename, expected):
    path = CATALOG / (name + ".imageset")
    contents = json.loads((path / "Contents.json").read_text())
    names = {r["filename"] for r in contents["images"] if "filename" in r}
    require(names == {filename}, "Unexpected rendition filenames: " + name)
    require(digest((path / filename).read_bytes()) == expected,
            "Imported artwork hash differs: " + name)

def verify():
    with ZipFile(ROOT / "Last-Seen-Build27-Recovered-Images.zip") as z:
        records = json.loads(z.read("manifest.json"))["assets"]
        expected = {f"Recovered_B27_{i:02d}" for i in range(1, 30)}
        require(len(records) == 29 and {r["asset_id"] for r in records} == expected,
                "Earlier recovered inventory differs")
        for r in records:
            name = r["asset_id"]
            filename = name + ".png"
            require(r["filename"] == filename, "Unexpected recovered filename")
            require(digest((APP / filename).read_bytes()) == r["sha256"],
                    "Standalone artwork differs: " + name)
            require(not (CATALOG / (name + ".imageset")).exists(),
                    "Duplicate catalog alias could shadow standalone original: " + name)
    with ZipFile(ROOT / "Last-Seen-Nora-Photo-Pack.zip") as z:
        records = json.loads(z.read("manifest.json"))
        expected = {"Nora_Profile", "Photo_Locked_Texture", "Nora_Collage_01", "Nora_Collage_02"}
        expected.update(f"Nora_Photo_{i:02d}" for i in range(1, 13))
        require(len(records) == 16 and {r["id"] for r in records} == expected,
                "Nora inventory differs")
        for r in records:
            verify_catalog(r["id"], "photo.jpg", r["sha256"])
        profile = next(r["sha256"] for r in records if r["id"] == "Nora_Profile")
        for i in range(1, 5):
            verify_catalog(f"Contact_Nora_{i:02d}", "portrait.jpg", profile)
    with ZipFile(ROOT / "LAST_SEEN_VEIL_Nora_Approved_Assets_v1.zip") as z:
        records = json.loads(z.read("manifest.json"))["assets"]
        expected = {"Icon_Veil"} | {f"Nora_Archive_{i:02d}" for i in range(1, 12)}
        require(len(records) == 12 and {r["asset"] for r in records} == expected,
                "VEIL inventory differs")
        for r in records:
            verify_catalog(r["asset"], "photo.png", r["sha256"])
    with ZipFile(ROOT / "LAST_SEEN_VEIL_Home_Selection_v1.zip") as z:
        records = json.loads(z.read("manifest.json"))["assets"]
        require(len(records) == 6 and {r["id"] for r in records} == {f"VEIL_Home_{i:02d}" for i in range(1,7)},
                "VEIL home inventory differs")
        for r in records:
            verify_catalog(r["id"], "photo.png", r["sha256"])
    print("Six additional VEIL home originals verified.")
    require(not any(APP.rglob("WorldPhoto_E01_*")),
            "Held world expansion artwork must remain outside runtime")
    require(not any(APP.rglob("LastSeen_B32_VoiceCandidates*")),
            "Unapproved candidate archive must remain outside runtime")
    print("Photo preflight: 29 standalone originals, 16 Nora assets, four canonical aliases and 12 VEIL assets verified; held artwork excluded.")

if __name__ == "__main__":
    verify()
