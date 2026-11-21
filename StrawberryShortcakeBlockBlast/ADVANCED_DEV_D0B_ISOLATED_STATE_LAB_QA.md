# 🍓 D0b · Developer Garden State & Timer Lab

**Date:** November 20, 2026. **Status:** Internal implementation candidate, CI and physical iPhone QA gated.  
**Branch:** `feature/berry-advanced-dev-d0b-state-time-lab`; parent [verified D0 PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63).  
**Roadmap:** [Advanced Developer Garden issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61), [initial 48-scenario catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json).

## Intent and hard boundaries
Create instant tests for funds, charges, save formats and countdown boundaries **without repeatedly playing the game**, buying items, spoofing the iPhone's clock or touching the user's real save state.

- [x] `BerryDeveloperStateLab.swift`: isolated Swift value-model; `#if BERRY_INTERNAL_QA` compile gate; no `BerryGameSession`, production `UserDefaults`, file writes, economy singleton, notifications, GPS or server.
- [x] `BerryQAIsolatedWallet`: reads **actual `BerryEconomy` price constants** for Undo/Shuffle/Hint, proves exact-price, one-short, zero-charge and counter-overflow policy cases in memory.
- [x] `BerryQAMemorySaveStore`: in-memory `[String: Data]` only; uses actual `BerryEngine` Codable schema for 8×8/12×12/24×24; corrupted payload can be rejected without affecting a good slot.
- [x] `BerryQAVirtualClock`: fixed disposable `Date` and manual `advance`, calling real `BerryTimedLifecycle` and `BerryCountdownMath` logic for pause/resume/expiration. No actual phone time manipulation.
- [x] `BerryDeveloperStateLabPanel.swift`: additional **State & Timer Lab** card in the Developer Garden's existing advanced **two-column grid**, itself a two-column fixture picker with mock balance/charges, expected/actual PASS/FAIL, Run and Discard.
- [x] Existing D0 `Scenario Sandbox`, Developer Garden controls, real-wallet QA grant and user settings preserved byte-identical apart from the necessary new menu cases. No new images needed.
- [x] **11 new targeted XCTest cases authored**, plus existing six D0 cases included in the combined named iPhone 16e simulator job.
- [ ] [GitHub Actions D0b test run](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0b-state-time-iphone16e.yml) must prove Release build without QA code and the full selected 17-test suite green before automated acceptance.
- [ ] Owner real iPhone 16e Developer Garden card layout, repeat/discard and unchanged wallet/save acceptance. No IPA is built or released as part of this workflow.

## Six preconfigured one-tap fixtures
| ID / label | Sandbox initial state | Expected result |
| --- | --- | --- |
| `exactPriceUndo` · Exact-Price Undo | Wallet 40, Undo cost from production `BerryEconomy.undoPrice`, charge 0 | One simulated purchase accepted; wallet 0, exactly one Undo charge |
| `oneBerryShort` · One Berry Short | Wallet 49, Shuffle cost `BerryEconomy.shufflePrice` 50 | Simulated purchase rejected; wallet and charges unchanged |
| `zeroToolCharge` · Zero Tool Charges | Wallet 0, Hint charges 0 | Use rejected; charges cannot become negative |
| `memorySave` · In-Memory Save | Seeded `BerryEngine`, no disk slots | JSON round-trip restores same engine in disposable dictionary |
| `corruptedSave` · Corrupted Save | Valid seeded engine and separate malformed `Data` | Malformed snapshot rejected while good copy remains identical |
| `virtualTimer` · Three-Second Timer | 3-second deadline, pause at +1s; virtual resume at +11s | Pause shows 2s, 10s of pause doesn't count, expires exactly 2s after resume |

## Testing receipts
- [x] New tests cover six scenario receipts, money boundaries, overflow guards, save roundtrip at 8/12/24, corrupted-byte isolation, virtual pause/deadline, rerun/discard and real saved UserDefaults-key snapshots.
- [ ] CI result and exact XCTest counts to be recorded only after terminal GitHub job conclusion and job-log inspection.
- [ ] Mac/iOS physical interface QA after separate approved installable build. Do not mark screenshot or simulator-only checks as an owner physical pass.

## Important technical limitation
**Do not misrepresent D0b as an end-to-end production purchase test.** `BerryQAIsolatedWallet` reproduces defensive transaction constraints using production pricing constants, but it does **not** call the game's actual checkout, saved inventory, daily gift or `BerryGameSession` tool debit handlers. Similarly, the save tests validate `BerryEngine`'s real Codable format in a `Data` dictionary, but do not yet validate the disk migration service or normal save/resume.

Before adding scenarios that invoke live app handlers, implement **D0c dependency injection** to test those same handlers with isolated stores. No reusing the legacy Developer Garden's permanent QA grant, no writing real currency, no faking a Night Market, and no claims that unimplemented features passed.

## Precise owner test checklist (future test candidate)
1. In internal-only build, open Settings and long-press the existing build label for 1.8 seconds; enter the existing developer PIN.
2. Expand More diagnostics; open **State & Timer Lab**. Observe two-column cards and a clear sandbox-only message.
3. Run Exact-Price Undo: PASS, **0 test berries / 1 test Undo**. Select One Berry Short: PASS, **49 test berries / 0 Shuffle**. Select Zero Tool Charges: PASS.
4. Run In-Memory Save, Corrupted Save and Three-Second Timer: each should report PASS without asking for access to actual game saves or changing the device clock.
5. Run the same fixture again; result and totals should match. Tap **Discard & reset**; test wallet returns to 40 and no result remains.
6. Close Developer Garden and compare the **real** existing wallet, tool inventory, bought cosmetics, 8/12/24 Endless saved boards and birthday/daily reward state. No changes are permitted.

**No version bump, Xcode asset import, live wallet mutation, signed IPA, merge or public release.** Complete D0b tests and owner device review first.


## CI attempt 1 diagnostic and corrected rerun
- [x] [Initial GitHub Actions run #44863898002](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44863898002) completed **FAILURE** after a successful source/art/audio verification and Release compile-exclusion check. **No D0b XCTest methods were executed.**
- [x] Exact root cause: copied CI setup wrote `$RUNNER_TEMP/berry-d0b-sims.json` but tried to read `$RUNNER_TEMP/berry-d0-sims.json`; and the later test step referred to the old `berry-d0-id` UDID path. This is a workflow filename mismatch, not a puzzle/economy/save/timer test failure.
- [x] Fixed all simulator JSON/UDID file references in the [workflow on main](https://github.com/ValentineBSAA/IPhone-Apps/blob/main/.github/workflows/berry-d0b-state-time-iphone16e.yml). Corrected workflow was pushed and starts [fresh CI run #44864274159](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44864274159), including the finalized canonical-JSON engine comparison change.
- [ ] Confirm the new CI run's terminal conclusion and **17 selected XCTest method counts** from logs. Mark iPhone simulator acceptance only after actual test execution.
- [ ] Physical iPhone owner acceptance and production handler integration remain pending regardless of CI outcome.
