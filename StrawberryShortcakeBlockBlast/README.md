# 🍓 Berry Block Blast for iPhone

**Version 0.5.8 • Build 1 • iOS 16.0+ • Native SwiftUI + UIKit input • 51 original songs & 16 original effects**

Berry Block Blast is an independent, original strawberry-themed block-placement puzzle for iPhone. Its classic three-piece 8×8 mechanics are inspired by Block Blast, but the original artwork, strawberry world, soundtrack and special modes are our own. This project is not affiliated with Hungry Studio or the Strawberry Shortcake brand owner.

## 0.5.8 Build 1 development candidate

This branch is for Codemagic iOS16 testing, not a published stable release. The sixteen original AI-generated image catalogs are stored as `BuildPayload/Berry-0.5.8-ArtCatalogs.zip` and are imported before XcodeGen. The bundle ID and all prior wallet, score, Story, skin and cottage-ownership keys remain unchanged.

Other improvements include a dedicated My Strawberry Cottage home card instead of the duplicate Boutique card, automatically rotating strawberry-colored quotes, piece-size labels on each tray slot, updated unlock prices in Inventory, five new Boutique block skins, and lower-frequency UI timer updates. Voice announcements are **not** included.

## Play
Choose one of three pieces. Drag from the tray to the board and release, or tap a piece followed by a placement square. Complete full rows and columns simultaneously, pursue streaks, and keep space open for large pieces. All play is offline.

## Seven game modes
- **Berry Classic:** Original 8×8 fresh high-score challenge with the giant glowing score. No Undo/Shuffle power-ups.
- **Sweet Endless:** The **only resumable mode**. Choose **8×8, 12×12, or 24×24** and return to your saved garden for that board size. When no move remains, a fresh season opens automatically while your score, lines and berry progress continue. The 24×24 Mega Garden uses larger pieces and a two-axis scrollable, enlarged board.
- **Berry Story:** Chapter goals, progress and earned rewards.
- **Daily Harvest:** Daily seeded puzzle, records and once-a-day rewards.
- **Cozy Cottage:** Relaxing piece distribution and interactive decoration garden. Previously purchased items persist; drag owned decorations to reposition them, with positions saved locally.
- **Berry Blitz:** Four timed score chases: **Quick Jam (1 minute)**, **Berry Rush (2 minutes)**, **Garden Sprint (5 minutes)** and **Berry Marathon (10 minutes)**, each with its own local record. No bonus time or power-ups. A stuck tray is rerolled, and a full board starts fresh without losing the run score; the run ends only when the timer expires.
- **Strawberry Nightmare:** Three-minute, 12×12 hard mode with larger pieces and separate records. Unlike Blitz, running out of legal moves is a defeat.

### Saving
Only **Sweet Endless** restores an unfinished board. Its 8×8, 12×12 and 24×24 sizes have independent safe continuation slots, clearly identified by strawberry bookmark badges. Sweet Endless never ends due to a full/stuck board: the next season automatically clears the garden while keeping the accumulated score and lifetime line stats. Berry Classic and all other modes start fresh, while retaining their separate records, Chapter progression, earned berries and purchased cosmetics. The previous Endless 8×8 save is migrated on first use, and original Build 1/Classic save keys remain untouched for rollback. Starting a New Garden intentionally resets only the selected Endless size.

## Original 51-track soundtrack and 16 sound effects
The complete iOS-ready AAC-LC M4A soundtrack and original PCM WAV effects have been imported **unchanged** from the two uploaded GitHub release archives. All **67 files** are embedded locally with SHA-256 verification. The music catalog contains **11 menu tracks, 22 gameplay tracks, 11 results songs, and 7 dedicated Berry Blitz recordings**. The SFX map covers real block pickup, successful/invalid placement, row clear, combo, record, victory, shop rewards, menu, and Blitz start/countdown/time-up cues.

The full soundtrack now lives in the dedicated **Strawberry Jukebox**, not beneath the More Adventures list. Settings provide music On/Off, Cozy 90/10, Balanced 70/30 (default), Arcade 40/60, shuffle, previous/next, and independent volumes.

Music uses one AVFoundation playback coordinator, no online stream and subtle non-overlapping fades. It honours the iOS Silent switch. From 0.5.8, music and lingering SFX are suspended as soon as iOS reports that the app is resigning active, preventing playback continuing through locking or backgrounding.

## Berry Boutique
Spend **earned** strawberries on permanent board cosmetics, selectable block skins, frames, sparkles and visible Cottage progression. Purchase keys and currency live across restarts. Berry Classic's fair score challenge is never affected by upgrades. No real-money items, ads, or subscriptions.

## Supported iPhone installation
The signed bundle identifier remains `com.valentinebsaa.berryblockblast`. Codemagic and the optional GitHub Actions workflow compile a physical iPhone app and package **`Berry-Block-Blast-v0.5.7-build1-unsigned.ipa`**. Sign the unsigned IPA with your existing Windows signing process before installation.

The Build 1 pipeline verifies all 51 original M4As and 16 WAVs in source, in the .app and in the finished IPA. Its simulator tests cover gameplay, 24×24 layouts, playlist routing and Blitz variants. **Physical iPhone testing is still mandatory**, particularly zoom/pan and drag on 24×24, Blitz countdown sounds, cosmetics, and data migration. Do not call Build 1 stable until device verification.

See `RELEASE-QA-0.5.6-BUILD2.md` and `CHANGELOG.md` for details.

## Earlier versions
Build 1 of 0.5.6 introduced the real 15-track offline soundtrack and persistent Strawberry Sound Studio. 0.5.5 built native UIKit finger tracking, Berry Classic and the big score display. 0.5.4 introduced Strawberry Nightmare and approved artwork.

## 0.5.7 Build 1 iOS 16 testing focus
- Fixed elevated drag placement anchor from preview to drop: never search for a different legal position; red individual blocked cells plus dimmed occupied cells. Pickup ghost shows immediately.
- Premium block tile shapes, brighter distinct Blueberry Velvet / Vanilla Cream cosmetics, bounded strawberry-clear particles, Sweet Endless seasonal palette, and the user-generated 29-icon game set.
- Main-menu Boutique button and wallet, new Berry Collection with Inventory, Awards and **offline personal** leaderboard, no made-up online ranks; bought helper counts and equip actions are visible.
- New Berry Hint (20 earned strawberries), suggests a real legal placement for three seconds; no auto-play and only available outside Classic/Blitz. Shuffle cannot be consumed if it cannot rescue play. Restart does not mint free helpers.
- Daily Harvest calendar with real local date, remaining reset hours, completed day history, and streak. Existing old daily-completion key is read without deleting it.
- Clear no-moves Game Over panel; no more misleading “board full” wording. Full multi-line Strawberry Blocks unlock sheet.
- Preserve all old iOS bundle ID and UserDefaults save/ownership keys. Audio resources preserved byte-for-byte.
- Full native Xcode build and live iPhone QA **not performed here**; use the updated GitHub Actions or Codemagic pipeline to make an unsigned test IPA.

See `RELEASE-QA-0.5.7-BUILD1.md` for regression instructions.
