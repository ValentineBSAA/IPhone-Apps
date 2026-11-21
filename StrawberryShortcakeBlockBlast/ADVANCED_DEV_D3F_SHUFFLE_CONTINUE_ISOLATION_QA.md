# 🍓 D3f · Real Story Shuffle Continue Checkout Safety

**Status:** Source implemented and **four real GameSession XCTest** committed on a new draft branch stacked on **I2 152/152 simulator PASS**. D3f 156-selected iPhone16e simulator CI and owner physical acceptance are **pending**. This milestone protects the real buy-and-use Shuffle handler but **does not yet prove the visible blocked Story Game Over screen or real finger taps**.

**Product compatibility:** iOS16+, `com.valentinebsaa.berryblockblast`, v0.5.16/internal Build46, original Story/Daily/Endless/Cozy/Blitz/Nightmare modes, existing save keys, 8/12/24-size Endless garden separation, original art/audio/cosmetic data, 50-berry `BerryEconomy.shufflePrice`, 250-berry Golden rescue and original 100-berry annual Birthday policy.

## Safety defect corrected
`BerryGameSession.buyAndContinueWithShuffle()` previously wrote directly to global `BerryEconomyLedger.shared` and `UserDefaults.standard` for spending and reward receipts **even when `checkoutDefaults` and `checkoutLedger` were injected for an isolated QA session**. Calling it from the advanced Developer Garden could have edited the live owner's records.

- [x] Routes its exact original **50-berry spend** to `checkoutLedger.recordSpend`.
- [x] Routes its exact original reward receipt to `checkoutDefaults.set(rewardsLog,…)`.
- [x] Production still defaults to the shared ledger/standard preferences, so no player-facing behavior, prices or save schema is changed.
- [x] Preserves the original guard: if another Shuffle is already owned, insufficient wallet, disallowed game mode or no legal tray can be produced, purchase must not debit. Checkout still only commits after the real engine produces a playable hand.
- [x] Does **not** rewrite game-over UI, offer silent free rescues, change Daily/Story progression or regenerate art.

## Four real handler tests
1. Start a real Story-mode `BerryGameSession` with a disposable stored inventory of 50 berries, zero Shuffles, and an injected real economy ledger. Call the actual combined checkout and verify exact **50 debit**, one ledger entry, one receipt, score/moves/lines unchanged, second purchase refused, wallet persists on new session.
2. Start with 49 berries and zero Shuffles: real checkout must reject without charging, writing a reward receipt or changing inventory/board.
3. Already-owned Shuffle and noneligible Classic/Blitz/Nightmare modes: no duplicate purchase, charge or receipt.
4. Before/after snapshot of original owner wallet, ledger, Story and all independent Endless 8/12/24 saved slots while the successful checkout runs in a separate UserDefaults suite. Test suite's Endless sentinel bytes also remain unchanged.

**Accuracy boundary:** Story currently starts a fresh run when its mode is re-entered. The test asserts persistent **inventory, receipts and ledger**, not that the Story engine board is stored and reopened. The fixture uses a real playable Story engine and engine-generated legal replacement tray. It is NOT a blocked-board Game Over UI test.

## Simulator and owner gates
- [ ] [D3f Actions #44874853828](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874853828): named iPhone16e, **156 selected XCTest** (previous integrated I2 152 + four new), source/iOS16/art/audio check, Release build excludes QA-only models/panels, no IPA; accept only with terminal **156/156 PASS zero failures**.
- [x] [I2 Actions #44874405824](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824) first attempt 152/152 PASS, Release QA excluded, no IPA.
- [ ] Actual Story blocked board, real Game Over overlay, two side-by-side rescue choices, Golden confirmation/cancel, physical iPhone16e taps and accessibility, real owner wallet and save protection, after force-close/reopen.
- [ ] Additional direct `Undo` and legacy-8x8-restart shared write paths still require separate injection-safe audit before claiming entire `BerryGameSession` is isolated. Do not test those paths against a temporary store until corrected.

[Full D3f Story Game Over UI roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3F_TRUE_GAME_OVER_UI_AND_RESCUE_QA_ROADMAP.md) retains true blocked-board and native screen tests plus the whole-game seasonal Day/Night, Build5 Village and Build6 Night Market targets. No merge, IPA, signed release or version bump without owner approval.
