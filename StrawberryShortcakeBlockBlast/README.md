# 🍓 Berry Block Blast for iPhone

**v0.2.0 source release • native SwiftUI • iOS 17+**

Unofficial strawberry-themed fan puzzle. Not affiliated with Strawberry Shortcake or Block Blast. Uses original artwork and code.

## What's new in 0.2.0
- Full-screen portrait layout, much smaller header and a tray that fits onscreen on compact iPhones.
- Endless 8×8 block puzzle: place three pieces, receive three more, continue until no remaining piece fits.
- Draggable placement with red/green validity preview; tap piece and then board as an alternate input.
- Newly generated trays include at least one playable shape; unavailable pieces appear faded.
- Scoring: 1 per tile, 10 × (lines cleared)² × combo multiplier, up to ×8; +300 on full board clear.
- Combos continue through two non-clearing placements and expire after three.
- Total line count, move count, best score, end-of-game summary, restart confirmation, haptics and sound toggles.
- Autosave of current board, score and piece tray; independent best score.

## Building
Use Xcode and XcodeGen with `project.yml`, or the repository's GitHub Actions iOS workflow once these sources have been committed. The ZIP is source code, **not a signed or compiled IPA**. iOS signing is required for installation.

## Validation
Swift parsing succeeded; the standalone engine completed 250 automated simulated placements and JSON save/restore checks. Actual SwiftUI compilation and iPhone touch testing are still required.
