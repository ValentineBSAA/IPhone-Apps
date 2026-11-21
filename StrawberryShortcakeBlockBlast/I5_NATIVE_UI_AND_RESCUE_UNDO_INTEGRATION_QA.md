# 🍓 I5 | Integrated native iPhone UI and real Shuffle/Undo payment safety

**Status:** Unmerged development branch; no IPA, signed build, release or physical-owner acceptance.

## Terminal green source evidence (independently tested)

- [x] I2 combined Quest/Story/Birthday/art: [152/152](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824), zero failures.
- [x] I3 native navigation: [3/3 XCUITest + 28/28 connected model tests](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44875158845), zero failures.
- [x] I4 native Daily/Story: [5/5 XCUITest + 28/28 connected model tests](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44875620343), zero failures.
- [x] D3f Shuffle [PR #86](https://github.com/ValentineBSAA/IPhone-Apps/pull/86): [156/156 model tests](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874853828), zero failures.
- [x] D3f Shuffle+Undo safety: [157/157 model tests](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874919600), zero failures.

## Combined source now committed to I5

- [x] Branch starts at green I4; all five actual player UI journeys, original project and accessibility improvements intact.
- [x] BerryGameSession.swift is byte-identical to the independent 157-green D3f Undo+Shuffle branch. Both paid Story Shuffle and Undo accounting/receipts use existing injected checkoutLedger and checkoutDefaults, rather than writing isolated QA data to the normal player's records.
- [x] Import both original, independently green test suites unchanged: four BerryShuffleContinueIsolationTests and five BerryRescueUndoIsolationTests.
- [x] Keep original D3f QA ledgers as historical provenance (their initial "pending" wording predates successful standalone workflow results).
- [x] No altered source art, music, original player-visible text, game mode, prices, quest/birthday rewards, save keys, bundle ID or version.

## Combined verification required

- [ ] Named iPhone 16e simulator: **5/5 real screen XCUITest** + **161/161 selected production model XCTest**, counting I2 152 plus four Shuffle and five Undo/Shuffle tests; exact logs and terminal result required.
- [ ] Original art/audio/iOS16 source preflight and production Release without developer-only sandbox or artificial wallets.
- [ ] Artifact inspection, no IPA, signing, publication, owner device mutations or backup export.
- [ ] Owner physical iPhone tests, VoiceOver/size and actual saved 8x8/12x12/24x24 Endless + Daily/Story Quest wallet and gameplay.
- [ ] Truly blocked Story Game Over, real native Shuffle rescue and Golden confirmation/cancel UI not yet tested. Isolated handler tests are not a substitute.
- [ ] Other legacy global preference writes, power-loss durable multi-key transactions and timezone-edge behavior still need audit.
- [ ] Whole-game long roadmap remains: Village/Quest/Journal final art issue #78, seasonal Day/Night 4.7/4.8, Build 5 Village, Build 6 separate Moonberries/Night Market, game balance, accessibility and hardware QA.

**Baseline:** iOS16+, com.valentinebsaa.berryblockblast, v0.5.16/internal Build46, 51 songs, 16 effects and all existing player saves. No merge, version bump, IPA, signing or physical signoff.
