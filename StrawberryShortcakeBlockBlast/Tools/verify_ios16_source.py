#!/usr/bin/env python3
"""Check supported iOS target and internally consistent bundle metadata.

The *project* owns the build number. Avoid pinning it to a stale release value:
Build 2, Build 3, etc. must pass when all plist fields agree.
These checks do not replace Xcode compilation or physical-device tests.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
project = (root / "project.yml").read_text(encoding="utf-8")


def setting(name: str) -> str:
    match = re.search(r"(?m)^\s*" + re.escape(name) + r"\s*:\s*['\"]?([A-Za-z0-9_.-]+)", project)
    if match is None:
        raise SystemExit(f"VERSION PREFLIGHT FAILED: missing project.yml setting {name}")
    return match.group(1)


if setting("iOS") != "16.0" or setting("IPHONEOS_DEPLOYMENT_TARGET") != "16.0":
    raise SystemExit("VERSION PREFLIGHT FAILED: both iOS deployment targets must equal 16.0")

marketing = setting("MARKETING_VERSION")
build = setting("CURRENT_PROJECT_VERSION")
if not build.isdecimal() or int(build) < 1:
    raise SystemExit(f"VERSION PREFLIGHT FAILED: invalid positive build number: {build!r}")

plist_marketing = setting("INFOPLIST_KEY_CFBundleShortVersionString")
plist_build = setting("INFOPLIST_KEY_CFBundleVersion")
if marketing != plist_marketing or build != plist_build:
    raise SystemExit(
        "VERSION PREFLIGHT FAILED: project.yml has conflicting bundle versions: "
        f"MARKETING_VERSION={marketing}, CFBundleShortVersionString={plist_marketing}, "
        f"CURRENT_PROJECT_VERSION={build}, CFBundleVersion={plist_build}"
    )

for file in (root / "BerryBlockBlast").rglob("*.swift"):
    content = file.read_text(encoding="utf-8")
    # iOS 17 added the two-parameter onChange closure. Keep iOS 16-safe calls.
    if re.search(r"\.onChange\(of:[^\n]+\)\s*\{\s*\w+\s*,\s*\w+\s+in", content):
        raise SystemExit(f"iOS 16 PREFLIGHT FAILED: unsupported two-argument onChange in {file}")

print(f"PASS: iOS 16 source signatures and consistent version {marketing} build {build}")
