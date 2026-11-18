# Berry Berry Blast: display contract and release gates

**Status:** 0.5.12 Build 3 is a *candidate only*. A green compilation is not a release. Do not tag, publish, or recommend an IPA as a verified release before all gates below pass.

## Research-backed display contract

The **iPhone 14 Pro** and **standard iPhone 16** both have **1179 x 2556 physical pixels**, corresponding to **393 x 852 logical points** at 3x scale. Do **not** multiply SwiftUI sizes by 3 or assume an app's safe-area content height is 852 points.

References (Apple):
- [iPhone 14 Pro official specs](https://support.apple.com/en-us/111849)
- [iPhone 16 official specs](https://support.apple.com/en-us/121029)
- [SwiftUI GeometryProxy](https://developer.apple.com/documentation/swiftui/geometryproxy)
- [Apple UI safe areas](https://developer.apple.com/documentation/UIKit/positioning-content-relative-to-the-safe-area)
- [Apple HIG: layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Apple: game touch/fullscreen/controls](https://developer.apple.com/videos/play/wwdc2026/358/)
- [Apple: recording XCTests with screenshots](https://developer.apple.com/documentation/xcuiautomation/xcuiscreenshot)

### Architecture

- Measure the **actual SwiftUI container** with `GeometryReader`; UIKit exposes the actual safe area via `safeAreaLayoutGuide`/`safeAreaInsets`. Never treat physical screen pixels as points. Do not subtract an already-applied safe-area inset a second time.
- Reserve space for actual HUD, timer, three-piece tray, tool buttons, and Home indicator clearance. **The puzzle board receives the remaining space**, subject to a square aspect ratio. Content should fit without scrolling during play.
- The board now has **one 3pt touch rim**. `BerryGameplayLayout.boardTouchMargin` is shared with `BerryDropGeometry`. Every drawn cell center must map back to the corresponding hit-tested engine row/column, including bottom-right (8x8 and 12x12).
- The three tray cards have deterministic width `(available - 16pt) / 3` and their shapes are **measured within the individual card**, never against the entire device. Each live piece must be colored and visible after refill, Undo, movement and drop; already-used slots show a checkmark.
- Mystery Garden removes target assistance **only**. The selected/draggable shape must always be rendered while in hand.
- Approved block skins stay. Rejected board-surface mockups and decorative frames are excluded from active play and shops; existing purchases, scores and settings keys are preserved for migration.
- Nightmare/Blitz timer digits derive from a monotonic *deadline-based* model rather than subtracting one for each UI refresh. Phone lock pauses the deadline, unlock restores it **exactly once**, and any interrupted touch is cancelled without mutating the tray.
- The Daily Harvest Almanac is fully strawberry-themed without altering existing streak, day, reward or replay eligibility values.

### Gate 1: source and packaging

- All Swift source passes Swift 5 parse and native iOS 16 compile.
- No deleted user preferences or saved entitlements.
- GitHub contains all approved art source files; PNG checksum manifest passes; 51 music and 16 sound effects are present.
- Exactly correct CFBundleIdentifier, marketing version, build number, iOS deployment target.
- All signed/unsigned IPA zip entries pass integrity checks and contain a real iPhone ARM application.
- **Unsigned IPA is for sideload signing/testing and is not an App Store release.**

### Gate 2: automated behavior and geometry

All XCTest tests must be green on an actual iPhone Simulator, **not just `swiftc -frontend -parse`**:
- 200 seeded initial deals and placements; untouched two tray slots preserved.
- 36+ piece shape/color combinations; every available slot has visible pixels across widths 320/375/393/430 and compact/normal tray heights.
- Entire interactive game screen, not only isolated components, measures the board, HUD, three tap targets and their nonoverlap across **all seven modes** and both 393pt target profiles. Attach full-screen test screenshots.
- Complete 8x8 and 12x12 cell-center touch coordinate mapping for top-left, bottom-right and every in-between square at all test widths.
- Nightmare/Blitz deadline, pause/resume, one-shot rewards, time-up, phone lock/unlock with short/long time away and resume without timer or board reset.
- Daily Harvest saved history, single-attempt-per-day rules and full Almanac screenshot.
- Trophy Garden thresholds and permanent unlock migration with existing saved data.

### Gate 3: real device acceptance

Check *both* phones with hardware builds, not only simulation:
1. Play Berry Classic for 15 minutes: refill, drag, tap-to-place and used-slot checkmarks. All three live shapes remain visible and cannot protrude outside their own cards.
2. Play 12x12 Nightmare and Blitz: slow/fast drag, Mystery/Sweet/Outline assist settings, full countdown, precise bottom-right board taps.
3. In Nightmare, lock iPhone mid-drag at 2:xx, unlock after >30 seconds; touch controls and countdown resume and only actual playtime is counted.
4. Rotate/interrupt with notification shade, home swipe, app switching and phone calls where practical. No phantom blocks, stuck paused state or double reward.
5. Daily Harvest previous win/loss dates and streaks remain accurate and the **Almanac**, not a checkbox calendar, renders correctly.
6. Confirm all active navigation/submenus use grids, and rejected board frames/surfaces are gone.
7. Compare iPhone 14 Pro and iPhone 16 screenshots for aligned board, content margins, no clipped controls and no gratuitous blank space.

If any gate fails, keep Build 2 as a fallback, label Build 3 **unverified**, attach logs/screenshots and fix before publishing. Never say an uninspected UI build is visually approved.
