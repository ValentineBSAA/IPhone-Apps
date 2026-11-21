# 🍓 D0c · Production-Shared Undo / Shuffle / Hint Transaction Rules

**Checkpoint:** November 20, 2026 (Arizona).  
**State:** Draft code implemented; awaiting CI and physical-owner QA. **Not merged, not released, no new IPA.**

## Why D0c matters
D0b's mock wallet tests were useful but did **not** prove the real in-game purchase methods followed the same policy. This small D0c slice extracts a **single pure transaction reducer** and routes the live `BerryGameSession.buyUndo()`, `buyShuffle()`, `buyHint()`, `useHintIfPossible()` code paths through it. The internal Developer Garden's isolated test-wallet fixture uses this exact same reducer.

## Actual source changes
- [x] Added `BerryStandardToolTransaction.swift`, compiled in both Release and QA: `purchase(berries:charges:price:)` returns either updated currency/charge counts or nil **without side effects**; `consumeCharge(_:actionIsValid:)` guards invalid/empty tool usage.
- [x] Updated **real production** `BerryGameSession.buyUndo`, `buyShuffle`, `buyHint` to require successful shared reducer before mutating existing wallet fields. Existing nominal prices, the Undo snapshot invalidation, spend ledger entry and `save()` call remain as before. Added explicit guard against negative balances and `Int.max` charge overflow.
- [x] Updated real `BerryGameSession.useHintIfPossible` to use shared charge consumption only **after** an eligible hint is found. The existing `gameOver` and `suggestedMove()` guard remains intact.
- [x] Updated the D0b `BerryQAIsolatedWallet` to invoke the **identical** shared reducer for mocked purchase and charge use. It still mutates only in-memory sandbox state, never production `UserDefaults`.
- [x] Added 10 `BerryStandardToolTransactionTests`: all three exact prices, all three one-short prices, invalid and negative inputs, charge overflow, count preservation, consumption only on valid action, QA parity.
- [x] Existing 6 D0 and 11 D0b tests remain selected in the new named iPhone 16e CI workflow; the existing `BerryEconomyTests` are also included.
- [ ] [D0c CI workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0c-shared-tools-iphone16e.yml): verify actual terminal successful iPhone 16e regression log and Release sandbox exclusion; don't mark pass based on commit presence.
- [ ] Real-device owner tests and complete shop/ledger/save-disk adapter injection remain separate gating work.

## Exact behavior parity
| Actual purchase/usage | Before | After this refactor |
| --- | --- | --- |
| Undo (40 strawberries) | Spend 40, +1 Undo, undo snapshot cleared, existing ledger/save | Same, but safe reject for invalid/overflow states |
| Shuffle (50 strawberries) | Spend 50, +1 Shuffle, undo snapshot cleared, existing ledger/save | Same, plus guard |
| Hint (35 strawberries) | Spend 35, +1 Hint, undo snapshot cleared, existing ledger/save | Same, plus guard |
| Use Hint | Only when not game over, charge exists, legal suggestion found | Same, with shared no-negative charge decrement |
| Insufficient funds | No purchase | Unchanged, now exercised by same production reducer in QA |
| Int.max charges | Potential overflow | Purchase safely rejected without currency debit |

## Non-goals / transparency
This is **not** a complete production checkout end-to-end harness. The QA reducer tests validate the actual shared decision logic called by the production purchase methods, but `BerryGameSession`'s `UserDefaults`, `BerryEconomyLedger.shared`, inventory persistence and entire Boutique purchase flow are **not injected or executed in an isolated device test** yet. The next incremental step is an isolated storage/ledger adapter for actual session logic, not a wholesale gameplay refactor.

No image generation, new currency, new developer cheats, GameCenter changes, mode rule changes, calendar changes, saved-data migration, Story/quest/daily rewards or version bump.

## Manual iPhone owner acceptance, when the internal test candidate is approved
- [ ] In Developer Garden `State & Timer Lab`, run Exact-Price Undo: PASS, 0 **test** berries, 1 **test** Undo charge.
- [ ] Run One Berry Short and Zero Tool Charge: both PASS, no negative counts or debit.
- [ ] Return to live game and confirm wallet, owned Undo/Shuffle/Hint, actual saved game, cosmetic selections are unchanged by lab scenarios.
- [ ] Separately test **real** purchase through normal UI with enough and insufficient berries, and an invalid Hint with no suggested move; confirm charge behavior.
- [ ] Run the existing Build 4.5 blocked-charge regression and recheck any completed tool behaviors, no full-length scoring grind required.

**Status discipline:** A green simulator proves selected code rules; it does not authorize merge, IPA, physical acceptance, or every planned Developer Garden scenario.
