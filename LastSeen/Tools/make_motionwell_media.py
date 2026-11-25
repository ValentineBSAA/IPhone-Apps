"""Encode original silent photo essays from the existing licensed source images.

No download, voice, external service or capture of real people. Fail closed on
missing source, encoding error, wrong codec, duration or dimensions.
"""
import argparse, hashlib, json, pathlib, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
def call(args):
    subprocess.run([str(a) for a in args], check=True)
def inspect(path, duration):
    data = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)]))
    video = [s for s in data["streams"] if s["codec_type"] == "video"]
    assert len(video) == 1 and video[0]["codec_name"] == "h264"
    assert (video[0]["width"], video[0]["height"]) == (640, 360)
    assert abs(float(data["format"]["duration"]) - duration) < 0.25
    assert not any(s["codec_type"] == "audio" for s in data["streams"])
def main(out):
    recipes = json.loads((ROOT / "MotionwellMedia/recipes.json").read_text())["clips"]
    catalog = ROOT / "LastSeenApp/Assets.xcassets"
    provenance = json.loads((ROOT / "CommunityPortraits/everyday-media-manifest.json").read_text())
    allowed = {row["asset"] for row in provenance["assets"] if row["license"] == "CC0-1.0"}
    out.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory() as td:
        work = pathlib.Path(td)
        for recipe in recipes:
            names = recipe["photos"]
            seconds = recipe["seconds"]
            assert names and set(names) <= allowed and seconds % len(names) == 0
            span = seconds // len(names)
            segments = []
            for i, name in enumerate(names):
                source = catalog / (name + ".imageset") / "photo.jpg"
                assert source.is_file()
                segment = work / (recipe["id"] + str(i) + ".mp4")
                vf = ("scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,"
                      "zoompan=z='min(1.0+on*0.0006,1.10)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2'"
                      f":d={span*24}:s=640x360:fps=24,format=yuv420p,"
                      f"fade=t=in:st=0:d=0.4,fade=t=out:st={span-0.4}:d=0.4")
                call(["ffmpeg","-v","error","-y","-i",source,"-vf",vf,"-an","-t",str(span),"-c:v","libx264","-preset","fast","-crf","24","-movflags","+faststart",segment])
                segments.append(segment)
            concat = work / (recipe["id"] + ".txt")
            concat.write_text("".join("file '" + str(s) + "'\n" for s in segments))
            output = out / ("Motionwell_" + recipe["id"] + ".mp4")
            call(["ffmpeg","-v","error","-y","-f","concat","-safe","0","-i",concat,"-c","copy","-movflags","+faststart",output])
            inspect(output, seconds)
            records.append({"filename":output.name,"seconds":seconds,"sha256":hashlib.sha256(output.read_bytes()).hexdigest(),"kind":recipe["kind"]})
    (out / "MotionwellMediaManifest.json").write_text(json.dumps({"assets":records}, indent=2)+"\n")
    print("Verified",len(records),"actual local H.264 MP4 photo essays")
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out",type=pathlib.Path,default=ROOT/"LastSeenApp"/"MotionwellMedia")
    main(parser.parse_args().out)
