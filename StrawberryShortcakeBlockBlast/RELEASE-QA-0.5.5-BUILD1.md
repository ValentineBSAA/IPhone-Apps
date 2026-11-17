# Berry Block Blast 0.5.5 build 1: foundational game repair

## Scope
Rebuild the touch handling and bring basic 8x8 block gameplay closer to Hungry Studio's published rules. This is an independent Berry implementation, not copied original code or a claim that unpublished scoring weights match exactly.

## Preserved
All modes: Sweet Endless, Berry Story, Daily Harvest, Cozy Cottage, Berry Blitz and 12x12 Strawberry Nightmare. Original artwork, sounds, shop, currency, undo, shuffle, and all previous saved-game keys are retained.

## Changes
- Native UIView touch lifecycle captures start, movement, release and cancellation even when the finger exits its tray box.
- Board geometry and finger both measured in UIWindow coordinates.
- Lifted block targeting for thumbs, with direct finger placement fallback.
- Preview and release use identical coordinates; tap then tap shares target math.
- Classic catalog gains 3x3, 2x3, 3x2, corners and zigzag shapes; old saved trays unchanged.
- Empty/duplicate-coordinate pieces rejected.
- Distinct best scores per mode; legacy shared best seeded to avoid losing recorded highs.
- Optional touch diagnostics in Settings (disabled by default).
- Version 0.5.5 build 1 and both Mac IPA workflows updated.

## QA required
Run xcodebuild simulator XCTest and verify unsigned IPA compilation; physical iPhone testing remains mandatory. Test actual drag across tray, hovering above your thumb, release when finger is below the board, screen edges and diagonal releases. Confirm piece disappears, score increments, preview matches release, invalid overlaps stay put, and tray refills after all three pieces. Test all six modes, saves, best scores, row/column intersection, streak break at three non-clears, undo, shuffle, music and scrolling sheets.

The test build is NOT stable until the iPhone 16e proves dragging actually works.
