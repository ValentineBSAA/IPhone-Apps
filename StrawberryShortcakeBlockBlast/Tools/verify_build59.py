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
    "GoldenStrawberry",
    "BerryCharacterPortrait", "BerryCharacterStanding",
    "BerryCharacterCelebrate",
    "BerryBoardCreamCell", "BerryBoardCandyGlassCell", "BerryBoardPicnicCell",
    "BerryBoardGardenCell", "BerryBoardSeedMosaicCell",
    "BerryFruitStrawberry", "BerryFruitBlueberry", "BerryFruitRaspberry",
    "BerryFruitLemon", "BerryFruitMint", "BerryMascotCenteredCircle",
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
icon_data = icon.read_bytes()
assert icon_data[:8] == bytes([137, 80, 78, 71, 13, 10, 26, 10])
assert (int.from_bytes(icon_data[16:20], "big"),
        int.from_bytes(icon_data[20:24], "big")) == (1024, 1024)
assert icon_data[25] == 2, "AppIcon must use opaque RGB PNG data"
for art in ("BerryMascotCenteredCircle", "BerryBoardCreamCell",
            "BerryFruitStrawberry", "BerryFruitBlueberry"):
    # Paletted PNGs retain transparency in the tRNS chunk.
    raw = (assets / (art + ".imageset") / (art + ".png")).read_bytes()
    assert b"tRNS" in raw, art + " lost its transparent edges"
assert 'BerryBoardCreamCell' in game and 'BerryBoardCandyGlassCell' in game
tileSource = (root / "BerryBlockBlast" / "BerryStyle.swift").read_text()
for art in ("BerryFruitStrawberry", "BerryFruitBlueberry",
            "BerryFruitRaspberry", "BerryFruitLemon", "BerryFruitMint"):
    assert art in tileSource, "Fruit asset not connected: " + art
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
assert (root / "Tests" / "BerryGoldenStrawberryTests.swift").is_file()
assert 'clearBoardWithGoldenStrawberry' in engine
assert (root / "Tests" / "BerryGoldenStrawberryTests.swift").read_text().count("func test") >= 5
economy = (root / "BerryBlockBlast" / "BerryEconomy.swift").read_text()
for marker in ("undoPrice = 40", "shufflePrice = 50", "hintPrice = 35",
               "[60, 90, 130, 180, 240, 300]", "nextCottagePrice(owned:"):
    assert marker in economy, "Missing 0.5.9 economy rule: " + marker
assert (root / "Tests" / "BerryEconomyTests.swift").read_text().count("func test") >= 4

# The user's approved Boutique navigation must stay consistent everywhere.
collection = (root / "BerryBlockBlast" / "BerryCollectionView.swift").read_text()
village = (root / "BerryBlockBlast" / "BerryProgression.swift").read_text()
home = (root / "BerryBlockBlast" / "BerryModes.swift").read_text()
jukebox = (root / "BerryBlockBlast" / "BerryJukeboxView.swift").read_text()
ui_assets = (root / "BerryBlockBlast" / "BerryUIAssets.swift").read_text()
score_views = [(root / "BerryBlockBlast" / name).read_text()
               for name in ("BerryScoreSpotlight.swift", "BerryBlitzHUD.swift")]
for name, contents in (("Collection", collection), ("Village/Journal/Quests", village),
                       ("Home", home), ("Jukebox", jukebox)):
    assert "LazyVGrid(columns:" in contents, name + " lost Boutique-style navigation"
assert "Picker(\"Collection sections\"" not in collection, "Collection reverted to segmented list"
assert "BerryGridNavigationTile" in ui_assets and "BerryGridInfoTile" in ui_assets
for screen, markers in ((collection, ("Personal Records", "LazyVGrid", "BerryGridInfoTile")),
                        (village, ("Berry Quest Board", "Strawberry Village", "Berry Journal")),
                        (home, ("More Adventures", "Garden Size", "Berry Blitz Challenges"))):
    for marker in markers:
        assert marker in screen, "Missing grid/menu content: " + marker
for surface in ("surface-cream", "surface-glass", "surface-picnic",
                "surface-garden", "surface-seed"):
    assert surface in (root / "BerryBlockBlast" / "BerryBoutiqueView.swift").read_text(), (
        "Board must be selectable in Frames & Sparkles: " + surface)
assert "ILLUSTRATED BOARD SURFACES" in (root / "BerryBlockBlast" / "BerryBoutiqueView.swift").read_text()
for code in (game, ui_assets, *score_views):
    assert "BerryCandyNumber" in code or "candyNumberGradient" in code, (
        "Numeric game results lost candy-gradient rendering")
assert "BerryCandyResultCounter" in game
print("PASS: Boutique-style card grids, five equip-ready board backgrounds, "
      "gradient Score/Best/Lines/Moves/Combo and personal records")

session = (root / "BerryBlockBlast" / "BerryGameSession.swift").read_text()
shop = (root / "BerryBlockBlast" / "BerryBoutiqueView.swift").read_text()
for source, needle in ((session, 'useGoldenStrawberry()'),
                       (session, 'nonisolated static let goldenStrawberryCost = 250'),
                       (session, 'buyAndUseGoldenStrawberry()'),
                       (session, 'buyAndContinueWithShuffle()'),
                       (session, 'canContinueWithShuffle'),
                       (session, 'canContinueWithGoldenStrawberry'),
                       (engine, 'goldenRescueUsed'),
                       (engine, 'canRescueWithGoldenStrawberry'),
                       (engine, 'var candidate = self'),
                       (shop, 'Golden Strawberry'),
                       (game, 'CONTINUE WITH SHUFFLE'),
                       (game, 'GOLDEN STRAWBERRY'),
                       (game, 'continueRescueOptions'),
                       (game, 'dismissRescueAfterSuccess')):
    assert needle in source, "Game Over Continue integration missing: " + needle
rescue_tests = (root / "Tests" / "BerryContinueRescueTests.swift").read_text()
assert rescue_tests.count("func test") >= 5, "Missing Shuffle/Golden Continue regression coverage"
assert "Continue with Shuffle" in session, "Shuffle game-over message missing"
assert "BerryEconomy.shufflePrice" in session, "Shuffle pricing is inconsistent"
print(f"PASS: Berry Berry Blast 0.5.9 Build 1, {len(names)} art catalogs, "
      "iOS16, four no-scroll 12x12 Endless patches, tests and app icon")
