# 🍓 D1c · Real Checkout One-Tap Commerce Lab

**Status: implemented in a separate draft feature branch; automated CI and owner physical iPhone acceptance still pending.** Based on D1b source. Same `com.valentinebsaa.berryblockblast`, iOS 16.0+, v0.5.16 / internal Build 46. No IPA, merge, artwork changes, product additions or pricing changes.

## What's actually in Developer Garden
- [x] A new internal-only **Commerce Lab** card in the **two-column advanced Developer Garden grid**. Kept all prior D0/D0b and Build 4.6 cards.
- [x] `BerryDeveloperCommerceLabPanel`: seven compact two-column scenario cards. **Tap any scenario once to prepare, execute and show the PASS/FAIL receipt**, with Expected, Actual, clear player-data-safe status, Re-run and Discard & reset.
- [x] `BerryDeveloperCommerceLab` uses **actual BerryGameSession and real BerryEconomyLedger purchase and use methods**, not a second copy of the purchase price policy. Each run seeds a fixed **disposable isolated UserDefaults suite**. Removes the suite before and after each run, and again on sheet disappearance.
- [x] Includes an explicit before/after test of normal player's wallet, Cottage/premium ownership, receipts and the saved 8/12/24 Endless keys; any detected write changes the result to FAIL. No permission to grant real QA wallet berries.
- [x] Protected with **`BERRY_INTERNAL_QA` compile condition**. A PIN alone is not security; Release must exclude the entire lab and commerce test cards.

## Seven one-tap real-checkout cases
1. **Cottage Exact Price:** real 60-strawberry first decoration, exact debit, ledger and ownership.
2. **Cottage 1 Berry Short:** 59/60 fails without debit.
3. **Twister 3 Charges:** real 200 purchase grants exactly three charges.
4. **Premium Not Enough:** 149/150 Trowel fails without debit.
5. **Pantry Buy Twice:** one 600-berry permanent purchase, second rejected.
6. **Protect 3 Gardens:** preseed saved 8, 12, 24 Endless slot bytes; buy a Cottage, Twister and Pantry through actual code; verify bytes unchanged.
7. **Invalid Trowel Use:** attempt an invalid board cell with one purchased/seeded charge; no consumption, no save mutation.

## Automated and owner verification gates
- [x] Six new source XCTest methods in `BerryDeveloperCommerceLabTests.swift`: all seven fixtures, repeat determinism, selection/reset, discard cleanup, real user data untouched and scope boundary.
- [ ] [D1c Actions](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d1c-real-commerce-iphone16e.yml) must finish terminal SUCCESS with **80/80 selected iPhone 16e simulator tests** (previous D0–D1b 74 + new six), Release compilation without internal commerce panels and no IPA. Authored tests are NOT accepted passes until logs actually confirm.
- [ ] Physical iPhone 16e QA: Developer Garden -> More diagnostics -> Commerce Lab; tap each card, see expected/actual PASS, close/reopen and verify original wallet, paid items, all 8/12/24 saved boards unchanged. Check small-screen 2-column layout, text and safe-area/VoiceOver.
- [ ] Full gameplay regression: existing seven modes, normal purchase/reopen/equip, invalid-action tool charges, updated pending journal recovery, Day/Night and art/audio.

## Deliberately still outstanding
- These are **actual purchase handlers in isolated test stores**, but not real SwiftUI Boutique/Cottage/Tools tap-path UI automation. The one-tap card is a test runner, not a test that taps the real production shop View.
- No guaranteed power-loss durable, atomic, multi-key Cottage/premium purchase recovery.
- No Night Market commerce (planned for Build 6), Night Story/modes, birthday/quest progression or production price changes.
- Some board-changing Trowel/Seed/Golden Strawberry/Shuffle use/recovery, tap-target UI and purchase cancellation tests remain future fixtures. The D1c invalid Trowel scenario checks rejection only.
- Never merge, publish a signed/unsigned IPA, bump versions or call physical tests passed without owner authorization.

**Next proposed developer QA stage:** D2/D3 tool action fixtures and actual save/reopen behavior for valid premium actions, then Story/Daily/progression and seasonal/Night scenario adapters. Preserve the prior 70-contract master scenario catalog and record accurate status.
