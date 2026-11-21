# 🍓 Berry Berry Blast · Advanced Developer Garden / QA Cockpit

**Status: ACTIVE STAGED DEVELOPMENT, draft/unmerged.** Build on the existing **Build 4.6 Developer Garden**, do not replace it. Goal: test every supported game mechanic **without hours of manual scoring, quests, purchases, or repeated play**.

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


## D1a real Berry Boutique testing and saved-garden protection · November 20, 2026
- [x] Opened [D1a draft PR #70](https://github.com/ValentineBSAA/IPhone-Apps/pull/70), based on verified D0e, beginning whole-game QA expansion beyond Undo/Shuffle/Hint into real Boutique ownership and cosmetics.
- [x] Central `BerryBoutiquePurchasePolicy` preserves existing 11 approved cosmetic prices and rejects unknown IDs, swapped costs, unaffordable or duplicate purchases. Real `BerryGameSession.buyCosmetic` now uses injected storage and real ledger for testable isolated purchase effects.
- [x] Separated `saveInventoryOnly()` from board-changing `save()`, protecting existing **8×8 / 12×12 / 24×24 Sweet Endless** saved boards from menu Boutique and Helper purchases.
- [x] Ten new real purchase XCTests authored (wallet, ownership, exact ledger, reward receipt, free item, old ownership, UI appearance preference preservation, duplicates, no standard player writes and saved-board bytes), plus six existing Boutique tests and 48 prior D0–D0e tests = **64 selected named iPhone 16e regression cases**.
- [x] [QA scenario catalog](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now **66 contracts**: 16 previously simulator-pass/device-pending, 4 D1a implemented-awaiting-CI, 44 planned, 2 not implemented.
- [ ] [D1a Actions #44868413961](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868413961) final terminal result and exact case counts, plus Release QA exclusion. Do not mark D1a passed without log proof.
- [ ] Future D1b: developer menu one-tap Boutique fixture UI and full view-driven purchase, equip/unequip and permanent ownership QA; D1c premium tools; D2 Daily/Story and quest/reward fixtures. These remain separate until tested.
- [ ] Real iPhone owner acceptance, multi-key cosmetic purchase crash recovery and whole-game regression remain pending; no merged code, new IPA or app version.


## Whole-game integration checkpoint after D1a · November 20, 2026
We must not accumulate endless successful isolated branches while the real iPhone game remains unchanged. After D1a simulator acceptance, the next release-planning milestone is an **integrated internal build gate**, not another long sequence of mock test suites.

- [ ] Review ancestry and cumulative diffs of [D0 #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63), [D0b #64](https://github.com/ValentineBSAA/IPhone-Apps/pull/64), [D0c #66](https://github.com/ValentineBSAA/IPhone-Apps/pull/66), [D0d #67](https://github.com/ValentineBSAA/IPhone-Apps/pull/67), [D0e #68](https://github.com/ValentineBSAA/IPhone-Apps/pull/68), and [D1a #70](https://github.com/ValentineBSAA/IPhone-Apps/pull/70) against the authoritative current Berry Berry Blast app branch. These are stacked drafts, not six production releases.
- [ ] Before integration check actual game build/version, identity, iOS 16 target, saved-game backwards compatibility, original approved artwork and complete music/audio catalogs. Do not casually merge stale base code over newer features.
- [ ] Produce ONE internal QA candidate only after CI and source integration checks. Keep internal Developer Garden gated and absent from public Release builds; do not ship a debug-enabled IPA as the public app.
- [ ] Owner physical iPhone verifies Developer Garden D0/D0b, real Boutique purchase/equip/unequip, actual saved 8/12/24 games, helper purchase, gameplay controls and existing features. Keep exact pass/fail receipts and preserve prior live installs until explicitly approved.
- [ ] Add Developer Garden visual Boutique scenario controls only after core source-integrity gate, then expand to premium/cottage, Daily Harvest, Berry Story, rewards/quests and Night experience as separate well-tested slices.
- [ ] If end-to-end integration or physical QA reveals broader problems, repair these first rather than simply increasing the count of planned test contracts.


## ✅ D1a real Boutique regression accepted · November 20, 2026
- [x] [GitHub Actions #44868413961](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868413961) terminal **SUCCESS** with **64/64 selected iPhone 16e simulator XCTest methods, zero failures**. Suites: real Boutique 10, original Boutique 6, D0–D0e regression 48; Release compiled without internal QA panels.
- [x] Real cosmetic checkout uses canonical existing prices and injected owner/inventory/rewards/ledger test store; existing owned and equipped cosmetics, actual player data and 8×8/12×12/24×24 Endless slot bytes preserved in regression.
- [x] [66-scenario QA registry](ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now **20 simulator-pass/device-pending, 44 planned, 2 not implemented**. These are 20 scenario contracts covered by 64 selected XCTest methods, not 20 app features shipped.
- [ ] **Physical iPhone QA and whole-game integration checkpoint** remain open. [D1a PR #70](https://github.com/ValentineBSAA/IPhone-Apps/pull/70) stays draft/unmerged, no new IPA/version.
- [ ] **Next focused audit:** Cottage and Premium purchases still use generic save/premium save paths that may clear a parked 8×8 Endless board from a menu session. D1b must preserve the board without disrupting actual board-changing tool-use saves. Daily Harvest, Story and Night follow after an integrated candidate.

---

## ✅ D1a accepted and D1b Cottage/premium follow-on started · November 20, 2026
- [x] **D1a confirmed:** [Actions #44868413961](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868413961) finished SUCCESS. Actual XCTest logs confirm **64/64 selected iPhone 16e simulator tests, zero failures**: 48 D0–D0e, 6 existing Boutique checks and 10 new real `buyCosmetic` tests. Release build excluded QA internals; no IPA.
- [x] D1a inventory-only changes protect previously saved Endless slots from standard-helper and cosmetic purchases made from a fresh menu session. Physical owner acceptance, full SwiftUI tap paths and crash-atomic multiple keys remain open.
- [x] [D1b draft PR #71](https://github.com/ValentineBSAA/IPhone-Apps/pull/71) continues on a branch based on D1a. Confirmed Cottage and premium-only purchase save risk: their prior generic `save()` could remove an unplayed 8×8 Endless snapshot. Changed checkout-only paths to injected real ledger/preferences + inventory-only persistence; actual premium board-changing usage keeps original full-board saves.
- [x] Added 10 new actual isolated `BerryCottagePremiumIsolationTests` for six premium SKUs, Cottage pricing, permanent purchase duplicate/overflow guards, 8/12/24 sentinel saved-garden protection, backward-compatible inventory and no writes to real player defaults.
- [x] Catalog now has **70 scenario contracts**: 20 simulator verified/device pending, 4 D1b implemented-awaiting-CI, 44 planned, 2 future Night not implemented. Not 70/70 tested.
- [ ] [Dedicated D1b iPhone 16e 74-selected-test workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d1b-cottage-premium-iphone16e.yml). Inspect actual terminal logs, do not count 74/74 until confirmed.
- [ ] D1c: internal two-column Developer Garden one-tap **real checkout against an isolated disposable store**, receipt/expected/actual/Reset and no side effect on live saved gardens. Existing D0/D0b mock QA panels remain labeled truthfully and are not silently upgraded to real checkout.
- [ ] Follow-up: premium *usage* board-change restore tests, multi-key crash-safe purchase design, Story/Daily/quests/birthday, seasonal and Night mechanics, complete physical owner QA, then explicit merge/build/IPA decisions.

D1b exact QA ledger: [Cottage & Premium Saved-Garden Safety](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d1b-cottage-premium-save-qa/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D1B_COTTAGE_PREMIUM_SAVE_QA.md). **No new IPA, no version bump, no merge.**

---

## D1c real Commerce Lab drafted · November 20, 2026
- [x] [D1c draft PR #72](https://github.com/ValentineBSAA/IPhone-Apps/pull/72), stacked on D1b PR #71, adds a **real production-handler Commerce Lab** to Developer Garden's internal **two-column card grid**. Existing D0 engine, D0b policy lab, and original manual QA strawberry grant stay unchanged.
- [x] **Seven one-tap internally disposable scenarios**: Cottage exact-price/one-short, Twister three charges, one-short Trowel, permanent Pantry duplicate, preserved 8/12/24 Endless saved gardens during actual purchases, and invalid Trowel usage. Each card **sets up + runs instantly**, reports expected vs actual, PASS/FAIL, and detects whether original player settings changed. Independent UserDefaults test suite and injected real economy ledger are cleared between runs and on exit.
- [x] Six additional XCTest methods in `BerryDeveloperCommerceLabTests` verify all seven fixtures, repeat/reset, discard and owner-key preservation. Production Release excludes UI/model behind `BERRY_INTERNAL_QA`.
- [ ] [D1c 80-selected iPhone 16e XCTest run #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471) was in progress at last inspection. **Do not mark passed until terminal results and actual test logs reviewed**. D1b 74-selected [run #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684) also pending at last check.
- [x] **77 coverage contracts** in the master catalog: 20 older simulator verified/device pending, 4 D1b real-checkout CI pending, **7 D1c one-tap Commerce Lab CI pending**, 44 planned, 2 future Night items not implemented. Not a 77/77 pass claim.
- [ ] D1c physical iPhone 16e interaction and layout acceptance, production SwiftUI shop tap paths, premium board-changing use/reopen checks and atomic multi-key purchase guarantees are still open. No IPA, no merge, no version bump.
- [ ] Next D2/D3: build safe deterministic valid-use tool and game-over/board/save scenarios, then Story/Daily/quest and later seasonal and Night mechanics. One-tap coverage must not be mistaken for end-to-end production UI automation.

[Exact D1c QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d1c-real-commerce-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D1C_REAL_COMMERCE_COCKPIT_QA.md).

---

## D1b/D1c simulator failure recovery and D2a actual premium use · November 20, 2026

**D1b and D1c first attempts were NOT green:** [D1b Actions #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684) ran **74 cases with 1 failure**, and [D1c Actions #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471) ran **80 cases with that same 1 failure**. Other selected cases passed, including all six newly introduced D1c Commerce Lab tests. The failing check was `BerryCottagePremiumIsolationTests.testCottageAndPremiumMenuBuysPreserveAllThreeEndlessSaves`, asserting raw engine JSON bytes were identical even though encoder dictionary key ordering is not guaranteed.

- [x] Repaired the **test assertion, not production game behavior**, on both D1b and D1c branches: canonical sorted-key JSON encoding of engine before and after. Original independent 8/12/24 save bytes remain compared byte-for-byte. **Both Actions runs have been re-run as attempt 2; terminal results pending**. Do not call them passed without final evidence.
- [x] Started [D2a draft PR #73](https://github.com/ValentineBSAA/IPhone-Apps/pull/73), stacked on D1c, focusing on actual **premium-tool use** rather than more purchases.
- [x] `BerryGameSession` mode selection now consistently uses injected preference storage to read saved Sweet Endless board size, legacy-migration bookkeeping, current best score and restored engine. Defaults to the original live storage for actual users.
- [x] Six new actual real-session/engine XCTest methods: valid occupied-cell Trowel and restart; valid Starberry Seed with saved move count; successful Golden Strawberry rescue with score and one-per-run limit after restart; invalid tool no-charge/no-save; independent 24×24 save/reopen preserving 8×8 and 12×12; and original player's keys unchanged.
- [ ] [D2a workflow #44870863706](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44870863706) selects **86 tests**, with original 80 regression methods plus six new D2a tests on named iPhone 16e simulator. Release QA-exclusion, source/art/audio preflight and no-IPA gate required. **Started but not yet accepted** at this checkpoint.
- [x] Master coverage catalog **83 contracts**: 20 verified simulator/device pending, 4 D1b CI pending, 7 D1c CI pending, 6 D2a CI pending, 44 planned, 2 future Night not implemented. Never call this 83 tests passed.
- [ ] Next **D2b**: add user-friendly Developer Garden two-column Tool Action Lab with one-tap *valid-use* actual tool scenarios, expected/actual receipts, in-memory/isolated save/reopen and Reset. Only stage after simulator evidence verifies D2a source and no normal owner-data writes.
- [ ] Longer-term: Twister/Pantry actual board changes, full 24×24 Golden rescue, game-over/blocked-tool cases, Story, Daily, quests, birthday, seasonal, Night and physical device QA. No release/IPA/merge/version bump.

[D2a exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2a-valid-tools-save-restore/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2A_PREMIUM_TOOL_SAVE_RESTORE_QA.md). The first-run failures were test serialization nondeterminism, **not proof of a broken actual saved game**, and must be resolved by passing terminal CI on both affected branches.

---

## ✅ D1b/D1c/D2a simulator acceptance, D2b Tool Action Lab implementation · November 20, 2026

**Full selected CI successes now documented from actual GitHub Actions logs:**
- [x] [D1b #44869316684](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684), attempt 2: **74/74 XCTest PASS, zero failures**; named iPhone16e simulator, production Release QA exclusion, no IPA.
- [x] [D1c #44869555471](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471), attempt 2: **80/80 PASS, zero failures**; all six new real Commerce Lab XCTest accepted under selected automated gate.
- [x] [D2a #44870863706](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44870863706), first attempt: **86/86 PASS, zero failures**; isolated real valid Trowel/Seed/Golden Strawberry use, independent 8/12/24 Endless save/reopen, production Release QA exclusion, no IPA.
- [x] The common first-attempt D1b/D1c false failure was fixed in XCTest using sorted-key deterministic engine JSON. Do not erase earlier failure history, but terminal reruns are green. Physical acceptance still outstanding.
- [x] New **D2b draft [PR #74](https://github.com/ValentineBSAA/IPhone-Apps/pull/74)** extends the existing Developer Garden Advanced two-column grid with **Tool Action Lab**. Seven isolated **one-tap actual game-engine and GameSession tool-use scenarios**, each executing instantly with temporary real session+saved engine+injected ledger+wallet, showing expected/actual and PASS/FAIL with reset, preserving user keys.
- [x] D2b scenarios: Trowel valid cell removal/reopen, Seed planting/reopen, Golden Strawberry rescue/reopen, Golden rescue second-attempt rejection, invalid premium targets no-charge/no-save, 24×24 save independence, and actual Trowel buy/use/reopen in one tap. Eight new XCTest methods added.
- [ ] [D2b Actions #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) selects **94 tests** (previous 86 plus eight D2b), preflights artwork/audio/iOS16, builds Release with all internal diagnostic models/panels excluded, verifies named iPhone16e simulator and no IPA. At this documentation checkpoint, tests are *not* accepted until terminal logs verify them.
- [x] Master catalog updated to **90 scenario contracts**: 37 earlier simulator verified/device pending, seven D2b implemented/CI-pending, 44 planned, two future Night not implemented. Do not confuse 90 contracts with 90 XCTest.
- [ ] D2b physical owner iPhone16e QA and production gameplay UI taps remain open. No IPA, version bump, merge, signed release or claim of multi-key crash atomicity.
- [ ] **Next D2c**: actual positive-use Ribbon Twister + Picnic Pantry on seeded boards, 24×24 Golden Strawberry Game Over rescue and restart, plus engine/test UI adapters. Then Story/Daily/quests/birthday, full day/night seasonal art and Night Market requirements remain on original game roadmap.

[D2b detailed QA file](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2b-one-tap-tool-action-lab/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2B_ONE_TAP_TOOL_ACTION_QA.md). The final product still aims at an entire berry puzzle game, not merely this debug cockpit.

---

## D2c real premium handler QA staged · November 20, 2026

- [x] [D2c draft PR #75](https://github.com/ValentineBSAA/IPhone-Apps/pull/75), stacked on D2b PR #74, implements narrow **real premium handler and rescue** coverage, not another general release.
- [x] Safety fix: combined `BerryGameSession.buyAndUseGoldenStrawberry()` now uses `checkoutLedger` for spending and `checkoutDefaults` for reward receipts instead of shared/global storage, matching production defaults and ensuring isolated QA sessions do not change actual player data. Removed unsupported claim that multi-key UserDefaults writes are crash-atomic.
- [x] **Eight D2c real-session XCTest** cover valid non-symmetric Ribbon Twister rotation/reopen, invalid Twister guards, Picnic Pantry stash/swap/reopen, invalid Pantry guards, 24×24 Golden Strawberry clearing occupied cells in all four quadrants while preserving 8/12 saved runs, exact 250-berry combined buy/rescue/reopen with isolated real ledger/receipt, negative combined rescue guards, and normal-player key nonmutation.
- [ ] [D2c Actions #44871838416](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) selects **102 XCTest** (D0–D2b 94 + D2c eight), on named iPhone16e simulator. Verify actual terminal 102/102 PASS, production Release QA-exclusion and no IPA **before** acceptance. Do not imply that code existing proves it.
- [ ] [D2b #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518), 94 selected, was in progress when D2c was committed. Confirm its terminal run independently, fix any failure before accepting D2b as a stable parent.
- [x] Coverage catalog now has **98 contracts**: 37 previously simulator verified/device pending, 7 D2b simulator-pending, 8 D2c simulator-pending, 44 planned, 2 future Night not implemented. Not 98 passed tests.
- [ ] D2d: expose **four new disposable one-tap D2c actions** in Tool Action Lab after D2c source passes simulator CI (Twister, Pantry, Mega Golden, combined rescue). Keep two-column cards, expected/actual receipts, full temporary-suite isolation and non-player wallet guarantees.
- [ ] Story **Game Over** production View and authentic blocked-run checkout UI have not been tested; D2c currently tests an occupied playable Endless board's combined handler only. Never claim the actual Story Game Over purchase path is verified. Crash-atomic multi-key purchase durability, full owner physical QA and the rest of the game remain pending.
- [ ] Next broader targets: D3 actual Daily/Story/quests/birthday tests with injectable persistence, D4 seasonal approved artwork, Build4.7/4.8 Day/Night parity, Build5 Village/quests and Build6 distinct Night modes, Moonberry wallet and Night Market. **Keep working on the whole game, not only the Developer Garden.**

[Exact D2c QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2c-premium-actions-rescue/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2C_PREMIUM_ACTION_RESCUE_QA.md).

---

## D2b/D2c real Seed isolation regression and D2d eleven-card Tool Action Lab · November 20, 2026

**A real defect was caught, not a test-only serialization issue.**
- [x] [D2b Actions #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) attempt 1 ran **94 selected XCTest; two assertions failed** inside one internal Tool Action Lab case: Starberry Seed used correctly and persisted, but the test session wrote a live `UserDefaults.standard` best-score key.
- [x] [D2c Actions #44871838416](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) attempt 1 ran **102 selected XCTest; the identical two failures**. Both first attempts had successful production Release builds and named iPhone16e test execution; neither was a pass.
- [x] Fixed **both** best-score persistence sites in `BerryGameSession` (`drop` and `useStarberrySeed`) to write `checkoutDefaults`, which remains `.standard` in live sessions. Also guarded `BerryProgression.shared.recordPlacement` in actual `drop` so isolated test sessions do not increment real quest state. Applied same corrections directly to D2b, D2c and D2d feature branches. This preserves normal player behavior and blocks QA leakage.
- [x] Requested **attempt 2 reruns** for D2b 94 and D2c 102. **Final terminal log evidence pending at this writing.** Do not certify either yet.
- [x] New [D2d draft PR #76](https://github.com/ValentineBSAA/IPhone-Apps/pull/76) stacked on D2c extends the existing `BERRY_INTERNAL_QA` two-column **Tool Action Lab** from **seven to eleven** one-tap real actions: (1) Twister L-shape rotation and charge/restart, (2) permanent Pantry stash and return across two restarts, (3) 24×24 Golden rescue across four occupied patches with independent 8/12 saved games, (4) exact 250-berry combined Golden purchase/rescue/receipt/ledger/reopen.
- [x] Six additional `BerryDeveloperToolActionExpansionTests` and updated existing enum coverage count to eleven. [D2d 108-test Actions #44872232106](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872232106), Release QA exclusions and no-IPA gate started, **not yet accepted**.
- [x] Master catalog now **102 scenario contracts**: **37 simulator verified/device pending, 7 D2b implemented/CI pending, 8 D2c implemented/CI pending, 4 D2d implemented/CI pending, 44 planned, 2 future Night not implemented**. These are tracking contracts, not the number of passed XCTest.
- [ ] Audit and repair any new CI failure; update final test counts and corresponding scenario statuses only when terminal XCTest evidence confirms them.
- [ ] Owner physical iPhone16e remains essential, including actual gameplay tool gestures, Story Game Over purchase path and two-column card accessibility. This lab uses real methods, not end-to-end native SwiftUI taps.
- [ ] Broad D3 Daily/Story/quests/birthday injection and isolated virtual dates already audited in [D3 roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3_DAILY_STORY_PROGRESSION_QA_ROADMAP.md); full game's seasons, Day/Night, Build5 village and Build6 Night Market remain open.

[D2d exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2d-premium-one-tap-expansion/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2D_ONE_TAP_PREMIUM_EXPANSION_QA.md). **No merge, IPA, signed release or version bump.**

---

## D3a genuine Daily Harvest sessions and virtual calendar · November 20, 2026

- [x] New [D3a draft PR #77](https://github.com/ValentineBSAA/IPhone-Apps/pull/77), stacked on D2d draft #76, implements the first whole-game **Daily** storage/date isolation slice. Unlike earlier mock timer cards, this uses the production `BerryGameSession.selectMode(.daily)`, real `BerryDailyHistory` persistence and actual puzzle engine.
- [x] `BerryDailyHistory` existing optional preferences injection now also has optional `now: Date = Date()` on active engine, expiry, begin, save and loss; normal app behavior remains based on device-local calendar. `BerryGameSession` accepts an optional `() -> Date` provider (defaults to actual Date()) and passes one injected store/date consistently through Daily enter, resume, fresh seed, save and loss.
- [x] Safety rule: when the daily outcomes key says `active` but the underlying `Attempt` record is malformed or contradicts today, **do not silently issue another free hand**; preserve old bytes for later user-friendly recovery.
- [x] Eight real Daily XCTest check first-entry before placement, same-day resume, legal `drop` with score and save/reopen, same-day loss denial, next-day local midnight expiry, legacy completion protection, corrupt-active record fail-closed and independent disposable Daily histories with live player keys unchanged.
- [ ] [D3a 116-selected iPhone16e CI #44872483508](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872483508) includes D0–D2d 108 prior regressions plus eight new, production Release with all QA internals absent and no IPA; **terminal CI pending**.
- [ ] D2b 94 and D2c 102 reruns plus D2d 108 simulator gates were all running at this checkpoint. Their final conclusions must be inspected; first attempts D2b/D2c failed due to real Seed best-score isolation leakage, corrected on all new branches.
- [x] [Coverage registry](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) **108 contracts**: 37 earlier verified simulator/device pending, 26 implemented/CI pending (D2b seven, D2c eight, D2d four, D3a seven), 43 planned including full Daily midnight+streak payout, two future Night not implemented. 108 contracts ≠ 116 selected tests.
- [ ] D3b: safe Daily win, claimed-once streak payout, `markCompleteToday`, quest claim and `awardOnce` isolation. Full progression singleton and Story/Birthday not yet safe for disposable QA. See [exact D3a QA scope](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d3a-daily-isolated-calendar/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3A_DAILY_ISOLATED_CALENDAR_QA.md) and [D3 roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3_DAILY_STORY_PROGRESSION_QA_ROADMAP.md).
- [ ] Physical iPhone16e real taps, voice accessibility, Night, seasonal packs, Village/quest progression, all original audio/art and whole-game modes remain separate acceptance gates. No IPA, version/build bump, merge or false claim of crash-atomic multi-key saves.

---

## D3b: Real Daily completion, once-only payouts and seven-day streak · November 20, 2026

- [x] **D2b** terminal [94/94 PASS](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) after fixing actual Starberry Seed best-score leakage into real owner preferences; **D2c** corrected [102/102 PASS](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416), **D2d** [108/108 PASS](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872232106), and **D3a** [116/116 PASS](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872483508), all named iPhone 16e simulator, zero selected failures, Release QA excluded and no IPA.
- [x] [D3b draft PR #79](https://github.com/ValentineBSAA/IPhone-Apps/pull/79) stacked on D3a, adds real `BerryDailyHistory` completed-day and won-state recording with injected UserDefaults + local date, exact streak-length and available-reward computations, and original **10, 15, 20, 25, 30, 40, 50** strawberry ladder.
- [x] Real `BerryGameSession` `earn`, `awardOnce` and `rewardDaily` now use injected store/real ledger for QA, preserving production's standard defaults. Already-paid legacy completions, won days and lost days cannot earn another reward. Story reward and Seed cleared-line quest callbacks are protected from isolated QA writes to the actual user progression singleton.
- [x] Eight **new** real `BerryDailyRewardIsolationTests`: once-only completion; seven-day reward/streak ladder; interruption reset; exact 10-berry payout once after reopen; exact 50 on seventh day; original legacy completion prevents duplicate payout; marked Daily loss has no reward; isolated Story/Daily payouts do not modify owner's preference keys.
- [ ] [D3b Actions #44872785775](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) selects **124** cases, includes D0–D3a 116 regression checks, iOS16/source/assets/audio, Release QA exclusion and no IPA. **Still running at this checkpoint; verify exact terminal XCTest result before acceptance.**
- [x] Machine-readable QA catalog now has **116 scenario contracts**, **63 simulator-verified/device-pending, eight D3b implemented/CI-pending, 43 planned, two future Night not implemented**. 116 contracts is not 124 XCTest methods.
- [ ] D3c: safe **Quest counter and claim payout** isolation, Story chapter and birthday one-time reward tests; retain existing local phone clock, Story and achievement history and exact reward key migration. Real iPhone16e Daily victory screens and actual touch navigation remain a separate owner acceptance gate.
- [ ] Continue **whole-game** priorities: [Issue #78](https://github.com/ValentineBSAA/IPhone-Apps/issues/78) actual missing Village/Quest/Journal art references, approved seasonal image wiring, Build 4.7/4.8 Day/Night parity, Build 5 Village/quests and Build 6 unique Night Market/Moonberry economy. Do not reduce development to QA tools only. No merge/IPA/version bump.

[D3b exact QA](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d3b-daily-streak-reward-isolation/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3B_DAILY_STREAK_REWARD_QA.md).

---

## D4 actual game art integration: safe approved fallbacks · November 20, 2026

- [x] Actual named iPhone16e simulator warnings and source audit confirmed **three missing Village/Quest/Journal image names**, documented in [issue #78](https://github.com/ValentineBSAA/IPhone-Apps/issues/78). The source catalog already bundles `BerryStory`, `HarvestReward`, `Milestone`.
- [x] [D4 draft PR #80](https://github.com/ValentineBSAA/IPhone-Apps/pull/80) adds central `BerryArtResolver.displayName(for:)` with automatic precedence for final exact approved imagesets. Until final images exist, Village→`BerryStory`, Quest→`HarvestReward`, Journal→`Milestone`. All Home/Village/Quest/Journal production image references now render through it. No image file, user save, other asset name, game mechanic or UI grid changed.
- [x] Four new actual UIKit asset-bundle XCTest verify exact or approved fallback for the three missing names, successful `UIImage(named:)` resolution, precedence for future final artwork, and unchanged existing assets.
- [ ] [D4 128-case Actions #44873072496](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873072496): previous D0–D3b 124 + four new, named iPhone16e simulator, iOS16/art/audio/source preflight, Release QA exclusion, no IPA. **Pending terminal CI**; no green claim yet.
- [ ] [D3b 124-case Actions #44872785775](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775): still pending when D4 source staged; verify independent complete result, fix failures.
- [x] Machine-readable scenario catalog now **120 contracts**: 63 simulator verified/device pending, D3b8+D4 four implemented/CI pending, 43 planned, 2 future Night not implemented. Contracts are not passed XCTest.
- [ ] Original approved images for Village/Quest/Journal must be located in user-approved release bundles or explicitly approved before integration. Temporary fallback solves missing frames, **not** final illustration quality or Day/Night variants. [Issue #78](https://github.com/ValentineBSAA/IPhone-Apps/issues/78) stays open until the owner visually accepts final results on physical iPhone16e.
- [ ] Continue actual full-game work: D3c isolated quest/Story/Birthday claims, D4 approved seasonal illustrations, Build4.7/4.8 Day/Night parity, Build5 Strawberry Village/quests, Build6 unique Night Market/Moonberries. **No merge, IPA or version increment**.

[D4 exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-d4-safe-village-quest-journal-art-fallbacks/StrawberryShortcakeBlockBlast/D4_APPROVED_ART_FALLBACK_QA.md).
