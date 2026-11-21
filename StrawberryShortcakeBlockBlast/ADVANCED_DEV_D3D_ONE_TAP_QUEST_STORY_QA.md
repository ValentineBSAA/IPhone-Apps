# 🍓 D3d · Real One-Tap Quest, Story and Village Developer Garden Lab

**Status:** Source implemented on stacked **draft feature branch**, simulator CI and owner physical QA pending. No IPA, merge, signed release or version bump. Original iOS16, `com.valentinebsaa.berryblockblast`, v0.5.16/Build46, all original game modes, saves, art/audio and payout keys preserved.

## New feature in the internal Developer Garden

- [x] **Quest & Story Lab** is a new internal-only card in the native **two-column advanced diagnostics grid**, alongside Scenario Sandbox, State & Timer Lab, Commerce Lab and eleven-card Tool Action Lab. No list-style replacement. `#if BERRY_INTERNAL_QA` protects both the runner and native SwiftUI panel, so they are absent from the normal Release app.
- [x] Five single-tap cards run *actual* `BerryProgression`, `BerryGameSession` and `BerryDailyHistory` methods, with their own temporary UserDefaults suite and injected real economy ledger. All use **fixed virtual local dates**, without touching the system clock, and tear down the test store after every card.
- [x] Each card displays **expected-versus-actual**, PASS/FAIL, owner-profile unchanged status, Repeat and Discard & reset. Source model and UI are not connected to the actual player's active GameSession.

### Five one-tap cards

1. **18-Move Quest:** generate 18 real progression placements, claim original 20-berry Garden Gardener reward once, reject second claim, reopen the disposable wallet and verify one receipt and lifetime claimed count one.
2. **Story Chapter & Claim:** record Chapter 2 twice (count one), claim original 35-berry Story Keeper quest once, grant original 25-berry Chapter 2 reward once and reopen to see exactly **60 berries and two receipts**.
3. **Four-Day Quest Rotation:** across four virtual local dates, verify exactly three distinct daily quests with all four quest IDs omitted once.
4. **Village Unlock Levels:** original Story chapter and 14 completed Daily dates yield level sequence **1 → 2 → 4 → 5**, capped at five.
5. **Wrong Wallet Protection:** deliberate cross-store quest claim is rejected; only the matching isolated GameSession receives 20 berries. The unrelated wallet remains zero.

All five snapshot critical real player keys before and after, including wallet, receipts, Story level, Daily history, four virtual quest days and 8×8/12×12/24×24 Endless saved games, and explicitly FAIL if any change.

### Seven new XCTest methods

- [x] All five scenarios run with true PASS receipts.
- [x] Specific 18-move once-only claim receipt.
- [x] Specific Chapter2 + Story Keeper total and two receipts.
- [x] Four-day clock rotation.
- [x] Village level unlock thresholds.
- [x] No payment to wrong GameSession wallet.
- [x] Repeat-run determinism, state isolation, reset and owner-key safety.

[D3d Actions #44873363717](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873363717) selects **139 XCTest** (132 preceding + seven new), iPhone 16e simulator, iOS16/art/audio preflight, Release compile with internal diagnostics excluded and **no IPA**.

- [ ] Verify **terminal 139/139 zero-failure** GitHub logs before marking D3d automated pass. Fix any actual failing handlers/tests first.
- [ ] [D3c 132-test Actions #44873090908](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873090908) must pass as the D3d parent. D3b [124/124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) was already verified terminal success, Release QA-excluded/no IPA.
- [ ] Owner actual iPhone16e: Developer Garden two-column layout, five card taps, repeated taps, readout text/contrast, accessibility, sheet dismissal, actual gameplay Story and quest-claim screens and save integrity.
- [ ] Keep [D4 approved-art fallback PR #80](https://github.com/ValentineBSAA/IPhone-Apps/pull/80) independent until safe integration. D3d is based on D3c, whereas D4 is a parallel D3b child. **Neither branch contains the other's unmerged changes.**

## Remaining original whole-game work

This lab calls actual model/transaction handlers, **not native production gameplay SwiftUI finger taps**, and does not prove power-loss atomicity or Story Game Over interactions. Birthday award/year-rollover, physically validated original Story/Daily/gameplay UI, final owner-approved seasonal/Village/Quest/Journal artwork, premium Day/Night parity, Build5 quests and Village evolution, Build6 distinct Night Market/Moonberries, full-game performance and save migration remain to be completed and tested.

**No user-visible IPA/merge/release without explicit owner authorization.**

## D3d CI failure and correction · November 20, 2026
- [x] [D3d 139-test Actions #44873363717](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873363717) **first attempt failed to compile the test binary**, not a gameplay test failure. Error: `BerryDeveloperQuestStoryLab.swift:203:57: ambiguous use of operator '=='` when comparing the four Village levels as arrays. The production Release QA-exclusion build had already passed.
- [x] Replaced ambiguous array equality with four explicit integer comparisons: `first == 1 && second == 2 && third == 4 && fourth == 5`. The Quest, Story, Village rules, wallets and save data were not modified. Applied the same correction in the separate I1 integrated source.
- [ ] Requested **D3d attempt 2**. Do not mark 139/139 passed until the new attempt finishes and actual terminal XCTest/Release/no-IPA evidence is inspected. [I1 143-case integration #44873619553](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873619553) may have checked out the pre-fix code; rerun that separately if its first attempt fails.
