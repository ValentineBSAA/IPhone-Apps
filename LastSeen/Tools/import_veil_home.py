"""Import six pinned creator-approved VEIL home originals; never overwrite HavenWatch."""
import argparse, hashlib, json, pathlib, struct, zipfile
EXPECTED = "5c6b8566420794422153e9b56cabf9ad8527cc675aca88f42973180f9b8f801c"
def sha(data): return hashlib.sha256(data).hexdigest()
def run(path, app):
    if sha(path.read_bytes()) != EXPECTED:
        raise ValueError("VEIL home archive digest mismatch")
    allowed = {f"VEIL_Home_{i:02d}": f"images/VEIL_Home_{i:02d}.png" for i in range(1,7)}
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        if z.testzip() is not None or len(names) != 8 or set(names) != set(allowed.values()) | {"manifest.json", "README.txt"}:
            raise ValueError("Unexpected VEIL home ZIP inventory")
        assets = json.loads(z.read("manifest.json"))["assets"]
        if len(assets) != 6 or {a["id"]: a["file"] for a in assets} != allowed:
            raise ValueError("Unexpected VEIL home manifest")
        verified = []
        for a in assets:
            data = z.read(a["file"])
            if sha(data) != a["sha256"] or data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II",data[16:24]) != (a["width"],a["height"]):
                raise ValueError("Invalid asset " + a["id"])
            verified.append((a["id"], data))
        for name, data in verified:
            dest = app / "Assets.xcassets" / (name + ".imageset")
            dest.mkdir(parents=True, exist_ok=True)
            (dest / "photo.png").write_bytes(data)
            (dest / "Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"photo.png"}],"info":{"author":"xcode","version":1}},indent=2)+"\n")
    print("VEIL home: six pinned originals imported")
if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--zip",type=pathlib.Path,required=True)
    p.add_argument("--app",type=pathlib.Path,default=pathlib.Path("LastSeenApp"))
    a=p.parse_args()
    run(a.zip,a.app)
