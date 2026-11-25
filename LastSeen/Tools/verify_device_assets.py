"""Validate physical-device build resources and final IPA bytes, not just simulator assets."""
import argparse, hashlib, json, pathlib, plistlib, zipfile
p=argparse.ArgumentParser()
p.add_argument("--app",type=pathlib.Path)
p.add_argument("--ipa",type=pathlib.Path)
p.add_argument("--catalog",type=pathlib.Path)
a=p.parse_args()
def digest(data): return hashlib.sha256(data).hexdigest()
packs = ["Last-Seen-Build27-Contact-Photos.zip","Last-Seen-Build27-Recovered-Images.zip","Last-Seen-Connected-World-Icons-01.zip","Last-Seen-World-Documents-01.zip"]
expected={}
for name in packs:
    with zipfile.ZipFile(name) as z:
        for record in json.loads(z.read("manifest.json"))["assets"]:
            assert record["filename"] not in expected
            expected[record["filename"]]=record["sha256"]
assert len(expected)==53
expected["ConnectedWorldDocuments.json"]=digest(pathlib.Path("LastSeenApp/ConnectedWorldDocuments.json").read_bytes())
if a.app:
    car=(a.app/"Assets.car").read_bytes()
    assert car.startswith(b"BOMStore") and len(car)>1024, "Malformed compiled asset catalog"
    print("Device Assets.car:",len(car),"bytes SHA-256",digest(car))
    for name,sha in expected.items():
        assert digest((a.app/name).read_bytes())==sha, name
    print("All 53 standalone originals and native document text verified")
if a.catalog:
    records=json.loads(a.catalog.read_text())
    assert isinstance(records,list) and len(records)>20, "Empty/unreadable CoreUI catalog"
    names={row.get("Name") for row in records if isinstance(row,dict)}
    required={"Jailbreak_"+n for n in ["FieldNotes","ClipGlass","LumaPlus","AfterglowStudio","PulseTerminal","RootExplorer","PocketClipboard","QuickPulse","PowerDeck","Relay","Patchline","TweakHub"]}
    required.update(["Contact_Maya","Contact_Denise","Nora_Profile","Icon_Messages","Icon_Save","Photo_Locked_Texture"])
    required.update(["Icon_Afterframe","Icon_Connective","Icon_CommonGround","Icon_VoiceMemos"])
    required.update(f"CommunityPortrait_{i:02d}" for i in range(1,19))
    required.update(["Icon_HavenWatch","Icon_Dayblink","Icon_Motionwell"])
    required.update(f"HavenWatch_CAM{i:02d}_{suffix}" for i in range(1,6) for suffix in ("empty","occupied"))
    missing=required-names
    assert not missing, f"Device catalog missing required renditions: {sorted(missing)}"
    print("Required device catalog renditions verified")
if a.ipa:
    assert a.app is not None
    with zipfile.ZipFile(a.ipa) as z:
        assert z.testzip() is None, "IPA CRC failed"
        prefix="Payload/LastSeen.app/"
        names=z.namelist()
        assert len(names)==len(set(names)), "Duplicate ZIP paths"
        info=plistlib.loads(z.read(prefix+"Info.plist"))
        assert info["CFBundleVersion"]=="32" and info["CFBundleShortVersionString"]=="1.9.0", "IPA identity disagrees with release contract"
        assert info["MinimumOSVersion"]=="16.0" and info["CFBundleIdentifier"]=="com.valentinebsaa.lastseen.horror"
        for name in ["Assets.car","Info.plist",info["CFBundleExecutable"]]:
            assert digest(z.read(prefix+name))==digest((a.app/name).read_bytes()), name
        for name,sha in expected.items():
            assert digest(z.read(prefix+name))==sha, name
        print("Final IPA CRC, identity, compiled catalog, executable and 54 resource hashes verified")
