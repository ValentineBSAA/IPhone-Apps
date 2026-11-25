"""Import the exact approved icon bytes into Xcode's asset catalog."""
import base64, json, pathlib, struct, zlib
root = pathlib.Path(__file__).resolve().parent.parent
expected = set("Opening_Computer Opening_Phone Opening_USB Opening_Permissions Opening_Diagnostics Opening_Install Opening_Unlock Opening_Terminal Opening_Reboot Opening_Respring Theme_Messages Theme_Contacts Theme_Photos Theme_Notes Theme_Calendar Theme_Mail Theme_Browser Theme_Files Theme_Clock Theme_Settings".split())
assets = {}
for file in sorted((root / "Tools").glob("approved_icons_*.json")):
    for name, encoded in json.loads(file.read_text()).items():
        assert name in expected and name not in assets, name
        data = base64.b64decode(encoded, validate=True)
        assert data[:8] == b"\x89PNG\r\n\x1a\n", name
        pos = 8
        while pos < len(data):
            length = struct.unpack_from(">I", data, pos)[0]
            chunk = data[pos+4:pos+8+length]
            crc = struct.unpack_from(">I", data, pos+8+length)[0]
            assert zlib.crc32(chunk) & 0xffffffff == crc, name
            pos += 12+length
        assert pos == len(data) and chunk == b"IEND", name
        width,height = struct.unpack_from(">II",data,16)
        assert width == height == (320 if name.startswith("Opening_") else 192), name
        assets[name] = data
assert set(assets) == expected, expected-set(assets)
for name,data in assets.items():
    folder = root / "LastSeenApp/Assets.xcassets" / (name+".imageset")
    folder.mkdir(parents=True,exist_ok=True)
    (folder/"icon.png").write_bytes(data)
    (folder/"Contents.json").write_text(json.dumps({"images":[{"filename":"icon.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}))
print("Verified and imported",len(assets),"approved icons")
