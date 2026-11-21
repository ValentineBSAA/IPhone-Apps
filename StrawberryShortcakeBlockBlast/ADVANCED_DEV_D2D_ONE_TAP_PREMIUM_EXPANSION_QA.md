# 🍓 D2d · Eleven One-Tap Real Premium Actions in Developer Garden

**Status:** Internal QA source and six targeted XCTest methods are implemented in a stacked draft feature branch, but selected CI and physical iPhone acceptance are **pending**. Do not call this a stable release.

**Baseline unchanged:** `com.valentinebsaa.berryblockblast`, iOS 16+, v0.5.16/internal Build46, existing sound/art packs, all game modes, saved 8×8/12×12/24×24 gardens, wallets and existing premium prices. No IPA, release, merge, signed download or version bump.

## New one-tap real-use cards (in addition to the original seven D2b cards)

Each card executes a real `BerryGameSession` and `BerryEngine` action on a legally placed one-move garden, uses a new disposable `UserDefaults` suite and injected actual `BerryEconomyLedger`, reopens the saved test board and checks source data. The same existing two-column `BerryDeveloperToolActionLabPanel` automatically displays the new cards, with expected/actual results, PASS/FAIL, repeat and reset.

1. **Twister Rotation:** saved known non-symmetric L-shaped tray piece, one real `useRibbonTwister(slot:1)`; verify actual shape rotation, exact 3→2 charge use, score/moves unchanged, rotated tray survives reopen.
2. **Picnic Pantry Swap:** real permanent Pantry ownership in test store; stash known piece, reopen, swap back, reopen again, confirm reserve/tray identity and no currency spent.
3. **Mega Golden Rescue:** occupied cells across all four 12×12 patches of a 24×24 Endless board; use real Golden Strawberry; confirm cleared board, score and rescue limit, exactly one charge spent and independent 8×8/12×12 save bytes untouched.
4. **Buy & Rescue Garden:** real combined `buyAndUseGoldenStrawberry()` handler (after D2c injected-spending/receipt correction), exact 250-berry wallet debit and ledger spend, one saved reward receipt, board clear, one-use limit and second attempt denied.

## Important safety regression found by D2b

[D2b Actions #44871494518 attempt 1](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) ran 94 selected tests and **failed two assertions inside one new test**. The Seed planting action and save/reopen worked, but the temporary test's normal player's best-score key changed. The actual culprit was `BerryGameSession.useStarberrySeed()` writing to `UserDefaults.standard` rather than the injected `checkoutDefaults`. This is a real test-isolation defect, not simply JSON order flakiness.

- [x] Fixed the two original best-score writes (`drop` and `useStarberrySeed`) to use `checkoutDefaults` on D2b, D2c and D2d branches. Normal sessions still use standard defaults.
- [x] Guarded `BerryProgression.shared.recordPlacement` in actual `drop` so isolated GameSessions cannot increment the real owner's daily quest progress; live sessions still call their original progression singleton. Wider `earn` and Story/Daily singletons are **not** certified for isolated D3 QA.
- [x] [D2b 94-test run #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) restarted as **attempt 2**. No pass claim without terminal logs.
- [ ] [D2c 102-test run #44871838416](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416): first attempt may still contain the original base branch, depending on checkout time. If it fails, rerun after patched D2c source is confirmed.
- [ ] [D2d 108-test run #44872232106](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872232106): 102 existing selected regression tests plus six new `BerryDeveloperToolActionExpansionTests`, named iPhone 16e simulator, source/audio/art/iOS16 checks, Release QA internals excluded, no IPA. Verify terminal log result.

## New XCTest methods (six)
- [x] Actual Twister rotation/charges and save/reopen receipt.
- [x] Actual Pantry stash and second swap across two restarts.
- [x] Golden rescue on four actual occupied Mega sections; other slots untouched.
- [x] Actual 250-berry combined rescue/ledger/receipt/one-use limit.
- [x] All eleven card receipts deterministic across repeat and reset, no sandbox state carried across runs.
- [x] Original owner's wallet, premium inventory, scores, economy ledger, rewards and all Endless saved games unchanged after all four additional one-tap fixtures.

## Physical and whole-game acceptance still open
- [ ] Real owner iPhone16e Developer Garden two-column readability/touch, card selection, accessibility, keyboard/Done dismissal, force-close/reopen and save safety.
- [ ] Actual gameplay or Story **Game Over screen** SwiftUI tap path: this lab calls a real handler on an occupied *playable Endless board*, not a proof of authentic blocked game-over UI behavior.
- [ ] Crash-durable multi-key purchase/write journal; the current separate UserDefaults writes are not guaranteed power-loss atomic.
- [ ] D3 Daily/Story/quests/birthday rewards and calendar boundaries, seasonal artwork, Day/Night parity, Village and distinct Night Market/Moonberries remain on original full-game roadmap.

**Do not merge or publish without explicit owner approval and full verification.**
