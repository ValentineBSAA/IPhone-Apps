# 🍓 D2c Safe Premium-Tool Actions and Game Over Rescue · Design Gate

**Status: D2c real-handler source and eight isolated regression tests IMPLEMENTED on draft PR #75, CI and owner QA pending. Internal on-device D2d one-tap UI expansion and Story Game Over view remain PLANNED ONLY.** Do not count unverified checks as passed, merge or release from this roadmap. This file is an explicit continuation of [D2b Tool Action Lab draft PR #74](https://github.com/ValentineBSAA/IPhone-Apps/pull/74) and the [master QA epic #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61).

**Entry condition:** D2b [94 selected iPhone 16e XCTest run #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) must finish green, with QA source excluded from production Release and no IPA. Its owner physical testing remains a separate step and is not automatically accepted.

## 1. Real Ribbon Twister use, saved and reopened
- Prepare a saved one-move 8×8 Endless board with a **non-rotationally symmetric** L-shaped tray piece deliberately retained in a known slot. Avoid relying on randomly replenished production tray order or trying dozens of turns.
- Seed one real Twister charge in a disposable suite; call real `BerryGameSession.useRibbonTwister(slot:)`; compare piece's point set before/after rotation, remaining charge (0), unchanged wallet/score, saved board/tray round trip and new instance reload.
- Reject attempts with zero charges, missing slot or a rotationally symmetric piece; no board/charge changes on rejection. Keep rotation code and original purchase prices untouched.
- Use an actual `BerryEngine` test fixture and selected `checkoutDefaults`, never a separate mock algorithm.

## 2. Real Picnic Pantry use and restoration
- Persist an Endless board with at least two tray pieces; stash a known piece using actual `BerryGameSession.usePicnicPantry(slot:)` with the permanent Pantry purchased/seeded in an isolated suite.
- Verify the stored `engine.pantryPiece` contents and tray state after save/reopen; on a valid second swap, verify ownership remains permanent and no berry debit or consumption. Test empty slot rejection and no saved-game mutation.
- The engine can refill if the last piece is stashed; do not assert specific randomly generated refill pieces. Validate the reserved piece and legally playable state instead.

## 3. 24×24 Golden Strawberry rescue
- Seed a legal 24×24 Endless game with occupied cells in multiple sections, moves > 0, score and charge; call actual `useGoldenStrawberry()`.
- Verify all four patches clear, score stays intact, `goldenRescueUsed` persists, no duplicate rescue, and **8×8 plus 12×12 saved games remain byte-identical**. Existing owned premium charges and wallet unchanged except for exactly one used rescue charge.
- Make separate invalid/empty-board tests. No real-device action yet.

## 4. Buy-and-rescue emergency Game Over: necessary safety refactor
**Audit finding:** `BerryGameSession.buyAndUseGoldenStrawberry()` currently writes through **`BerryEconomyLedger.shared`** and **`UserDefaults.standard`** for ledger/reward log, even when `checkoutDefaults` is injected. It MUST NOT be called inside a disposable QA suite as-is because it may mutate the owner's real preferences.

- First route exactly the Game Over combined purchase's ledger and reward log writes through `checkoutLedger` and `checkoutDefaults`, preserving normal player behavior and original 250-berry rescue cost. Do not modify premium grant amounts, progression or scores.
- Then add an isolated actual `BerryGameSession` test with a genuinely blocked board but `canContinueWithGoldenStrawberry` true, no prior rescue, 250 berries, zero Golden charges; buy + rescue once; reopen and verify wallet 0, ledger 250, one reward receipt, entire board clear and one-rescue guard.
- Invalid rescue (empty board, already rescued, insufficient wallet, unsupported Classic/Blitz/Nightmare) must not charge or mutate. Full Story/Daily singletons need separate careful injection before claiming isolated mode tests.
- **Important:** UserDefaults multi-key writes are not power-loss atomic. A separate crash journal and process-kill test are required before promising durable purchase-and-rescue transactions.
- End-to-end actual user-facing SwiftUI Game Over and purchase tap paths are a separate UI/device test, not covered by method calls alone.

## 5. Internal two-column Developer Garden expansion and acceptance
- Only after successful real handler regression, add one-tap **Tool Action Lab** cards for Twister, Pantry, 24×24 Golden and safe combined purchase+rescue, with Expected/Actual, PASS/FAIL, reset, independent disposable suites and live-user-key nonmutation.
- Keep `#if BERRY_INTERNAL_QA` for diagnostics, avoid leaking any lab symbol into Release, maintain iOS16, `com.valentinebsaa.berryblockblast`, v0.5.16/internal Build46 until an explicitly approved new version.
- Preserve the existing modes, scores, inventories, save migration, 51 audio tracks, 16 effects and approved artwork.
- Simulator **named iPhone 16e**; never substitute another model. Physical iPhone acceptance and an eventual full-game regression remain distinct gates. No IPA until owner requests and tests actually pass.

## 6. After D2c, continue the entire game roadmap
D3: Daily, Story, quest/birthday progress and clock boundaries using injected persistence. D4: seasonal approved icon and fallback integration. Build 4.7/4.8: Day/Night entire UI and core mode visual parity. Build 5: Daily Quests, Village evolution; Build 6: genuinely separate Night Market/Moonberry economy, modes and Story. Maintain the approved source-art library and the project's existing issue links. **Developer testing is tooling for the whole game, not the game itself.**

### November 20 implementation checkpoint
- [x] Real Twister, Pantry, 24×24 Golden rescue and combined pay/rescue **handler** tests are now coded in [D2c PR #75](https://github.com/ValentineBSAA/IPhone-Apps/pull/75), with the relevant shared wallet/receipt writes injected. Eight new XCTest methods.
- [ ] [D2c 102 selected simulator XCTest #44871838416](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) pending at the time of this edit. Verify terminal logs before claiming pass.
- [ ] The tests use occupied playable Endless fixtures, **not authentic player-facing Story Game Over flow**. Preserve remaining UI/Game Over, physical QA, crash recovery and whole-game roadmap tasks.
