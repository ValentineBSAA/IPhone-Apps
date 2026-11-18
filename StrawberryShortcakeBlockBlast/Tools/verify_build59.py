#!/usr/bin/env python3
"""Offline source and art checks for Berry Berry Blast 0.5.9 Build 1.

Runs AFTER both art payloads have been installed and before xcodebuild.
This validator does not claim the Swift app was compiled or device-tested.
"""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
project = (root / "project.yml").read_text(encoding="utf-8")
assets = root / "BerryBlockBlast" / "Assets.xcassets"
engine = (root / "BerryBlockBlast" / "BlockEngine.swift").read_text(encoding="utf-8")
game = (root / "BerryBlockBlast" / "BerryGameView.swift").read_text(encoding="utf-8")
required_settings = [
    'INFOPLIST_KEY_CFBundleDisplayName: "Berry Berry Blast"',
    'MARKETING_VERSION: "0.5.9"',
    'CURRENT_PROJECT_VERSION: "1"',
    'INFOPLIST_KEY_CFBundleShortVersionString: "0.5.9"',
    'INFOPLIST_KEY_CFBundleVersion: "1"',
    'PRODUCT_BUNDLE_IDENTIFIER: com.valentinebsaa.berryblockblast',
    'iOS: "16.0"',
]
for setting in required_settings:
    assert setting in project, "Missing project setting: " + setting

names = [
    "BerryBerryBlastLogo", "BerryEmptyGardenConcept", "BerryVillageMap",
    "BerryVillageGate", "BerryQuestBoardArt", "BerryJournalArt",
    "BerryDailyHarvestHeader", "BerryStreakTrophy",
    "GoldenTrowel", "RibbonTwister", "StarberrySeed",
    "PicnicPantry", "BerrySpyglass", "PremiumToolsCategory",
    "BerryCharacterPortrait", "BerryCharacterStanding",
    "BerryCharacterCelebrate",
]
for name in names:
    imageset = assets / (name + ".imageset")
    metadata = json.loads((imageset / "Contents.json").read_text(encoding="utf-8"))
    filename = metadata["images"][0]["filename"]
    assert filename == name + ".png", "Incorrect file reference: " + name
    blob = (imageset / filename).read_bytes()
    assert blob[:8] == bytes([137, 80, 78, 71, 13, 10, 26, 10]), "Bad PNG: " + name
    assert len(blob) > 200, "Empty art payload: " + name

icon = assets / "AppIcon.appiconset" / "AppIcon.png"
assert icon.read_bytes()[:8] == bytes([137, 80, 78, 71, 13, 10, 26, 10])
assert "ScrollView([.horizontal, .vertical])" not in game, "Endless must not scroll"
for needle in ("visibleSide", "activeGardenSection", "gardenPatchMoves",
               "gardenPatchLines", "advanceCompletedGardenPatch",
               "beginNextEndlessSeasonIfStuck"):
    assert needle in engine, "Missing 24x24 quadrant logic: " + needle
assert "BerryDropGeometry.candidates(" in game
assert "side: session.engine.visibleSide" in game
assert "showEndlessMove()" in game
assert "BerryQuestBoardView" in (root / "BerryBlockBlast" / "BerryProgression.swift").read_text()
assert (root / "Tests" / "BerryEndlessGardenSectionsTests.swift").is_file()
print(f"PASS: Berry Berry Blast 0.5.9 Build 1, {len(names)} art catalogs, "
      "iOS16, four no-scroll 12x12 Endless patches, tests and app icon")
