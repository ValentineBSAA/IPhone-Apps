# 🍓 Berry Berry Blast · Advanced Developer Garden / QA Cockpit

**Status: ROADMAP / DESIGN ONLY.** Build on the existing **Build 4.6 Developer Garden**, do not replace it. Goal: test every supported game mechanic **without hours of manual scoring, quests, purchases, or repeated play**.

## Product promise
One-tap **Create scenario → Run checks → Review PASS/FAIL evidence → Discard sandbox**. Scenarios are deterministic and use isolated testing state, not the player's actual saves, history, shops, inventory or wallet.

## Real baseline identified in source
- Hidden 1.8-second long-press on Settings build text and a PIN UI; this PIN is convenience, **not security**.
- Current cards: QA test strawberries, touch/placement diagnostics, 8/12/24 Endless save inspector, combo visual preview; additional economy, build, clocks, experimental features and planned notification preview.
- The internal QA currency grant currently writes to the *real saved wallet* and persists. This must remain explicitly separated and clearly labeled as a legacy/manual QA operation. A new sandbox must **not** grant permanent currency or silently modify a real wallet.
- Game is still native iOS 16+ and only the **iPhone 16e** is a required QA device. Preserve current 2-column card design, B4.6 base app, approved files and all user data.
- Existing XCTest, seed-based 2,030-session Fair Play diagnostics and iPhone on-device QA are strengths to reuse, not rerun as long manual grind sessions.

## D0 · Sandbox safety and observability (implement FIRST)
- [ ] Internal-build-only compile and runtime gates: `BERRY_INTERNAL_QA` for all scenario mutators and UI, non-exported in distribution; don't rely on the PIN alone.
- [ ] In-memory **QA fixture/session namespace** with explicit dependency injection for engine, store, inventory, history, time, region, RNG/seed and user-defaults/test file storage. Never use production singleton/UserDefaults for scenario mutations.
- [ ] Separate QA snapshot/restore: record initial states, run in disposable sandbox, **Discard**/Reset; restore original screen and original saved run regardless of interruption, app relaunch or crash; tests for abandonment/cleanup.
- [ ] Preview-before-apply and strong warning for any legacy live-wallet QA grant. No destructive save editor, no public cheat feature, no overwrite or delete of real data.
- [ ] Test audit object: scenario id, seed, board dimensions, scenario setup, action, expected/actual deltas, PASS/FAIL/BLOCKED, warnings, elapsed duration, build SHA, and optional sanitized report export. No location, password, tokens or personal data.
- [ ] CI prove scenario APIs cannot compile into release/TestFlight distribution, and sandbox operations leave production keys byte-identical.

## D1 · Scenario Library and fast test navigation
- [ ] Developer Garden expands to readable two-column category grid (no lists): **Gameplay Lab, Special Tools Lab, Economy Lab, Progression Lab, Day/Night & Seasons, Night Game, Audio/Visual, Saves & Migration, Diagnostics & Reports**.
- [ ] Every test card has **Set Up**, **Run**, **Show expected**, **Show actual**, **Reset**, **Export**; bounded progress and clear state: PASS, FAIL, BLOCKED, NOT IMPLEMENTED, UNRUN.
- [ ] Reusable scenario fixtures as JSON/Codable or typed Swift models with schema version + migration tests; deterministic seeds for repeatability; no networking.
- [ ] One-tap presets: nearly full board, exact missing corner, last legal move, next line clear, combo x2/x3, imminent game-over, Endless 24×24 edge, timer 00:03, zero tool charge, 1 berry short of purchase, quest 1 action remaining, birthday/Christmas overlap.
- [ ] Favorites/recent scenarios and "run all fast checks" limited to sandbox; keep long stress tests in GitHub CI, not blocking phone UX.
- [ ] Dynamic capability manifest connects each game feature to test IDs and implementation status; unimplemented Night Market features display **NOT IMPLEMENTED**, never fake pass.

## D2 · Gameplay mechanics without manual grind
- [ ] Classic 8×8; Endless 8×8, 12×12, 24×24; Story; Daily; Cozy; Blitz timers; Nightmare 12×12. Check each actual game's intended rules and restrictions.
- [ ] Board injection under sandbox: legal/illegal placement, near-edge/corner cells, tray drag/drop, occupied cells, ghost/preview hints, row/column/combination clear, no-move exhaustion, rescue/end-screen.
- [ ] Deterministic action runner can fast-forward seeded moves/season or Story targets **without rendering every frame**; inspect board engine deltas and guard against fake earned currency.
- [ ] Difficulty adaptive first-slot limits, 24×24 patch/section transitions, stale save resume, New Garden, pause/resume, re-entry and orientation-safe layout.
- [ ] Timed Blitz: inject virtual monotonic clock, pause/background/foreground, expiration, zero-time, rollover. Do not change iPhone system clock.
- [ ] Fair Play Lab: launch bounded seed runs, summarize confidence and assumptions. Never equate first-fit synthetic performance with human difficulty.

## D3 · Special Tools and economy transaction safety
- [ ] Test Undo, Shuffle, Hint, Trowel, Twister, Seed, Golden Strawberry, Pantry, Spyglass, and each mode's allowed/blocked states.
- [ ] Prebuilt failing test states: 0 charges, locked, insufficient funds, no selected piece, impossible placement, invalid board cell, repeated/double-tap, stale state, purchase cancels, in-flight dismiss.
- [ ] Assert **no charge deducted on invalid action**; exact purchase price, no negative balance, no duplicate charge, no repeated grant, no phantom economy ledger income.
- [ ] Test Undo reversing the correct line-income while purchased cosmetics/inventory remain protected; no charge consumed on invalid purchase or interrupted checkout.
- [ ] Keep current Day wallet separated from future Moonberries/Night Market test fixtures and catalog. Never inject unapproved night items/prices.
- [ ] Complete outstanding Build 4.5 physical **blocked tool/no charges/pricing** regression (#14 item 8) through reproducible sandbox and one minimal owner validation.

## D4 · Progression, saved data and one-time reward testing
- [ ] Daily Harvest: ready/already played/same-day resume/rollover, date fixture, streak, no duplicate daily grants.
- [ ] Berry Story chapters, quests, trophies/awards, Journal, Village/Cottage decorating and cosmetics: locked/owned/equipped/purchased/redeemed state; scenario snapshots with no player data edits.
- [ ] Birthday month/day + once-annual existing 100-strawberry gift: simulate dates and trigger exactly once, independence from visual birthday art and Feb-29 policy.
- [ ] Persistent saves: Classic vs Endless 8/12/24, old v0.5.x migration, restart, corrupted/incompatible fixtures, crash recovery, never overwrite real data.
- [ ] Future distinct Night progression tracked as **planned** until Night game and Story mechanics approved and implemented.

## D5 · Seasonal Calendar and two-experience preview
- [ ] Reuse dormant H5 holiday resolver (PR #60). Test Halloween Oct 31, Christmas Dec 25, US fourth-Thursday Thanksgiving, optional Birthday, time-zone region changes, calendar midnight and 6AM/6PM transitions.
- [ ] Virtual date/locale preview only; **no GPS, real clock spoofing or live wallet/birthday gift triggers**.
- [ ] Inspect exact selected asset name, installed/approved status, fallback source, Day/Night lighting, missing BC-06/07/08. Allow overlay preview without changing active mode.
- [ ] Night modes, separate Story and Night Market become scenario categories when implemented. Their tests cannot be green before actual features exist.

## D6 · Audio, input, accessibility and performance probes
- [ ] Reuse 51 music + 16 sound files; test shuffle/repeat/mute, haptic toggles, missing playback assets and interruption recovery without loud output by default.
- [ ] Input targeting stress: iPhone 16e safe areas, Pause/Home/Settings/Help, touch paths, long press, accidental taps, disabled/zero-charge tools, 8/12/24 grids.
- [ ] Fireworks/berry rain/celebration previews with deterministic effect seeds, Reduce Motion and bounded particle counts; pointer/touch passthrough always safe.
- [ ] Screenshot/profiling receipts, memory and launch/frame-time sampling where supported; don't promise precise FPS from simulator alone.
- [ ] VoiceOver, Dynamic Type, screen reader status and large font contrasts; separate preview from device acceptance.

## D7 · CI, reporting and release gates
- [ ] Test harness Swift unit/XCTest and deterministic JSON scenario contracts run on named iPhone 16e simulator plus physical acceptance on changed features.
- [ ] Export compact redacted test report + replay seed; open a report in GitHub Issues/PR only on owner request (no automatic private save uploads).
- [ ] CI test catalog coverage detects newly added mechanics lacking at least one scenario; report **coverage gaps** rather than saying every mechanic tested.
- [ ] Regression after every release: source/build integrity, 8/12/24 placements, currency guard, resume/saves, invalid tool, birthday once-only, seasonal fallback and UI safe area.
- [ ] UI review: polished grid-first compact cards, obvious Run/Reset/Done, high-contrast badges, one-click return to actual game; no large lists or nested control clutter.
- [ ] No app version bump, merge, IPA or public QA controls until separate owner approval and full regression.

## Shortest implementation path
**First code milestone:** D0 disposable sandbox with read-only diagnostics and one **"one move from line clear"** fixture; test source non-mutation. **Second:** D1 menu/card registry and status model. **Third:** D2/D3 high-value complete game-over/blocked tool flows. Add further scenario families incrementally, never one giant risky refactor.

**Dependencies:** [Night Garden roadmap #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23), [Fair Play #14](https://github.com/ValentineBSAA/IPhone-Apps/issues/14), [Seasonal H5 #47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47), [existing Developer Garden #19](https://github.com/ValentineBSAA/IPhone-Apps/issues/19), [latest H5 PR #60](https://github.com/ValentineBSAA/IPhone-Apps/pull/60).


**Tracking issue:** https://github.com/ValentineBSAA/IPhone-Apps/issues/undefined

## Machine-readable initial test coverage registry
- [x] Created [46 explicit scenario contracts](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json), split across gameplay (12), tools (11), economy (5), progression (7), calendar/seasons (6), future Night experience (2) and visuals (3).
- [x] Every scenario defines a fixture, an expected assertion, and a status; **all current scenario statuses remain planned or not implemented**. This is inventory, not proof any scenario has run.
- [ ] Before D1, build a validator that flags newly introduced mechanics without a matching scenario and stops false PASS statuses without evidence.
- [ ] D0 sandbox must be completed before any scenario can modify engine, wallet, rewards or saves.


## D0 implementation milestone · November 20, 2026
- [x] **Implementation actually started** in [draft PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63), `feature/berry-advanced-dev-d0-isolated-sandbox` based on Build 4.6, not in the planning PR.
- [x] New internal-QA-only disposable `BerryEngine`-backed scenario runner with fixed UUIDs, in-memory state, 2-column selection, actual engine actions, automatic comparison and Discard; **no live GameSession/UserDefaults**.
- [x] Two initial runnable fixtures: final action clearing a single 8×8 row for precisely **11 points**, and invalid placement into occupied cell returning no mutation. Real board generation is deterministic. No images generated.
- [x] Six targeted XCTest methods authored, including snapshot protection of real wallet/save keys and deterministic rerun behavior. **No pass claim until CI finishes.**
- [x] Updated [scenario catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) to **48 planned/implemented test contracts**, where two D0 examples are `implemented_untested` pending automated and physical proof. Broader 46 scenarios are still planned/not implemented.
- [ ] [D0 GitHub Actions #44862930573](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44862930573) verifies Release compilation excludes QA code and runs only six new methods on named iPhone 16e; keep pending until final result verified.
- [ ] Physical iPhone 16e checks using [exact D0 test steps](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d0-isolated-sandbox/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D0_SANDBOX_BUILD_AND_QA.md) only after green CI. No new IPA or install candidate yet.
- [ ] Build D1 scenario registry and additional mechanism fixtures **only after D0 safety gate**. Do not reuse persistent QA wallet grants to simulate sandbox funds.


## ✅ D0 automated acceptance · November 20, 2026
- [x] [Draft PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63): real-engine reusable single-row-clear and occupied-cell-rejection fixtures in isolated `BERRY_INTERNAL_QA` Developer Garden panel.
- [x] [GitHub Actions #44862930573](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44862930573): **Release compiled excluding the QA sandbox** and named iPhone 16e XCTest **6/6 PASS, zero failures**.
- [x] [48-contract scenario catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now records two `automated_pass_device_pending` examples, **44 planned and 2 unimplemented**. Do not report 48/48 tested.
- [ ] Physical device UI/restore confirmation and owner approval pending; still not merged/released. Next D0b isolated mock wallets/time/saves before any mutation capable of influencing real gameplay or economy.


## D0b state/time lab candidate · November 20, 2026
- [x] New [draft PR #64](https://github.com/ValentineBSAA/IPhone-Apps/pull/64) based on previously green [D0 PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63).
- [x] 6 new **sandbox-only** scenarios: exact-price Undo, one-berry-short Shuffle, zero Hint charges, in-memory BerryEngine save, corrupted data rejection, 3-second virtual pause/resume/expiry.
- [x] Actual source `BerryEconomy` prices, `BerryEngine` Codable and `BerryTimedLifecycle` / `BerryCountdownMath` referenced in **mock value-state tests**. No real wallet/checkout, save-disk operations, phone clock, gifts or player preferences touched.
- [x] New `State & Timer Lab` two-column card and scene; 11 new focused XCTest cases, plus the prior six D0 cases = **17 selected tests** for the [named iPhone 16e CI workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0b-state-time-iphone16e.yml).
- [x] [Scenario coverage catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) updated to **54 total**: 2 previously automated-pass/device-pending, 6 new implemented-untested, 44 future planned, 2 not implemented. CI result and physical QA pending.
- [ ] **D0c** must inject isolated stores into actual production shop/tool and game save handlers before claiming end-to-end purchase or save migration tests. Current D0b mock wallets do not validate the live transactional pipeline.
- [ ] Run 17 selected XCTests and Release compile-exclusion gate, inspect logs, then physical owner iPhone 16e acceptance before app version or IPA decision. Draft PR #64 remains unmerged.


## D0b successful iPhone 16e simulator gate · November 20, 2026
- [x] [D0b workflow #44864274159, attempt 2](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44864274159) finished **SUCCESS**; actual job log reports **17/17 selected XCTest passed, zero failures** (6 previous D0 and 11 new D0b).
- [x] Debug simulator named iPhone 16e, Release compiled with internal-only QA sandbox excluded, source/art/audio checks passed, no IPA shipped. CI runner-path and missing-`try` test syntax errors corrected, with both failures preserved in the [D0b QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d0b-state-time-lab/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D0B_ISOLATED_STATE_LAB_QA.md).
- [x] [Scenario catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) currently **54** test contracts: 8 `automated_pass_device_pending` (2 D0 + 6 D0b), 44 `planned`, 2 `not_implemented`; this is NOT 54/54 tested.
- [ ] Physical-owner iPhone 16e interface checks, **D0c injected real shop/save handler tests**, complete gameplay regression and merge/release approval remain open. D0b mock price checks do not assert production checkout safety.


## D0c shared production transaction rules · November 20, 2026
- [x] Opened [draft PR #66](https://github.com/ValentineBSAA/IPhone-Apps/pull/66) on top of D0b. This is the first small **production-connected** test slice: `BerryGameSession.buyUndo`, `buyShuffle`, `buyHint`, `useHintIfPossible` invoke the same pure `BerryStandardToolTransaction` reducer used by the isolated QA wallet.
- [x] Preserved existing normal tool prices **Undo 40, Shuffle 50, Hint 35**, Undo snapshot invalidation, spend ledger and existing save calls. New invalid/negative/charge-overflow requests safely reject without debits.
- [x] Added 10 new targeted shared-reducer XCTest methods, selected alongside 6 D0 and 11 D0b regression methods and the existing economy tests for the [named iPhone 16e workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0c-shared-tools-iphone16e.yml).
- [x] [QA coverage catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now **56 total**: 8 prior automated-pass/device-pending, 2 new D0c implemented-untested, 44 planned and 2 not implemented. Do not claim whole-game coverage.
- [ ] **D0c CI terminal pass** and physical user checks. No production merge/release or IPA while draft.
- [ ] **Next D0d:** injection of real store/ledger/save dependencies, with isolated fixtures, before asserting full checkout, transaction atomicity or persistent migration testing.
- [ ] User's existing Build 4.5 blocked-tool charge regression remains open for physical UI acceptance; no lengthy gameplay grinding needed when sandbox fixtures become production-backed.


## ✅ D0c automated rule-parity acceptance · November 20, 2026
- [x] [D0c Actions #44865715817](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865715817) terminal **SUCCESS**. Exact iPhone 16e simulator log: **31 selected XCTests, 0 failures**, comprising D0 6, D0b 11, shared transaction 10, existing economy 4.
- [x] Release build compiled and excluded the `BERRY_INTERNAL_QA` panels/fake wallets. Approved artwork/audio integrity unchanged, no IPA or release artifact.
- [x] Two D0c contracts promoted to `automated_pass_device_pending` in the [56-contract catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **10 simulator-pass/device-pending, 44 planned, 2 not implemented**.
- [ ] D0c [draft PR #66](https://github.com/ValentineBSAA/IPhone-Apps/pull/66) remains unmerged; physical iPhone testing and injected real checkout, ledger and save-disk paths are NOT accepted. Keep next D0d small and isolated.


## D0d actual-session isolated checkout and ledger · November 20, 2026
- [x] New [draft PR #67](https://github.com/ValentineBSAA/IPhone-Apps/pull/67), based on D0c. Real `BerryGameSession.buyUndo/buyShuffle/buyHint` now share `BerryStandardToolCheckout` with the QA lab, retaining original prices and save/ledger effects via a checked callback.
- [x] Normal app still constructs `BerryGameSession()` with original `UserDefaults.standard` / `BerryEconomyLedger.shared`. New injected `checkoutDefaults` and isolated real ledger can be supplied in a test session, proving actual inventory encoding, ledger writes and reload without touching player data.
- [x] Added **9 D0d actual-session XCTest cases**, including purchase/reopen, insufficient funds and overflow no-write, legacy missing-hint compatibility and proof of unchanged real preferences. Combined selected regression **40 XCTest methods** on named iPhone 16e, Release QA exclusion enforced in [D0d workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0d-real-checkout-isolation-iphone16e.yml).
- [x] QA registry now **59 scenarios**: 10 earlier simulator-pass/device-pending, 3 D0d implemented-untested, 44 planned, 2 not implemented.
- [ ] Actual checkout workflow test job and Release safety result to verify before promoting scenarios.
- [ ] Other Story/Daily/Boutique/premium/quests save handlers remain singleton-backed and **not D0d-injection-certified**. UserDefaults inventory and ledger are separate non-atomic writes; crash-recovery and full-UI/hardware QA remain open. Do not rush a production merge or IPA.


## ✅ D0d actual-session checkout regression verified · November 20, 2026
- [x] [D0d Actions #44866663042](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44866663042) **SUCCESS**. Exact log: **40 selected XCTest cases, zero failures**, comprising D0 6, D0b 11, D0c tool rules 10, existing economy 4 and D0d real-session checkout 9 on named iPhone 16e.
- [x] Production Release built without internal QA panels/fixtures; sources, approved artwork and audio unchanged. No IPA or merge.
- [x] [59-contract QA catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now records **13 simulator-pass/device-pending**, **44 planned** and **2 not implemented**. No false full-game or physical-device acceptance.
- [x] Real `BerryGameSession` standard-tool purchase handlers use shared checked checkout callback and isolated injectable inventory preferences/real ledger in tests; legacy missing-Hint compatibility and exact save/ledger receipts verified. Standard production default storage remains the same.
- [ ] **Next targeted stage:** prove partial-write/crash recovery or design a genuinely atomic transaction boundary for standard-tool wallet and ledger, then apply injected dependencies to additional shop, daily and premium handlers safely. Complete real iPhone UI QA separately.


## D0e interrupted-purchase recovery safety milestone · November 20, 2026
- [x] Opened [draft PR #68](https://github.com/ValentineBSAA/IPhone-Apps/pull/68), based on D0d, adding versioned `BerryStandardPurchaseJournal` and real `BerryGameSession` automatic recovery before saved inventory is decoded.
- [x] Journal holds exact post-inventory bytes and **absolute** real spending totals, preventing duplicate charge on repeated replay. It stages before writing inventory/ledger and preserves corrupt unresolved entries rather than silently deleting purchase evidence.
- [x] Eight new actual-session interruption XCTest methods authored; combined **48 selected** on named iPhone 16e with Release QA-panel exclusion via [D0e workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0e-purchase-recovery-iphone16e.yml). Await terminal CI proof.
- [x] [Scenario catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) expanded to **62 contracts**: 13 D0–D0d simulator-pass/device-pending, 3 D0e implemented-untested, 44 planned, 2 not implemented.
- [ ] True power-loss durability is **not guaranteed by UserDefaults**, and real multi-key writes are not atomic; this is best-effort journal replay, not a transactional database. Fault-injection device testing and player-friendly corrupt-journal messaging remain future work.
- [ ] Keep all broader gameplay, Boutique, Story, Daily, Night, progression and approved artwork gates. No new IPA/version or feature merges without full game integration regression and physical iPhone approval.


## ✅ D0e interrupted-purchase recovery simulator acceptance · November 20, 2026
- [x] [D0e Actions #44867590124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44867590124) final **SUCCESS**, named iPhone 16e **48/48 selected XCTest methods, zero failures** (D0 6, D0b 11, D0c 10, BerryEconomy 4, D0d 9, D0e 8). Release compiled without QA-only panels; no IPA.
- [x] Real GameSession standard tool purchases can stage and replay the exact post-inventory and spending-ledger values. Simulated interruption tests cover journal-only, inventory-only, ledger-partial, second launch, corrupted pending, overflow/no overwrite and normal player storage untouched.
- [x] [62-scenario catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **16 simulator-pass/device-pending**, **44 planned**, **2 not implemented**. Zero new Developer Garden owner-device signoffs.
- [ ] Best-effort UserDefaults replay is **not power-loss-durable or a truly atomic database transaction**. Physical iPhone process-kill and friendly corrupted-journal recovery UX remain required before production release.
- [ ] [Draft D0e PR #68](https://github.com/ValentineBSAA/IPhone-Apps/pull/68) remains unmerged. Next move to actual whole-game coverage: Boutique, premium tools, Daily/Story save and reward boundaries, in separate isolated work packages, not one risky refactor.
