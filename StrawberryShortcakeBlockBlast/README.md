# 🍓 Berry Block Blast for iPhone

**Version 0.5.6 • Build 3 • iOS 16.0 minimum • Native SwiftUI + UIKit input • Original offline soundtrack**

**iPhone 14 Pro / iOS 16.0 compatibility:** Build 3 lowers the minimum from iOS 17 to iOS 16 and replaces iOS 17-only SwiftUI observation and scroll anchoring with iOS 16-compatible equivalents. Game modes, soundtrack, effects, saves, graphics and puzzle rules are intentionally unchanged. The app is unsigned and designed for device testing before a stable release. Build 3 is built using the [GitHub Actions iOS 16 workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-ios16-compat.yml). See `RELEASE-QA-0.5.6-BUILD3-IOS16.md`.

Berry Block Blast is an independent, original strawberry-themed block-placement puzzle for iPhone. Its classic three-piece 8×8 mechanics are inspired by Block Blast, but the original artwork, strawberry world, soundtrack and special modes are our own. This project is not affiliated with Hungry Studio or the Strawberry Shortcake brand owner.

## Play
Choose one of three pieces. Drag from the tray to the board and release, or tap a piece followed by a placement square. Complete full rows and columns simultaneously, pursue streaks, and keep space open for large pieces. All play is offline.

## Seven game modes
- **Berry Classic:** Original 8×8 fresh high-score challenge with the giant glowing score. No Undo/Shuffle power-ups.
- **Sweet Endless:** The **only resumable mode**. Choose **8×8, 12×12, or 24×24** and return to your saved garden for that board size. When no move remains, a fresh season opens automatically while your score, lines and berry progress continue. The 24×24 Mega Garden uses larger pieces and a two-axis scrollable, enlarged board.
- **Berry Story:** Chapter goals, progress and earned rewards.
- **Daily Harvest:** Daily seeded puzzle, records and once-a-day rewards.
- **Cozy Cottage:** Relaxing piece distribution and visibly upgraded cottage.
- **Berry Blitz:** One family of fast modes: **Quick Jam (60 seconds)** and **Berry Rush (120 seconds)**, each with its own record. Fixed clocks, no automatic score target, bonus time or in-race power-ups.
- **Strawberry Nightmare:** Separate 12×12 challenging shape distribution.

### Saving
Only **Sweet Endless** restores an unfinished board. Its 8×8, 12×12 and 24×24 sizes have independent safe continuation slots, clearly identified by strawberry bookmark badges. Sweet Endless never ends due to a full/stuck board: the next season automatically clears the garden while keeping the accumulated score and lifetime line stats. Berry Classic and all other modes start fresh, while retaining their separate records, Chapter progression, earned berries and purchased cosmetics. The previous Endless 8×8 save is migrated on first use, and original Build 1/Classic save keys remain untouched for rollback. Starting a New Garden intentionally resets only the selected Endless size.

## Original 51-track soundtrack and 16 sound effects
The complete iOS-ready AAC-LC M4A soundtrack and original PCM WAV effects have been imported **unchanged** from the two uploaded GitHub release archives. All **67 files** are embedded locally with SHA-256 verification. The music catalog contains **11 menu tracks, 22 gameplay tracks, 11 results songs, and 7 dedicated Berry Blitz recordings**. The SFX map covers real block pickup, successful/invalid placement, row clear, combo, record, victory, shop rewards, menu, and Blitz start/countdown/time-up cues.

The full soundtrack now lives in the dedicated **Strawberry Jukebox**, not beneath the More Adventures list. Settings provide music On/Off, Cozy 90/10, Balanced 70/30 (default), Arcade 40/60, shuffle, previous/next, and independent volumes.

Music uses one AVFoundation playback coordinator, no online stream and subtle non-overlapping fades. It honours the iOS Silent switch and suspends when actually backgrounded, not during a momentary screenshot interruption.

## Berry Boutique
Spend **earned** strawberries on permanent board cosmetics, selectable block skins, frames, sparkles and visible Cottage progression. Purchase keys and currency live across restarts. Berry Classic's fair score challenge is never affected by upgrades. No real-money items, ads, or subscriptions.

## Supported iPhone installation
The signed bundle identifier remains `com.valentinebsaa.berryblockblast`. Codemagic's existing Build 2 pipeline and the GitHub Actions workflows compile a physical iPhone app and package **`Berry-Block-Blast-v0.5.6-build2-unsigned.ipa`**. Sign the unsigned IPA with your existing Windows signing process before installation.

The Build 2 pipeline verifies all 51 original M4As and 16 WAVs in source, in the .app and in the finished IPA. Its simulator tests cover gameplay, 24×24 layouts, playlist routing and Blitz variants. **Physical iPhone testing is still mandatory**, particularly zoom/pan and drag on 24×24, Blitz countdown sounds, cosmetics, and data migration. Do not call Build 2 stable until device verification.

See `RELEASE-QA-0.5.6-BUILD3-IOS16.md` for Build 3 compatibility checks, plus `RELEASE-QA-0.5.6-BUILD2.md` and `CHANGELOG.md` for existing-game verification.

## Earlier versions
Build 1 of 0.5.6 introduced the real 15-track offline soundtrack and persistent Strawberry Sound Studio. 0.5.5 built native UIKit finger tracking, Berry Classic and the big score display. 0.5.4 introduced Strawberry Nightmare and approved artwork.
