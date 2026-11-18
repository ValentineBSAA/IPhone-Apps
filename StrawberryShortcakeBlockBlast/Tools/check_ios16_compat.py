#!/usr/bin/env python3
"""Source-level iOS 16 guard, independent of the incremental build number."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.yml").read_text(encoding="utf-8")
errors = []
if not re.search(r'(?m)^\s+iOS:\s*"16\.0"\s*$', project):
    errors.append("XcodeGen deploymentTarget.iOS must equal 16.0")
if not re.search(r'(?m)^\s+IPHONEOS_DEPLOYMENT_TARGET:\s*"16\.0"\s*$', project):
    errors.append("IPHONEOS_DEPLOYMENT_TARGET must equal 16.0")
# Marketing and build numbers are validated for internal consistency by
# verify_ios16_source.py. Older compatibility guards must not pin Build 1/2/3.
if not re.search(r'(?m)^\s+CURRENT_PROJECT_VERSION:\s*"[1-9][0-9]*"\s*
for file in sorted((ROOT / "BerryBlockBlast").glob("*.swift")):
    content = file.read_text(encoding="utf-8")
    if ".defaultScrollAnchor(" in content:
        errors.append(f"{file.name}: iOS 17 defaultScrollAnchor is unguarded")
    for match in re.finditer(r"\.onChange\s*\(of:[^\n]+\)\s*\{\s*[^\n]*?\bin", content):
        closure = match.group()
        if re.search(r"\{\s*\w+\s*,\s*\w+\s+in", closure):
            errors.append(f"{file.name}: iOS 17 two-argument onChange found")
if errors:
    for error in errors:
        print("ERROR:", error, file=sys.stderr)
    sys.exit(1)
print("PASS: iOS 16.0 target and known SwiftUI iOS-17-only APIs checked.")
, project):
    errors.append("CURRENT_PROJECT_VERSION must be a positive integer")
for file in sorted((ROOT / "BerryBlockBlast").glob("*.swift")):
    content = file.read_text(encoding="utf-8")
    if ".defaultScrollAnchor(" in content:
        errors.append(f"{file.name}: iOS 17 defaultScrollAnchor is unguarded")
    for match in re.finditer(r"\.onChange\s*\(of:[^\n]+\)\s*\{\s*[^\n]*?\bin", content):
        closure = match.group()
        if re.search(r"\{\s*\w+\s*,\s*\w+\s+in", closure):
            errors.append(f"{file.name}: iOS 17 two-argument onChange found")
if errors:
    for error in errors:
        print("ERROR:", error, file=sys.stderr)
    sys.exit(1)
print("PASS: iOS 16.0 target and known SwiftUI iOS-17-only APIs checked.")
