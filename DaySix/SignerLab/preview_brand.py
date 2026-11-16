#!/usr/bin/env python3
"""Clearly identify an experimental AGPL-licensed SideStore derivative.

This is a build-time experiment, not an iPhone signing bypass. It only changes
the application display name and writes non-secret provenance information.

Do not replace a functioning official SideStore with this technical preview.
"""
from __future__ import annotations
import argparse
import json
import plistlib
from pathlib import Path

DISPLAY_NAME = "DaySix Signer Lab"


def patch(root: Path, upstream_sha: str) -> Path:
    plist_path = root / "AltStore" / "Info.plist"
    if not plist_path.is_file():
        raise FileNotFoundError(f"Upstream SideStore Info.plist absent: {plist_path}")

    with plist_path.open("rb") as source:
        info = plistlib.load(source)
    original_name = info.get("CFBundleDisplayName", info.get("CFBundleName", "SideStore"))
    if original_name != DISPLAY_NAME:
        info["CFBundleDisplayName"] = DISPLAY_NAME
        # This marker is informational, not a security or entitlement claim.
        info["DaySixSignerLabPreview"] = True
        with plist_path.open("wb") as dest:
            plistlib.dump(info, dest, sort_keys=False)

    with plist_path.open("rb") as source:
        result = plistlib.load(source)
    if result.get("CFBundleDisplayName") != DISPLAY_NAME:
        raise RuntimeError("Display-name patch failed")
    if not result.get("DaySixSignerLabPreview"):
        raise RuntimeError("Preview marker absent")
    if result.get("CFBundleURLTypes") != info.get("CFBundleURLTypes"):
        raise RuntimeError("Existing URL schemes were unexpectedly modified")

    evidence = {
        "product": DISPLAY_NAME,
        "purpose": "technical preview only, not a verified iPhone signer",
        "upstream_repository": "https://github.com/SideStore/SideStore",
        "upstream_commit": upstream_sha.strip(),
        "upstream_license": "AGPL-3.0",
        "modification": "CFBundleDisplayName and informational Info.plist flag only",
        "dependency_licenses": "Check upstream source and nested package licenses",
        "iphone_signing_tested": False,
        "iphone_self_renewal_tested": False,
    }
    provenance = root.parent / "daysix-signerlab-provenance.json"
    provenance.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    return provenance


def verify_ipa(path: Path) -> dict:
    import zipfile
    if not path.exists():
        raise FileNotFoundError(path)
    with zipfile.ZipFile(path) as archive:
        plist_names = [
            x for x in archive.namelist()
            if x == "Payload/SideStore.app/Info.plist"
        ]
        if len(plist_names) != 1:
            raise RuntimeError("Expected exactly one primary SideStore app in the IPA")
        info = plistlib.loads(archive.read(plist_names[0]))
    if info.get("CFBundleDisplayName") != DISPLAY_NAME:
        raise RuntimeError("Packaged IPA lost DaySix Signer Lab label")
    if not info.get("DaySixSignerLabPreview"):
        raise RuntimeError("Packaged IPA missing its experimental marker")
    bundle_id = info.get("CFBundleIdentifier", "")
    if not bundle_id or "$(" in bundle_id:
        raise RuntimeError("Bundle ID is absent or unresolved")
    if bundle_id in {"com.SideStore.SideStore", "com.SideStore.SideStore.Beta"}:
        raise RuntimeError(
            "Would conflict with an official SideStore installation. Refuse packaging.")
    return {
        "bundle_id": bundle_id,
        "display_name": info.get("CFBundleDisplayName"),
        "version": info.get("CFBundleShortVersionString"),
        "note": "Packaged successfully; actual signing and installation are untested",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path)
    parser.add_argument("--sha")
    parser.add_argument("--verify-ipa", type=Path)
    args = parser.parse_args()

    if args.verify_ipa:
        print(json.dumps(verify_ipa(args.verify_ipa), indent=2))
        return
    if not args.root or not args.sha:
        parser.error("Use --root and --sha together, or --verify-ipa")
    print(patch(args.root, args.sha))


if __name__ == "__main__":
    main()
