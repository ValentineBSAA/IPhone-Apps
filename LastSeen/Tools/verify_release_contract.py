"""Fast, fail-closed checks for release metadata and duplicated timing contracts.
Runs before asset downloads or simulator allocation. Does not replace XCTest.
"""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

def read(relative):
    return (root / relative).read_text(encoding="utf-8")

def capture(pattern, source, label):
    matches = re.findall(pattern, source, flags=re.M)
    if len(matches) != 1:
        errors.append(f"{label}: expected exactly one value, found {matches}")
        return None
    return matches[0]

project = read("project.yml")
version = capture(r'^\s*MARKETING_VERSION:\s*"([^"]+)"\s*$', project, "project version")
build = capture(r'^\s*CURRENT_PROJECT_VERSION:\s*"([^"]+)"\s*$', project, "project build")
identity = read("Tests/BuildIdentityTests.swift")
workflow = (root.parent / ".github/workflows/last-seen-ios16.yml").read_text()
require(version == capture(r'XCTAssertEqual\(marketing,\s*"([^"]+)"', identity, "version test"), "version test disagrees with project")
require(build == capture(r'XCTAssertEqual\(build,\s*"([^"]+)"', identity, "build test"), "build test disagrees with project")
require(version == capture(r'test "\$MARKETING_VERSION" = "([^"]+)"', workflow, "CI version gate"), "CI version gate disagrees with project")
require(build == capture(r'test "\$BUILD_NUMBER" = "([^"]+)"', workflow, "CI build gate"), "CI build gate disagrees with project")
require(f'LabeledContent("Software", value: "{version} ({build})")' in read("LastSeenApp/PhoneLabView.swift"), "Settings version disagrees with project")
require(f'Last-Seen-v{version}-iOS16-unsigned.ipa' in workflow, "IPA name disagrees with project")

source = read("LastSeenApp/RecoveryPrologue.swift")
pace = source.split("enum OpeningPace {", 1)[1].split("    static func duration", 1)[0]
constants = {name: int(value) for name, value in re.findall(r"static let (\w+) = (\d+)\s*$", pace, re.M)}
expression = capture(r"static let total = ([^\n]+)", pace, "opening total expression")
total = None
if expression:
    names = [name.strip() for name in expression.split("+")]
    if all(name in constants for name in names):
        total = sum(constants[name] for name in names)
    else:
        errors.append(f"OpeningPace total cannot be checked: {expression}")

# Exactly one independent numeric total contract. Other suites should test their
# own behavior, not duplicate the entire opening duration.
owners = []
for path in sorted((root / "Tests").rglob("*.swift")):
    body = path.read_text()
    for m in re.finditer(r"XCTAssertEqual\s*\(\s*OpeningPace\.total\s*,\s*(\d+)|XCTAssertEqual\s*\(\s*(\d+)\s*,\s*OpeningPace\.total", body):
        expected = int(m.group(1) or m.group(2))
        owners.append(path.name)
        require(expected == total, f"{path.name}: stale opening total {expected}; actual {total}")
require(owners == ["RecoverySecurityTests.swift"], f"Total timing must have one test owner, found {owners}")

if errors:
    for error in errors:
        print(f"::error::{error}")
    sys.exit(1)
print(f"Release preflight passed: {version} ({build}), {total}s, one timing contract.")
