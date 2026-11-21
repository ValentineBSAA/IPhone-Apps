# 🍓 D3f additional safety audit · Undo and Shuffle accounting

**Status:** Unmerged, unpublished source + five isolated handler XCTest on a **diagnostic feature branch**. [157-case simulator run #44874919600](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874919600) pending final terminal log. No signed IPA, version bump, physical iPhone approval or native Game Over UI acceptance.

**Baseline:** Based on already simulator-verified I2 [152/152](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824), retaining `com.valentinebsaa.berryblockblast`, iOS16+, v0.5.16/Build46, all Story/Daily modes, source art/audio, saved 8×8/12×12/24×24 gardens, exact purchased Shuffle price and original reward receipt keys.

## Source changes

- [x] `BerryGameSession.buyAndContinueWithShuffle()` uses the existing injected `checkoutLedger.recordSpend` and `checkoutDefaults.set(rewardsLog,...)` instead of global `BerryEconomyLedger.shared` and `UserDefaults.standard`. Live sessions still select the same standard ledger and defaults automatically.
- [x] `BerryGameSession.undo()` now uses injected `checkoutLedger.reverseUndoneLineEarnings` and `checkoutDefaults.set(rewardsLog,...)` to reverse only the current test wallet's earned-line accounting and receipt, preserving the original normal-game behavior.
- [x] Neither change alters original spend price, payout formula, undo charge count, save key, use condition, UI panel or score values. Both are safe persistence routing corrections, not new game mechanics.
- [x] Five actual `BerryRescueUndoIsolationTests`: paid Story-mode Shuffle debit/ledger/receipt/score persistence; insufficient-funds negative; already-owned or disallowed mode negative; real row completion, receipt/earnings and Undo reversal to the same board/score/wallet; real normal owner preferences and 8/12/24 saved slots untouched.
- [ ] 157 selected XCTest (I2 152 + five new) on named iPhone16e, Release QA internals excluded, no IPA: [D3f+Undo Actions #44874919600](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874919600). No pass statement until successful terminal result and exact count are checked.

## Avoid duplicate Shuffle development

[Independent draft PR #86](https://github.com/ValentineBSAA/IPhone-Apps/pull/86) already stages the overlapping Shuffle-only storage fix and **four** real handler tests on `feature/berry-d3f-shuffle-continue-isolation`. Its independent [CI #44874853828](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874853828) was pending at this audit.

**Do not create or merge a competing second Shuffle PR.** If both independent suites pass, choose PR #86 as the canonical Shuffle fix; then carry the distinct **Undo** injection and at least one Undo-focused test in a deliberately stacked follow-up, or explicitly reconcile source after careful comparison and new selected XCTest. This diagnostic branch's broader 157 test suite alone does not prove a merged/released result.

## Still not tested

This source test uses actual paid Shuffle and Undo handler methods but **does not synthesize a genuinely blocked Story engine or press the real SwiftUI Game Over overlay buttons**. Those remain in the [D3f real UI roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3F_TRUE_GAME_OVER_UI_AND_RESCUE_QA_ROADMAP.md). Need real owner iPhone16e tests, actual confirm/cancel/rapid tapping and rescue mode guards. Existing holiday/day-night visuals, Story/Village and Moonberry Night Market remain on whole-game roadmap.

No release or actual player data migration is authorized by this checkpoint.
