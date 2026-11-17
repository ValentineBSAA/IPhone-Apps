# Berry Block Blast 0.5.6 build 1: original 15-track soundtrack

## Previous features retained
Built from 0.5.5 build 1: all seven modes including Berry Classic, UIKit touch handling, score/high-score animations, saved games, shop, rewards, approved icon and mascot, native puzzle SFX and touch diagnostics.

## Exact approved audio source
GitHub Release V1: BerryBlastBlast-Soundtrack-v1.0-iOS-Ready.zip.
All 15 AAC-LC M4A files imported byte-for-byte from that supplied archive, verified with SHA-256. The archive's original manifest/playlist metadata determines track titles, moods and special roles. Duration total 31:36. Original source audio had already undergone an Opus-to-AAC lossy conversion in the supplied iOS-ready package, not repeated here. No synthetic music substitutes.

## Audio
- Native AVAudioPlayer with a single app-wide music coordinator, no separate players per screen.
- Home theme: Welcome to Berryland (#01); victory results: Sweetest Victory (#05), played only on results, not shuffled mid-game.
- 13 gameplay recordings: 10 calm (#06-#15), 3 upbeat (#02-#04).
- Mode weights: Cozy 90/10, Balanced 70/30 default, Arcade 40/60.
- Persistent music toggle, shuffle, mode, music volume, effect volume; track title and Next controls.
- No immediately repeated gameplay song in shuffle. Automatic playback on completion, fade-out/fade-in without simultaneous song overlap.
- Audio pauses when app inactive and honours interruptions and output changes; follows iOS silent switch through the ambient AVAudioSession.
- Original responsive placement/clear/error cues remain, with temporary background ducking on celebrations.

## Build gates
1. verify_artwork.py and verify_soundtrack.py check exact original resources before compiling.
2. XcodeGen copies Soundtrack as a resource folder into BerryBlockBlast.app.
3. Simulator unit tests validate gameplay and shuffle/mode selection.
4. Release iPhone compilation runs only after validations.
5. verify_soundtrack.py --app checks 15 exact M4A hashes in .app.
6. Packaging checks verify_soundtrack.py --ipa with 15 exact files inside unsigned IPA.

## Remaining physical acceptance
- Sign using user's existing external Windows signing workflow; no signing credential is available to this automation.
- Install on real iPhone 16e. Verify drag/drop (still requires user acceptance), all seven modes, records and saves.
- Listen to actual 15 files (including first and last), check fade, silent switch, background/foreground, wired/Bluetooth route, music settings and SFX levels.
- Confirm home-to-game transitions do not restart playback.
- Verify menu/result theme transitions, auto-advance and no simultaneous music playback.
- Check increase in IPA size and install time compared to old generated music.
- Public soundtrack redistribution rights remain user responsibility; supplied SOURCE_AND_RIGHTS.md is retained unmodified.
