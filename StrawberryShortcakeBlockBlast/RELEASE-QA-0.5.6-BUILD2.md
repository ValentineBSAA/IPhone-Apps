# Berry Block Blast 0.5.6 Build 2 · Development QA

## Source baseline and protection
- From user-tested Build 1: do not rewrite UIKit drag/drop or classic placement logic.
- Never reset or delete old non-Classic save keys. Berry Classic is the sole resumable game board.
- Preserve old best scores, Chapters, daily unlocks, strawberry balance and old signed bundle ID.
- Version: MARKETING_VERSION 0.5.6, CURRENT_PROJECT_VERSION 2.

## 67 original audios from GitHub release audio-v1.0
- OST ZIP: BerryBlastBlast-OST-v1.2-51Tracks-iOS.zip, SHA-256 fc1c27da553edd1b42cbc8ea8254875a91818c741e9db8904e1a211ae1dadadc.
- SFX ZIP: BerryBlastBlast-SFX-v1.0-16Effects-iOS.zip, SHA-256 982487908e5064c4b0c0845d7f37c73fba0df077e9ddff217129f7c51b89bd6b.
- ImportManifest.json retains the exact original archive paths and per-audio SHA-256.
- MusicSourceDocs/AUDIO_MANIFEST.json is authority for 11 menu, 22 game (calm/upbeat), 11 victory/results, 7 Blitz tracks.
- EffectSourceDocs/SFX_MANIFEST.json assigns the 16 event_key mappings including 10-second warning and two-second untrimmed countdown.
- Verify source via `python3 Tools/verify_audio_build2.py`, compiled .app via `--app`, and IPA via `--ipa` before distribution.
- Bundle audio folders as blue folder references 'Music' and 'Effects', not as streaming links.
- No generated placeholder recordings and no re-encoding.

## Playability / integration tests
1. Berry Classic 8×8: native pickup, direct drag, lifted-thumb drop, tap-then-place and single saved-run badge.
2. Return Home from Classic and relaunch: board/score resume. End a run/restart: saved badge clears. Do not overwrite old legacy keys.
3. Sweet Endless: choose 8×8, 12×12 and 24×24. 24 must zoom and scroll; finger and board coordinates match after panning. Larger pieces must allow reasonable progress.
4. Berry Story, Daily Harvest, Cozy Cottage, Strawberry Nightmare unchanged. Records, Chapter unlocks and earned berries persist, but boards start fresh.
5. Berry Blitz: 60-sec Quick Jam and 120-sec Berry Rush have separate records. Clock cannot receive bonus seconds. Race ends at zero. 10-second warning, final countdown WAV and time-up fire each ONCE.
6. No HUD display, visible pause overlay or music restart should occur solely because an iOS screenshot temporarily makes the app inactive.
7. More Adventures shows only mode cards, no raw tracklist. Strawberry Jukebox contains all 51 titled tracks and categories, with the original playback modes intact.
8. Purchases: insufficient berries disabled, ownership permanent, equipped cosmetics actually visible, no double spending; Classic remains power-up free.
9. Verify sound events during pickup/drop/clear/combo/record/Blitz/shop, independent effects volume and music ducking; check on headphones and speaker.
10. Verify iPhone keyboard/screen/sheet navigation, all Settings, Reduce Motion, portrait layout, font scaling, and offline playback.
11. Before calling stable: run Xcode/iOS Simulator tests plus **real iPhone 16e** drag-and-drop, pan, saves and audio checks.

## Installation and signing
The GitHub or Codemagic pipeline produces an **unsigned** iPhone IPA. The user signs it on Windows with their existing credentials. No signing or device installation is implied by automated CI success.
