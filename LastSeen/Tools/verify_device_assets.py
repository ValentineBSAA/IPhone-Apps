"""Validate physical-device build resources and final IPA bytes, not just simulator assets."""
import argparse, hashlib, json, pathlib, plistlib, zipfile, wave
from verify_ipa_payload import verify_payload
from verify_world_photo_intake import verified_originals,reject_held
from import_phone_sounds import TRACKS as ORIGINAL_TRACKS
from import_extra_phone_sounds import TRACKS as CORRECTIVE_TRACKS
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
for name,data in verified_originals("Last-Seen-World-Photos-Expansion-01.zip").items():
    assert name not in expected
    assert digest((pathlib.Path("LastSeenApp")/name).read_bytes())==digest(data)
    expected[name]=digest(data)
# Use the same pinned originals as the importers, not hashes of potentially
# corrupted output. Restart WAVs are deterministic local generated resources.
assert len(ORIGINAL_TRACKS)==11 and len(CORRECTIVE_TRACKS)==4
assert not set(ORIGINAL_TRACKS).intersection(CORRECTIVE_TRACKS)
for name, (_, sha) in {**ORIGINAL_TRACKS, **CORRECTIVE_TRACKS}.items():
    assert name+".mp3" not in expected
    expected[name+".mp3"]=sha
for name in ("RespringDown", "RespringUp", "UserspaceDown", "UserspaceUp"):
    source=pathlib.Path("LastSeenApp/Resources")/(name+".wav")
    with wave.open(str(source),"rb") as wav:
        assert (wav.getnchannels(),wav.getsampwidth(),wav.getframerate(),wav.getnframes())==(1,2,44100,int(44100*0.78)), name
        assert len(wav.readframes(wav.getnframes()))==wav.getnframes()*2, name
    expected[name+".wav"]=digest(source.read_bytes())
scripts=json.loads(pathlib.Path("VoiceAssets/initial_scripts.json").read_text())
voice_names={r["file"] for r in scripts["memos"]+scripts["assistant"]}
assert len(voice_names)==10
# No approved voice pack is pinned/imported in this release configuration.
# An approved future intake must explicitly update this contract.
def reject_unapproved_voice(names):
    for path in names:
        name=pathlib.PurePosixPath(str(path)).name
        assert name not in voice_names and name!="LumaVoiceManifest.json" and not name.startswith("LastSeen_B32_VoiceCandidates"), "Unapproved voice resource: "+str(path)
reject_unapproved_voice(pathlib.Path("LastSeenApp").rglob("*"))
expected["ConnectedWorldDocuments.json"]=digest(pathlib.Path("LastSeenApp/ConnectedWorldDocuments.json").read_bytes())
support_root=pathlib.Path("LastSeenApp/RelaySupportResources")
with zipfile.ZipFile("LastSeen_Build32_RelaySupport_ContentPack_v1.zip") as support:
    approved = json.loads(support.read("RelaySupport/Knowledge/guides.json"))
    assert len(approved) == 13
    for guide in approved:
        name = guide["filename"]
        sha = digest(support.read("RelaySupport/Docs/" + name))
        assert digest((support_root/name).read_bytes()) == sha, name
        expected[name] = sha
    for name in ("guides", "packages"):
        filename = "RelaySupport_" + name + ".json"
        sha = digest(support.read("RelaySupport/Knowledge/" + name + ".json"))
        assert digest((support_root/filename).read_bytes()) == sha, filename
        expected[filename] = sha
motion_root=pathlib.Path("LastSeenApp/MotionwellMedia")
motion_manifest=motion_root/"MotionwellMediaManifest.json"
motion_records=json.loads(motion_manifest.read_text())["assets"]
assert {r["filename"] for r in motion_records}=={"Motionwell_coffee.mp4","Motionwell_woodland.mp4","Motionwell_animals.mp4","Motionwell_studio.mp4","Motionwell_cafe-lunch.mp4","Motionwell_green-walk.mp4"}
assert len(motion_records)==6
for record in motion_records:
    assert digest((motion_root/record["filename"]).read_bytes())==record["sha256"]
    expected[record["filename"]]=record["sha256"]
expected[motion_manifest.name]=digest(motion_manifest.read_bytes())
for credit in pathlib.Path("LastSeenApp/CommunityReserveCredits").iterdir():
    if credit.is_file():
        expected[credit.name]=digest(credit.read_bytes())
assert len([name for name in expected if name.startswith("CommunityReserve")]) == 4
if a.app:
    reject_unapproved_voice(a.app.rglob("*"))
    reject_held(a.app.rglob("*"))
    car=(a.app/"Assets.car").read_bytes()
    assert car.startswith(b"BOMStore") and len(car)>1024, "Malformed compiled asset catalog"
    print("Device Assets.car:",len(car),"bytes SHA-256",digest(car))
    for name,sha in expected.items():
        assert digest((a.app/name).read_bytes())==sha, name
    print("All",len(expected),"standalone originals, documents and local media verified")
if a.catalog:
    records=json.loads(a.catalog.read_text())
    assert isinstance(records,list) and len(records)>20, "Empty/unreadable CoreUI catalog"
    names={row.get("Name") for row in records if isinstance(row,dict)}
    required={"Jailbreak_"+n for n in ["FieldNotes","ClipGlass","LumaPlus","AfterglowStudio","PulseTerminal","RootExplorer","PocketClipboard","QuickPulse","PowerDeck","Relay","Patchline","TweakHub"]}
    required.update(["Contact_Maya","Contact_Denise","Nora_Profile","Icon_Messages","Icon_Save","Photo_Locked_Texture"])
    required.update(["Icon_Afterframe","Icon_Connective","Icon_CommonGround","Icon_VoiceMemos"])
    required.update(f"CommunityPortrait_{i:02d}" for i in range(1,19))
    required.update(r["asset"] for r in json.loads(pathlib.Path("CommunityPortraits/runtime-reserves.json").read_text())["assets"])
    required.update(["Icon_HavenWatch","Icon_Dayblink","Icon_Motionwell","Icon_RelaySupport","Support_AlexMorgan"])
    required.update(f"HavenWatch_CAM{i:02d}_{suffix}" for i in range(1,6) for suffix in ("empty","occupied"))
    required.add("Icon_Veil")
    required.update(f"Nora_Archive_{i:02d}" for i in range(1,12))
    required.update(f"VEIL_Home_{i:02d}" for i in range(1,7))
    required.update(f"Nora_Photo_{i:02d}" for i in range(1,13))
    required.update(["Nora_Collage_01","Nora_Collage_02"])
    # Build27 originals are standalone PNGs, not CoreUI renditions.
    # Their exact bytes are already verified against the pinned manifest in
    # both the device bundle and the final IPA.
    assert all(f"Recovered_B27_{i:02d}.png" in expected for i in range(1,30))
    assert not any(isinstance(name,str) and name.startswith("WorldPhoto_E01_") for name in names), "Held world artwork in compiled catalog"
    missing=required-names
    assert not missing, f"Device catalog missing required renditions: {sorted(missing)}"
    print("Required device catalog renditions verified")
if a.ipa:
    assert a.app is not None
    with zipfile.ZipFile(a.ipa) as z:
        assert z.testzip() is None, "IPA CRC failed"
        file_count=verify_payload(z,a.app)
        print("Verified exact compiled app payload:",file_count,"files")
        prefix="Payload/LastSeen.app/"
        names=z.namelist()
        assert len(names)==len(set(names)), "Duplicate ZIP paths"
        reject_unapproved_voice(names)
        reject_held(names)
        info=plistlib.loads(z.read(prefix+"Info.plist"))
        assert info["CFBundleVersion"]=="32" and info["CFBundleShortVersionString"]=="1.9.0", "IPA identity disagrees with release contract"
        assert info["MinimumOSVersion"]=="16.0" and info["CFBundleIdentifier"]=="com.valentinebsaa.lastseen.horror"
        for name in ["Assets.car","Info.plist",info["CFBundleExecutable"]]:
            assert digest(z.read(prefix+name))==digest((a.app/name).read_bytes()), name
        for name,sha in expected.items():
            assert digest(z.read(prefix+name))==sha, name
        print("Final IPA CRC, identity, compiled catalog, executable and",len(expected),"resource hashes verified")
