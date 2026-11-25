"""Verify approved original intake; intentionally do not expose held artwork in runtime."""
import hashlib, json, pathlib, struct, zipfile
p=pathlib.Path("Last-Seen-World-Photos-Expansion-01.zip")
assert p.stat().st_size==46400998
assert hashlib.sha256(p.read_bytes()).hexdigest()=="0d7b45bc6bc2ec65d77c2fb47c41ed9879fb79da0e610bfd5a07fa9d30ab0e10"
with zipfile.ZipFile(p) as z:
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
    assert sum(r["kind"]=="composite" for r in records)==1
print("Verified 18 approved intake originals; staged outside player-facing bundle pending continuity approval.")
