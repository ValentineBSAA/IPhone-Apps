"""Import the pinned creator-approved visual candidates from release L1."""
import argparse, hashlib, json, pathlib, struct, zipfile
EXPECTED = "ae366293c682b11c6b5866548fbbedcc296a0fdec14f7702202d2a3224a38192"
def sha(data): return hashlib.sha256(data).hexdigest()
def run(path, app):
    if sha(path.read_bytes()) != EXPECTED:
        raise ValueError("VEIL archive digest mismatch")
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        if z.testzip() is not None or len(names) != 14 or len(set(names)) != len(names):
            raise ValueError("VEIL ZIP integrity or entry count")
        assets = json.loads(z.read("manifest.json"))["assets"]
        allowed = {"Icon_Veil": "Icons/Icon_Veil.png", **{f"Nora_Archive_{i:02d}": f"Archive/Nora_Archive_{i:02d}.png" for i in range(1,12)}}
        if len(assets) != 12 or {a["asset"]: a["path"] for a in assets} != allowed or set(names) != set(allowed.values()) | {"README.txt","manifest.json"}:
            raise ValueError("Unexpected VEIL asset inventory")
        for a in assets:
            data = z.read(a["path"])
            if sha(data) != a["sha256"] or len(data) != a["bytes"] or data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II",data[16:24]) != (a["width"],a["height"]):
                raise ValueError("Invalid asset " + a["asset"])
            dest = app / "Assets.xcassets" / (a["asset"] + ".imageset")
            dest.mkdir(parents=True,exist_ok=True)
            (dest/"photo.png").write_bytes(data)
            (dest/"Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"photo.png"}],"info":{"author":"xcode","version":1}},indent=2)+"\n")
    print("VEIL: 12 pinned PNG assets imported")
if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--zip",type=pathlib.Path,required=True)
    p.add_argument("--app",type=pathlib.Path,default=pathlib.Path("LastSeenApp"))
    a=p.parse_args()
    run(a.zip,a.app)
