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

## Scoring refinement
- Normal line-clear points now use the independently examined Android 10.8.1 Classic baseline: one line 10, two lines 20, three lines 60, four lines 120, plus placement points, combo multiplier and +300 full-board reward.
- We cannot assert the current iOS app uses these identical weights. Berry retains its own objectives and six modes.
- Automated tests cover two-line, three-line, and continuing combo scoring.

## Berry Classic and score celebration
- Added Berry Classic as a seventh mode in the home menu. All six prior modes remain.
- Berry Classic has its own 8x8 board snapshot, best-score key, three-piece tray, no timer and no Undo/Shuffle/Shop shortcuts.
- Berry Classic uses the corrected classic piece catalog and core scoring pipeline.
- The Classic score receives a large strawberry/pink/gold spotlight with a slow pulse, bright glow, best record and combo label.
- Any mode displays a brief original "NEW BERRY BEST!" banner after surpassing the score at the beginning of that run.
- The celebration runs at most once per run, is noninteractive and respects iOS Reduce Motion.
- Keep evaluating drag pickup, movement and release as the top release gate. Visual work does not mean touch reliability is verified.
