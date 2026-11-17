# Berry Block Blast 0.5.6 Build 3: iOS 16 Compatibility QA

## Purpose
Build a native iPhone test bench for **jailbroken iPhone 14 Pro / iOS 16.0**, using the existing Berry Block Blast game, not a web wrapper.

## Scope of changes
1. XcodeGen project iOS deployment target lowered from 17.0 to **16.0**; app build number 3.
2. All 12 SwiftUI `onChange(of:) { _, newValue in }` calls migrated to iOS-16-supported `onChange(of:) { newValue in }`. Actions preserved.
3. 24×24 Mega Garden's `defaultScrollAnchor(.center)` replaced with a `ScrollViewReader` that initially centers the enlarged board while preserving horizontal and vertical panning.
4. No changes to the puzzle engine, touch engine, save keys, game modes, the existing icon, 51 audio recordings or 16 sound effects.

## CI acceptance checklist
- [ ] Source compatibility preflight passes.
- [ ] Original icon / mascot verification passes.
- [ ] Original 51 AAC-LC M4As plus 16 WAV verification passes in source.
- [ ] Unsigned iPhone build compiles successfully against **iOS 16.0 deployment target**.
- [ ] Built `Info.plist` reports `MinimumOSVersion = 16.0`.
- [ ] All 67 audio files are verified inside the built app and final IPA.
- [ ] All BerryBlockBlastTests pass in an available iPhone simulator.
- [ ] GitHub Actions publishes `Berry-Block-Blast-v0.5.6-build3-iOS16-unsigned.ipa`.

## Physical iPhone 14 Pro / iOS 16.0 test bench
- [ ] Install unsigned IPA using an installation method supported by this jailbreak. An unsigned IPA may still need appropriate trust/signing depending on installer. The game does not require network.
- [ ] Launch and return from app switcher without crashing. Check fullscreen portrait and Dynamic Island safe areas.
- [ ] Verify finger **drag and drop** on 8×8 and tap-to-place fallback. Check clear, invalid drop, combos and giant flashing high score.
- [ ] Pan **24×24 Mega Garden horizontally and vertically**, verify its starting centered position and drag/drop target alignment.
- [ ] Start every game mode (Berry Classic, Sweet Endless, Story, Daily, Cozy, Blitz 60/120, Strawberry Nightmare).
- [ ] Verify Blitz timer/countdown effects, no unearned clock bonuses or score-target end.
- [ ] Verify Strawberry Jukebox all 51 songs, music shuffle/modes, SFX volume/16 effects, behavior when backgrounding.
- [ ] Verify Boutique purchases and cosmetics after force quit/relaunch.
- [ ] Verify Sweet Endless independent 8/12/24 saves; confirm Classic still starts fresh, and no saved data is erased during update.

## Important limitations
A successful CI build proves compilation with an iOS 16 deployment target; it is **not** proof that gameplay has passed on a physical iOS 16.0 device. GitHub's available simulator may be newer than iOS 16. This is a separate compatibility test build, not a stable public release. Existing Berry Block Blast bundle identifier stays unchanged.
