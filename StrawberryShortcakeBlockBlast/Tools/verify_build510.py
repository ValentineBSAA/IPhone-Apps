#!/usr/bin/env python3
"""Offline source and art checks for Berry Berry Blast 0.5.10 Build 2.

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
    'MARKETING_VERSION: "0.5.10"',
    'CURRENT_PROJECT_VERSION: "2"',
    'INFOPLIST_KEY_CFBundleShortVersionString: "0.5.10"',
    'INFOPLIST_KEY_CFBundleVersion: "2"',
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
    assert marker in economy, "Missing 0.5.10 economy rule: " + marker
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
assert "BOARD SURFACES · ORIGINAL + OPTIONAL" in (root / "BerryBlockBlast" / "BerryBoutiqueView.swift").read_text()
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

# Playtime is an additive offline journal, never a fabricated score or upload.
playtime = (root / "BerryBlockBlast" / "BerryPlaytimeTracker.swift").read_text()
app = (root / "BerryBlockBlast" / "BerryBlockBlastApp.swift").read_text()
for marker in ("berryberryblast.playtime.days.v059",
               "berryberryblast.playtime.lifetime.v059",
               "berryberryblast.playtime.modes.v059",
               "berryberryblast.playtime.modeDays.v059",
               "berryberryblast.playtime.sessions.v059",
               "secondsByDayAndMode", "modeSessions",
               "scenePhaseDidChange", "beginModeSegment", 'dateFormat = "h:mm a"'):
    assert marker in playtime, "Missing separate local playtime session tracking: " + marker
assert "playtime.scenePhaseDidChange" in app, "App foreground/background playtime wiring missing"
for marker in ("BerryPlaytimeTracker.shared.enterMode", "BerryPlaytimeTracker.shared.leaveMode",
               "setModePlaying(activePuzzle)", "updateModePlaytime()"):
    assert marker in game, "Mode playtime tracking missing: " + marker
for marker in ("Playtime & Sessions", "ForEach(BerryPlaytimeTracker.modeCatalog)",
               "playtime.recentSessions", "RECENT GAME SESSIONS"):
    assert marker in collection, "Missing Playtime leaderboard section: " + marker
assert (root / "Tests" / "BerryPlaytimeTrackerTests.swift").read_text().count("func test") >= 5

story_source = (root / "BerryBlockBlast" / "BerryStoryNarrative.swift").read_text()
story_tests = (root / "Tests" / "BerryStoryNarrativeTests.swift").read_text()
assert 'The Village in Full Bloom' in story_source, "Twelve-chapter Story progression missing"
assert 'Light the Lantern Orchard' in story_source, "Story chapter 7 missing or renamed"
assert story_tests.count("func test") >= 3, "Story narrative regression tests missing"
assert 'Chapter story conclusion' in game, "Story victory needs visible narrative text"
print(f"PASS: Berry Berry Blast 0.5.10 Build 2, {len(names)} art catalogs, "
      "iOS16, four no-scroll 12x12 Endless patches, tests and app icon")


# 0.5.10 regression gates: never replace authentic 0.5.8 board geometry.
tiles = (root / "BerryBlockBlast" / "BerryStyle.swift").read_text()
boutique = (root / "BerryBlockBlast" / "BerryBoutiqueView.swift").read_text()
daily = (root / "BerryBlockBlast" / "BerryDailyHarvestView.swift").read_text()
school = (root / "BerryBlockBlast" / "BerrySchoolView.swift").read_text()
home = (root / "BerryBlockBlast" / "BerryModes.swift").read_text()
ledger = (root / "BerryBlockBlast" / "BerryEconomyLedger.swift").read_text()
for marker in ('guard skin == "strawberry-fruit" else',
               'else if skin == "strawberry-fruit"'):
    assert marker in tiles, "Sculpted fruit incorrectly replaced original square blocks"
assert 'skin == "default" || skin == "strawberry-fruit"' not in tiles, (
    "Default skin must remain classic square candy blocks")
for marker in ('.fill(Color.white.opacity(0.96))',
               'Color(red: 0.64, green: 0.32, blue: 0.46).opacity(0.83)',
               'private let gap: CGFloat = 3',
               'boardSurface == "original"'):
    assert marker in game, "Original 0.5.8 empty board square changed: " + marker
for marker in ('surface-original', 'surface-cream', 'surface-glass',
               'surface-picnic', 'surface-garden', 'surface-seed',
               'RESTORE ORIGINAL BOARD ONLY'):
    assert marker in boutique, "Missing restored Boutique board option: " + marker
assert 'storyDialogueCard(compact: compact)' in game
assert '.offset(x: 34, y: 38)' not in game, "Story dialogue must not overlap the board"
for marker in ('BerryCandyToolbarButton', 'BerryStyle.timerGradient',
               'BerryStyle.urgentTimerGradient'):
    assert marker in ((root / "BerryBlockBlast" / "BerryGameView.swift").read_text()
                      + (root / "BerryBlockBlast" / "BerryBlitzHUD.swift").read_text()), (
        "Gameplay toolbar/timer polish missing: " + marker)
for marker in ('beginToday(', 'markLostToday(', 'saveActiveEngine(',
               'outcome(on date:', 'BerryDailyHistory.outcome()',
               'One attempt per day'):
    assert marker in (daily + game), "Daily one-attempt rule missing: " + marker
assert 'guard activeMode != .daily else { return }' in session, (
    "Daily Harvest still permits new-game retries")
assert 'BerryDailyHistory.activeEngine()' in session, "Daily resume save missing"
assert (root / "Tests" / "BerryDailyAttemptTests.swift").read_text().count("func test") >= 5
assert 'BerryGridNavigationTile' in home and 'BerryGridInfoTile' in collection
assert 'BerryEconomyLedger.shared.recordSpend' in session
assert 'LINE EARNINGS BY MODE' in collection
assert 'BerryCandyNumber' in school and 'practiceFilled' in school
print("PASS: 0.5.10 restored original squares, optional skins, one Daily attempt, "
      "economy ledger, premium icons, Story dialogue and learning cards")

# 0.5.10 Build 2: no change to selected block styles or placement grid.
appearance = (root / "BerryBlockBlast" / "BerryUIAssets.swift").read_text()
assert 'struct BerryBoardAppearanceControls: View' in appearance
assert 'Restore Original Board Only' in appearance
assert 'Restore All Appearance Defaults' in appearance
assert 'boardSurface = "original"' in appearance
assert 'borderSkin = "default"' in appearance
assert 'BerryBoardAppearanceControls()' in game
assert 'BerryBoardAppearanceControls()' in home
assert 'storyDialogueCard(compact: compact)' in game
assert 'showFullStory' in game
assert 'private let gap: CGFloat = 3' in game
assert 'layoutReserve' in game and 'mode == .story ? 426' in game
assert 'DRAG OR TAP TO PLACE' in game
assert 'private func toolSymbol(' in game
assert 'BerryWalletPill(berries: session.berries)' not in game, (
    "Full-size second wallet row returned, crowding the board")
print("PASS: build 2 original-board controls, Story layout, tool icons, "
      "compact counters and unchanged game grid")
