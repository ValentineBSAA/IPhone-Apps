# Berry Block Blast 0.5.8 Build 1 | iOS 16 Codemagic test candidate

**Status:** Development candidate. Not device-verified or ready for stable publication.
**Branch:** feature/berry-058-build1-ios16
**Bundle ID:** com.valentinebsaa.berryblockblast (unchanged)
**Target:** iOS 16.0+
**Build:** 0.5.8 (1); Codemagic unsigned IPA
**Voice lines:** explicitly deferred to a later update; none added.

## Changes included in the source

1. Berry Blitz adds **1, 2, 5, and 10 minute** challenges with independent high-score keys. Stuck pieces automatically reroll if at least one square remains; a completely full board restarts without losing score, currency, moves or time. Only the countdown ending finishes Blitz.
2. Strawberry Nightmare gets an independent **three-minute** countdown while preserving its difficult 12x12 puzzle pieces. Running out of moves is still a legitimate defeat in Nightmare.
3. Tray cards display **actual square counts** calculated from each piece's points.
4. Music and sound effects stop when iOS delivers **willResignActive**, not seconds after didEnterBackground. Timed UI refresh rate reduced to 1 Hz; animations are reduced in Low Power Mode or with Reduce Motion.
5. The main-menu second Berry Boutique card is replaced with **My Strawberry Cottage**, keeping the small top-bar Boutique shortcut.
6. New persistent cottage layout with drag-to-place decorations, six original upgrades, garden background and home image. Previously purchased decorations and berry currency persist.
7. Five new Boutique skins: Raspberry Ruby, Lemon Glaze, Chocolate Truffle, Mint Frost and Blackberry Jam. The new fruit-shaped Strawberry Candy block art is also used. Existing Blueberry Velvet and Vanilla Cream remain unchanged.
8. Inventory offers strawberry-colored helper counts, purchased/equipped labels and price details for locked cosmetic options.
9. Home-page quotes are bold, strawberry-colored and automatically rotate without a manual refresh button.
10. Berry Collection personal records include the new 5- and 10-minute Blitz durations.
11. **16** original generated Xcode image catalogs imported from `BuildPayload/Berry-0.5.8-ArtCatalogs.zip`, with a strict import/PNG integrity gate.
12. All **51** original M4A music tracks and **16** WAV sound effects preserved byte-for-byte. No voice lines or new music in this build.

## Preservation rules

Keep `com.valentinebsaa.berryblockblast` and all 0.5.7 UserDefaults keys, saved games, ownership, skin selection, strawberries, lifetime-lines, Story progression, Daily Harvest history and personal bests unchanged. Use additional versioned keys only for new garden placements and new Blitz records. Do not overwrite old installed app data while testing without first backing it up.

## Release gates

- Codemagic should import the 16 image catalogs, run all Python source/audio checks and XcodeGen, compile Release iPhone device target, verify 67 audio files inside the packaged app/IPA, and publish the **unsigned** IPA artifact.
- Compile XCTest sources separately. Simulator test execution may be marked **NOT VERIFIED** when Codemagic simulator infrastructure hangs. This is *not* a pass; genuine test failures remain fatal.
- On an iOS16 iPhone 14 Pro, play Quick Jam until zero even after a stuck tray, then test 2-, 5- and 10-minute challenges. Confirm scores are separate and preserved.
- Test Nightmare's 3-minute countdown and its separate no-moves defeat.
- Lock the phone or background the app during both music and sound effects. Verify audio stops immediately, and resumes correctly on foreground when enabled.
- Test opening/closing game screens and scrolling under Low Power Mode; ensure no visible jitter or blocked touches.
- Place pieces with all six cosmetic skins; verify actual piece geometry, valid/invalid previews, hit-testing, and no invisible art.
- Purchase multiple cottage decorations using earned berries and drag them around the garden; force quit/restart and ensure placement positions survive.
- Test shop and collection navigation, locked-item prices, all four Blitz record categories, and automatic quote rotation.
- Verify old 0.5.7 currency, achievements, music settings and cosmetics are retained after upgrade.

**This build is not considered verified until native compilation and real-device tests pass.**
