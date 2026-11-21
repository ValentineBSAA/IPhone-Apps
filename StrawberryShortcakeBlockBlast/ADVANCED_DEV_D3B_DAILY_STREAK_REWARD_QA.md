# 🍓 D3b · Daily Harvest Completion, Streak and Reward Isolation

**Status:** Stacked draft source branch with eight new real Daily Reward XCTest cases. CI and owner physical iPhone 16e QA pending. No IPA, release, merge or version bump.

**Compatibility preserved:** `com.valentinebsaa.berryblockblast`, iOS16+, v0.5.16/internal Build 46, all existing game modes, original approved art/music, Cottage/Pantry pricing, Endless 8/12/24 saved boards, legacy Daily completion and game reward keys.

## What is implemented

This follows D3a's real Daily `BerryGameSession` isolation and local virtual-date support. D3b finishes the next safe seam:

- [x] `BerryDailyHistory.completedDays(defaults:)` reads original Daily completed-history and legacy completed-date keys from any injected store. Existing `completed` property stays as a standard-default wrapper for the live game.
- [x] `markCompleteToday(defaults:now:)` performs an actual Daily **won** state and once-only completion recording using injected date/store, retaining original live no-argument behavior and key compatibility.
- [x] `nextStreakDay(on:defaults:)`, `rewardToday(on:defaults:)` and `streak(on:defaults:)` are virtual-local-date and store aware. Existing `nextStreakDay`, `rewardToday` and `streak` properties still use the real device clock and standard preferences.
- [x] Existing reward ladder remains exactly 10, 15, 20, 25, 30, 40, then 50 strawberries for the seventh and subsequent consecutive day. No higher prices or altered payouts.
- [x] `BerryGameSession.earn`, `awardOnce`, `rewardDaily` and Story reward's shared progression callback now respect the session's injected store/ledger. The live session defaults remain the originals.
- [x] A marked **lost** Daily cannot receive that day's streak reward from the reward handler. Already completed legacy or current Daily dates cannot be paid a second time. `useStarberrySeed` no longer sends shared progression callbacks from temporary sessions when clearing a line.
- [x] Original owner's actual wallet, Daily attempt, quest progression, reward receipt, story chapter and saved games remain untouched by isolated reward fixtures.

## Eight simulator XCTest cases

1. Real Daily win records one completed day, rejects repeat completion and prevents same-day entry again.
2. Six completed days followed by seventh day test the **original 10-to-50 reward ladder**, final streak count and post-win zero available reward.
3. Missing a day resets the next streak reward to 10 without modifying old completion history.
4. Actual ten-berry Daily reward produces one receipt and never pays twice after GameSession reload.
5. A sixth-day history then seventh-day completion awards exactly 50 once and persists wallet across reopen.
6. Legacy already-completed Daily date does not receive another payout.
7. Loss blocks Daily payouts and today's streak credit.
8. Original player's keys are unchanged after isolated Story chapter reward and Daily reward scenarios.

[**D3b GitHub Actions #44872785775**](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) selects **124 named iPhone 16e XCTest**: 116 previous D0–D3a selected plus eight D3b. The workflow also checks iOS16/source and original art/audio, compiles a production Release with all internal QA panels excluded and creates **no IPA**.

- [ ] Inspect final CI logs for **124/124 tests, zero failures**, successful production Release compile, no-IPA gate. Do not claim successful testing until terminal conclusion and logs verify it.
- [ ] The stacked D2c, D2d and D3a previous 102/108/116 selected runs must also be reviewed individually.
- [ ] Real owner iPhone16e: test Daily win/failure UI, streak labels, same-day resume, actual calendar/quest screen, accessibility and existing scores/saves before releasing.

## Important limits, next phase

The tests call actual game **history and reward methods** with disposable local stores, not the production SwiftUI Daily win animation or native tap path. D3b doesn't finish all Story chapter progression, `BerryProgression.shared` quest claim injection, birthday awards, broader timezone travel handling or transactional crash consistency. UserDefaults multi-key writes are not guaranteed power-loss atomic.

**D3c** can isolate quest counters/claim payout and Story completion, with an explicit opt-in date provider and safe reward callbacks. Broader targets remain seasonal approved assets, Build4.7/4.8 Day/Night feature parity, Build5 Village/quests and Build6 Night Market/Moonberry economy. Don't let the QA cockpit replace the actual game roadmap.
