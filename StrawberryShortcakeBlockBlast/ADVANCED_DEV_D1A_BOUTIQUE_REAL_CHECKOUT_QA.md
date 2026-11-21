# 🍓 D1a · Real Berry Boutique Checkout and Saved-Garden Safety

**Date:** November 20, 2026 (Arizona). **Status:** Implemented on a new D1a branch; CI/device acceptance pending.  
**Baseline:** [D0e PR #68](https://github.com/ValentineBSAA/IPhone-Apps/pull/68), 48/48 selected iPhone 16e simulator tests green.  
**Master workstream:** [Advanced Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61).

## Why this matters to the entire game
We are expanding beyond the original standard Undo/Shuffle/Hint purchase system. Berry Boutique contains real ownership and pricing logic. A purchase must persist the correct cosmetic, deduct exactly once, protect previously owned items, and **never erase a saved Endless garden just because the player opened the Boutique from a fresh menu session**.

## Source changes
- [x] `BerryBoutiquePurchasePolicy.swift`: authoritative original catalog of 11 eligible cosmetics and existing prices, including one free strawberry-fruit block option; excludes unapproved seasonal placeholders, free board-surface switching and unknown IDs.
- [x] `BerryGameSession.buyCosmetic(id:cost:)` now uses the canonical catalog and an exact-price check instead of a duplicated inline lookup. Unknown, discounted/spoofed or already-owned items are refused before wallet or ledger side effects.
- [x] Real Boutique purchases now use **injected `checkoutDefaults` and `checkoutLedger`**, as the standard-tool system does; production `BerryGameSession()` continues using the original standard defaults and shared ledger.
- [x] Real GameSession init loads **Boutique ownership and rewards** from the selected injected store rather than accidentally mixing normal owner history into isolated QA scenarios; production behavior is unchanged for normal instances.
- [x] Separated `saveInventoryOnly()` from board-saving `save()`. Cosmetic and standard-tool purchases only change inventory/ownership, so they no longer invoke board-save logic that could clear the 8×8 Endless slot when buying from a fresh menu session.
- [x] Existing actual gameplay placement, new-game, tool consumption and board-affecting operations continue to use `save()` and their established save/restore behavior.
- [x] The Boutique view's existing two-column layout, item titles, real prices, and equipped appearance settings are unchanged. No image work.

## Automated test additions
- [x] `BerryBoutiqueCheckoutIsolationTests`: **10 new actual `BerryGameSession.buyCosmetic` methods** tested with disposable UserDefaults suite and real injected `BerryEconomyLedger`.
- [x] Test exact checkout + ownership + reward receipt + real ledger.
- [x] Test insufficient funds; wrong price/unknown item/seasonal placeholder; already-owned no repeat debit even after restart.
- [x] Test free strawberry skin (once, no spend); legacy owned items and equipped board/block appearance unchanged; reward list still capped at 20.
- [x] Test saved **8×8, 12×12, 24×24 Endless slots stay byte-for-byte unchanged** by menu Boutique and standard helper purchases; original user defaults and spending receipts remain untouched.
- [x] [iPhone 16e GitHub Actions D1a workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d1a-boutique-isolation-iphone16e.yml): Release compile without QA tools, selected D0–D0e **48 prior tests**, existing Build 4.4 Boutique tools **6 tests**, and **10 new tests = 64 selected**.
- [ ] Confirm terminal CI result and exact 64/64 from logs. Do not infer green from presence of source or started job.
- [ ] Owner physical iPhone test of Boutique buy/reopen/equip/unequip and saved progress after a future approved candidate; still required separately.

## Important scope boundaries
- Cosmetic ownership/ledger/inventory are still separate UserDefaults keys. This milestone **does not make cosmetic purchases crash-atomic** or extend the D0e pending-intent journal to Boutique. That needs a separate design/recovery review before a shipping claim.
- The generic `refreshEconomyFromDisk()` and other singleton-backed UI/premium operations are **not D1a-isolation-certified**. Tests use the real purchase handler with a directly constructed injected session, not every view interaction.
- No new price changes, cosmetics added/removed, paid-for items reset, actual user data, image generation, version bump, merge or IPA.

## Future owner QA after a signed test candidate is approved
- [ ] Note wallet and the three Endless saved board sizes.
- [ ] Buy an unowned cosmetic at the listed price, see it in Inventory and equip it.
- [ ] Force-close/reopen and confirm ownership remains, wallet spent exactly once, score and board unchanged.
- [ ] Remove/equip a cosmetic and confirm original board/card controls and selected settings remain intact.
- [ ] Attempt a second purchase of the same owned cosmetic and an item with insufficient berries: no extra charges.
- [ ] Test a normal Helper checkout from the Boutique menu, then return to a saved **8×8** Endless run. The unfinished board must remain available.
- [ ] Verify Night/Story/Daily and old licensed skins have not been accidentally activated or changed.

**Release gate:** Await CI and physical-device acceptance, then full-game regression. D1a is a bounded feature validation step in the larger Berry Berry Blast roadmap.


## Follow-up save-risk audit
- [x] Confirmed purchase-only save hazard in **cosmetic and standard-helper** paths, addressed by `saveInventoryOnly()` with 8/12/24 sentinel-slot regression.
- [ ] **Not yet fixed or tested** for `buyCottageDecoration()` and `buyPremium()`: those paths still call the generic `save()` or `persistPremium()`, and may trigger the same 8×8 unplayed-board cleanup when invoked from a separate menu session. In D1b, inject their real data stores, preserve valid board state, and write explicit no-change tests for every Endless size.
- [ ] Also audit `buyAndContinueWithShuffle()`, Golden Strawberry and other *board-changing* premium actions separately, because they may legitimately need a board snapshot. Do not blanket-change all save calls without checking gameplay semantics.
