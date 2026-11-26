import hashlib,json,pathlib,struct,zipfile
path=pathlib.Path("Last-Seen-Build27-Recovered-Images.zip")
assert hashlib.sha256(path.read_bytes()).hexdigest()=="48928fdc8d8a01631eccac01e1ab0aaa6ef30ca579ce67feb5d2369b6ae2a317"
with zipfile.ZipFile(path) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(set(z.namelist())), "Duplicate recovered ZIP member"
    records=json.loads(z.read("manifest.json"))["assets"]
    assert len(records)==29 and {r["asset_id"] for r in records}=={f"Recovered_B27_{i:02}" for i in range(1,30)}
    validated=[]
    for r in records:
        name=r["asset_id"]
        assert r["filename"]==name+".png"
        data=z.read(r["filename"])
        assert hashlib.sha256(data).hexdigest()==r["sha256"]
        assert data[:8]==b"\x89PNG\r\n\x1a\n" and struct.unpack(">II",data[16:24])==(r["width"],r["height"])
        assert not (pathlib.Path("LastSeenApp/Assets.xcassets")/(name+".imageset")).exists(), "Recovered catalog alias: "+name
        validated.append((name,data))
    # Verify the entire inventory before writing any resource.
    for name,data in validated:
        (pathlib.Path("LastSeenApp")/(name+".png")).write_bytes(data)
        print("Verified standalone resource:",name)
