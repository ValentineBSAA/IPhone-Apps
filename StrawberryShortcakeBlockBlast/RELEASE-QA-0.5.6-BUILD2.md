# Berry Block Blast 0.5.6 Build 2: validation and device release gate

## Audio source
Two ZIP archives uploaded to GitHub release audio-v1.0:
- BerryBlastBlast-OST-v1.2-51Tracks-iOS.zip (51 original AAC-LC/M4A songs)
- BerryBlastBlast-SFX-v1.0-16Effects-iOS.zip (16 original PCM/WAV effects)

Real files are imported byte-for-byte under AudioBuild2/Music and AudioBuild2/Effects.
Tools/verify_audio_build2.py checks 51+16 identities/hashes in the SOURCE TREE, compiled .app and unsigned IPA. No sample substitutions, no re-encoding.

## Changes
- Berry Classic 8×8 unchanged drag math and rules, one saved unfinished game with Strawberry bookmark.
- Sweet Endless 8×8, 12×12 and 24×24, larger piece catalog and scrollable viewport at 24×24.
- Berry Blitz: 1-minute Quick Jam + 2-minute Berry Rush, isolated high scores. No time-extension bonus or low fixed target.
- Remaining modes retained: Story, Daily Harvest, Cozy Cottage, Strawberry Nightmare 12×12, in addition to Sweet Endless, Berry Blitz and Classic.
- Strawberry Jukebox has 51 categorized songs; premium music controls, automatic transition and responsive sound FX.
- Berry Boutique permanent cosmetic ownership and equipment, berry wallet, Cottage decorations; no real money.
- Screenshot-induced temporary inactivity does not open pause UI.
- Existing sound/music settings, personal scores, story and rewards preserved.

## Automated gates
1. Verify artwork and all 67 original audio files in source.
2. XcodeGen project generation and unsigned Release iphoneos build.
3. Check all 51 M4As and 16 WAVs inside compiled BerryBlockBlast.app.
4. Check 51+16 in packaged IPA by checksum.
5. Run iPhone simulator unit test suite, including large-board mechanics and playlist logic.
6. Keep product bundle ID com.valentinebsaa.berryblockblast and build version 0.5.6 (2).

## Physical iPhone 16e acceptance required
- [ ] Classic 8×8 drag-and-drop after new install, drag to edges, finger lifted preview and tap-to-place.
- [ ] 12×12 and 24×24 game boards; scroll 24×24 in every direction without losing the touch target.
- [ ] Classic unfinished run resumes after Home/relaunch; berry saved badge; other modes begin fresh.
- [ ] Screenshot during active gameplay never shows pause UI.
- [ ] Berry Blitz Quick Jam ends after 60s and Berry Rush after 120s with appropriate independent best scores.
- [ ] High-score banner and record audio, combos, line clear effects, shop purchase, equip/unequip and persistence.
- [ ] 51 song playlist rotates between menu, normal, Blitz, victory; no repeated track or multiple overlapping music players.
- [ ] Test all 16 WAV sound effects, shuffle, SFX/music sliders, interruption behavior and AirPods/Bluetooth route.
- [ ] No excessive performance drain or unreadable elements on 24×24 board.
- [ ] Confirm original in-app purchase-free economy, no duplicate currency or lost records.

The unsigned IPA is NOT a signed, installed or physically verified release. Do not mark stable before tests.
