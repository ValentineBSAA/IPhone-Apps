# Berry Berry Blast: real iPhone layout and release gates

**Scope:** 0.5.12 Build 3. **Status:** candidate development only until all simulator gates pass, then BOTH real phones are tested.

## Verified platform guidance

- Apple SwiftUI GeometryReader reports the dimensions of its own parent-proposed space, **not a universal screen size**: https://developer.apple.com/documentation/swiftui/geometryreader
- GeometryProxy exposes both `size` and `safeAreaInsets`: https://developer.apple.com/documentation/swiftui/geometryproxy/
- Apple advises respecting *actual* safe areas, not guessing fixed padding around the Dynamic Island or home indicator: https://developer.apple.com/design/human-interface-guidelines/layout
- Dynamic layouts should measure and place views, not rely on fixed model-based offsets: https://developer.apple.com/documentation/swiftui/layout
- XCTest supports full-screen screenshot attachments and recorded results: https://developer.apple.com/documentation/xcuiautomation/xcuiscreenshot
- Xcode recommends unit + integration + UI testing, and running complete test suites before integration: https://developer.apple.com/documentation/xcode/testing

## What we learned from the iPhone 14 Pro screenshots

1. Increasing the board width without reserving the tray height let piece sprites escape their cards.
2. A tray shape could be tappable but visually offscreen. **Touch presence is not visual proof.**
3. Mystery Garden incorrectly hid a carried piece when both the floating sprite and placement ghost were suppressed.
4. Extra frame decoration reduced perceived board size and conflicted with the playable grid.
5. SwiftUI scenePhase may lag UIKit app activation after unlocking; timed modes need idempotent pause/resume and the original deadline must shift by locked duration.
6. An IPA containing artwork does not mean every asset is wired into a visible control.

## Automated release-candidate gate (runs independently on BOTH models)

Device models: **iPhone 14 Pro** and **iPhone 16**, using exact simulator device types. Both have a 393×852-point logical portrait display under their nominal 3× configuration; safe areas must be read from the *actual simulator window*, not copied from a constant.

- `BerryPhysicalScreenGeometryTests` creates an actual UIWindow attached to its UIWindowScene and records UIScreen bounds, scale, safeAreaInsets, the board CGRect and three tray CGRects. It attaches an image and JSON for Classic and Nightmare.
- The board must be square, within the window safe area, at least **92%** of the usable width, and must not overlap the tray.
- All 3 tray rectangles must be separate, fully visible, at least 85 points wide / 50 points tall, and approximately equal width.
- Piece-pixel tests must exercise long horizontal, vertical, zigzag and square shapes across 6 colors. No zero-pixel tappable piece.
- Board touch-mapping tests must prove every 8×8 and 12×12 cell maps accurately to placement coordinates.
- Nightmare tests must enforce continuous real-time digits, idempotent background pause/resume, input availability on unlock, no reset, and no duplicate credits.
- Daily Harvest tests must preserve saved wins and one-attempt-per-day behavior; Trophy Garden tests must preserve permanent rewards.
- CI **must fail** if a target simulator is unavailable. It may NOT silently substitute another iPhone.
- CI **must fail** if either model's suite fails or full-screen screenshot attachments are missing.
- Only if both model gates pass can an **unsigned QA candidate** be packaged. It must never auto-publish to a GitHub Release.

## Actual hardware signoff (not automatable with GitHub-hosted simulators)

On **both** the iPhone 14 Pro (iOS 16+) and iPhone 16:

1. Open Classic, Story, Daily Harvest, and Nightmare. Verify visible board/tray/icons throughout.
2. Place, refill, undo, shuffle, rotate as available. Drag near corners and each edge and verify exact placement.
3. Change Mystery / Outline / Sweet Assist; the carried block never disappears even if the target preview is hidden.
4. Lock Nightmare for 2 seconds, 30 seconds, then longer than the remaining timer and unlock. Verify timer is preserved, all pieces are still visible, the board immediately accepts touches, and progress is not reset.
5. Verify Calendar, Trophy Garden, previous Berry wallet, and existing unlocked Strawberry Red all persist after restarting the app.
6. Take two full-screen screenshots per device. Record OS version and whether every check passed.

**Stop-ship:** any invisible piece, board/tray overlap, wrong placement, stuck timed gameplay, lost progress, or incorrect unlock. Do not label the build “finished” just because Swift compiles, the IPA opens, or unit tests are green.

## Branch / artifact policy

Keep the last stable rollback. Use version **0.5.12 Build 3 QA Candidate** until the hardware signoff above. Public releases require the exact source commit, QA screenshots + geometry JSON, clean unit/integration tests, and real-device acceptance. No automated publishing is enabled.
