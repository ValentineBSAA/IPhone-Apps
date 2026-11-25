"""Import both creator-approved original social icons. No substitutions."""
import argparse, hashlib, json, pathlib, zipfile
EXPECTED_ZIP = "b54a975cc30710e4b455e8be2baf2b5b43d66a5df991e908a4406c2540f4d71b"
EXPECTED = {
    "Icon_Dayblink": "537cfb70e0531638f5a3f6e127948a9c5c8d9e434d7e44c2322405f83b7aff34",
    "Icon_Motionwell": "64cadbffffa2e7d287a16aa08e9a43856e039a6b8d90dfd690d845050d66bfc2",
}
def sha(data): return hashlib.sha256(data).hexdigest()
def run(archive, catalog):
    if sha(archive.read_bytes()) != EXPECTED_ZIP:
        raise ValueError("Approved social icon archive hash mismatch")
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None or len(z.namelist()) != len(set(z.namelist())):
            raise ValueError("Invalid icon ZIP")
        records = json.loads(z.read("manifest.json"))["assets"]
        if len(records) != 2 or {r["asset"] for r in records} != set(EXPECTED):
            raise ValueError("Unexpected icon manifest")
        verified = {}
        for record in records:
            asset = record["asset"]
            data = z.read(asset + ".png")
            if record["filename"] != asset + ".png" or sha(data) != record["sha256"] or sha(data) != EXPECTED[asset] or not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Icon hash or format mismatch: " + asset)
            verified[asset] = data
        for asset, data in verified.items():
            folder = catalog / (asset + ".imageset")
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "photo.png").write_bytes(data)
            (folder / "Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"photo.png"}],"info":{"author":"xcode","version":1}}, indent=2)+"\n")
    print("Both approved social icons verified and imported")
if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--zip", type=pathlib.Path, required=True)
    p.add_argument("--catalog", type=pathlib.Path, default=pathlib.Path("LastSeenApp/Assets.xcassets"))
    a = p.parse_args()
    run(a.zip, a.catalog)
