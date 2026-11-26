"""Import the pinned creator-approved support content without extracting arbitrary paths."""
import argparse, hashlib, json, pathlib, re, zipfile

EXPECTED = "1735b2c2d0c52e5441214fbf550b53c111d0c1b550db2ccaf09fb6d0d227e35e"
ROOT = "RelaySupport/"
ART = {"Contact_AlexMorgan.png": "Support_AlexMorgan", "Icon_RelaySupport.png": "Icon_RelaySupport"}
def sha(data): return hashlib.sha256(data).hexdigest()

def run(archive, app):
    if sha(archive.read_bytes()) != EXPECTED:
        raise ValueError("Relay Support archive differs from approved L1 asset")
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        if z.testzip() is not None or len(names) != 21 or len(set(names)) != len(names):
            raise ValueError("Unexpected support archive")
        manifest = {}
        for line in z.read(ROOT + "SHA256SUMS.txt").decode().splitlines():
            digest, name = line.split("  ", 1)
            if name in manifest or not re.fullmatch(r"[0-9a-f]{64}", digest):
                raise ValueError("Invalid manifest row")
            manifest[name] = digest
        if set(names) != {ROOT + name for name in manifest} | {ROOT + "SHA256SUMS.txt"}:
            raise ValueError("Manifest does not cover archive")
        data = {name: z.read(ROOT + name) for name in manifest}
        if any(sha(value) != manifest[name] for name, value in data.items()):
            raise ValueError("Support manifest hash mismatch")
    guides = json.loads(data["Knowledge/guides.json"])
    packages = json.loads(data["Knowledge/packages.json"])
    if len(guides) != 13 or len({g["id"] for g in guides}) != 13:
        raise ValueError("Expected 13 unique guides")
    if len(packages) != 29 or len({p["id"] for p in packages}) != 29:
        raise ValueError("Expected 28 catalog records and proposed app")
    source = (app / "RelayCatalog.swift").read_text()
    ids = set(re.findall(r'RelayPackage\("([^"]+)"', source))
    approved = {p["id"] for p in packages if p["status"] == "existing_catalog"}
    if ids - {"relay-support"} != approved or len(approved) != 28:
        raise ValueError("Package help does not match current Relay catalog")
    if {g["filename"] for g in guides} != {p.split("/", 1)[1] for p in data if p.startswith("Docs/")}:
        raise ValueError("Guide filenames do not match DOCX files")
    for guide in guides:
        name = guide["filename"]
        if not re.fullmatch(r"RS-\d{2}_[a-z0-9-]+\.docx", name) or not data["Docs/" + name].startswith(b"PK"):
            raise ValueError("Invalid document resource")
    for name in ART:
        if not data["Artwork/" + name].startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError("Invalid approved PNG")
    # Only explicitly named resources enter the bundle. Whole package guides
    # remain behind runtime authorization; no unfiltered library listing.
    resources = app / "RelaySupportResources"
    resources.mkdir(parents=True, exist_ok=True)
    for name in ("guides", "packages"):
        (resources / ("RelaySupport_" + name + ".json")).write_bytes(data["Knowledge/" + name + ".json"])
    for guide in guides:
        name = guide["filename"]
        (resources / name).write_bytes(data["Docs/" + name])
    for name, asset in ART.items():
        dest = app / "Assets.xcassets" / (asset + ".imageset")
        dest.mkdir(parents=True, exist_ok=True)
        (dest / "photo.png").write_bytes(data["Artwork/" + name])
        (dest / "Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"photo.png"}],"info":{"author":"xcode","version":1}}, indent=2) + "\n")
    print("Relay Support: verified 21 archive entries, 13 DOCX files, 29 metadata records and two PNGs")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", type=pathlib.Path, required=True)
    parser.add_argument("--app", type=pathlib.Path, default=pathlib.Path("LastSeenApp"))
    args = parser.parse_args()
    run(args.zip, args.app)
