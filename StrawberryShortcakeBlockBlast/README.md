# 🍓 Berry Block Blast for iPhone

**Version 0.5.5 • Build 1 • Native SwiftUI + UIKit touch input • Independent original game**

Berry Block Blast is a strawberry-themed 8×8 block-placement puzzle for iPhone. Its classic rules are inspired by Block Blast, but all Berry illustrations, user interface, original music and extra game modes are independent. The project is not affiliated with Hungry Studio or Strawberry Shortcake.

## How to play
Choose one of three blocks. Drag it toward the board and lift your finger to place it, or tap a piece and then tap the board. Pieces never rotate or fall. Complete a row or column to clear it, earn points and grow your combo. After all three blocks are placed, three new ones arrive. The game ends only when none of the remaining pieces can fit.

On a touch screen the aimed piece can float above your finger; the game accepts a legal direct-finger target as a fallback. A green preview means the position fits; red means it overlaps or is out of bounds.

## All seven game modes
- **Berry Classic:** Pure 8×8 three-piece endless run, no timer or power-ups, giant glowing record-chase score.
- **Sweet Endless:** High-score garden, 8×8, no timer.
- **Berry Story:** Chapter missions and rewards.
- **Daily Harvest:** Reproducible daily puzzle and daily rewards.
- **Cozy Cottage:** Smaller, more forgiving piece selection and cottage decorations.
- **Berry Blitz:** Timed 8×8 score challenge.
- **Strawberry Nightmare:** A separate 12×12 board with large, difficult pieces.

All existing modes preserve their saved-board keys; new Berry Classic receives its own. High scores are maintained separately, using the previous shared record as a safe starting value for new per-mode records.

## What's new in 0.5.5 build 1
- Replaced unreliable SwiftUI tray dragging with native UIKit touch tracking that continues past the tray.
- Made touch positions and board measurements use the same UIWindow coordinate system.
- Centralized preview, lifted-thumb placement, drop validation, and tap-to-place.
- Added common classic pieces, including 3×3 squares, 2×3 rectangles, corners and zigzags.
- Added Berry Classic as a featured home-screen option, plus a continuously glowing big score and a new-best celebration in every mode.
- Hardened malformed-piece handling, combo and line-clear tests.
- Adjusted base multi-line scoring toward an independently examined Android Classic baseline; the current iOS app's exact proprietary scoring is not claimed.
- Retained the approved custom app icon, Berry mascot, UI, music, saves, shop, Undo and Shuffle.
- Added optional **Touch diagnostics (testing)** in Berry Settings, disabled by default.

## iPhone builds
The `codemagic.yaml` workflow is the primary manual unsigned-IPA builder. A separate optional GitHub Actions workflow can compile an unsigned IPA for physical iPhone installation. **Build artifact: `Berry-Block-Blast-v0.5.5-build1-unsigned.ipa`.** Sign it with your existing iPhone signing method before installing.

This build is **development/testing** until reliable dragging has been confirmed on the physical iPhone 16e. See `RELEASE-QA-0.5.5-BUILD1.md` for the complete checklist.

## Earlier versions
0.5.4 introduced 12×12 Nightmare and layout improvements. Earlier 0.3.x builds introduced the Strawberry Village menu, Story and Daily modes, sound, effects, and economy. Previous saved progress is not intentionally reset.
