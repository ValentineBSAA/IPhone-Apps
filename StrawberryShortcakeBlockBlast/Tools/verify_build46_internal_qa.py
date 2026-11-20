#!/usr/bin/env python3
"""Build 4.6 source gate. Keep debug-only money away from releases."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
read = lambda path: (root / path).read_text()
project = read("project.yml")
identity = read("BerryBlockBlast/BerryBuildIdentity.swift")
settings = read("BerryBlockBlast/BerrySettingsHub.swift")
developer = read("BerryBlockBlast/BerryDeveloperGardenView.swift")
session = read("BerryBlockBlast/BerryGameSession.swift")
layout = read("BerryBlockBlast/BerryGameplayLayout.swift")
game = read("BerryBlockBlast/BerryGameView.swift")
night = read("BerryBlockBlast/BerryDayNightClock.swift")
rain = read("BerryBlockBlast/BerryStrawberryRain.swift")
assert 'MARKETING_VERSION: "0.5.16"' in project
assert 'CURRENT_PROJECT_VERSION: "46"' in project
assert 'B4.6 VISUAL LAB' in identity
assert "BERRY_INTERNAL_QA" in project
assert '.onLongPressGesture(minimumDuration: 1.8)' in settings
assert 'Developer_Mode_Strawberry_Lock' not in settings
assert 'qaWallet = "Test Strawberries"' in developer
assert 'TextField("Type amount, e.g. 1200"' in developer
assert 'Button("Review strawberry grant")' in developer
assert '.alert("Add test strawberries?"' in developer
assert 'static func grantQAStrawberries' in session
assert 'guard var inventory = existing else { return nil }' in session
assert 'amount <= Int.max - inventory.berries' in session
grant = session.split("static func grantQAStrawberries", 1)[1].split("    #endif", 1)[0]
assert 'recordSpend' not in grant and 'totalEarnedBerries +=' not in grant
assert 'boardWidthFraction: CGFloat = 0.92' in layout
assert 'comfortableWidth = width * boardWidthFraction' in layout
assert (root / "Tools/berry_build46_geometry_preflight.swift").is_file()
assert 'animateSuccessfulLanding' in game and 'BerryLandingVisual' in game
assert 'private let count = 44' in rain and 'session.drop' not in rain
assert 'hour < 6 || hour >= 18' in night
assert 'dateFormat = "h:mm a"' in night
assert (root / "Tests/BerryBuild46InternalQATests.swift").is_file()
assert (root / "Tests/BerryBuild46DayNightTests.swift").is_file()
print("PASS: 4.6 build, hidden typed QA grants, geometry, animation and Night Edition source.")
