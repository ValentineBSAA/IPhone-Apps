# 🍓 Berry Berry Blast · D1b Cottage and Premium Purchase Save-Safety QA

**Scope:** new isolated D1b draft feature branch, based on verified D1a. **Product version remains 0.5.16 / internal Build 46, iOS 16+.** No new IPA, public release, asset import, pricing change or merge.

**Parent:** [Advanced Developer Garden epic #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61) and [D1a #70](https://github.com/ValentineBSAA/IPhone-Apps/pull/70).

## Why this milestone was necessary
- D1a protected Cosmetic + Undo/Shuffle/Hint menu purchases from accidentally clearing a saved Endless 8×8 slot by changing purchase-only persistence to saveInventoryOnly.
- Source audit found `buyCottageDecoration()` and `buyPremium(_ id:)` still calling the generic `save()` from potentially unplayed menu sessions. That path removes the 8×8 Endless saved board when current engine.moves == 0.
- The existing `UserDefaults.standard` and `BerryEconomyLedger.shared` references in those purchases prevented true isolated session tests.

## Production-connected D1b changes
- [x] Cottage ownership, premium charges and permanently owned premium upgrades reload from the session's injected `checkoutDefaults` on init. Normal production continues using `UserDefaults.standard`.
- [x] Cottage purchases use the session's real injected economy ledger and preferences. They save inventory but **do not rewrite/delete an unrelated board**.
- [x] Purchasing any premium item uses the same injected wallet and real ledger, and writes charges/ownership with `persistPremium(boardChanged: false)` (inventory-only). Normal premium *usage*, e.g. Trowel, Seed, Golden Strawberry, Twister, continues to use `persistPremium()` with board state saving.
- [x] Prevent integer overflow from incremental premium tool-charge purchases before debit. Original six SKUs and amounts untouched: Trowel 150, Twister 200 (three charges), Seed 230, Golden Strawberry 250, Pantry 600 (permanent), Spyglass 900 (permanent).
- [x] Keep existing escalating Cottage prices 60, 90, 130, 180, 240, 300; current ownership, account keys and board save migration unchanged.
- [x] Skip shared progression-celebration broadcast in disposable injected sessions. Normal purchases still celebrate upgrades.

## Ten new real GameSession XCTests
- [x] Cottage first and second purchases preserve exact prices, ledger and restart ownership.
- [x] Cottage unavailable / one-berry-short attempts do not spend or write inventory.
- [x] Every premium item debits the canonical price, produces exact charges or ownership, records real isolated ledger spends and reloads.
- [x] Unknown/underfunded premium product requests reject without mutations.
- [x] Permanent Pantry and Spyglass purchases cannot be duplicated after reopening.
- [x] Overflow of three-charge Twister stack rejects before money is taken.
- [x] Menu Cottage plus premium shopping preserves byte-identical 8/12/24 Sweet Endless saves and unchanged engine bytes.
- [x] Previously owned Cottage and permanent/consumable premium supplies remain owned.
- [x] Invalid on-board Trowel action spends no charge and does not change any saved Endless board.
- [x] Isolated production-session tests leave original player UserDefaults keys byte-identical.

**CI expectations:** run 10 new D1b methods together with the prior **64 D0–D1a selected** methods on the explicitly named **iPhone 16e simulator**, compile Release with `BERRY_INTERNAL_QA` internals excluded, run source/art/audio verification, produce **no IPA**. Tests authored does not mean tests passed: record actual final workflow conclusion, XCTest count and failure summary before acceptance.

Workflow: [Berry D1b iPhone 16e](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d1b-cottage-premium-iphone16e.yml) (CI infrastructure only is on `main`, checkout explicitly selects the D1b feature branch).

## Not covered and not allowed to be claimed as completed
- [ ] Physical iPhone 16e tapping, screenshots, purchase/restart/re-equip and actual game save acceptance.
- [ ] Power-loss durability or atomic multi-key purchase rollback for Cottage/premium. UserDefaults has no multi-key transaction guarantee. Additional journal design is needed before claiming it.
- [ ] Real in-game premium board-mutation save round-trips, full SwiftUI shop purchase tap paths and every mode's progress state. D1b preserves the original board-changing method behavior but does not certify it.
- [ ] New one-tap Developer Garden UI for premium/Cottage; current tests are XCTest, not interactive cockpit scenarios yet.
- [ ] Remaining singleton-dependent Story, Daily, birthday/quest and Night features.
- [ ] Full regression and physical owner acceptance before any IPA, build bump, merge or release.

## Later developer cockpit work
D1c should expose these isolated purchase scenarios in a two-column grid using non-player test state, PASS/FAIL receipts and Reset/Discard, without enabling the normal live-strawberry QA grant implicitly. Keep proper distinction between sandbox scenarios, real production checkout in isolated dependency-injected tests, and manual owner iPhone acceptance.
