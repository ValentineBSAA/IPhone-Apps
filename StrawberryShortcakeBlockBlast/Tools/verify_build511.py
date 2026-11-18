#!/usr/bin/env python3
"""Berry Berry Blast 0.5.11 source-only non-regression checks.

Seasonal images are bundled into the unsigned IPA packaging layer. Never
alter the original gameplay, audio or board-collision formats to display art.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(name):
    return (root/"BerryBlockBlast"/name).read_text(encoding="utf-8")
project=(root/"project.yml").read_text()
game=read("BerryGameView.swift")
home=read("BerryModes.swift")
shop=read("BerryBoutiqueView.swift")
settings=read("BerrySettingsHub.swift")
studio=read("BerryBoardStudio.swift")
ui=read("BerryUIAssets.swift")
session=read("BerryGameSession.swift")
for need in ['MARKETING_VERSION: "0.5.11"',
             'CURRENT_PROJECT_VERSION: "1"',
             'iOS: "16.0"',
             'PRODUCT_BUNDLE_IDENTIFIER: com.valentinebsaa.berryblockblast']:
    assert need in project, "Version or bundle change: "+need
assert 'v0.5.11 • 1' in home
assert 'private let gap: CGFloat = 3' in game, "Original board geometry changed"
assert '.fill(Color.white.opacity(0.96))' in game, "Restored default empty squares changed"
assert 'BerryDropGeometry.target(' in game, "Original tap geometry missing"
assert 'BerryDecorativeBoardFrame(boardSize: size)' in game
assert '.allowsHitTesting(false)' in studio, "Decorative frame must not capture taps"
assert 'berryberryblast.frame.overlay.v0511' in studio
assert 'berryblockblast.shop.equippedBlockSkin.v056b2' in settings
for name in ('BBBFrameChristmas','BBBFrameBirthday','BBBFrameSpring',
             'BBBFrameMidnight','BBBFramePicnic'):
    assert name in studio, "Approved frame catalog missing: "+name
for name in ('BBBIconHome','BBBIconPause','BBBIconSettings',
             'BBBIconHelp','BBBIconShop'):
    assert name in ui, "Approved control icon mapping missing: "+name
for need in ('case boardStudio, blocks, sparkleStudio, seasonal, helpers',
             'case .boardStudio:', 'case .seasonal:',
             'case .restore:', 'LazyVGrid', 'BoardSubmenu'):
    assert need in shop, "Grid Boutique regression: "+need
assert 'BerrySettingsHubView()' in home
assert 'BerrySettingsHubView(onRestart:' in game
for need in ('case gameplay, appearance, audio, celebration, accessibility, restore',
             'LazyVGrid', 'birthday.month.v0511', 'birthday.day.v0511',
             'berryblockblast.musicVolume','berryblockblast.shop.equippedBorder'):
    assert need in settings, "Nested Settings grid regression: "+need
assert 'BerryDailyHistory.beginToday()' in session
assert 'BerryDailyHistory.markLostToday()' in game
assert 'showFullStory' in game
assert 'private func boardInteraction(actualSize:' in game
assert 'BerryEconomyLedger.shared.recordSpend' in session
assert 'BerryGridInfoTile(title: "Best Score"' in game
assert 'BerryGridInfoTile(title: "Drag or Tap"' in game
assert 'BerryGridInfoTile(' in home or 'BerryGridNavigationTile(' in home
print("PASS: 0.5.11 source, grid menus, independent cosmetic layers, safe saves and iOS16 pins")
