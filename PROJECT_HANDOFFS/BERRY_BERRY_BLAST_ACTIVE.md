# 🍓 Berry Berry Blast | ACTIVE DEVELOPMENT HANDOFF

**Maintained November 20, 2026 (America/Phoenix).** Use this as the first recovery entry when a ChatGPT conversation fills up. This is a factual checkpoint of GitHub refs and acceptance gates, **not permission to merge or publish**.

## Exactly where to resume
- Repository: `ValentineBSAA/IPhone-Apps`, game: `StrawberryShortcakeBlockBlast/`.
- **Active source branch:** `feature/berry-advanced-dev-d2b-one-tap-tool-action-lab` (stacked on D2a, D1c, D1b and D1a).
- **Current draft PR:** [#74 D2b Tool Action Lab](https://github.com/ValentineBSAA/IPhone-Apps/pull/74) (seven one-tap valid tool and save/reopen cards, eight XCTest), based on [#73 D2a valid premium actions](https://github.com/ValentineBSAA/IPhone-Apps/pull/73), [#72 D1c Commerce Lab](https://github.com/ValentineBSAA/IPhone-Apps/pull/72), [#71 D1b Cottage/premium](https://github.com/ValentineBSAA/IPhone-Apps/pull/71), [#70 D1a](https://github.com/ValentineBSAA/IPhone-Apps/pull/70) and D0–D0e.
- **Verified CI:** [D1b #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684) attempt2 **74/74 PASS**; [D1c #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471) attempt2 **80/80 PASS**; [D2a #44870863706](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44870863706) first attempt **86/86 PASS**, all zero selected failures on named iPhone16e simulator, Release QA exclusion and no IPA. **D2b Actions #44871494518** selects 94 tests and is pending final CI. Earlier D1b/D1c one-failure attempts were corrected with canonical sorted-key JSON in tests, retain historical logs.
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
10. **D2a selected simulator PASS:** actual valid Trowel, Seed, Golden Strawberry action/save/reopen, 8/12/24 independence, 86/86 CI green, [PR #73](https://github.com/ValentineBSAA/IPhone-Apps/pull/73), owner physical QA pending.
11. **D2b now source-staged:** internal Developer Garden two-column Tool Action Lab, seven one-tap **real tool-use** scenarios and eight new XCTest, [PR #74](https://github.com/ValentineBSAA/IPhone-Apps/pull/74), [94-test Actions #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) awaiting terminal CI. Next D2c: valid Ribbon Twister, Pantry and Golden 24×24 rescue tests; then Story/Daily/quests/migration and original game roadmap.

## Master scenario catalog
[Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61) and [roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_GARDEN_QA_COCKPIT_ROADMAP.md) link everything. [Machine-readable catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **90 scenario contracts = 37 D0–D2a simulator verified/device pending, 7 D2b implemented/CI pending, 44 planned, 2 future Night not implemented** at this handoff. 90 is **not** a count of passed XCTest; D2b selects 94 tests including prior regression.

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

## D2b current latest QA
- [D2b precise QA and owner-device checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2b-one-tap-tool-action-lab/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2B_ONE_TAP_TOOL_ACTION_QA.md).
- Seven one-tap **actual real game action** cards run independently against disposable UserDefaults and isolated ledger, then reopen the saved engine, show expected/actual PASS/FAIL. New D2b panel/model compiled only under BERRY_INTERNAL_QA, not production Release.
- **Do not fabricate D2b CI result**. Review run #44871494518 and fix failures before progressing. Physical owner iPhone16e, gameplay swipe/taps and crash-atomic savings remain separate work. No IPA/merge/version bump.

## Next D2c audited, not implemented
- [D2c Twister, Pantry, 24×24 Golden and Game Over rescue design checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2C_TOOL_ACTION_RESCUE_ROADMAP.md) includes exact fixtures and guardrails for the next milestone. Do **not** code or claim success until D2b CI is green.
- Audit found `buyAndUseGoldenStrawberry()` still writes directly to `BerryEconomyLedger.shared` and `UserDefaults.standard`. Never invoke that method from a temporary QA suite before isolating both write paths. Actual player checkout behavior is unchanged; this is a testing safety prerequisite.
