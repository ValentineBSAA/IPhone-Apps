# 🍓 Berry Berry Blast | ACTIVE DEVELOPMENT HANDOFF

**Maintained November 20, 2026 (America/Phoenix).** Use this as the first recovery entry when a ChatGPT conversation fills up. This is a factual checkpoint of GitHub refs and acceptance gates, **not permission to merge or publish**.

## Exactly where to resume
- Repository: `ValentineBSAA/IPhone-Apps`, game: `StrawberryShortcakeBlockBlast/`.
- **Active source branch:** `feature/berry-advanced-dev-d2a-valid-tools-save-restore` (stacked on D1c, D1b and D1a).
- **Current draft PR:** [#73 D2a premium-tool valid use/save-reopen](https://github.com/ValentineBSAA/IPhone-Apps/pull/73), based on [#72 D1c one-tap real Commerce Lab](https://github.com/ValentineBSAA/IPhone-Apps/pull/72), [#71 D1b Cottage/premium save safety](https://github.com/ValentineBSAA/IPhone-Apps/pull/71), and [#70 D1a](https://github.com/ValentineBSAA/IPhone-Apps/pull/70), then D0–D0e.
- **Current CI:** [D1b #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684): 74 tests, [D1c #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471): 80 tests, and [D2a #44870863706](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44870863706): 86 tests. D1b/D1c initial runs failed **one identical JSONEncoder key-order assertion**; sorted-key fix pushed to both branches and attempts 2 running at last check. D2a initial run also active. **None green yet, never invent pass.** All are no-IPA workflows.
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
9. **D1c source implemented/unmerged:** internal two-column Commerce Lab, seven real disposable checkout scenarios, six XCTest, [PR #72](https://github.com/ValentineBSAA/IPhone-Apps/pull/72). First run 80/80 had 1 shared JSON byte-order failure; retry pending.
10. **D2a staged/unmerged:** actual valid Golden Trowel, Starberry Seed and Golden Strawberry actions with save/reopen and one-rescue limits; six new XCTest and injected real Endless save selection; [PR #73](https://github.com/ValentineBSAA/IPhone-Apps/pull/73). D2a 86-test CI pending. Next D2b one-tap valid Tool Action Lab only after D2a green. Then Story/Daily/quest/migration, seasonal and Night mechanics.

## Master scenario catalog
[Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61) and [roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_GARDEN_QA_COCKPIT_ROADMAP.md) link everything. [Machine-readable catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **83 contracts = 20 earlier simulator verified/device pending, 4 D1b CI pending, 7 D1c CI pending, 6 D2a CI pending, 44 planned, 2 future Night not implemented** at this handoff. 83 is **not** a count of passed tests.

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

## D2a current latest
- [D2a source + exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2a-valid-tools-save-restore/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2A_PREMIUM_TOOL_SAVE_RESTORE_QA.md) contains six actual seeded board/tool action/reopen checks, including 24×24 separation. Not yet an internal one-tap UI.
- **Halt any IPA/merge claim** until full cumulative simulator gate, broad regression and owner physical QA are accepted. UserDefaults multi-key save changes are not power-loss atomic.
