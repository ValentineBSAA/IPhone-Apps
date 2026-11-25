import hashlib,json,pathlib,struct,zipfile
packs=[
("Last-Seen-Build27-Jailbreak-Icons.zip","b21598061b90a038a581d730a6541f4872a6cda1a97478528db0faaf0bf0282d",{"Jailbreak_"+x for x in ["FieldNotes","ClipGlass","LumaPlus","AfterglowStudio","PulseTerminal","RootExplorer","PocketClipboard","QuickPulse","PowerDeck","Relay","Patchline","TweakHub"]},(1024,1024)),
("Last-Seen-Build27-Contact-Photos.zip","01ebac08759b4ac6e56cd570380b2bbf6f878e013ed935ce5b2c2cf47d88216b",{f"Contact_B27_{i:02}" for i in range(1,11)},(1122,1402))]
for filename,digest,names,dimensions in packs:
    path=pathlib.Path(filename)
    assert hashlib.sha256(path.read_bytes()).hexdigest()==digest, filename
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        records=json.loads(z.read("manifest.json"))["assets"]
        assert len(records)==len(names) and {r["asset_id"] for r in records}==names
        for r in records:
            name=r["asset_id"]
            assert r["filename"]==name+".png"
            data=z.read(r["filename"])
            assert hashlib.sha256(data).hexdigest()==r["sha256"]
            assert data[:8]==b"\x89PNG\r\n\x1a\n" and struct.unpack(">II",data[16:24])==dimensions
            if name.startswith("Jailbreak_"): assert r["status"]=="standalone"
            dest=pathlib.Path("LastSeenApp/Assets.xcassets")/(name+".imageset")
            dest.mkdir(parents=True,exist_ok=True)
            (dest/"image.png").write_bytes(data)
            (dest/"Contents.json").write_text(json.dumps({"images":[{"filename":"image.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}))
            print("Verified:",name)
