#!/usr/bin/env python3
"""Low-cost Build 4.5 source checks, ahead of macOS simulators."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
def source(path):
    return (root / path).read_text()
project = source("project.yml")
build = source("BerryBlockBlast/BerryBuildIdentity.swift")
engine = source("BerryBlockBlast/BlockEngine.swift")
garden = source("BerryBlockBlast/BerryDeveloperGardenView.swift")
game = source("BerryBlockBlast/BerryGameSession.swift")
economy = source("BerryBlockBlast/BerryEconomy.swift")
workflow = source("../.github/workflows/berry-build4-foundation-qa.yml")
assert 'MARKETING_VERSION: "0.5.15"' in project
assert 'CURRENT_PROJECT_VERSION: "45"' in project
assert 'B4.5 FAIR PLAY' in build
assert 'feature/berry-build4-r6-fair-play-lab' in build
assert 'init(side: Int, hard: Bool = false, cozy: Bool = false, seed: UInt64)' in engine
assert "private func fairPlayRule(for mode: BerryMode)" in garden
assert "Read-only data from the existing economy ledger" in garden
assert "BerryEconomyLedger.shared" in garden
assert 'let price = prices[id]' in game
assert 'static let undoPrice = 40' in economy
assert 'static let shufflePrice = 50' in economy
assert 'static let hintPrice = 35' in economy
assert 'static let cottagePrices = [60, 90, 130, 180, 240, 300]' in economy
assert 'berryblockblast.inventory.v3' in game
assert 'berryberryblast.premium.charges.v059' in game
assert 'Berry-0515-Build4.5-FAIR-PLAY-QA-UNSIGNED-IPA' in workflow
for filename in ("Tools/berry_build45_seeded_audit.swift", "Tools/verify_build45_report.py",
                 "Tests/BerryBuild45FairPlayTests.swift", "BUILD4_5_FAIR_PLAY_QA.md"):
    assert (root / filename).is_file(), filename
print("PASS: Build 4.5 version, read-only QA, seeded tools, existing wallet and pricing")
