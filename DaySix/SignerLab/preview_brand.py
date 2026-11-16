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
PREVIEW_ORG = "com.valentinebsaa.daysix"
PREVIEW_BUNDLE_ID = PREVIEW_ORG + ".signerlab"
UPSTREAM_BUNDLE_ID = "com.SideStore.SideStore"
PREVIEW_TEAM_ID = "XYZ0123456"  # upstream's ad-hoc CI placeholder, not a real certificate


def replace_exact(path: Path, old: str, new: str) -> None:
    """Reject unknown upstream versions instead of making unsafe guesses."""
    if not path.is_file():
        raise FileNotFoundError(path)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"Expected one match in {path}, found {count}: {old}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def patch_build_identifiers(root: Path) -> None:
    """Patch actual Xcode build settings, not the unused Makefile suffix flag."""
    replace_exact(root / "Build.xcconfig",
                  "ORG_IDENTIFIER = com.SideStore",
                  f"ORG_IDENTIFIER = {PREVIEW_ORG}")
    replace_exact(root / "Build.xcconfig",
                  "BASE_BUNDLE_ID                                  = $(ORG_IDENTIFIER).SideStore",
                  "BASE_BUNDLE_ID                                  = $(ORG_IDENTIFIER).signerlab")
    replace_exact(root / "Makefile", "ORG_IDENTIFIER=com.SideStore",
                  f"ORG_IDENTIFIER={PREVIEW_ORG}")

    # SideStore's ad-hoc ldid release targets embed static app identifiers
    # and static application group names even though the Info.plist uses Xcode
    # variables. Update BOTH main and widget values consistently.
    for relative in [
        "AltStore/Resources/ReleaseEntitlements.plist",
        "AltWidget/Resources/ReleaseEntitlements.plist",
    ]:
        target = root / relative
        replace_exact(target, f"{PREVIEW_TEAM_ID}.{UPSTREAM_BUNDLE_ID}",
                      f"{PREVIEW_TEAM_ID}.{PREVIEW_BUNDLE_ID}")
        replace_exact(target, f"group.{UPSTREAM_BUNDLE_ID}",
                      f"group.{PREVIEW_BUNDLE_ID}")


def patch(root: Path, upstream_sha: str) -> Path:
    plist_path = root / "AltStore" / "Info.plist"
    if not plist_path.is_file():
        raise FileNotFoundError(f"Upstream SideStore Info.plist absent: {plist_path}")

    patch_build_identifiers(root)

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
        "modification": "Display label, preview marker, Xcode main/extension bundle IDs, ad-hoc CI entitlements, and Makefile org identifier",
        "expected_bundle_id": PREVIEW_BUNDLE_ID,
        "ad_hoc_team_placeholder": PREVIEW_TEAM_ID,
        "install_warning": "Experimental signer may still conflict with SideStore URL schemes and installer callbacks",
        "dependency_licenses": "Check upstream source and nested package licenses",
        "iphone_signing_tested": False,
        "iphone_self_renewal_tested": False,
    }
    provenance = root.parent / "daysix-signerlab-provenance.json"
    provenance.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    return provenance


def verify_ipa(path: Path) -> dict:
    import io
    import zipfile

    if not path.exists():
        raise FileNotFoundError(path)
    main_path = "Payload/SideStore.app/Info.plist"
    widget_path = "Payload/SideStore.app/PlugIns/AltWidgetExtension.appex/Info.plist"
    backup_path = "Payload/SideStore.app/SideBackup.ipa"
    nested_path = "Payload/SideBackup.app/Info.plist"

    with zipfile.ZipFile(path) as archive:
        if archive.namelist().count(main_path) != 1:
            raise RuntimeError("Expected exactly one primary app in the IPA")
        info = plistlib.loads(archive.read(main_path))
        if widget_path not in archive.namelist():
            raise RuntimeError("Missing the expected widget extension Info.plist")
        widget = plistlib.loads(archive.read(widget_path))
        if backup_path not in archive.namelist():
            raise RuntimeError("Missing the nested SideBackup IPA")
        with zipfile.ZipFile(io.BytesIO(archive.read(backup_path))) as backup:
            if nested_path not in backup.namelist():
                raise RuntimeError("Missing nested backup app Info.plist")
            backup_info = plistlib.loads(backup.read(nested_path))

    if info.get("CFBundleDisplayName") != DISPLAY_NAME:
        raise RuntimeError("Packaged IPA lost DaySix Signer Lab label")
    if not info.get("DaySixSignerLabPreview"):
        raise RuntimeError("Packaged IPA missing its experimental marker")

    expected_ids = {
        "main": PREVIEW_BUNDLE_ID,
        "widget": PREVIEW_BUNDLE_ID + ".AltWidget",
        "backup": PREVIEW_BUNDLE_ID + ".SideBackup",
    }
    actual_ids = {
        "main": info.get("CFBundleIdentifier", ""),
        "widget": widget.get("CFBundleIdentifier", ""),
        "backup": backup_info.get("CFBundleIdentifier", ""),
    }
    for key, expected in expected_ids.items():
        actual = actual_ids[key]
        if actual != expected:
            raise RuntimeError(
                f"{key} bundle ID {actual!r}; expected {expected!r}. Refuse packaging.")

    return {
        "bundle_id": actual_ids["main"],
        "embedded_bundle_ids": actual_ids,
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
