# 🍓 D0d: Real Undo / Shuffle / Hint Checkout With Isolated Inventory and Ledger

**Checkpoint:** November 20, 2026 (Arizona). **State:** implementation committed; CI / physical iPhone gates pending.  
**Branch:** `feature/berry-advanced-dev-d0d-injected-checkout-ledger`, based on [D0c draft PR #66](https://github.com/ValentineBSAA/IPhone-Apps/pull/66).  
**Master tracker:** [Advanced Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61).

## Scope of this increment
Unlike earlier D0b mock rules, these new tests exercise the **real `BerryGameSession.buyUndo()`, `buyShuffle()`, and `buyHint()` purchase methods**, the existing **`BerryGameSession.save()` inventory JSON encoding** and the **real `BerryEconomyLedger.recordSpend()`** while injecting **separate `UserDefaults(suiteName:)` test storage** and an isolated ledger instance. Neither test reads or writes the real player's active wallet/save/ledger as a result of the purchase, and each test deletes its disposable preferences domain at the end.

## Implementation and compatibility
- [x] New `BerryStandardToolCheckout.swift`: checked purchase decision + exactly one injected synchronous commit callback, with typed `BerryStandardToolPurchaseReceipt`, production prices and before/after balance/charge state.
- [x] The **three real session purchase methods** use that same checkout orchestration. Callback preserves the existing Undo-history invalidation, wallet decrement, charge increment, real spending-ledger recording, and `save()` behavior. Rejected purchases never call the commit callback.
- [x] The QA-only `BerryQAIsolatedWallet.buy()` also uses the same checkout executor, retaining its purely in-memory mock wallet and charge counts.
- [x] `BerryEconomyLedger` now supports an injected `UserDefaults` instance. Its existing `.shared` instance still defaults to production `.standard` and uses the exact same keys, observable counters and spend/earn logic.
- [x] `BerryGameSession` initializer supports `checkoutDefaults: UserDefaults = .standard`, `checkoutLedger: BerryEconomyLedger? = nil`; normal `BerryGameSession()` creates the original game behavior and key names.
- [x] `BerryGameSession.save()` writes standard inventory and Endless snapshots through the instance's selected preferences store. No inventory key changes, no schema migration, no game version change. Daily/Story singleton-backed operations are **not yet injectable or D0d-certified**.
- [x] Added **9 new actual-session XCTest methods** with unique disposable preference suites, exercising Undo/Shuffle/Hint, multiple purchases, insufficient funds and overflow no-write guards, session reinitialization from saved inventory, old missing-Hint field compatibility, real ledger counters, and proving normal `.standard` inventory/spending keys unchanged.
- [x] New named iPhone 16e [D0d CI workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0d-real-checkout-isolation-iphone16e.yml) runs the existing **6 D0 + 11 D0b + 10 D0c + 4 BerryEconomy + 9 D0d = 40 selected XCTest methods** and a Release build that excludes all internal QA panels.
- [x] [D0d GitHub Actions #44866663042](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44866663042) **SUCCESS**, confirmed from actual job log: **40/40 selected XCTest cases passing, zero failures**, Release builds with QA-only panels excluded; no IPA created.
- [ ] Physical owner iPhone 16e checks for normal purchased inventory, persistent history, no double-debit, drawer resets and existing save resume. Do not mark fully player-accepted from simulator results.
- [ ] Test crash/partial-commit recovery and multi-key atomicity separately: standard UserDefaults inventory and spending ledger are **not an atomic database transaction**.
- [ ] Extend dependency injection before claiming full daily, Story, Boutique, special-tool, migration or rewards coverage.

## Safety boundary
- This branch deliberately changes *how standard tool checkout chooses its commit destination* without changing what the production destination normally is.
- Only the three **standard-tool purchase methods** and isolated test helpers are verified with injection. Other `BerryGameSession` operations still depend on legacy app-wide singletons; do **not** call those on an injected test session and claim isolation.
- Avoid blanket replacing `UserDefaults.standard` across unrelated gameplay, since it could damage saved state or progression compatibility.
- Actual prices: Undo 40, Shuffle 50, Hint 35 strawberries. Real player history, scores, game modes, ownership, 8/12/24 Endless saves and approved artwork remain unchanged by this development branch.

## Device acceptance sequence after separately approved build
- [ ] Verify existing real wallet before any testing. Use internal Developer Garden `State & Timer Lab` to run six disposable scenarios and Discard; real balance unchanged.
- [ ] In real game purchase one Undo, then close and reopen; confirm exact wallet change, one helper charge, and persisted totals, with Undo history semantics unchanged.
- [ ] Try insufficient-funds Shuffle and Hint actions while blocked; verify no berry debit or phantom charges.
- [ ] Confirm existing Endless 8/12/24 saves and owned cosmetics were not modified by testing.
- [ ] Return to Developer Garden; all test histories and balances reset after leaving the sandbox.

**No new images, no new public cheat menu, no IPA/version bump, no PR merge.** D0d is a carefully bounded layer of our *whole-game* QA infrastructure, not a completed game release.


## CI attempt history
- [x] [Initial D0d run #44866568830](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44866568830) stopped **before Xcode build or XCTest** because the copied workflow still expected direct `BerryStandardToolTransaction.purchase` references inside GameSession and the QA lab. D0d intentionally replaces those call sites with `BerryStandardToolCheckout.purchase`.
- [x] Corrected the workflow to verify both checkout call sites and the reducer implementation directly; [fresh run #44866663042](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44866663042) started. Do not report the initial workflow-check failure as an app or XCTest failure.
- [ ] Await terminal compile and test results from fresh run, then update acceptance status. Original artwork, save keys and app version remain unchanged.


## ✅ D0d final automated acceptance · November 20, 2026 (Arizona)
- [x] [GitHub run #44866663042](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44866663042) terminal **SUCCESS** and logged `** TEST SUCCEEDED **` after named iPhone 16e simulator execution.
- [x] Exact suite counts: `BerryDeveloperSandboxTests` **6/6**, `BerryDeveloperStateLabTests` **11/11**, `BerryStandardToolTransactionTests` **10/10**, `BerryEconomyTests` **4/4**, `BerryStandardToolCheckoutIsolationTests` **9/9**. Total **40/40**, **zero failures**.
- [x] Production Release configuration successfully compiled, QA sandbox/panel symbols excluded; source, art and audio verification passed; no IPA or public release.
- [x] The nine D0d cases executed actual GameSession standard-tool purchases with disposable real UserDefaults/ledger and tested no mutation to normal player inventory and spend keys.
- [ ] **Not yet proved:** physical iPhone 16e UX, real multi-key crash atomicity, Store/Boutique checkout UI, Daily and Story saves, premium charges, quest/birthday reward writes, iPhone install/IPA, or full 59-scenario coverage. Keep draft PR.
