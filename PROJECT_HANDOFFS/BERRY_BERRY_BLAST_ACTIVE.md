# 🍓 Berry Berry Blast | ACTIVE DEVELOPMENT HANDOFF

**Maintained November 20, 2026 (America/Phoenix).** Use this as the first recovery entry when a ChatGPT conversation fills up. This is a factual checkpoint of GitHub refs and acceptance gates, **not permission to merge or publish**.

## Exactly where to resume
- Repository: `ValentineBSAA/IPhone-Apps`, game: `StrawberryShortcakeBlockBlast/`.
- **Active source branch:** `feature/berry-advanced-dev-d1c-real-commerce-cockpit` (stacked on D1b and D1a).
- **Current draft PR:** [#72 D1c internal one-tap real Commerce Lab](https://github.com/ValentineBSAA/IPhone-Apps/pull/72), based on [#71 D1b Cottage/premium saved-garden safety](https://github.com/ValentineBSAA/IPhone-Apps/pull/71), which is stacked on **[D1a PR #70](https://github.com/ValentineBSAA/IPhone-Apps/pull/70)** and prior D0–D0e.
- **Active CI (as of this handoff update):** [D1b Actions #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684): 74 selected, and [D1c Actions #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471): 80 selected, both pending terminal XCTest logs at last check. Do not call either pass until confirmed. Neither workflow creates an IPA.
- **Last VERIFIED green:** [D1a Actions #44868413961](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868413961), terminal SUCCESS, **64/64 selected XCTest passed, zero failures, named iPhone 16e simulator**, and Release compiled with internal QA panels excluded.
- **Bundle/version retained:** `com.valentinebsaa.berryblockblast`, **v0.5.16 / internal Build 46**, iOS 16.0+; source-of-truth is the active branch's `project.yml`. Root game README on `main` is older and should not be used as latest version proof.
- Owner has already physically validated Build 4.6's basic hidden Developer Garden / numeric QA strawberries behavior on iPhone 16e, but the newer D0–D1b labs have **no owner physical device acceptance** yet. The iPhone 14 Pro QA requirement is retired.

## Developer Garden coverage, in order
1. Build 4.6 preserved hidden Developer Garden, existing wallet grant with confirmation, diagnostics, save inspector, economy, timed clock and combo previews.
2. D0 internal `BERRY_INTERNAL_QA` real-engine isolated Scenario Sandbox: one-row 11-point line clear and blocked occupied-cell move; six XCTest accepted.
3. D0b separate disposable State & Timer Lab: exact Undo, insufficient Shuffle, zero Hint, in-memory good/bad saves, virtual timer. D0/D0b 17/17 XCTest accepted.
4. D0c production-shared standard helper policy; 31/31 selected tests accepted.
5. D0d actual injected standard helper purchase+inventory save+real ledger; 40/40 selected tests accepted.
6. D0e best-effort interrupted standard helper purchase intent replay; 48/48 selected tests accepted, **not power-loss durable**.
7. D1a real Boutique purchases, original 11 prices, duplicate ownership protection, inventory-only saves, independent 8/12/24 Endless protection; 64/64 accepted **on simulator only**.
8. **D1b now staged:** real Cottage+premium purchases use selected isolated ledger and preferences; inventory-only purchases don't delete a saved Endless board, while actual tool use retains full board saving. [Detailed D1b QA document](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d1b-cottage-premium-save-qa/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D1B_COTTAGE_PREMIUM_SAVE_QA.md), 10 targeted new XCTest, pending CI.
9. **D1c source implemented and unmerged:** internal two-column **Commerce Lab** one-tap scenario cards, PASS/FAIL, expected vs actual, Discard. Seven internally disposable real GameSession checkout/use tests, six new unit tests, separate [PR #72](https://github.com/ValentineBSAA/IPhone-Apps/pull/72). Simulator and owner physical acceptance pending. Next broaden valid premium-tool board effects, Story/Daily/quest/migration, seasonal and Night mechanics.

## Master scenario catalog
[Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61) and [roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_GARDEN_QA_COCKPIT_ROADMAP.md) link everything. [Machine-readable catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **77 contracts = 20 simulator verified/device pending, 4 D1b implemented/CI pending, 7 D1c one-tap Commerce Lab implemented/CI pending, 44 planned, 2 future Night not implemented** at this handoff. 77 is **not** a count of passed tests.

## Whole-game roadmap preserved separately
- [Night Garden epic #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23): Build 4.7 Day/Night premium foundation, Build 4.8 whole-screen parity/fireworks, Build 5 Daily Quests/Village, Build 6 separate Moonberry currency and transactional Night Market.
- Different Night experience, modes, Story and unique shop catalog have dedicated [#33](https://github.com/ValentineBSAA/IPhone-Apps/issues/33), [#34](https://github.com/ValentineBSAA/IPhone-Apps/issues/34), [#35](https://github.com/ValentineBSAA/IPhone-Apps/issues/35), [#36](https://github.com/ValentineBSAA/IPhone-Apps/issues/36). Mechanics/content remain awaiting owner review.
- [Seasonal H5 issue #47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47), holiday original-art and H5 offline fallback/resolver PRs are separately staged. Approved 55-art master archive is documented in [PR #59](https://github.com/ValentineBSAA/IPhone-Apps/pull/59). Approved source is not equivalent to Xcode/physical integration.
- Retain 51 original local music tracks, 16 sound effects, iOS16 support, two-column grids throughout non-gameplay menus, the original approved artwork, all game modes/saved scores/inventories, 8/12/24 Endless progress, existing shop pricing and unlocked inventory.

## Non-negotiable release/QA gates
- **No merge, version bump, unsigned QA IPA, public release, or owner physical pass claim without explicit review and approval.**
- Tests must be honest: mock policy != actual purchase handler != full SwiftUI interaction != physical iPhone.
- Simulator is only **iPhone 16e**. Final on-device QA includes core modes, 8/12/24 edge mapping, purchases/ownership, unchanged saved boards, invalid actions, time/calendar, Day/Night and source-art/audio integrity.
- `UserDefaults` multi-key purchases are not crash-atomic or physically power-loss durable; do not claim otherwise.
- Keep internal QA feature flag `BERRY_INTERNAL_QA` out of production distribution. The historical QA strawberry grant is a separate explicit operation that changes the REAL wallet; scenario laboratories must not do so.
- When opening a new chat: read this file, issue #61, latest draft PR, latest Actions logs, and scenario catalog **before writing new code**, so work resumes rather than restarts.

## D1c current exact QA notes
- [D1c QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d1c-real-commerce-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D1C_REAL_COMMERCE_COCKPIT_QA.md) lists all seven real checkout/disposable-store cards, six XCTest and critical exclusions.
- The internal one-tap Commerce Lab does **not** simulate clicking through the normal player-facing SwiftUI Boutique UI; it calls actual production business methods in isolated app state. Do not conflate the two.
- No proof of iPhone actual usability or production suite pass until separate evidence and owner acceptance.
