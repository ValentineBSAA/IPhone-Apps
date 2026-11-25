"""Import exactly the creator-approved HavenWatch V2 archive, fail closed."""
import argparse, csv, hashlib, io, json, pathlib, zipfile

EXPECTED_ZIP = "d9b44afe162641f0a7884e7fa4cf7516f2b4c5adaf026457ab6839f67d013881"
ROOT = "HavenWatch_Version_Two_Approved/"
CAMERAS = ["Front_Entrance", "Living_Room", "Balcony", "Kitchen", "Exterior_Doorbell"]
def sha(data): return hashlib.sha256(data).hexdigest()
def run(archive, catalog):
    if sha(archive.read_bytes()) != EXPECTED_ZIP:
        raise ValueError("HavenWatch V2 archive SHA-256 differs from approved copy")
    paths = {"HavenWatch_App_Icon.png": "Icon_HavenWatch"}
    for i, camera in enumerate(CAMERAS, 1):
        code = f"CAM{i:02d}"
        for source, suffix in [("empty_reference", "empty"), ("nora_present", "occupied")]:
            paths[f"{code}_{camera}/{code}_{source}.png"] = f"HavenWatch_{code}_{suffix}"
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None or len(z.namelist()) != len(set(z.namelist())):
            raise ValueError("Invalid HavenWatch ZIP")
        rows = list(csv.DictReader(io.StringIO(z.read(ROOT + "manifest.csv").decode("utf-8-sig"))))
        if len(rows) != len(paths) or {r["package_path"] for r in rows} != set(paths):
            raise ValueError("Unexpected HavenWatch manifest")
        verified = []
        for row in rows:
            name = row["package_path"]
            data = z.read(ROOT + name)
            if sha(data) != row["sha256"] or not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("HavenWatch image hash or format mismatch: " + name)
            verified.append((paths[name], data))
        for asset, data in verified:
            dest = catalog / (asset + ".imageset")
            dest.mkdir(parents=True, exist_ok=True)
            (dest / "photo.png").write_bytes(data)
            (dest / "Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"photo.png"}],"info":{"author":"xcode","version":1}}, indent=2)+"\n")
    print("HavenWatch V2: 11 approved PNGs verified and imported")
if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--zip", type=pathlib.Path, required=True)
    p.add_argument("--catalog", type=pathlib.Path, default=pathlib.Path("LastSeenApp/Assets.xcassets"))
    a = p.parse_args()
    run(a.zip, a.catalog)
