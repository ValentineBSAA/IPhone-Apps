#!/usr/bin/env python3
"""Brand a pinned SideStore checkout as the independent BerryStore build.

Maintains Xcode target/internal executable names for compatibility. This
script does not sign apps or communicate with Apple accounts.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import plistlib
import shutil
import struct
import subprocess
import zlib

DISPLAY_NAME = "BerryStore"
ORG_IDENTIFIER = "com.valentine.berrystore"
BUNDLE_ID = ORG_IDENTIFIER + ".SideStore"
VERSION = "0.1.0"

def require_replace(path: Path, old: str, new: str):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise RuntimeError(f"Unexpected pinned upstream content at {path}: {old!r}")
    path.write_text(text.replace(old,new),encoding="utf-8")

def modify_plist(path: Path, fn):
    obj = plistlib.loads(path.read_bytes())
    fn(obj)
    path.write_bytes(plistlib.dumps(obj, fmt=plistlib.FMT_XML,sort_keys=False))

def ellipse(x,y,cx,cy,rx,ry):
    return ((x-cx)/rx)**2 + ((y-cy)/ry)**2

def blend(a,b,t):
    t=max(0.,min(1.,t))
    return tuple(round(a[i]*(1-t)+b[i]*t) for i in range(3))

def berry_png(size=1024):
    """Deterministic RGBA PNG icon; no external Python packages required."""
    raw=bytearray()
    for py in range(size):
        y=(py+.5)/size
        raw.append(0)
        for px in range(size):
            x=(px+.5)/size
            radial=min(1.,math.hypot(x-.24,y-.12)/1.14)
            rgb=(int(48-31*radial),int(35-19*radial),int(84-40*radial))
            glow=max(0.,1.-math.hypot(x-.35,y-.19)/.65)**2
            rgb=blend(rgb,(107,67,159),glow*.31)
            left=ellipse(x,y,.405,.46,.205,.242)<1.
            right=ellipse(x,y,.595,.46,.205,.242)<1.
            cone=(.37<y<.86 and abs(x-.5)<.39*(.99-y) and y<.86-.05*abs(x-.5))
            body=(left or right or cone) and y>.30
            if body:
                shine=max(0.,1.-math.hypot(x-.39,y-.39)/.46)
                rgb=blend((168,27,74),(255,77,118),.22+.60*shine)
                for row, yy in enumerate((.46,.56,.66,.75)):
                    for col in range(4):
                        xx=.335+col*.105+(.048 if row%2 else 0)
                        if ellipse(x,y,xx,yy,.010,.014)<1:
                            rgb=(255,202,138)
            if (ellipse(x,y,.39,.30,.145,.052)<1 or
                ellipse(x,y,.61,.30,.145,.052)<1 or
                ellipse(x,y,.50,.264,.057,.125)<1):
                rgb=(72,188,126) if x<.5 else (54,169,106)
            if .484<x<.515 and .195<y<.31:
                rgb=(113,207,133)
            if body and ellipse(x,y,.37,.37,.048,.018)<1:
                rgb=blend(rgb,(255,234,239),.60)
            raw.extend((*rgb,255))
    def chunk(kind,data):
        return struct.pack("!I",len(data))+kind+data+struct.pack("!I",zlib.crc32(kind+data)&0xffffffff)
    return b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack("!2I5B",size,size,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(raw),8))+chunk(b"IEND",b"")

def prepare(root:Path):
    root=root.resolve()
    required=[
        "Makefile","Build.xcconfig","AltStore/Info.plist",
        "AltStore/Resources/ReleaseEntitlements.plist",
        "AltStore/Resources/Icons.xcassets/AppIcon.appiconset/Contents.json"
    ]
    for filename in required:
        if not (root/filename).is_file():
            raise FileNotFoundError(f"Missing upstream file {root/filename}")
    require_replace(root/"Makefile","ORG_IDENTIFIER=com.SideStore",f"ORG_IDENTIFIER={ORG_IDENTIFIER}")
    require_replace(root/"Build.xcconfig","ORG_IDENTIFIER = com.SideStore",f"ORG_IDENTIFIER = {ORG_IDENTIFIER}")
    modify_plist(root/"AltStore/Info.plist",lambda obj:obj.update({"CFBundleDisplayName":DISPLAY_NAME}))
    def set_fake_entitlements(obj):
        obj["application-identifier"]="XYZ0123456."+BUNDLE_ID
        obj["com.apple.security.application-groups"]=["group."+BUNDLE_ID]
    modify_plist(root/"AltStore/Resources/ReleaseEntitlements.plist",set_fake_entitlements)
    icons=root/"AltStore/Resources/Icons.xcassets/AppIcon.appiconset"
    master=icons/"1024.png"
    master.write_bytes(berry_png())
    content=json.loads((icons/"Contents.json").read_text())
    sips=shutil.which("sips")
    if not sips:
        print("Non-macOS environment: icon resizing is skipped")
    else:
        for name in sorted({x["filename"] for x in content["images"] if "filename" in x}-{"1024.png"}):
            size=int(Path(name).stem)
            subprocess.run([sips,"-s","format","png","-z",str(size),str(size),str(master),"--out",str(icons/name)],check=True,stdout=subprocess.DEVNULL)
    (root/"AltStore/Resources/Assets.xcassets/SideStore.imageset/1024.png").write_bytes(master.read_bytes())
    (root/"BerryStore-BuildInfo.json").write_text(json.dumps({
        "name":DISPLAY_NAME,"version":VERSION,"bundle_identifier":BUNDLE_ID,
        "internal_target":"SideStore","signing":"fake-signed; must be re-signed by device installer"
    },indent=2)+"\n",encoding="utf-8")
    print(f"Prepared BerryStore {VERSION}, bundle={BUNDLE_ID}; internal target remains SideStore")

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--source",required=True,type=Path)
    prepare(parser.parse_args().source)
