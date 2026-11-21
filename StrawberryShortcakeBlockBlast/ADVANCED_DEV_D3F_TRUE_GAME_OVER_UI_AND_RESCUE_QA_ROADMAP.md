# 🍓 Berry Berry Blast | D3f Story Game Over, Real Rescue Buttons & Physical UI QA

**Status: audited roadmap only, not source-implemented.** Based on the I2 integrated source (`BerryGameView.swift`, `BerryGameSession.swift`). D3d 139/139 and I1 143/143 simulator tests are verified; I2 152 remains pending at this checkpoint. Preserve all player saves, original reward prices, Story chapter states, art/audio and iOS16.

## Exact current player path to verify

- Game Over is shown by `BerryGameView` when `session.gameOver` becomes true, with an overlay explaining the result, score/lines/moves and Story chapter objective. Daily ends at midnight with **no Game Over rescue controls**.
- `continueRescueOptions` presents **Shuffle** (owned or purchase) and **Golden Strawberry** (owned or 250-berry combined checkout) as independently gated cards. The Golden route opens `confirmGoldenStrawberry`; a second modal offers a purchase/use action or **Keep My Strawberries** cancellation. On successful checkout, `dismissRescueAfterSuccess()` clears the Game Over overlay and returns to the same game.
- The engine's `canRescueWithShuffle` and `canRescueWithGoldenStrawberry`, the current mode and existing charges/currency govern action availability. The Story chapter and current score should survive rescue. The Golden rescue is limited to once per run.

## Safety discovery before any QA implementation

**Important:** `BerryGameSession.buyAndContinueWithShuffle()` currently still writes directly to `BerryEconomyLedger.shared` and `UserDefaults.standard` for receipt persistence. In an injected temporary GameSession, calling that real combined purchase could charge or write the *owner's* ledger/receipts. D3f **must first route these two writes through the already-injected `checkoutLedger` and `checkoutDefaults`**, just as D2c corrected the Golden Strawberry flow. Preserve the current `BerryEconomy.shufflePrice`, existing save keys and original live behavior. This is a prerequisite, not optional polish.

The Story chapter selection/achievement UI additionally uses real `@AppStorage` and `BerryProgression.shared`. Do not fake chapter completion with writes to the normal player's preferences. Use a fully isolated DI fixture for method-level checks and a separate clearly labeled native UI-test build for actual SwiftUI tap paths. Do not confuse the two.

## D3f acceptance tests
- [ ] Build **true blocked-run legal Story fixture**: full/nonplaceable game board and tray after a legitimate prior move, actual `gameOver=true`, valid rescue routes. This is not equivalent to D2c's occupied but still playable Endless board fixture.
- [ ] Simulate a **real Story Golden Strawberry owned-charge rescue** and **combined 250-berry purchase**. Check board cleared, chapter/score/moves/earned berries unchanged, real charge or wallet spends exactly once, persisted receipts/ledger, 24×24 saved-garden independence, reopen behavior and repeat blocked.
- [ ] Actual **Shuffle-owned** and **buy-and-continue** paths: if a legal new tray can be produced, use/debit exact count once; if not, do not charge. Verify all receipts/ledger writes use the disposable store, no normal player data changed.
- [ ] Failure cases: insufficient 250 berries, no available rescue, golden already used, cancel purchase, two rapid taps, reopen with one-charge balance and already-claimed annual/Story reward. None should double-charge or double-claim.
- [ ] Native UI automation under an **explicit internal QA launch profile**, with actual visible Game Over overlay, correct two-column/side-by-side rescue cards, confirmation alert and cancel, button accessibility and no blank card icons. Include narrow iPhone16e screen and dynamic type.
- [ ] Daily, Classic, Blitz/Nightmare mode restrictions and rapid lock/unlock mid-overlay. Daily attempt must not be reopened; Story chapter and lifetime rewards must not be reset or granted twice.
- [ ] Real owner **physical iPhone16e** review of the Game Over flow, actual taps and readable tone, plus force-close/reopen and all 8/12/24 Endless saves and wallet totals.
- [ ] Source/CI gates: named iPhone16e simulator, exact selected XCTest final count with zero failures, **production Release binary excludes all internal QA**, no IPA and no merge until owner approves.

## Whole game still pending

Complete Story/Daily/Quest native UX, birthday rewards and settings on physical hardware, true final approved Village/Quest/Journal illustrations, seasons/Halloween/Christmas/Thanksgiving/birthdays with day/night variants, Build4.7/4.8 Day/Night design, Build5 Village/quest progression and Build6 separate Moonberry Night Market and story mechanics. The Developer Garden exists to accelerate **testing all game mechanics**, not replace game development.

**Never claim that an isolated handler test proved a player-facing SwiftUI touch path.**
