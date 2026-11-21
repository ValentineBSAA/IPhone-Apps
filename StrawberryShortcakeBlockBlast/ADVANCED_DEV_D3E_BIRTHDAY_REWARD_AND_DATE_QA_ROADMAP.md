# 🍓 Berry Berry Blast | D3e Birthday Gift, Calendar and Settings QA

**Status: SOURCE-AUDITED ROADMAP ONLY.** Do not represent Birthday reward safety as implemented or simulator-verified yet. D3d and integrated I1 need terminal green results first. This audit is grounded in the production `BerryModes.swift`, `BerrySettingsHub.swift` and `BerryGameSession.swift` as of the I1 feature branch.

## Existing game behavior to preserve

- **Birth month/day only** use `@AppStorage("berryberryblast.birthday.month.v0511")` and `@AppStorage("berryberryblast.birthday.day.v0511")`, not birth year. The Settings Celebration screen already uses the native **two-column card grid** and tells the player their birthday stays on-device.
- The Home Birthday Berry Bash appears when local `Date()` month/day equals stored month/day. It offers **100 strawberries once per calendar year**, using the original `berryblockblast.award.birthday-YYYY` key and actual `BerryGameSession.awardOnce("birthday-YYYY", amount:100, reason:"Birthday Berry Bash")`.
- Claim button disables after that year's award key is set, and the live session refreshes its wallet. Keep original reward amounts, legacy paid years and correct local time behavior.

## Safety issues found

1. Birthday date comparisons and annual reward year are duplicated between `BerryModes.swift` and `BerrySettingsHub.swift`, each using `Date()` directly. Avoid changing the actual device clock to test.
2. Settings Day picker offers **1 through 31 for every month**. February 30, April 31 and other impossible combinations can be saved. That needs an **understandable disabled/adjusted state**, without silently overwriting existing saved data.
3. Leap-day birthdays are celebrated on **February 29 in leap years** under current behavior. In non-leap years the celebration does not occur. A substitute celebration date (Feb 28 versus Mar 1) is a separate product decision; **do not invent or silently change this behavior** while staging QA.
4. Home's actual `@AppStorage` binding and the real wallet may be updated by accidental QA taps. New isolated scenarios must **never write** live month/day, annual award keys, reward receipts, currency or a normal saved game.

## D3e recommended implementation order

- [ ] Introduce a small pure local-date `BerryBirthdayPolicy` with `isBirthday(month:day:on:calendar:)` and `awardKey(on:calendar:)`, preserving original live behavior and the original `birthday-YYYY` key. Validate actual dates against a leap-capable reference year for month/day validity; `29 February` is a valid stored birthday.
- [ ] Route Home and Settings birthday visibility through that pure policy, retaining current `@AppStorage` and existing on-device privacy copy. No extra stored birth year, server sync, notifications or Health-related data.
- [ ] Add a safe `claimBirthday` handler that calls the actual injected `BerryGameSession.awardOnce` only when the stored month/day is valid and matches an injected local date, and the annual key is absent. Refuse repeated or mismatched claims without writing a receipt.
- [ ] Preserve native two-column Settings Celebration tiles; make month-aware day choices accessible, clarify unavailable invalid dates and support clearing/unsetting either month or day with one tap. Do not silently rewrite a user's previous month/day when opening Settings.
- [ ] Add at least **8 real isolated XCTest** cases: unset birthday, invalid Apr31 and Feb30, normal birthday first 100 receipt, same-year repeated claim refused including reopen, next-year genuine claim, leap-day valid leap-year, non-leap Feb29 not celebrated under current policy, different local times on either side of midnight, and original owner UserDefaults unchanged.
- [ ] Internal-only Developer Garden **one-tap Birthday Lab** with two-column cards, expected/actual/readable PASS/FAIL, temporary store, virtual date and replay/reset. Production Release must exclude QA internals.
- [ ] Build named iPhone 16e simulator Release compile with QA excluded and no IPA; verify selected XCTest final log. Request owner physical iPhone 16e review of Settings month/day, Birthday banner, wallet change and accessibility before any public build.

## All other work remains active

Prioritize D3d [Quest & Story Lab PR #82](https://github.com/ValentineBSAA/IPhone-Apps/pull/82), parallel D4 [approved-image fallback PR #80](https://github.com/ValentineBSAA/IPhone-Apps/pull/80), and combined [I1 PR #83](https://github.com/ValentineBSAA/IPhone-Apps/pull/83). None is merged. Continue game-wide Story/Daily real UI QA, final approved art integration, Build4.7/4.8 Day/Night, Build5 Village and quests and Build6 genuine Night Market/Moonberries. The Developer Garden is a test tool for the *whole game*, not a substitute for delivering it.

**No IPA, merge, release, version bump or player-data migrations from this roadmap.**
