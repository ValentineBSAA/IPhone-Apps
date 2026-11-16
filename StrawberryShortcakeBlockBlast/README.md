# 🍓 Berry Block Blast for iPhone

**Version 0.3.0 • Native SwiftUI • iPhone • Original fan concept**

An independent, strawberry-themed endless 8×8 block puzzle. Not affiliated with Strawberry Shortcake or Block Blast. No official art, logos, or audio copied.

## Play
Drag a piece to the board, or tap a piece then a cell. Fill rows or columns to clear them. New pieces arrive after all three have been used. Keep playing until no placement remains. Clearing lines builds combos and earns strawberries. Earned strawberries buy undo and shuffle helpers. No advertisements or in-app purchases.

## Version 0.3.0
- True edge-to-edge launch screen configuration (fixes black letterboxing on modern iPhones)
- Responsive, safe-area-aware layout with visible board and piece tray
- Native full-screen pastel garden with original character illustration
- Undo and shuffle tools, berry currency and in-game basket
- Auto-save with migration from v0.2.0, achievements/stat scrapbook
- First-launch tutorial, combo display, haptics and sound toggles
- Endless puzzle rules, line-clear bonuses, game-over handling

## Build
The GitHub Actions workflow generates the Xcode project with XcodeGen and packages `Berry-Block-Blast-v0.3.0-unsigned.ipa`. Unsigned IPAs require signing before installation. Test on real iPhones for touch behavior and safe-area layout.
