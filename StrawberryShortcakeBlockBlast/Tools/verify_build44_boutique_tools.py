#!/usr/bin/env python3
"""Build 4.4 source preflight, before costly iOS simulators are started.

This checks Board Studio's shared appearance preference and tool safety
routing without changing the saved game or user wallet.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
boutique = (root / "BerryBlockBlast/BerryBoutiqueView.swift").read_text()
settings = (root / "BerryBlockBlast/BerrySettingsHub.swift").read_text()
game = (root / "BerryBlockBlast/BerryGameView.swift").read_text()
special = (root / "BerryBlockBlast/BerrySpecialToolsSheet.swift").read_text()
policy_test = root / "Tests/BerryBuild44BoutiqueToolsTests.swift"

assert policy_test.is_file(), "Missing Build 4.4 Boutique/Tools regression suite"
assert boutique.count('boardSurfaceCard(') == 3, "Expected two preview choices and one builder"
assert 'BerryBoardAppearancePolicy.original' in boutique
assert 'BerryBoardAppearancePolicy.blossomGlass' in boutique
assert 'Category.allCases.filter { $0 != .seasonal }' in boutique, "Board Studio hidden again"
assert '"surface-glass"' not in boutique.split("case .boardStudio:")[-1].split("case .sparkleStudio:")[0], "Retired surface exposed"
for path, source in [("Boutique", boutique), ("Settings", settings), ("GameView", game)]:
    assert '@AppStorage(BerryBoardAppearancePolicy.storageKey)' in source, path + " lost shared board setting"
card = boutique.split("private func boardSurfaceCard(", 1)[1].split("\n    @ViewBuilder", 1)[0]
assert "boardSurface = id" in card
assert "buyCosmetic" not in card and "berries -=" not in card, "Selecting board must be free"
assert ".accessibilityLabel(title)" in card and ".accessibilityValue(" in card
assert 'Text("🍓 Special Tools")' not in special, "Duplicate Special Tools title"
assert ".opacity(canUse(tool) ? 1 : 0.52)" not in special, "Unreadable disabled tool card returned"
assert ".disabled(!canUse(tool))" in special
assert 'guard canUse(tool) else { return }' in special
assert 'BerrySpecialToolAvailability.canUse(' in special
assert 'BerrySpecialToolAvailability.label(' in special
assert 'mode == .classic ?' in game and 'Classic: no Undo, Shuffle, Hint or premium tools' in game
print("PASS: Board Studio, shared appearance save, free selection and readable tool safety.")
