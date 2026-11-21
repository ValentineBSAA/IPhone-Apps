# 🍓 Berry Berry Blast | D2c Premium Action and Rescue QA

**Status:** Production-connected D2c code and eight isolated XCTest methods have been committed to a new **draft development branch**, based on D2b. CI and owner physical QA remain separate. No IPA, merge or version bump. iOS 16+, `com.valentinebsaa.berryblockblast`, v0.5.16/internal Build 46 unchanged.

## Why this milestone matters

D2a proved basic Trowel, Seed and Golden Strawberry usage survives saved-game reopening. D2b added one-tap internal QA cards. Remaining actual premium action handlers, including Ribbon Twister and Picnic Pantry, and the combined pay-to-rescue Golden Strawberry flow needed real storage-isolated coverage.

**Safety bug identified:** `BerryGameSession.buyAndUseGoldenStrawberry()` still wrote spending to `BerryEconomyLedger.shared` and reward receipts to `UserDefaults.standard`, bypassing its already-injected test suite. Calling that method in an isolated QA session could have altered the real player's records. D2c routes those **two existing writes** to `checkoutLedger` and `checkoutDefaults`. Normal sessions still use their original `.shared` ledger and `.standard` store. No pricing or behavior changes. Explicitly removed an inaccurate claim that multi-key persistence is crash atomic.

## Real-session isolated test cases (eight)
- [x] Valid Ribbon Twister rotates a **known non-symmetric** piece, consumes one of three charges and restores tray orientation/charges after closing and reopening a saved Endless run.
- [x] Missing/symmetric/invalid Twister targets reject without spending a charge or writing a saved board.
- [x] Valid permanently owned Picnic Pantry stashes a known tray piece, survives restart, swaps the piece back and persists both states without spending berries.
- [x] Unowned Pantry and empty/invalid slot reject without writing a save.
- [x] Valid **24×24 Golden Strawberry** clears occupied cells in all four 12×12 sections, preserves score and rescue limit, and leaves independent 8×8/12×12 saved garden bytes unchanged.
- [x] Combined **250-berry buy-and-use Golden Strawberry** executes the production method on a genuine occupied, one-move Endless board with separate store/ledger; verifies debit once, exact spending, one receipt, cleared board, unchanged score and one-rescue limit after reopen.
- [x] Combined rescue fails without debit on an insufficient wallet, existing purchased charge or empty board. **This verifies the handler, not a true player-facing Story Game Over screen.**
- [x] Isolated valid Twister, Pantry, and combined buy+rescue paths do not change any normal player wallet, premium inventory, receipts, ledger, migration, board-size, score or Endless saved-game keys.

All fixtures use actual `BerryGameSession`, `BerryEngine`, the original 250-berry price and genuine `BerryEconomyLedger`, with disposable UserDefaults suite storage that is removed after each test. They do not substitute a mock purchase policy or treat manual user taps as tested.

## CI gate

[GitHub Actions D2c run #44871838416](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) selects **102 XCTest cases** (94 prior D0–D2b + eight D2c), compiles a Release bundle without internal QA models/panels, performs source/art/audio/iOS16 integrity checks on a **named iPhone 16e simulator** and creates **no IPA**.

- [ ] **D2b run #44871494518 must be confirmed terminal success**, or its test/code failures repaired before accepting the cumulative baseline.
- [ ] D2c run must be terminal success with **102/102 selected tests, zero failures** and confirmed release compile and no-IPA gate, or failures diagnosed and repaired. Test code authored is not a passed test.
- [ ] Owner physical iPhone 16e QA for real Twister/Pantry/Mega/Golden rescue taps, UI small-screen spacing, repeated reopen, game-over behavior and saved-game integrity.
- [ ] Add internal two-column QA cards for new D2c fixtures **after handler tests pass**; do not conflate direct method tests with actual app gameplay touch paths.

## Open work and no overclaims

UserDefaults has **no guarantee of crash-atomic multi-key writes**. A fail-safe journal and process-kill/restore QA would be necessary before guaranteeing combined rescue payment consistency under power loss. The D2c test proves normal success and expected rejection, not durable disaster recovery.

Story/Daily singleton-backed progression and authentic Game Over UI are not yet covered by these D2c tests. The 24×24 test uses a legal one-move playable fixture with occupied cells in each section, not an actual user-driven high-round death. Complete game mode/UI/quests/seasonal/Night/approved art regression and owner approval remain separate.

Next candidate: **D2d internal one-tap premium Tool Action Lab expansion**, then D3 Story/Daily/quest/clock and the whole-game Build 4.7/4.8/5/6 roadmap. No merge, version bump, IPA or release permission implied.
