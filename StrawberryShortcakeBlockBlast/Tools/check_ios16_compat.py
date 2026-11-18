#!/usr/bin/env python3
"""Source-only iOS 16 compatibility checks; release versions are checked elsewhere."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
project = (root / "project.yml").read_text(encoding="utf-8")
errors = []

if 'iOS: "16.0"' not in project:
    errors.append("XcodeGen deploymentTarget.iOS must be 16.0")
if 'IPHONEOS_DEPLOYMENT_TARGET: "16.0"' not in project:
    errors.append("IPHONEOS_DEPLOYMENT_TARGET must be 16.0")

# Bundle version consistency is owned by verify_ios16_source.py. Do not
# pin a number here, since this check is reused by future builds.
for source in sorted((root / "BerryBlockBlast").rglob("*.swift")):
    code = source.read_text(encoding="utf-8")
    if ".defaultScrollAnchor(" in code:
        errors.append(f"{source.name}: defaultScrollAnchor requires iOS 17")
    if re.search(r"\.onChange\(of:[^\n]+\)\s*\{\s*\w+\s*,\s*\w+\s+in", code):
        errors.append(f"{source.name}: two-argument onChange requires iOS 17")

if errors:
    for error in errors:
        print("iOS 16 ERROR:", error, file=sys.stderr)
    sys.exit(1)

print("PASS: iOS 16 target and known unsupported SwiftUI APIs")
