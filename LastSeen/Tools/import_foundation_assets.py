"""Verify and import the exact approved Foundation asset pack."""
import hashlib, json, argparse, struct
from pathlib import Path
from zipfile import ZipFile
EXPECTED = set("Wallpaper_BlueHourGlass Wallpaper_TitaniumFlow Wallpaper_CoastalDusk Wallpaper_NeonStudio Wallpaper_PearlMist Wallpaper_CityAfterMidnight Wallpaper_AuroraNight Wallpaper_VelvetPlum Wallpaper_BookshopMorning Wallpaper_ObsidianWave Icon_Save Icon_Messages Icon_Contacts Icon_Photos Icon_Notes Icon_Calendar Icon_Mail Icon_Files Icon_Browser Icon_Clock Icon_Calculator Icon_Settings Icon_Phone Brand_LumaOS System_Recovery System_ProtectedStorage".split())
def sha(data): return hashlib.sha256(data).hexdigest()
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--zip", required=True, type=Path)
    args = p.parse_args()
    if sha(args.zip.read_bytes()) != "ca5e1a9b050e3c6bf7f701aae8207281ab20f54d92b7d765a99b58042d35a2ba":
        raise SystemExit("Foundation archive digest mismatch")
    with ZipFile(args.zip) as z:
        if z.testzip(): raise SystemExit("Corrupt Foundation archive")
        manifest = json.loads(z.read("manifest.json"))
        if len(manifest) != 26 or {m["id"] for m in manifest} != EXPECTED:
            raise SystemExit("Invalid Foundation asset list")
        for m in manifest:
            data = z.read(m["filename"])
            if sha(data) != m["sha256"] or data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != (m["width"],m["height"]):
                raise SystemExit("Invalid asset: " + m["id"])
            dest = Path("LastSeenApp/Assets.xcassets") / (m["id"]+".imageset")
            dest.mkdir(parents=True, exist_ok=True)
            (dest/"image.png").write_bytes(data)
            (dest/"Contents.json").write_text(json.dumps({"images":[{"filename":"image.png","idiom":"universal"}],"info":{"author":"xcode","version":1}},indent=2))
    print("Verified and imported 26 original Foundation assets")
if __name__ == "__main__": main()
