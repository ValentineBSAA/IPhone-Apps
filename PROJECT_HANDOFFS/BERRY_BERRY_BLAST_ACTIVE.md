# 🍓 Berry Berry Blast | ACTIVE DEVELOPMENT HANDOFF

**Maintained November 20, 2026 (America/Phoenix).** Use this as the first recovery entry when a ChatGPT conversation fills up. This is a factual checkpoint of GitHub refs and acceptance gates, **not permission to merge or publish**.

## Exactly where to resume
- Repository: `ValentineBSAA/IPhone-Apps`, game: `StrawberryShortcakeBlockBlast/`.
- **Active source branch:** `feature/berry-advanced-dev-d3b-daily-streak-reward-isolation` (stacked on D3a, D2d, D2c, D2b, D2a, D1c, D1b, D1a).
- **Current draft PR:** [#79 D3b Daily win/streak and once-only payouts](https://github.com/ValentineBSAA/IPhone-Apps/pull/79), based on [#77 D3a](https://github.com/ValentineBSAA/IPhone-Apps/pull/77), [#76 D2d](https://github.com/ValentineBSAA/IPhone-Apps/pull/76), [#75 D2c](https://github.com/ValentineBSAA/IPhone-Apps/pull/75), [#74 D2b](https://github.com/ValentineBSAA/IPhone-Apps/pull/74), and earlier D2a–D0. **All are draft/unmerged.**
- **Verified CI:** D1b [74/74](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869316684), D1c [80/80](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44869555471), D2a [86/86](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44870863706), D2b [94/94](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) attempt2, D2d [108/108](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872232106) first attempt, all named iPhone16e simulator, zero failures, QA excluded from compiled Release and no IPA. **D2c [102 attempt2](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416), D3a [116](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872483508) and D3b [124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) still pending terminal verification** at this update. Earlier D2b/D2c Seed-leak failures were fixed; do not invent green.
- **Last VERIFIED green:** [D1a Actions #44868413961](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44868413961), terminal SUCCESS, **64/64 selected XCTest passed, zero failures, named iPhone 16e simulator**, and Release compiled with internal QA panels excluded.
- **Bundle/version retained:** `com.valentinebsaa.berryblockblast`, **v0.5.16 / internal Build 46**, iOS 16.0+; source-of-truth is the active branch's `project.yml`. Root game README on `main` is older and should not be used as latest version proof.
- Owner has physically validated the Build4.6 basic hidden Developer Garden on iPhone16e; newer D0–D3b tests **have no owner physical acceptance** yet.

## Developer Garden coverage, in order
1. Build 4.6 preserved hidden Developer Garden, existing wallet grant with confirmation, diagnostics, save inspector, economy, timed clock and combo previews.
2. D0 internal `BERRY_INTERNAL_QA` real-engine isolated Scenario Sandbox: one-row 11-point line clear and blocked occupied-cell move; six XCTest accepted.
3. D0b separate disposable State & Timer Lab: exact Undo, insufficient Shuffle, zero Hint, in-memory good/bad saves, virtual timer. D0/D0b 17/17 XCTest accepted.
4. D0c production-shared standard helper policy; 31/31 selected tests accepted.
5. D0d actual injected standard helper purchase+inventory save+real ledger; 40/40 selected tests accepted.
6. D0e best-effort interrupted standard helper purchase intent replay; 48/48 selected tests accepted, **not power-loss durable**.
7. D1a real Boutique purchases, original 11 prices, duplicate ownership protection, inventory-only saves, independent 8/12/24 Endless protection; 64/64 accepted **on simulator only**.
8. **D1b automated PASS:** real Cottage+premium purchases, injected ledger/preferences, inventory-only saves and all Endless slot protection; 74/74 on named iPhone16e simulator, owner device QA pending. [PR #71](https://github.com/ValentineBSAA/IPhone-Apps/pull/71).
9. **D1c automated PASS:** internal two-column Commerce Lab, seven real disposable checkout scenarios, six XCTest; 80/80 on named iPhone16e simulator; owner device QA pending. [PR #72](https://github.com/ValentineBSAA/IPhone-Apps/pull/72).
10. **D2a selected simulator PASS:** actual valid Trowel, Seed, Golden Strawberry action/save/reopen, 8/12/24 independence, 86/86 CI green, [PR #73](https://github.com/ValentineBSAA/IPhone-Apps/pull/73), owner physical QA pending.
11. **D2b source-staged, CI pending:** internal Developer Garden Tool Action Lab seven one-tap real tool-use/save-reopen scenarios and eight XCTest; [PR #74](https://github.com/ValentineBSAA/IPhone-Apps/pull/74), [Actions #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518), 94 selected, not yet verified.

## Master scenario catalog
[Master coverage catalog](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEVELOPER_SCENARIO_COVERAGE_CATALOG.json): **116 scenario contracts: 48 simulator-verified/device-pending, 23 implemented/CI-pending, 43 planned, 2 future Night not implemented**. Contracts do not equal selected XCTest counts.

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
- **Do not fabricate D2b/D2c/D2d CI results**. D2b and D2c first attempts failed from actual Seed best-score storage leakage. This is fixed on all three branches; run conclusions require inspection of attempts2 and D2d first attempt. UI finger taps and crash-atomic saves remain separate. No IPA/merge/version bump.

## D2c production-handler code implemented, pending simulator and physical acceptance
- [D2c Twister, Pantry, 24×24 Golden and Game Over rescue design checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2C_TOOL_ACTION_RESCUE_ROADMAP.md) includes exact fixtures and guardrails for the next milestone. D2c actual handlers have been staged separately while D2b CI remains pending. Do **not** claim success until terminal simulator logs are green.
- D2c fixed the two shared-store writes in `buyAndUseGoldenStrawberry()` by routing spending and receipt persistence through existing injected `checkoutLedger`/`checkoutDefaults`. Normal player checkout behavior and the 250-berry price are unchanged; crash-atomic multi-key durability remains unproven.

## Exact D2c latest source and gate
- [Draft PR #75](https://github.com/ValentineBSAA/IPhone-Apps/pull/75) contains safe combined Golden rescue checkout injection and eight real-session Twister/Pantry/Mega/combined-rescue XCTest. [D2c detailed QA](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2c-premium-actions-rescue/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2C_PREMIUM_ACTION_RESCUE_QA.md).
- D2c uses occupied *playable Endless* fixtures. Authentic Story Game Over UI and a true blocked-run rescue are **not yet proved**. D2d on-device one-tap cards and physical iPhone16e remain pending.
- [D2c 102-test run](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) was in progress at last inspection. Do not count green until final logs checked. No IPA, release, merge or version bump.

## D3 whole-game progression audit, design only
- [D3 Daily, Story, rewards, quests, birthdays and Village QA roadmap](https://github.com/ValentineBSAA/IPhone-Apps/blob/planning/berry-advanced-developer-qa-cockpit/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3_DAILY_STORY_PROGRESSION_QA_ROADMAP.md) reviewed actual singleton and UserDefaults write paths. `BerryDailyHistory` already injects preferences for some methods, but `BerryGameSession.selectMode(.daily)` still calls shared defaults; `BerryProgression.shared` and `awardOnce` also touch real owner reward keys. **Never call these from disposable QA tests before dependency injection.**
- D3a and D3b are now implemented as draft source/test stages, with final simulator CI pending; full quest claim, Story/Birthday and real Daily screen UX are still planned. Do not change system time or actual player streaks.

## D2d latest source, safety recovery and next action
- [Draft PR #76](https://github.com/ValentineBSAA/IPhone-Apps/pull/76) extends internal Developer Garden Tool Action Lab to eleven **one-tap actual handlers**, adding Twister L-shape rotation/reopen, Pantry stash/swap/two reopens, four-patch 24×24 Golden rescue with other save protection, 250-berry combined Golden rescue/ledger/receipt/one-use limit. Adds six XCTest, selects 108 on named iPhone16e.
- [D2d exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d2d-premium-one-tap-expansion/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D2D_ONE_TAP_PREMIUM_EXPANSION_QA.md) records real Seed best-score isolation defect and source fix: both score writes now use injected defaults and GameSession drop no longer changes shared quest progression in isolated sessions. Normal default-store behavior preserved.
- **D2b 94/94 and D2d 108/108 are terminal green**. Inspect D2c attempt2, D3a and D3b for exact final XCTest counts; fix any new failures before accepting cumulative coverage.
- Next D3 priorities: safe injected Daily date/attempt, Story quest/birthday, then whole-game actual SwiftUI touch paths, seasonal artwork, Day/Night, Build5 Village and Build6 Night Market. D3 roadmap linked below. None of those are completed by one-tap premium tests.

## D3a newest active source: Daily real-entry and virtual local calendar
- [D3a PR #77](https://github.com/ValentineBSAA/IPhone-Apps/pull/77) adds actual **`BerryGameSession.selectMode(.daily)`** store and date injection plus eight targeted XCTest; [exact D3a QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d3a-daily-isolated-calendar/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3A_DAILY_ISOLATED_CALENDAR_QA.md). No changes to phone time or real Daily attempts; default live date/standard store remain unchanged.
- Core Daily methods `beginToday`, active engine, expiration, saving and loss now accept injected `now`. A separate active-outcome key with corrupted attempt record fails closed, preserving existing data and preventing an extra free hand. One legal real Daily placement can be saved and resumed in disposable storage. Full streak reward/quest and native Daily view taps are NOT proved.
- [D3a Actions #44872483508](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872483508) selects **116 cases**, includes D0–D2d regression, named iPhone16e simulator Release QA-exclusion and no IPA. It was running at the last checkpoint: **confirm terminal logs before success claim**. Also verify D2b/D2c corrected reruns and D2d 108.
- D3b Daily win/streak/reward source is staged, but **D3c quest claims, Story and Birthday are not implemented**. Complete game plan: D4 seasonal approved artwork, Build4.7/4.8 Day/Night parity, Build5 Village/quests, Build6 unique Night Market/Moonberries, physical iPhone16e acceptance. No merge, IPA, signed release or version bump.

## D4 missing Village/Quest/Journal asset integration finding
- [Issue #78](https://github.com/ValentineBSAA/IPhone-Apps/issues/78) records verified missing `Assets.xcassets` names **BerryVillageMap**, **BerryQuestBoardArt** and **BerryJournalArt** on active D3a branch. The first two also produced real missing-image warnings in named iPhone16e simulator logs; actual `BerryModes.swift` and `BerryProgression.swift` references were reviewed.
- Do not regenerate or substitute user-approved artwork without checking approved GitHub art assets first. Integrate final matching imagesets when available, otherwise choose a safe approved bundled fallback and add CI image-reference validation. This is a concrete whole-game D4 art/UX task, not a simulator XCTest pass nor a license to merge.

## D3b current latest: Daily win/streak/reward isolated source
- [D3b draft PR #79](https://github.com/ValentineBSAA/IPhone-Apps/pull/79): original win/completed history and seven-day streak reward methods now accept isolated preferences and a virtual local date. Real `BerryGameSession.earn`, `awardOnce` and `rewardDaily` use session preferences/ledger and prevent repeat or lost-day payout; normal live behavior remains standard/default clock.
- [D3b exact QA ledger](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-advanced-dev-d3b-daily-streak-reward-isolation/StrawberryShortcakeBlockBlast/ADVANCED_DEV_D3B_DAILY_STREAK_REWARD_QA.md) covers eight new real Daily+Story payout XCTest. [D3b 124-test run](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) requires terminal result review and no-IPA/Release QA-exclusion gate.
- Physical iPhone16e Daily/Story screen testing, quest claims, full birthday, village/seasonal/Night game mechanics and crash-atomic multi-key persistence still **open**. Keep issue #78 missing Village/Quest/Journal art references on the whole-game D4 task list.
