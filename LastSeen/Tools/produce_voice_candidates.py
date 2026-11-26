"""Explicitly requested paid one-take production. No automatic retries."""
import argparse, hashlib, json, os, pathlib, re, subprocess, urllib.request, urllib.error, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
REQUEST = ROOT.parent / ".github/last-seen-voice-request.json"
ASSETS = ROOT / "VoiceAssets"
WORK = ASSETS / "VoiceCandidateWork"
OUTPUT = ASSETS / "LastSeen_B32_VoiceCandidates_v1.zip"
MODEL = "eleven_v4"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def config():
    request = json.loads(REQUEST.read_text())
    assert request["authorization"] == "one-take-1001-characters"
    assert request["model"] == MODEL and request["takes"] == 1
    assert request["max_estimated_credits"] == 1100
    voices = request["voices"]
    assert set(voices) == {"Nora Bennett", "Tessa Reed", "Luma Assistant"}
    assert len(set(voices.values())) == 3
    assert all(re.fullmatch(r"[A-Za-z0-9]{20}", v) for v in voices.values())
    script_bytes = (ASSETS / "initial_scripts.json").read_bytes()
    assert hashlib.sha1(b"blob " + str(len(script_bytes)).encode() + b"\0" + script_bytes).hexdigest() == request["script_catalog_git_blob"], "Scripts changed since authorization"
    scripts = json.loads(script_bytes)
    rows = scripts["memos"] + [{**r, "speaker":"Luma Assistant"} for r in scripts["assistant"]]
    assert len(rows) == 10 and sum(len(r["text"]) for r in rows) == 1001
    assert len({r["file"] for r in rows}) == 10
    assert all(re.fullmatch(r"Luma(?:Memo|Assistant)_[a-z]+\.m4a",r["file"]) for r in rows)
    assert not OUTPUT.exists(), "Candidate archive already exists; refusing regeneration"
    return rows, voices

def main(check_only):
    rows, voices = config()
    if check_only:
        print("Authorized one-take request: 10 clips, 1001 characters; no generation in check mode.")
        return
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        raise SystemExit("ELEVENLABS_API_KEY is not configured. No credits spent.")
    WORK.mkdir(exist_ok=False)
    records = []
    for row in rows:
        filename = row["file"]
        voice = voices[row["speaker"]]
        body = json.dumps({"text":row["text"],"model_id":MODEL}).encode()
        url = "https://api.elevenlabs.io/v1/text-to-speech/" + voice + "?output_format=mp3_44100_128"
        request = urllib.request.Request(url, data=body, headers={"xi-api-key":key,"Content-Type":"application/json","Accept":"audio/mpeg"}, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                audio = response.read()
        except urllib.error.HTTPError as error:
            raise SystemExit(f"Generation stopped at {filename}: HTTP {error.code}. No automatic retry.")
        assert len(audio) > 1000, filename
        mp3 = WORK / (filename + ".mp3")
        target = WORK / filename
        mp3.write_bytes(audio)
        subprocess.run(["ffmpeg","-nostdin","-v","error","-xerror","-i",str(mp3),"-c:a","aac","-b:a","128k","-movflags","+faststart",str(target)],check=True)
        subprocess.run(["ffmpeg","-nostdin","-v","error","-xerror","-i",str(target),"-f","null","-"],check=True)
        probe = json.loads(subprocess.check_output(["ffprobe","-v","error","-show_streams","-show_format","-of","json",str(target)]))
        assert len(probe["streams"]) == 1 and probe["streams"][0]["codec_name"] == "aac"
        duration = float(probe["format"]["duration"])
        assert 0.5 < duration < 60
        records.append({"file":filename,"sha256":sha(target.read_bytes()),"script_sha256":sha(row["text"].encode("utf-8")),"speaker":row["speaker"],"voice_id":voice,"provider":"ElevenLabs","model":MODEL,"duration_seconds":duration,"rights_reviewed":False})
        (WORK / "manifest.json").write_text(json.dumps({"version":1,"creator_approved":False,"assets":records},indent=2)+"\n")
        print("Candidate generated and decoded:", filename, flush=True)
    with zipfile.ZipFile(OUTPUT,"w",zipfile.ZIP_DEFLATED) as archive:
        for row in records:
            archive.write(WORK / row["file"],row["file"])
        archive.write(WORK / "manifest.json","manifest.json")
    with zipfile.ZipFile(OUTPUT) as archive:
        assert archive.testzip() is None and len(archive.namelist()) == 11
    print("Candidate archive complete. Human voice and rights approval required before runtime import.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check",action="store_true")
    main(parser.parse_args().check)
