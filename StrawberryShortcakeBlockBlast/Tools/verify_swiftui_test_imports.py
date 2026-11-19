#!/usr/bin/env python3
"""Fast CI guard for missing SwiftUI imports in XCTest files.

Build 4.3 failed on both simulator profiles when a test used Color without
import SwiftUI. Run this BEFORE allocating expensive macOS simulator runners.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "Tests"
# Keep this deliberately narrow: types that require SwiftUI and previously
# caused compiler failures, not generic identifiers or UIKit's UIImage.
SWIFTUI_SYMBOLS = re.compile(r"\b(?:Color|LinearGradient|RadialGradient|AngularGradient)\s*(?:\(|\.)")
IMPORT = re.compile(r"(?m)^\s*import\s+SwiftUI\s*$")


def uses_swiftui_without_import(source: str) -> bool:
    code = "\n".join(line.split("//", 1)[0] for line in source.splitlines())
    return bool(SWIFTUI_SYMBOLS.search(code)) and not bool(IMPORT.search(code))


def main() -> None:
    assert uses_swiftui_without_import("import XCTest\nlet c = Color(red: 1, green: 0, blue: 0)"), "Guard did not reproduce the missing Color import"
    assert not uses_swiftui_without_import("import XCTest\nimport SwiftUI\nlet c = Color.red"), "Guard rejects a correct import"
    assert not uses_swiftui_without_import("import XCTest\nlet icon = UIImage(named: \"foo\")"), "UIKit-only tests should not require SwiftUI"

    files = sorted(TESTS.rglob("*.swift"))
    assert files, "No XCTest source files were found"
    violations = [str(path.relative_to(ROOT)) for path in files
                  if uses_swiftui_without_import(path.read_text(encoding="utf-8"))]
    if violations:
        raise SystemExit("SWIFTUI TEST IMPORT PREFLIGHT FAILED: missing 'import SwiftUI' in: "
                         + ", ".join(violations))
    print(f"PASS: {len(files)} XCTest sources checked for SwiftUI Color imports.")


if __name__ == "__main__":
    main()
