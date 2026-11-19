# Berry Berry Blast 0.5.14 • Build 4.1 POLISH QA

Development branch: feature/berry-build4-r2-polish
Parent Build 4 candidate: feature/berry-build4-approved-assets-foundation
Never overwrite known-good Build 3: b4ffda288b7a778a79a860c8d8ebc2cab3e5755b

## Exact app identity

- Home top-left: "🍓 B4.1 TEST • v0.5.14"
- Settings bottom: "Berry Berry Blast v0.5.14 • Build 4.1 • POLISH QA"
- Developer Garden > Build Information: same installed Info.plist label and branch.
- GitHub Actions IPA filename includes "build4.1-POLISH-QA". The IPA is unsigned, NOT an installable signed release.

## Scope: preserve the gameplay engine

- Branded, season-aware Sweet Endless header without duplication.
- More distinguishable opt-in Blossom Glass empty cells and outside-only border. Never mutate touch mapping or BoardEngine.
- Garden Helpers and Special Tools category artwork distinguished with existing packaged imagery.
- Boutique header and sheet spacing tightened; card press animations respect Reduced Motion.
- Developer Garden adds 8th Combo Preview tile; banners are display-only, no session mutation, points, rewards, saves or achievements.
- Touch diagnostics clarified: the QA TOUCH readout appears beneath gameplay toolbar.
- Feature notes disclose that night/economy and notification controls are not yet functional.
- 9 owner-approved full-resolution developer/helper PNG candidates are in original next-chat handoff ZIP and are not silently claimed to be in GitHub. Art package import is tracked separately.

## Pre-hardware acceptance

- [ ] GitHub CI engine regression green.
- [ ] iPhone 14 Pro + iPhone 16 simulator XCTest green.
- [ ] Signed IPA from artifacts, not GitHub public release.
- [ ] iPhone 16e physical install check shows 0.5.14/4.1 and B4.1 TEST.
- [ ] iPhone 14 Pro physical install check shows 0.5.14/4.1 and B4.1 TEST.
- [ ] Original vs Blossom Glass selectable, readable, tappable edges 8/12/24 where supported; no loss of saved game.
- [ ] Full settings/Boutique/Developer Garden navigation, sheet top/bottom, audio/haptics.
- [ ] ×10/20/30/50 previews look correct and never grant achievements or rewards.
- [ ] True Special Tools charges/actions and invalid-charge safety verified separately.

Keep parent draft PR #7 unmerged. Only record physical tests as checked after actual device testing.
