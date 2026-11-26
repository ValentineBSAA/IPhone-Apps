"""Fast, fail-closed checks for release metadata and duplicated timing contracts.
Runs before asset downloads or simulator allocation. Does not replace XCTest.
"""
from pathlib import Path
import re
import sys
import subprocess

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
# Validate every Python helper without executing imports or creating bytecode.
# The workflow depends on assertions in the pinned resource importers.
require(sys.flags.optimize == 0, "Release verification must not run with Python optimization")
helpers = sorted((root / "Tools").rglob("*.py"))
require(bool(helpers), "No Python build helpers found")
for helper in helpers:
    try:
        compile(helper.read_bytes(), str(helper.relative_to(root)), "exec", optimize=0)
    except (SyntaxError, ValueError) as error:
        errors.append(f"{helper.relative_to(root)}: {error}")
for relative in sorted(set(re.findall(r'python3\s+(Tools/[\w.-]+\.py)\b', workflow))):
    require((root / relative).is_file(), "Workflow references missing helper: " + relative)
require('IPHONEOS_DEPLOYMENT_TARGET: "16.0"' in project and 'iOS: "16.0"' in project,
        "Project deployment target differs from iOS 16.0")
require(version == capture(r'XCTAssertEqual\(marketing,\s*"([^"]+)"', identity, "version test"), "version test disagrees with project")
require(build == capture(r'XCTAssertEqual\(build,\s*"([^"]+)"', identity, "build test"), "build test disagrees with project")
require(version == capture(r'test "\$MARKETING_VERSION" = "([^"]+)"', workflow, "CI version gate"), "CI version gate disagrees with project")
require(build == capture(r'test "\$BUILD_NUMBER" = "([^"]+)"', workflow, "CI build gate"), "CI build gate disagrees with project")
require(f'LabeledContent("Software", value: "{version} ({build})")' in read("LastSeenApp/PhoneLabView.swift"), "Settings version disagrees with project")
require(f'Last-Seen-v{version}-iOS16-unsigned.ipa' in workflow, "IPA name disagrees with project")
device_verifier = read("Tools/verify_device_assets.py")
require(build == capture(r'info\["CFBundleVersion"\]\s*==\s*"([^"]+)"', device_verifier, "IPA verifier build gate"), "IPA verifier build disagrees with project")
require(version == capture(r'info\["CFBundleShortVersionString"\]\s*==\s*"([^"]+)"', device_verifier, "IPA verifier version gate"), "IPA verifier version disagrees with project")

# Runtime cue names and the two pinned MP3 manifests must be a bijection.
# Parse literal names only; never execute Swift or import sound bytes here.
import ast
def track_names(relative):
    tree=ast.parse(read(relative))
    nodes=[n.value for n in tree.body if isinstance(n,ast.Assign)
           and any(isinstance(t,ast.Name) and t.id=="TRACKS" for t in n.targets)]
    require(len(nodes)==1, relative+": missing unique TRACKS manifest")
    return set(ast.literal_eval(nodes[0])) if len(nodes)==1 else set()
original=track_names("Tools/import_phone_sounds.py")
corrective=track_names("Tools/import_extra_phone_sounds.py")
require(len(original)==11 and len(corrective)==4 and not original.intersection(corrective),
        "Approved MP3 manifest count or overlap changed")
cue_source=read("LastSeenApp/PhoneSensoryEngine.swift")
asset_switch=cue_source.split("var assetName: String {",1)[1].split("var title: String {",1)[0]
cue_names=re.findall(r'return "([^"]+)"',asset_switch)
require(len(cue_names)==15 and len(set(cue_names))==15 and set(cue_names)==original|corrective,
        "PhoneCue assets disagree with pinned MP3 manifests")
# Require complete launcher coverage in the spoiler-free audit register.
launcher=read("LastSeenApp/PhoneLabView.swift").split("enum LabApp:",1)[1].split("var foundationIcon:",1)[0]
app_names=re.findall(r'= "([^"]+)"',launcher)
audit_names=re.findall(r'^\| ([^|]+) \| .* \| (?:Pending|Targeted pass|Source reviewed) \| (?:Pending|Passed) \| (?:Pending|Passed) \|$',read("BUILD32_APP_AUDIT.md"),re.M)
require(len(app_names)==len(set(app_names)) and len(audit_names)==len(set(audit_names)) and set(app_names)==set(audit_names),
        "App acceptance register differs from launcher: "+str(set(app_names).symmetric_difference(audit_names)))
# Final visual decisions must agree with playable catalogs. Parse only
# literal authored image arrays/keys, without requiring Pillow or media bytes.
web = read("LastSeenApp/LumaWebBrowser.swift")
veil = read("LastSeenApp/VeilBrowser.swift")
photo = read("LastSeenApp/NoraPhotoCatalog.swift")
browser_images = [asset for group in re.findall(r'images:\s*\[([^\]]*)\]',web)
                  for asset in re.findall(r'"(Recovered_B27_\d{2})"',group)]
reflection = re.findall(r'"(Recovered_B27_\d{2})"',veil.split("static let reflectionAssets=",1)[1].split("\n",1)[0])
expected_recovered = {f"Recovered_B27_{i:02}" for i in range(1,30) if i!=6}
require(set(browser_images+reflection)==expected_recovered and len(browser_images+reflection)==len(expected_recovered),
        "Recovered assignments differ from the browser and VEIL inventory")
titles = photo.split("static let everydayTitles=",1)[1].split("static let everydayDescriptions=",1)[0]
descriptions = photo.split("static let everydayDescriptions=",1)[1].split("static let photos:",1)[0]
expected_expansion={f"WorldPhoto_E01_{i:02}" for i in range(1,11)}
require(set(re.findall(r'"(WorldPhoto_E01_\d{2})"\s*:',titles))==expected_expansion and
        set(re.findall(r'"(WorldPhoto_E01_\d{2})"\s*:',descriptions))==expected_expansion,
        "Camera roll expansion titles/descriptions differ from approved inventory")
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

if not errors:
    result = subprocess.run([sys.executable, "-B", "-m", "unittest", "-v", "test_ipa_payload"], cwd=root / "Tools")
    require(result.returncode == 0, "Offline IPA payload fixtures failed")

if errors:
    for error in errors:
        print(f"::error::{error}")
    sys.exit(1)
print(f"Release preflight passed: {version} ({build}), {total}s, one timing contract, {len(helpers)} Python helpers parsed.")
