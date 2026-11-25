"""Fail-closed import of approved connected-world originals and native structured text."""
import hashlib, io, json, pathlib, struct, zipfile, xml.etree.ElementTree as ET
root = pathlib.Path("LastSeenApp")
def sha(b): return hashlib.sha256(b).hexdigest()
def pack(name, size, digest, ids):
    path=pathlib.Path(name)
    assert path.stat().st_size==size and sha(path.read_bytes())==digest
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None and len(set(z.namelist()))==len(z.namelist())
        manifest=json.loads(z.read("manifest.json"))
        assert manifest["version"]==1
        records=manifest["assets"]
        assert len(records)==len(ids) and {r["asset_id"] for r in records}==set(ids)
        for r in records:
            name=r["filename"]
            assert name==r["asset_id"]+pathlib.Path(name).suffix and "/" not in name and "\\" not in name
            b=z.read(name)
            assert len(b)==r["bytes"] and sha(b)==r["sha256"]
            yield r,b
icons=["Icon_Afterframe","Icon_Connective","Icon_CommonGround","Icon_VoiceMemos"]
for r,b in pack("Last-Seen-Connected-World-Icons-01.zip",5832029,"b76aa378d958cc92e0d0f1faae895284dd8dd1c84445085d1e6aca8ebcc222b2",icons):
    assert r["filename"]==r["asset_id"]+".png"
    assert b[:8]==b"\x89PNG\r\n\x1a\n" and struct.unpack(">II",b[16:24])==(1254,1254)
    folder=root/"Assets.xcassets"/(r["asset_id"]+".imageset")
    folder.mkdir(parents=True,exist_ok=True)
    (folder/r["filename"]).write_bytes(b)
    (folder/"Contents.json").write_text(json.dumps({"images":[{"filename":r["filename"],"idiom":"universal"}],"info":{"author":"xcode","version":1}}))
    (root/r["filename"]).write_bytes(b)
ns={"w":"http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
def tag(n): return "{"+ns["w"]+"}"+n
def paragraph(p): return "".join(t.text or "" for t in p.iter(tag("t"))).strip()
docs=[]
for r,b in pack("Last-Seen-World-Documents-01.zip",366335,"944149baab8f01d831d13c1e4003dcc4b636080cafb413bccb37d553c5d3bced",[f"WorldDoc_01_{i:02}" for i in range(1,11)]):
    assert r["filename"]==r["asset_id"]+".docx"
    with zipfile.ZipFile(io.BytesIO(b)) as z:
        assert z.testzip() is None and len(set(z.namelist()))==len(z.namelist())
        assert all(not n.startswith("/") and ".." not in pathlib.PurePosixPath(n).parts and "vbaProject" not in n for n in z.namelist())
        xml=z.read("word/document.xml")
        assert b"<!DOCTYPE" not in xml.upper() and b"<!ENTITY" not in xml.upper()
        body=ET.fromstring(xml).find("w:body",ns)
        assert body is not None
        blocks=[]
        for child in body:
            if child.tag==tag("p"):
                text=paragraph(child)
                if not text or text==r["title"]: continue
                style=child.find("w:pPr/w:pStyle",ns)
                kind="heading" if style is not None and "heading" in style.get(tag("val"),"").lower() else "paragraph"
                blocks.append({"kind":kind,"text":text})
            elif child.tag==tag("tbl"):
                rows=[["\n".join(paragraph(p) for p in cell.findall("w:p",ns) if paragraph(p)) for cell in row.findall("w:tc",ns)] for row in child.findall("w:tr",ns)]
                assert rows and all(rows)
                blocks.append({"kind":"table","rows":rows})
        assert len(blocks)>=4
    (root/r["filename"]).write_bytes(b)
    docs.append({"id":r["asset_id"],"title":r["title"],"author":r["author"],"role":r["role"],"relativeDate":r["relative_date"],"revision":r["revision"],"classification":r["classification"],"blocks":blocks})
(root/"ConnectedWorldDocuments.json").write_text(json.dumps(docs,ensure_ascii=False,sort_keys=True),encoding="utf-8")
print("Verified 4 original icons and 10 original DOCX records; native structured text generated.")
