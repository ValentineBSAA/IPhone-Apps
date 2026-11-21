# 🍓 Berry Berry Blast · Next Non-Artwork Engineering Queue

**Checkpoint:** November 20, 2026. This is a continuity index of outstanding roadmap tracks, not permission to ship an IPA or merge development branches.  
**Working base:** v0.5.16 / Build 4.6 developer branch. **Platform:** iOS 16+, iPhone 16e first. **Build number:** unchanged.  
**Current H5 lab:** [H5 checklist](SEASONAL_H5_CALENDAR_FALLBACK_QA.md) and [draft PR #60](https://github.com/ValentineBSAA/IPhone-Apps/pull/60).  
**Do not lose previous staged work:** [55 seasonal originals PR #59](https://github.com/ValentineBSAA/IPhone-Apps/pull/59), [40 Night Garden RGBA PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40), prior Build 4.x draft PR chain.

## Where we stand
- [x] 55 unique approved seasonal designs imported exactly into GitHub; one 319 MB master Release ZIP and 55-key mapping available.
- [x] 40 Night Garden art originals + derived RGBA candidates individually owner approved and staged on separate branch, **not merged into running game**.
- [x] Foundation-only local holiday, region and birthday prototype from H0 plus H5 pure artwork fallback resolver; nine H5 XCTest methods created.
- [x] H5 Swift/Foundation compilation and offline smoke green [#44861283856](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861283856).
- [ ] iPhone 16e named simulator XCTest and owner physical QA still gated separately.
- [ ] 13 missing RGBA sources (8 Home Classic + 5 Berry Collection); 22 derived cleanup candidates need final matte/edge QA, 20 native RGBA still need small-size visual acceptance.
- [ ] 3 absent Berry Collection designs **BC-06 Thanksgiving Night, BC-07 Birthday Day, BC-08 Birthday Night** postponed until image generation available. Do not invent them, use fallback.

## Safe next-work sequencing (one independent PR at a time)
| Gate | Work package | Engineering state | Why it matters | Guardrail |
| --- | --- | --- | --- | --- |
| P0 | **H5 local holiday/day-night calendar and asset fallback** [#47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47) | **STARTED**: resolver + nine tests on PR #60; Swift smoke green | Player sees correct Christmas, Oct 31, US fourth-Thursday Thanksgiving and optional birthday imagery by calendar + timezone, without broken missing icons | Only aesthetic selection; no GPS, gameplay or reward mutation; no live UI until approvals |
| P1 | **Seasonal alpha/matte technical cleanup** [audit](https://github.com/ValentineBSAA/IPhone-Apps/blob/artwork/berry-seasonal-approved-h1-consolidated-20261120/StrawberryShortcakeBlockBlast/SEASONAL_ALPHA_TECHNICAL_REVIEW_H1.md) | 20 native RGBA, 22 derived/needs edge QA, 13 RGBA missing | Clean transparent Home icons at 64/96/144px on light/dark backgrounds | Preserve exact originals; no blind production import |
| P2 | **Build 4.5 left-behind tool charge safety check** [#14](https://github.com/ValentineBSAA/IPhone-Apps/issues/14) | 10/12 owner physical QA checked; #12 independent data-audit reviewed; #8 invalid/blocked tool charge/pricing test still open | Do not declare 12/12 or silently consume currency | Changed-area manual test only; no grind or unapproved economy tuning |
| P3 | **Build 4.7 Night visual foundation** [#23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23), [#24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24), [#25](https://github.com/ValentineBSAA/IPhone-Apps/issues/25), [#26](https://github.com/ValentineBSAA/IPhone-Apps/issues/26), [#32](https://github.com/ValentineBSAA/IPhone-Apps/issues/32) | Planned; 40/40 approved image sources separate; baseline clock functional but plain | Premium 12-hour digital plaque, gameplay HUD/toolbar, visually distinct Night blocks/board | No broken cell hit targets, saved cosmetics or fake clocks |
| P4 | **Build 4.8 full menu/Boutique/Tools & celebrations** [#27](https://github.com/ValentineBSAA/IPhone-Apps/issues/27), [#28](https://github.com/ValentineBSAA/IPhone-Apps/issues/28), [#29](https://github.com/ValentineBSAA/IPhone-Apps/issues/29), [#30](https://github.com/ValentineBSAA/IPhone-Apps/issues/30) | Planned; current berry burst too small and not owner accepted | Complete two-column grid parity, clear disabled tools, larger strawberry fireworks/rain | No shop price or ownership changes, Reduce Motion and touch-safe |
| P5 | **Build 5 existing Quests/Village/Journal visibility** [#8](https://github.com/ValentineBSAA/IPhone-Apps/issues/8) | Staged roadmap | Better daily goals, Village and earned rewards presentation | Preserve reward counters and once-only payouts |
| P6 | **Build 6 distinct Night Market/Moonberries** [#35](https://github.com/ValentineBSAA/IPhone-Apps/issues/35) | Design only, independent wallet and catalog not approved | Genuine separate night offerings and transactional correctness | No fake inventory, no change to Day prices or cross-wallet charges |
| P7 | **Future two-experience Night modes & Story** [#33](https://github.com/ValentineBSAA/IPhone-Apps/issues/33), [#34](https://github.com/ValentineBSAA/IPhone-Apps/issues/34), [#36](https://github.com/ValentineBSAA/IPhone-Apps/issues/36) | Architecture plan only | Night becomes a distinct game experience, not merely purple mode | Distinct Story, progress namespaces and full end-to-end QA first |

## Holiday product decisions still unresolved
- [ ] **Event duration**: exact day versus preholiday window; current pure H0 prototype uses exact day only.
- [ ] **Regional selection**: iOS Region or explicit in-app country override; no precise GPS/location needed for holidays.
- [ ] **Birthday**: separate appearance opt-in, local month/day only; birthday gift **already exists** and must never duplicate or be altered.
- [ ] **Overlaps**: birthday vs Christmas, leap-day birthday in non-leap years, manual preview and Off priority.
- [ ] **Automatic vs opt-in**: current H0 implementation is dormant and defaults OFF until player-facing consent/privacy decisions. Product should eventually feel automatic once enabled.
- [ ] **Lighting boundaries**: keep the existing 6:00 AM and 6:00 PM visual routing unless the owner chooses a different policy; this is not a GPS sunrise/sunset system.
- [ ] **Missing-image fallback**: stay on the existing safe art for 3 missing Berry Collection variants and any Xcode asset not yet owner-approved.

## QA and release rules
- [ ] Source integrity and Swift/Foundation smoke.
- [ ] Named iPhone 16e simulator Swift/XCTest including boundary/fallback proof, no retired iPhone 14 Pro gate.
- [ ] Owner reviews alpha edges at actual size and verifies clock numerals remain live SwiftUI text, not baked image.
- [ ] Real iPhone 16e app UI QA, including safe areas, fast repeated taps, 8×8/12×12/24×24 gameplay touch mapping, saved mode, scores, wallet, Story/Daily/Birthday payouts, purchases and existing cosmetics.
- [ ] Only after approval, decide build number, IPA, merge/release. **Do not infer app readiness from image ZIP validation or green source-only tests.**

**Immediate scope during artwork generation cooldown:** advance H5 deterministic calendar routing and tests, formalize remaining alpha QA, and preserve Build 4.5 unresolved invalid-tool check without blocking all progress.


## New workstream: Advanced Developer Garden QA Cockpit (D0–D7)
- [x] Actual Build 4.6 Developer Garden implementation audited before writing this plan: hidden Settings long-press, PIN, two-column cards, read-only diagnostics/saves, economy inspector, combo preview and existing **live-wallet QA grant** identified.
- [x] Dedicated [Issue #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61), [developer QA roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_GARDEN_QA_COCKPIT_ROADMAP.md), and [draft planning PR #62](https://github.com/ValentineBSAA/IPhone-Apps/pull/62) opened.
- [ ] **D0 FIRST:** isolated, disposable test-fixture state and explicit restoration/cleanup with tests proving real saves, inventory, currency and gifts unchanged. Do not route existing permanent QA wallet grants into this sandbox.
- [ ] D1 scenario gallery and one-tap Setup/Run/Results/Discard; D2 board/gameplay modes; D3 special tools, invalid charges, shops and wallet; D4 Story/Daily/quests/birthday/upgrade/save scenarios; D5 H5 seasonal/time previews and future Night game; D6 audio/visual/input/performance; D7 CI/regression receipts.
- [ ] User goal: no long grinding just to reach line clears, high combos, game over, locked quests, near-expiry timers, invalid tool states, or rare rewards. Every fixture reports deterministic expected/actual outcomes, with BLOCKED/NOT IMPLEMENTED distinguished from PASS.
- [ ] Roadmap is **design-only**; no new Developer Garden UI, sandbox engine integration, app release or IPA has been made.


## D0 disposable QA sandbox implementation checkpoint
- [x] New [draft PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63) adds internal-only Scenario Sandbox to existing Developer Garden advanced 2-column grid; **no game state or UI change in main**.
- [x] Two real `BerryEngine` fixtures: near-line clear (one row, 11 points) and occupied-cell rejection (entire engine unchanged). Reusable, deterministic seed/UUID state, Run/Discard buttons and observable PASS/FAIL outcomes.
- [x] Six targeted tests authored for repeatability, score/clear, rejection, reset, saved keys and fixed tray IDs. [D0 CI](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44862930573) checks Release sandbox exclusion and named iPhone 16e XCTest. **Status pending terminal result**.
- [x] [Advanced QA scenario catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) now contains **48 contracts**, including two D0 entries correctly marked **implemented_untested**, not accepted/tested-pass.
- [ ] Separate hardware QA and signed-off sandbox safety. Live-wallet injection and Story/Daily/Quest/Shop scenarios are **not** implemented and remain isolated roadmap tasks. No user saves, app version or holiday assets changed.


## ✅ D0 simulator QA completion · November 20, 2026
- [x] [D0 Actions #44862930573](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44862930573) **SUCCESS**, Release build excludes internal sandbox and selected iPhone 16e **6/6 XCTest methods passed**.
- [x] Tested two new disposable engine setups; exact score/move, invalid placement, deterministic repeat/reset and real wallet/save nonmutation covered.
- [ ] Owner physical iPhone 16e use test and source integration authorization open in [PR #63](https://github.com/ValentineBSAA/IPhone-Apps/pull/63). D1–D7 broader test coverage still roadmap, not complete.


## D0b State & Timer Lab in isolated PR #64
- [x] [D0b draft PR #64](https://github.com/ValentineBSAA/IPhone-Apps/pull/64): six new disposable value-state tests for test-wallet exact-price/insufficient-funds/zero-charge, `BerryEngine` in-memory Codable valid/corrupt snapshots and virtual Blitz pause/expiry.
- [x] Eleven D0b XCTest cases added, existing six D0 kept; `BERRY_INTERNAL_QA` Release exclusion preserved. Two-column internal Developer Garden card added without image generation or player data changes.
- [x] Advanced QA roadmap catalog now **54 contracts**, of which six D0b are **implemented_untested** until CI results confirmed, and two D0 already simulator-pass pending physical review.
- [ ] [Combined D0+D0b named iPhone 16e CI](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0b-state-time-iphone16e.yml) final result/receipt; no IPA/merge without owner QA.
- [ ] D0c actual production transaction/save adapters with injected separate stores. D0b mocked purchase guard tests should not count as full live shop coverage.


## D0b successful iPhone 16e simulator gate · November 20, 2026
- [x] [D0b workflow #44864274159, attempt 2](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44864274159) finished **SUCCESS**; actual job log reports **17/17 selected XCTest passed, zero failures** (6 previous D0 and 11 new D0b).
- [x] Debug simulator named iPhone 16e, Release compiled with internal-only QA sandbox excluded, source/art/audio checks passed, no IPA shipped. CI runner-path and missing-`try` test syntax errors corrected, with both failures preserved in the [D0b QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d0b-state-time-lab/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D0B_ISOLATED_STATE_LAB_QA.md).
- [x] [Scenario catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) currently **54** test contracts: 8 `automated_pass_device_pending` (2 D0 + 6 D0b), 44 `planned`, 2 `not_implemented`; this is NOT 54/54 tested.
- [ ] Physical-owner iPhone 16e interface checks, **D0c injected real shop/save handler tests**, complete gameplay regression and merge/release approval remain open. D0b mock price checks do not assert production checkout safety.


## D0c production-shared standard tool rules
- [x] [Draft PR #66](https://github.com/ValentineBSAA/IPhone-Apps/pull/66) adds shared side-effect-free `BerryStandardToolTransaction` to actual `BerryGameSession` Undo/Shuffle/Hint purchases and legal Hint charge-use; D0b QA lab now tests **the same production decision logic**.
- [x] Unit tests cover exact cost/one short/invalid input, count overflow and invalid-use no charge deduction. [D0c workflow](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d0c-shared-tools-iphone16e.yml) selected regression with named iPhone 16e and Release QA exclusion; terminal status pending.
- [x] Coverage catalog now **56 contracts**, only 2 new D0c entries implemented-but-untested pending CI. The existing 8 automated-pass D0/D0b contracts remain device-owner pending.
- [ ] Full live store and ledger/endless-save injection, device taps, blocked tool charge and full app regression are still separate. No new image, IPA or release.


## ✅ D0c verified shared production purchase policy
- [x] [GitHub Actions #44865715817](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44865715817) **31/31 selected simulator tests PASS**, including 10 production-shared transaction cases. Release build excludes QA sandbox.
- [x] Actual `BerryGameSession` Undo/Shuffle/Hint purchase and Hint charge use routes through the same defensive no-overflow, no-insufficient-funds reducer used by the disposable Developer Garden State & Timer Lab.
- [x] [Scenario registry](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json) remains honest: **10/56 simulator verified, 44 planned, 2 not implemented**, zero physically accepted in the D0 series.
- [ ] Next step: injected production checkout/ledger/save adapters and physical owner iPhone 16e review, before any app release or merge. PR #66 intentionally draft.
