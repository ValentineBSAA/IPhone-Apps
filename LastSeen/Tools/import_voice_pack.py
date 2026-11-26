"""Validate an explicitly approved local voice pack; never generate or download audio."""
import argparse, hashlib, json, pathlib, subprocess, zipfile, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
def sha(data):
    return hashlib.sha256(data).hexdigest()
def run(archive, output, physical_qa=False):
    if physical_qa:
        # Explicit creator acceptance of this exact existing recording pack
        # for private physical QA, not a commercial licensing determination.
        data=archive.read_bytes()
        assert hashlib.sha1(b"blob "+str(len(data)).encode()+b"\x00"+data).hexdigest()=="b10305b42e39cb54f445b313fc7e273fd1e158ca", "Unexpected candidate archive"
    scripts = json.loads((ROOT / "VoiceAssets/initial_scripts.json").read_text())
    expected = {r["file"]: r for r in scripts["memos"] + scripts["assistant"]}
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        assert len(names) == len(set(names)) == len(expected) + 1
        assert set(names) == set(expected) | {"manifest.json"}
        assert z.testzip() is None
        manifest = json.loads(z.read("manifest.json"))
        assert manifest["version"] == 1 and (manifest["creator_approved"] is True or physical_qa)
        rows = manifest["assets"]
        assert len(rows) == len(expected) and {r["file"] for r in rows} == set(expected)
        with tempfile.TemporaryDirectory() as tmp:
            staging = pathlib.Path(tmp)
            for row in rows:
                name = row["file"]
                data = z.read(name)
                assert len(data) > 1000 and sha(data) == row["sha256"], name
                assert row["script_sha256"] == sha(expected[name]["text"].encode("utf-8")), name
                assert row["voice_id"] and row["provider"] and (row["rights_reviewed"] is True or physical_qa), name
                (staging / name).write_bytes(data)
                probe = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(staging / name)]))
                streams = probe["streams"]
                assert len(streams) == 1 and streams[0]["codec_type"] == "audio" and streams[0]["codec_name"] == "aac", name
                assert 0.5 < float(probe["format"]["duration"]) < 60, name
                subprocess.run(["ffmpeg","-v","error","-xerror","-i",str(staging/name),"-f","null","-"],check=True)
            output.mkdir(parents=True, exist_ok=True)
            for name in expected:
                (output / name).write_bytes((staging / name).read_bytes())
            if physical_qa:
                manifest["creator_approved"]=True
                manifest["approval_scope"]="private_physical_qa"
            (output / "LumaVoiceManifest.json").write_text(json.dumps(manifest, indent=2)+"\n")
    print("Verified ten approved local AAC recordings; transcript matching and vocal quality require human review.")
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, default=ROOT / "LastSeenApp/VoiceResources")
    parser.add_argument("--physical-qa", action="store_true", help="Exact creator-accepted B32 candidate only; not commercial release clearance")
    args = parser.parse_args()
    run(args.zip, args.out, args.physical_qa)
