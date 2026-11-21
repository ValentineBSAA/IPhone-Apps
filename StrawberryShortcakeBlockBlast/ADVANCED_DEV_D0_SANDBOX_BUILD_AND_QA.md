# 🍓 D0 | Isolated Developer Garden Testing Sandbox | QA Ledger

**Status:** D0 implementation candidate, **not released or merged**. Branch `feature/berry-advanced-dev-d0-isolated-sandbox`, based on Build 4.6 branch `feature/berry-build4-r7-night-bounce-qa`.  
**Parent:** [Advanced Developer Garden Issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61); [roadmap PR #62](https://github.com/ValentineBSAA/IPhone-Apps/pull/62). **iPhone:** 16e simulator and physical 16e only. **Minimum iOS:** 16; app bundle ID, versions and player saves unchanged.

## D0 scope implemented in source
- [x] New `BerryDeveloperScenarioSandbox.swift` strictly wrapped in `#if BERRY_INTERNAL_QA`. Uses an ephemeral **value-type `BerryEngine`**, not `BerryGameSession`, its storage/singletons, wallets, shops or UserDefaults.
- [x] One-tap **One Move From Line Clear** fixture: 8×8 with seven cells of row 4 occupied and one unrelated cell to prevent board-clear bonus. Actual engine placement completes exactly one row, earns **11** points, and checks score/line count.
- [x] One-tap **Blocked Placement** fixture: attempt to occupy an already filled cell; actual engine must reject the move and **canonical encoded engine bytes remain identical**.
- [x] Three tray pieces with stable UUIDs and fixed tints; repeat Run restarts fresh deterministic fixture and does not randomly refill.
- [x] Reset/discard clears the scenario and result. Sandbox panel is owned by the Developer Garden's sheet and discards state upon dismissal.
- [x] Added an internal-only **Scenario Sandbox** card under Developer Garden's expanded 2-column advanced grid; board preview, selected fixture, Run and Discard buttons, PASS/FAIL expected/actual info. No new illustration required.
- [x] Preserved historical **real-wallet QA grant** as an unchanged, explicitly separate legacy tool. Never route it through this new sandbox.
- [x] Added **6 iPhone XCTest methods**: exact line clear, invalid move state equality, repeated-run determinism, discard/reset, no mutation of real save/wallet preference keys, and stable tray IDs.
- [ ] **GitHub Actions [D0 iPhone 16e and Release compiler gate](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0-developer-sandbox-iphone16e.yml)** must complete green before declaring automated acceptance. Release compile must exclude QA-only panel/code, while Debug simulator tests run the six new cases.
- [ ] Verify on **physical iPhone 16e**: Settings build-text 1.8-sec long press → Developer Garden PIN → More diagnostics → Scenario Sandbox; scenario card layout readable in 2 columns, Run/Discard works, Done returns to unchanged actual saved board and wallet.
- [ ] Additional scenarios and broader D1/D2/D3 fixture injection only after isolation/physical baseline accepted. Do not mutate real `BerryGameSession` or daily history.

## Critical non-goals
No changes to GameSession, BoardEngine rules, underlying prices/earnings, saved data keys, premium supplies, Night Garden image assets, seasonal art, active quests/story or gameplay difficulty. No IPA, version bump, merge or release at D0.

## Manual QA, precise taps
1. Open Settings. Long press its build text for around 1.8 seconds. Unlock Developer Garden with your existing internal QA PIN.
2. Tap **More diagnostics and build information**. Locate **Scenario Sandbox**.
3. Tap **One Move From Line Clear**, verify seven filled cells in the fourth row and one marker in the bottom-right. Tap **Run engine test**. Expect **PASS** and exactly **1 row / 11 points**.
4. Tap **Blocked Placement**, then **Run engine test**. Expect **PASS**, rejected placement and unchanged puzzle state.
5. Tap **Run engine test** again; result remains identical. Tap **Discard & reset**. Current fixture returns to the pretest line-clear board.
6. Close with Done, return to your real board and check your same score, wallet, selected cosmetics and saved Sweet Endless sizes. **No expensive manual scoring required.**

## Handoff
Next D1 creates a typed scenario registry based on the [46 planned contracts](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json). Only scenarios with code and actual test reports may be marked PASS. Future D0b adds injectable virtual game clock, isolated wallet and save-store fixtures **before** tool/purchase/reward actions are simulated.

**Important distinction:** D0's current two scenarios mutate only an isolated engine. This is NOT yet general-purpose injection of hypothetical quest/wallet states into the live playing screen.


## CI checkpoint (Release compile)
- [x] [Actions #44862930573](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44862930573): **Release target compiled successfully with QA sandbox excluded**, after source integrity and original art/audio checks passed.
- [ ] Named iPhone 16e six-test suite currently executing; do not assert full green until the job's final conclusion and test counts are checked.
- [ ] Physical iPhone QA and production merge/release remain open.
