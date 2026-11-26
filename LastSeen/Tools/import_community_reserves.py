"""Verify and convert reviewed, pinned source reserves for the runtime catalog."""
import hashlib, json, pathlib, shutil, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "CommunityPortraits"
APP = ROOT / "LastSeenApp"
def blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
def main():
    assignments = json.loads((SOURCE / "runtime-reserves.json").read_text())["assets"]
    assert len(assignments) == 18
    for key in ("handle", "asset", "filename"):
        assert len({r[key] for r in assignments}) == len(assignments)
    manifests = {}
    for intake in ("Intake02", "Intake03"):
        records = json.loads((SOURCE / intake / "manifest.json").read_text())["assets"]
        manifests[intake] = {r.get("asset", r.get("path")): r for r in records}
    for row in assignments:
        name = row["filename"]
        assert pathlib.Path(name).name == name
        metadata = manifests[row["intake"]][name]
        assert metadata["license"].startswith("Apache-2.0")
        source = SOURCE / row["intake"] / name
        assert blob(source.read_bytes()) == metadata.get("git_blob_sha", metadata.get("sha")), name
        dest = APP / "Assets.xcassets" / (row["asset"] + ".imageset")
        dest.mkdir(parents=True, exist_ok=True)
        target = dest / "portrait.png"
        if source.suffix == ".webp":
            subprocess.run(["sips", "-s", "format", "png", str(source), "--out", str(target)], check=True)
        else:
            shutil.copyfile(source, target)
        assert target.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), name
        (dest / "Contents.json").write_text(json.dumps({"images":[{"idiom":"universal","filename":"portrait.png"}],"info":{"author":"xcode","version":1}}, indent=2)+"\n")
    credits = APP / "CommunityReserveCredits"
    credits.mkdir(exist_ok=True)
    for intake, filename, output in [
        ("Intake02","LICENSE","CommunityReserve_Apache_LICENSE.txt"),
        ("Intake02","NOTICE","CommunityReserve_Appcove_NOTICE.txt"),
        ("Intake03","NOTO-IMAGE-LICENSE.txt","CommunityReserve_Noto_IMAGE_LICENSE.txt")
    ]:
        shutil.copyfile(SOURCE / intake / filename, credits / output)
    provenance = []
    for row in assignments:
        item = manifests[row["intake"]][row["filename"]]
        provenance.append({**row, "source_url":item["source_url"],"license":item["license"],"source_git_blob":item.get("git_blob_sha",item.get("sha")),"conversion":"PNG conversion" if row["filename"].endswith(".webp") else "unchanged PNG"})
    (credits / "CommunityReserveProvenance.json").write_text(json.dumps(provenance, indent=2)+"\n")
    print("Verified and imported 14 synthetic portraits and four illustrated hobby avatars")
if __name__ == "__main__":
    main()
