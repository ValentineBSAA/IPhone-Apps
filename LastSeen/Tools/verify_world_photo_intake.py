"""Pinned expansion inventory and explicitly reviewed runtime subset."""
import hashlib, json, pathlib, struct, zipfile

APPROVED = {f"WorldPhoto_E01_{i:02}.png" for i in range(1,11)}

def verified_originals(path):
    path=pathlib.Path(path)
    assert path.stat().st_size==46400998
    assert hashlib.sha256(path.read_bytes()).hexdigest()=="0d7b45bc6bc2ec65d77c2fb47c41ed9879fb79da0e610bfd5a07fa9d30ab0e10"
    selected={}
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        assert len(z.namelist())==len(set(z.namelist()))
        m=json.loads(z.read("manifest.json"))
        assert m["version"]==1
        records=m["assets"]
        assert len(records)==18 and {r["asset_id"] for r in records}=={f"WorldPhoto_E01_{i:02}" for i in range(1,19)}
        for r in records:
            assert r["filename"]==r["asset_id"]+".png"
            b=z.read(r["filename"])
            assert len(b)==r["bytes"] and hashlib.sha256(b).hexdigest()==r["sha256"]
            assert b[:8]==b"\x89PNG\r\n\x1a\n" and struct.unpack(">II",b[16:24])==(r["width"],r["height"])
            if r["filename"] in APPROVED:
                assert r["kind"]!="composite"
                selected[r["filename"]]=b
        assert sum(r["kind"]=="composite" for r in records)==1
    assert set(selected)==APPROVED
    return selected

def reject_held(paths):
    for path in paths:
        name=pathlib.PurePosixPath(str(path)).name
        assert not name.startswith("WorldPhoto_E01_") or name in APPROVED, "Held expansion artwork: "+str(path)

if __name__=="__main__":
    originals=verified_originals("Last-Seen-World-Photos-Expansion-01.zip")
    app=pathlib.Path("LastSeenApp")
    reject_held(app.rglob("*"))
    for name,data in originals.items():
        (app/name).write_bytes(data)
    print(f"Verified 18 expansion originals; imported exactly {len(APPROVED)} reviewed camera-roll originals.")
