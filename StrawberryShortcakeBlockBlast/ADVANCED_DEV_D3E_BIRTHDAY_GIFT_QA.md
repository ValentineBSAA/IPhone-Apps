# 🍓 D3e · Valid Birthday Dates and Safe Annual Strawberry Gift

**Status:** Production Home and Settings source plus nine real isolated XCTest implemented on an **unmerged draft feature branch** based on D3c's previously verified quest/wallet safe baseline. The iPhone16e simulator run and owner physical QA remain pending. No IPA, merge, release or version/build bump.

**Compatibility:** iOS 16+, `com.valentinebsaa.berryblockblast`, v0.5.16/internal Build46, original local birthday month/day preference keys (`berryberryblast.birthday.month.v0511`, `berryberryblast.birthday.day.v0511`), the same annual `berryblockblast.award.birthday-YYYY` key and exactly **100 strawberries**. No birth year collected, no cloud sync, no notifications, no changes to saved game/skins/music/quests.

## User-facing bug and source changes
- [x] Previous Celebration Settings day picker offered every number **1–31 regardless of month**, allowing impossible February 30/April 31 stored pairs and silent absence of the birthday celebration.
- [x] New **`BerryBirthdayPolicy`** validates real month/day ranges in one production code path. February 29 stays **valid as a stored birthday** regardless of the current year. Under original policy, Feb29 gift appears on Feb29 leap years only, **not automatically Feb28 or March1**. Do not invent a replacement date without the owner's product decision.
- [x] Settings retains its exact **two-column native card layout** and original privacy copy, but the Day menu now shows only valid dates for the chosen month. If the player already stored an impossible pair, display a friendly instruction to choose a valid date. **Do not silently rewrite existing saved month/day or delete prior gifts.**
- [x] Home Birthday Berry Bash banner and claimed-state visibility now use the same production policy. Its actual Claim button calls the existing real `BerryGameSession.awardOnce` for exactly 100, after validating date, original annual claim key and that the GameSession uses the same preferences store. The original live `UserDefaults.standard`, wallet refresh and device-local date continue unchanged. No alternative reward ledger implemented.
- [x] Disposable UserDefaults test suites and real injected `BerryGameSession` allow date and reward verification **without changing the real phone clock or user's wallet/birthday/day, old annual awards or Endless games**.

## Nine real Birthday XCTest cases
1. Valid month-specific day lengths, impossible pairs rejected and Feb29 still offered as a saved date.
2. Not-set month/day never appears or awards berries.
3. Impossible saved April31/February30 cannot pay and existing stored choices are **not modified**.
4. Actual 100-berry gift pays **once**, creates one original receipt, records the annual key and survives game restart.
5. Local midnight before/after birthday rejects; exact birthday succeeds, mismatched month denied.
6. A new calendar year pays a genuinely distinct 100 once, 200 cumulative, without overwriting previous year's claim.
7. Feb29 is celebrated **only** on real leap-day under the existing product policy.
8. Cross-profile wallet mismatch is refused; only matching disposable GameSession may receive the gift.
9. Snapshot original player birthday month/day, wallet, rewards, annual keys and independent 8×8, 12×12, 24×24 saves; all remain identical after isolated test claim.

## CI and remaining acceptance
- [ ] [D3e 141-selected iPhone16e Actions #44874176487](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874176487): 132 previous D0–D3c selected tests plus nine new. iOS16/art/audio integrity, **production Release with QA panels excluded**, no IPA. Verify actual final logs for **141/141, zero failures** before acceptance. Source code existing does not imply tests passed.
- [ ] Owner physical iPhone16e: month and day picker, change month with a previously stored high day, friendly warning visibility and VoiceOver, birthday banner, once-only wallet reward, reopening and native Home/Settings taps.
- [ ] Real live timezone changes, app background at midnight, restoration after process kill in the middle of wallet write, yearly rollover and leap-day product preference discussion still require physical/manual QA beyond synthetic Date tests.
- [ ] No regressions to Story/Daily/quests, premium tools, approved art/audio or 8/12/24 existing saves.

**Parallel branches:** D3e branches from [D3c draft PR #81](https://github.com/ValentineBSAA/IPhone-Apps/pull/81), the most recent verified 132-test quest baseline. D3d [#82](https://github.com/ValentineBSAA/IPhone-Apps/pull/82) and combined I1 [#83](https://github.com/ValentineBSAA/IPhone-Apps/pull/83) remain independently under CI, and D4 [#80](https://github.com/ValentineBSAA/IPhone-Apps/pull/80) has 128/128 passing source tests but final named art pending. **D3e does not yet contain D3d Quest & Story Lab or D4 artwork**. Require explicit regression-tested reconciliation later; no merge or IPA without owner approval.

Next whole-game work remains authentic Story/Daily UI validation, final Village/Quest/Journal and seasonal art, Build4.7/4.8 Day/Night parity, Build5 Village/quests and Build6 separate Moonberry Night Market.
