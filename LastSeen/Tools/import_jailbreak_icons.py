import argparse, hashlib, json, pathlib, struct, zipfile
p=argparse.ArgumentParser()
p.add_argument("--zip", required=True)
args=p.parse_args()
archive=pathlib.Path(args.zip)
assert hashlib.sha256(archive.read_bytes()).hexdigest()=="83added411fb0bb6ea9abd7fe586baeadfb6b90216f8db80000d9c0f4e900703", "Archive hash changed"
expected={"Jailbreak_"+x for x in ["FieldNotes","ClipGlass","LumaPlus","AfterglowStudio","PulseTerminal","RootExplorer","PocketClipboard","QuickPulse","PowerDeck","Relay","Patchline","TweakHub"]}
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    records=json.loads(z.read("manifest.json"))["assets"]
    assert len(records)==12 and {r["asset_id"] for r in records}==expected
    for r in records:
        name=r["asset_id"]
        assert r["filename"]==name+".png"
        data=z.read(r["filename"])
        assert hashlib.sha256(data).hexdigest()==r["sha256"]
        assert data[:8]==b"\x89PNG\r\n\x1a\n" and struct.unpack(">II",data[16:24])==(1024,1024)
        # Keep contact-sheet drafts out of production asset catalog.
        if r["status"]!="standalone":
            print("Archived draft only:",name)
            continue
        dest=pathlib.Path("LastSeenApp/Assets.xcassets")/(name+".imageset")
        dest.mkdir(parents=True,exist_ok=True)
        (dest/"icon.png").write_bytes(data)
        (dest/"Contents.json").write_text(json.dumps({"images":[{"filename":"icon.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}))
        print("Verified:",name)
