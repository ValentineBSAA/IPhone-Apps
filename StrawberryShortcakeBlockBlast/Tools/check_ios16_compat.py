#!/usr/bin/env python3
"""Source-level guard for Berry Block Blast 0.5.6 build 3's iOS 16 target."""
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
if not re.search(r'(?m)^\s+CURRENT_PROJECT_VERSION:\s*"3"\s*$', project):
    errors.append("Build version should be 3")
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
