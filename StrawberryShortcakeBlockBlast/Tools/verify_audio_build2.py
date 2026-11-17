#!/usr/bin/env python3
"""Strict source/app/IPA gate for the exact 51 M4A + 16 WAV files in Build 2."""
from pathlib import Path
import json, hashlib, zipfile, argparse, sys

ROOT=Path(__file__).resolve().parents[1]
AUDIO=ROOT/"AudioBuild2"

def sha(data): return hashlib.sha256(data).hexdigest()
def require(ok,msg):
    if not ok: raise AssertionError(msg)

def verify():
    ap=argparse.ArgumentParser()
    ap.add_argument("--app",type=Path)
    ap.add_argument("--ipa",type=Path)
    args=ap.parse_args()
    original=json.loads((AUDIO/"ImportManifest.json").read_text(encoding="utf-8"))
    music=json.loads((AUDIO/"Music/Catalog.json").read_text(encoding="utf-8"))["tracks"]
    effects=json.loads((AUDIO/"Effects/Catalog.json").read_text(encoding="utf-8"))["effects"]
    require(len(music)==51 and len(effects)==16,"Expected exactly 51 music files and 16 effects")
    require(sorted(t["id"] for t in music)==list(range(1,52)),"Music catalog IDs 1-51 missing/duplicated")
    require(sorted(t["id"] for t in effects)==list(range(1,17)),"Effect catalog IDs 1-16 missing/duplicated")
    sources=((music,original["tracks"],"Music",".m4a"),(effects,original["effects"],"Effects",".wav"))
    if args.ipa: z=zipfile.ZipFile(args.ipa)
    else: z=None
    try:
        for files,originals,folder,suffix in sources:
            for track in files:
                matched=next((i for i in originals if i["id"]==track["id"]),None)
                require(bool(matched),f"Missing original for {folder} {track['id']}")
                require(track["sha256"]==matched["sha256"],f"Wrong original {folder} {track['id']}")
                require(track["bytes"]==matched["bytes"],f"Wrong original size {folder} {track['id']}")
                data=(AUDIO/folder/track["file"]).read_bytes()
                require(sha(data)==track["sha256"] and len(data)==track["bytes"],f"Changed {track['file']}")
                if suffix==".m4a": require(data[4:8]==b"ftyp",f"Invalid M4A {track['file']}")
                if suffix==".wav": require(data[:4]==b"RIFF" and data[8:12]==b"WAVE",f"Invalid WAV {track['file']}")
                if args.app:
                    dest=args.app/folder/track["file"]
                    require(dest.is_file() and sha(dest.read_bytes())==track["sha256"],f"App missing original {dest}")
                if z:
                    zname="Payload/BerryBlockBlast.app/"+folder+"/"+track["file"]
                    require(zname in z.namelist() and sha(z.read(zname))==track["sha256"],f"IPA missing original {zname}")
            require(len(list((AUDIO/folder).glob("*"+suffix)))==len(files),f"Unexpected {folder} count")
            if args.app:
                cat=args.app/folder/"Catalog.json"
                require(cat.is_file(),f"App missing catalog {cat}")
            if z:
                require("Payload/BerryBlockBlast.app/"+folder+"/Catalog.json" in z.namelist(),f"IPA missing {folder} catalog")
    finally:
        if z:z.close()
    print("BERRY BUILD 2 AUDIO PASS: 51 M4A + 16 WAV original files preserved byte-for-byte"+
          (" in .app" if args.app else "")+(" in IPA" if args.ipa else ""))

if __name__=="__main__":
    try:verify()
    except (AssertionError,OSError,ValueError,KeyError,zipfile.BadZipFile) as e:
        print("AUDIO VALIDATION ERROR:",e,file=sys.stderr);sys.exit(1)
