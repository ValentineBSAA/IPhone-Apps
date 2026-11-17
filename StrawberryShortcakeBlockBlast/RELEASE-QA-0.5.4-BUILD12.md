# Berry Block Blast v0.5.4 build 12 development QA

This patch addresses the issues photographed on an iPhone 16e in build 11.

## Code repairs
- Unified tap and drag gesture on a tray piece, with an 8-point movement threshold.
- Board frame and touch use matching global coordinates; the release is computed directly.
- Expanded Shop, Stats, Help, Settings, Cottage, Welcome, and other gameplay sheets.
- Expanded home sound settings; preserved regular scrolling.
- Daily, Story, Blitz, and Nightmare objective descriptions persist after a shuffle.
- Kept existing 8x8/12x12 engines, saves, rewards, tiles, and drag visuals.
- Incremented build to 12 while staying at 0.5.4.

## Artwork prerequisite
The two approved PNGs are not yet stored in GitHub. Apply the provided artwork patch:
- BerryBlockBlast/Assets.xcassets/AppIcon.appiconset/AppIcon.png
- BerryBlockBlast/Assets.xcassets/BerryMascot.imageset/BerryMascot.png

Codemagic intentionally blocks an IPA with missing or substituted artwork.
It also runs XCTest on an available iPhone simulator, before compiling an unsigned device IPA.

## Still requires physical testing
- Verify approved app icon and home mascot after installing.
- Drag 1x1, 2x2, L and 12x12 large pieces on empty, crowded and edge cells.
- Test fast diagonal release and invalid collisions; preview must match final placement.
- Tap piece then board; test sound and haptic feedback.
- Open every gameplay sheet and scroll to its bottom button.
- Test save/resume and Nightmare's separate game, with no progress regression.
