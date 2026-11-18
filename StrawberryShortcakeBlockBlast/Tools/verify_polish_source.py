#!/usr/bin/env python3
"""Fast source-only checks before 0.5.10 image extraction and XcodeGen."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
def source(filename):
    return (root / "BerryBlockBlast" / filename).read_text(encoding="utf-8")

project = (root / "project.yml").read_text(encoding="utf-8")
board = source("BerryGameView.swift")
tile = source("BerryStyle.swift")
shop = source("BerryBoutiqueView.swift")
session = source("BerryGameSession.swift")
daily = source("BerryDailyHarvestView.swift")
home = source("BerryModes.swift")

for marker in ('MARKETING_VERSION: "0.5.10"',
               'CURRENT_PROJECT_VERSION: "1"',
               'iOS: "16.0"',
               'PRODUCT_BUNDLE_IDENTIFIER: com.valentinebsaa.berryblockblast'):
    assert marker in project, marker
assert 'guard skin == "strawberry-fruit" else' in tile
assert 'skin == "default" || skin == "strawberry-fruit"' not in tile
for marker in ('private let gap: CGFloat = 3',
               '.fill(Color.white.opacity(0.76))',
               '.strokeBorder(.white.opacity(0.58), lineWidth: 1)',
               'boardSurface == "original"', 'storyDialogueCard(compact: compact)',
               'BerryCandyToolbarButton', 'BerryStyle.urgentTimerGradient'):
    assert marker in board, marker
for marker in ('surface-original', 'surface-cream', 'surface-glass',
               'surface-picnic', 'surface-garden', 'surface-seed',
               'RESTORE ORIGINAL 0.5.8 APPEARANCE'):
    assert marker in shop, marker
for marker in ('beginToday(', 'markLostToday(', 'saveActiveEngine(',
               'enum Outcome: String, Codable', 'struct Attempt: Codable'):
    assert marker in daily, marker
for marker in ('BerryDailyHistory.activeEngine()', 'guard activeMode != .daily else { return }',
               'BerryEconomyLedger.shared.recordSpend'):
    assert marker in session, marker
assert 'BerryDailyHistory.outcome() == .lost' in home
assert 'BerryGridNavigationTile' in home
assert source("BerryEconomyLedger.swift")
assert source("BerrySchoolView.swift")
assert (root / "Tests" / "BerryDailyAttemptTests.swift").is_file()
print("PASS: 0.5.10 original board/blocks, optional skins, one Daily attempt, "
      "timers, Story dialogue, school and economy checks")
