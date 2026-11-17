#!/usr/bin/env python3
"""Lightweight source checks, NOT a substitute for compiling with Xcode."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
p = (root / 'project.yml').read_text()
assert 'iOS: "16.0"' in p
assert 'IPHONEOS_DEPLOYMENT_TARGET: "16.0"' in p
assert 'CURRENT_PROJECT_VERSION: "1"' in p
assert 'MARKETING_VERSION: "0.5.7"' in p
for f in (root / 'BerryBlockBlast').rglob('*.swift'):
    content = f.read_text()
    assert not re.search(r'\.onChange\(of:[^\n]+\)\s*\{\s*\w+\s*,\s*\w+\s+in', content), f
print('PASS: iOS 16 source-level target and onChange signatures')
