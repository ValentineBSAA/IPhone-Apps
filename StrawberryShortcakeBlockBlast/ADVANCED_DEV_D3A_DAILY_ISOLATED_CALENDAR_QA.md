# 🍓 D3a · Real Daily Harvest Attempt and Virtual Local Calendar QA

**Status:** Source implementation plus eight XCTest methods staged on a **draft stacked development branch**. CI, physical iPhone acceptance and full Daily win/reward UI remain pending. No IPA, merge, release or version bump.

**Product baseline:** `com.valentinebsaa.berryblockblast`, iOS 16+, v0.5.16/internal Build 46; existing local saves, Day/Night setting, Story/Daily/Endless/Cozy/Blitz/Nightmare, approved 51 music tracks/16 effects and original cosmetics preserved.

## What D3a actually changes

`BerryDailyHistory` already had optional injected `UserDefaults` for some Daily methods, but its date and key checks used `Date()`; `BerryGameSession.selectMode(.daily)` still used global Daily history. The previous state made a real-session Daily QA fixture unsafe, because it could consume **the owner's actual current attempt**.

- [x] `BerryDailyHistory.activeEngine`, `expirePriorAttemptIfNeeded`, `beginToday`, `saveActiveEngine`, `finishToday` and `markLostToday` now accept an optional **`now: Date = Date()`**. They consistently use the provided date for local day checks. Existing app callers retain unchanged production defaults.
- [x] `BerryGameSession` accepts optional `now: () -> Date`, defaulting to the actual device clock. Daily mode entry, resume, first engine save, game-over loss and subsequent engine-save behavior all pass `checkoutDefaults` and the selected local date. New Daily engines are seeded from the selected date. Other modes retain their original behavior.
- [x] `beginToday` now **rejects a supposedly active attempt when its separately saved attempt record is malformed or inconsistent**. It does not erase original outcome/attempt keys or silently create another hand. This is a fail-closed protection against duplicate Daily attempts after damaged storage.
- [x] This builds upon D2b's score/quest isolation fix: `drop` writes best score to injected defaults and suppresses the shared quest placement callback for isolated sessions. Real live sessions retain existing progression.

## Eight actual Daily simulator tests

- [x] First selected Daily entry consumes exactly one attempt **before any placement** and saves a real engine.
- [x] Same-day second GameSession reopens the exact serialized engine with no extra attempt.
- [x] A real legal puzzle placement via `BerryGameSession.drop` persists Daily score/moves/board, reopens, and does not touch watched normal owner quest/score/attempt keys.
- [x] Marked-loss day refuses a second attempt and preserves original loss record.
- [x] Virtual local midnight expires a prior active attempt as loss while leaving the new day open exactly once, without touching phone clock.
- [x] Previously completed **legacy Daily** dates remain completed and never grant a new attempt.
- [x] Corrupt active attempt record with separate active outcome is **not** treated as a fresh free attempt or wiped.
- [x] Two independent disposable UserDefaults suites can have different Daily outcomes on the same date while the real player's current Daily keys remain unchanged.

**Named iPhone 16e Actions gate:** [D3a 116-selected XCTest workflow #44872483508](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872483508) includes 108 prior D0–D2d selected tests plus eight D3a, iOS16/source/art/audio checks, Release with QA-only diagnostics absent, and no IPA. **CI pending; never call pass without actual terminal log.**

## Honest limitations

This does not yet test actual native finger taps through the Daily Harvest views, full Daily completion, `BerryDailyHistory.markCompleteToday`, streak reward payouts or `BerryProgression.shared` quest claims. Those still use global persistence and require **D3b safe injection** before temporary fixtures are allowed to execute them. Story/birthday/Village are also still outside this test scope.

A damaged record is conservatively refused rather than automatically rebuilt, to avoid silently gifting an additional attempt; product-facing recovery guidance remains a future task. UserDefaults multi-key writes have no guaranteed power-loss transaction atomicity.

The tests exercise deterministic calendar inputs via injected `Date`; they do not change system time, real timezone, player data or app-wide `@AppStorage`. Full Story/Daily/game-night cosmetics and seasonal work remain on the original whole-game roadmap.

**Entry gate:** D2b 94, D2c 102 and D2d 108 selected CI runs must all complete as green on the corrected branches before treating cumulative D3a as an approved test baseline. The owner still must approve a physical iPhone16e QA build before any release.
