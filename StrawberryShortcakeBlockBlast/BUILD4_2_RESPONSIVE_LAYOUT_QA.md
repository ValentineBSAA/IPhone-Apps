# Berry Berry Blast • Build 4.2 responsive screen / Blossom Glass correction

Status: **DRAFT QA CANDIDATE, NOT A RELEASE**. User has stopped physical
testing until the two blocking visual defects are corrected and CI passes.

## Source and identity
- Branch: feature/berry-build4-r3-responsive-layout
- Based on *successful* Build 4.1 internal build 41.
- New Info.plist: 0.5.14, CFBundleVersion 42; Home **B4.2 LAYOUT**.
- Previous Build 4.1, Build 4 and hardware-tested Build 3 unchanged.

## Why Build 4.1 failed visual inspection
1. Full-size transparent-center Blossom Glass floral image was applied as an
   **overlay** after the touch tracking frame. Floral corners were not
   transparent: they obscured legal 8x8 cells along the board edges.
2. Main board budget was sized as though Endless had a 17pt title, even
   after the title became 32pt, and did not count the optional touch-status
   line. Fixed-size screen fractions left no deliberate breathing room.

## Build 4.2 corrections
- Completely remove floral PNG overlay from **gameplay**.
- Keep Blossom Glass opt-in and visually distinct through Tile_Empty and
  seven-point premium-gradient exterior rim (BerryBlossomEdgeFrame). Only
  the outside eight-point decoration is painted. All 64 cells, including
  corner cells, remain unobscured. The old illustration is retained in the
  asset catalog for possible use as an *in-menu* preview, not on gameplay.
- Use one screen-size budget in BerryGameplayLayout, based on logical points,
  actual safe-area GeometryReader content size, real 32pt Endless title,
  Story rows, Daily card, timed HUD, 24x24 sector navigation, the three
  tray pieces, tools, counters and optional diagnostics.
- Cap the playable board to roughly 87% of available width, or smaller
  when the mode has a taller HUD. Preserve identical square cells, the same
  3pt input track gutter, and exact placement geometry.
- On 390pt iPhone 16e and 393pt iPhone 14 Pro widths, ordinary Endless
  targets about 339pt / 342pt. Real screen geometry, not device-name
  checks, determines placement; shorter modes adapt further.
- Remove duplicate Sweet Endless sizing/season subtitle from top brand row.
  The large label above the game remains authoritative.
- Preserve dynamic top/bottom spacers for extra space; avoid fixed y-offsets,
  hard-coded model IDs, or painting ornament over touch targets.
- Keep 24x24 as the *existing* four 12x12 visible sectors; do not
  pretend to display 576 cells simultaneously on a 6.1-inch phone.

## QA gates
- [ ] Version preflight, iOS 16, audio, 9 imported icons and static
      border-exclusion check pass.
- [ ] Deterministic engine regression unchanged.
- [ ] Responsive size tests for all 7 modes, 390x751 and 393x759 safe
      content sizes, compact 320x650 and large 430x835 pass.
- [ ] Actual iPhone 14 Pro + iPhone 16 simulator geometry and screenshots
      pass. The iPhone 16 simulator is not a 16e, so the 16e physical
      test remains essential.
- [ ] Device-target IPA compilation, version 0.5.14 (42) and audio checks pass.
- [ ] iPhone 16e, original then Blossom Glass, eight-by-eight corner and
      edge readability/tapping; verify all painted cells remain visible.
- [ ] Recheck 12x12 board and 24x24 mode's 12x12 sectors, Story extra HUD,
      timed Blitz/Nightmare and Cozy/Daily control access and tray.
- [ ] Check portrait safe area: notch/Dynamic Island, toolbar and bottom
      gesture region do not overlap; text and notifications flow around HUD.
- [ ] Existing saved Endless run, score, wallet, lines, tools, art, music,
      haptics and tactile placement are unchanged.
- [ ] iPhone 14 Pro physical regression separately signed off.
- [ ] Never merge draft PR without real-device visual acceptance.

## Evidence / references
Apple iPhone 16e: 1170x2532 physical pixels, 6.1-inch OLED.
Apple iPhone 14 Pro: 1179x2556 physical pixels, 6.1-inch OLED.
Both screens use **logical UIKit points**, not those physical pixel values
directly, for SwiftUI geometry. Let the operating system report safe area.
Apple API references: GeometryReader, ViewThatFits, layoutPriority and
safeAreaInset. Avoid using approximate screenshots to hardcode coordinates.

No game-engine, score, placement logic, saves, item prices, shop data,
currency ledger, music assets or other gameplay changes in this patch.
