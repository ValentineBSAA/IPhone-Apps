#!/usr/bin/env python3
"""Verify the real compiled IPA, not merely that the build command returned 0."""
from pathlib import Path
import argparse
import hashlib
import plistlib
import zipfile

EXPECTED_ID="com.valentine.berrystore.SideStore"
EXPECTED_NAME="BerryStore"

def verify(path:Path):
    if not path.is_file() or not zipfile.is_zipfile(path):
        raise ValueError("Missing or invalid IPA")
    prefix="Payload/SideStore.app/"
    with zipfile.ZipFile(path) as z:
        required={prefix+"Info.plist",prefix+"SideStore"}
        missing=required-set(z.namelist())
        if missing:
            raise ValueError("Missing app payload files: "+str(missing))
        info=plistlib.loads(z.read(prefix+"Info.plist"))
        bundle,name=info.get("CFBundleIdentifier"),info.get("CFBundleDisplayName")
        if (bundle,name)!=(EXPECTED_ID,EXPECTED_NAME):
            raise ValueError(f"Wrong bundle/name: {bundle!r}/{name!r}")
        if len(z.read(prefix+"SideStore"))<1024:
            raise ValueError("Executable is unexpectedly small")
    return hashlib.sha256(path.read_bytes()).hexdigest()

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("ipa",type=Path)
    args=p.parse_args()
    print("Verified:",args.ipa, "SHA256:",verify(args.ipa))
