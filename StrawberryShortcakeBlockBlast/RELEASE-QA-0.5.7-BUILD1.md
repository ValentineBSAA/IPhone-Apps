# Berry Block Blast 0.5.7 Build 1 | iOS 16 test candidate

**Bundle identifier:** `com.valentinebsaa.berryblockblast` (UNCHANGED)  
**Target:** iOS 16.0 or later  
**Release state:** Development build, **NOT device-verified**  
**Version:** MARKETING_VERSION 0.5.7 / CURRENT_PROJECT_VERSION 1

## Included fixes and features

- **Reliable placement:** A single deterministic lifted drag anchor for the entire interaction, shared by preview and release. Never move the piece to a different available location on release. Valid cells show green, invalid footprint red; colliding filled cells temporarily recede and return to normal as the finger moves. Wrong-sized piece shapes are never resized by the engine; all points are exact grid coordinates.
- **Pickup feedback:** Begin raised piece feedback on touch-down, with a floating ghost under touch tracking, including 8×8, 12×12, and scrollable 24×24. Physical device testing needed.
- **Fairer trays:** Avoid duplicate shapes/tints in each freshly dealt hand where distinct catalog choices exist; preserve difficult game modes and genuine dead ends in Classic.
- **Rescue behavior:** Shuffle gives a valid new move if a free cell remains and is not consumed on a completely solid board. Undo is available after a failed final placement if a previous move exists; restarting does not mint extra free helpers.
- **Game Over:** Explicit "No More Moves!" and explanation; score, lines, moves, and Story objective status; rescue with Shuffle when possible. Old "Berry Patch Is Full" message removed.
- **Story:** Complete "Strawberry Blocks Unlocked!" text uses line wrapping, and original milestone reward remains.
- **Visuals:** 10 new game mode/menu icons, 12 Berry Collection badge icons, seven earlier gameplay icons, plus Berry Hint and Jukebox icons (31 named assets total). Distinct glossy default/Blueberry/Vanilla block effects, a clearer equipped state, strawberry-clear particle overlay, four mild Sweet Endless seasons.
- **Boutique:** Dedicated home top-bar store access and main menu store card, shared persistent wallet, improved scrolling via LazyVStack and a single page-level ScrollView, buttons and helper counts, previews, and sensible text wrapping.
- **Berry Collection:** Separate Collection, Inventory, Awards, and personal best-record leaderboard tabs. No invented internet ranking; no network required. Equipped ownership is kept in the original saved keys.
- **Garden Helpers:** Undo and Shuffle in play; Berry Hint purchased for 20 earned strawberries and shown for three seconds, never auto-placed. Classic and Blitz have no gameplay helpers. Inventory quantities saved in a backward-compatible extension of `berryblockblast.inventory.v3`.
- **Daily Harvest:** Explicit local calendar, today’s date, streak, complete day history, reset time and 120-point challenge; older `berryblockblast.daily.completed` value is read without deletion.
- **Copy:** Strawberry School now describes Bazaar/Boutique, Inventory, helpers and daily progression accurately; clickable original strawberry-themed quote rotation replaces ads/offline slogan.

## No-data-loss constraints

Do not change the signed bundle ID. Preserve exact 51 original M4As and 16 original WAVs, the approved app icon and mascot, and the prior saved engine keys, score keys, cosmetic ownership/equipment keys and lifetime-lines value. Daily completion history expands from old single-date key, without overwriting it.

## QA status and mandatory release gates

**Passed in this environment:** Swift parser over all app/test source files; iOS 16 source checks; 31 asset-catalog/PNG checks; byte-for-byte source verification of all 51 original music and 16 sound-effect files; debug and optimized native Swift engine smoke test for 8×8/12×12/24×24 including unique shapes, hints, rescue/solid-board rejection and Codable roundtrip.

**NOT YET DONE:** No macOS Xcode compiler, Apple simulator, code signing credentials or physical iPhone access in this runtime. An unsigned IPA was **NOT** produced here. A native build and the full XCTest suite must pass before packaging a candidate IPA in GitHub Actions/Codemagic. An iOS 16 iPhone 14 Pro real-device pass is essential before calling it stable.

### iPhone 14 Pro acceptance tests

1. Overinstall signed candidate with **same bundle ID**. Verify original saved currency, purchases, high scores, Endless 8/12/24 saves and Story chapters unchanged. Backup first.
2. Touch a tray L shape and hold without moving, then drag with finger lifting above the board. Make legal and illegal drops near edges and over occupied blocks; it must never change shape or move to an unrelated legal cell. Confirm blocked cells dim/red-X, then instantly return normal on finger move.
3. Test tap-to-place across all 8×8 modes; stress 12×12 and 24×24 panning with SwiftUI scrolling. Check 24×24 performance.
4. Fill Story board until no move. Confirm score/line/move panel, unambiguous No More Moves wording, optional Shuffle rescue, and correct Story goal progress.
5. Reproduce Strawberry Blocks unlock at 10 lifetime lines; ensure no clipping in both large and small text modes.
6. Buy Blueberry Velvet and Vanilla Cream, Equip/Unequip in Boutique and Inventory, verify both tray and board visually. Preview Rose/Mint border, Berry Sparkle, owned Cottage decorations.
7. Verify Berry Hint purchase is 20 berries, one hint only consumed on a valid suggestion, three-second outline, and unavailable in Berry Classic/Blitz. Restart must not mint helpers.
8. Test home Bazaar/Boutique scroll all the way through, readable descriptions, large berry wallet K/M/B/T, and all 31 local icons.
9. Complete Daily Harvest, check exact date, reset countdown, calendar history, streak, and only one reward per day. Test relaunch, timezone change behavior, and local midnight if practical.
10. Sweet Endless season changes, score persistence, mode separation; 51 music tracks, 16 effects, timers/Blitz 60s/120s and silent-mode behavior.
11. Test Game Over, Story popup, modal closing, stats and settings with VoiceOver / large fonts / screenshot inactive/active, including cracked-screen low-contrast areas.

**If any test fails, keep installed 0.5.6 as the rollback and do not announce 0.5.7 as stable.**
