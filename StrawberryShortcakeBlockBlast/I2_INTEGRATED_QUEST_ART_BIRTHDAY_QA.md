# 🍓 I2 · Combined Quest & Story, Approved Art Fallbacks and Safe Birthday Gift

**Status:** Draft integrated source, **not merged or released**. [I2 GitHub Actions #44874405824](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824) selects 152 regression XCTest on a named iPhone 16e simulator and was queued at this writing. Do not mark passed until terminal tests/Release QA exclusion/no IPA logs are confirmed.

**Compatibility preserved:** v0.5.16/internal Build46, iOS16+, `com.valentinebsaa.berryblockblast`, original local Core Data/UserDefaults where applicable, 8×8/12×12/24×24 independent saved games, all modes, existing original approved art/audio, wallets, cosmetics, quest targets/reward values, Birthday month/day preferences, old annual gift claim keys.

## Sources integrated precisely

- Starts with [I1 draft PR #83](https://github.com/ValentineBSAA/IPhone-Apps/pull/83), incorporating verified D3c quest/Story isolated handlers, D3d five-card `BERRY_INTERNAL_QA` one-tap lab, and separate D4 approved-existing-image fallbacks. Keeps all six view-only artwork references plus three Home navigation tile artwork references intact.
- Adds *unchanged* `BerryBirthdayPolicy.swift`, `BerryBirthdayPolicyIsolationTests.swift` (nine test methods), and the D3e QA ledger from [D3e draft PR #84](https://github.com/ValentineBSAA/IPhone-Apps/pull/84), without altering its source or tests.
- In `BerryModes.swift`, changes only Birthday day-match and annual-claim visibility and payment handler to `BerryBirthdayPolicy`. Preserves exact original 100-berry payout, `birthday-YYYY` once-only award key, and uses current local calendar in live UI. Existing approved-art fallbacks remain intact.
- In `BerrySettingsHub.swift`, day picker now limits itself to the selected month's valid days, retaining February 29 as a valid stored date. Previously stored invalid month/day values are **not silently overwritten**; a friendly corrective notice appears. Maintains the existing two-column native Settings cards and local-only privacy explanation.
- `BerryBirthdayPolicy.claim` checks actual valid birthday, annual claimed key, and exact `BerryGameSession` preference identity before invoking the original `awardOnce`. Isolated test stores cannot award into an unrelated real wallet. Leap-day birthdates celebrate only on actual February 29 under existing behavior, with no speculative alternate day.

## Automated verification gates

- [x] [D3d #44873363717](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873363717) attempt2 **139/139 PASS**, zero failures, production Release QA-only panels excluded, no IPA.
- [x] [D4 #44873072496](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873072496) **128/128 PASS**, zero failures, approved existing-art fallback only. Final named artwork not yet integrated; issue #78 remains open.
- [ ] [I1 #44873619553](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873619553) attempt2 **143 selected** combined Quest/Story+art regression: pending terminal CI.
- [ ] [D3e #44874176487](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874176487) **141 selected** Birthday+prior isolated regressions: pending terminal CI.
- [ ] [I2 #44874405824](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824) **152 selected** combined tests (I1 143 + nine Birthday tests), named iPhone16e, source/iOS16/approved art/audio preflight, Release without internal QA models/panels and no IPA. **This is the required integrated evidence; parent successes alone cannot establish it.**
- [ ] Owner physical iPhone16e UI: Home Birthday banner/taps/annual payout, months/days and invalid-date UX, accessibility/VoiceOver, all five Quest & Story one-tap diagnostic cards, native Story/Daily/Quest screens, approved-art display/contrast, force-close and saved gardens/wallet protection.

## Unfinished whole-game work and caution

Source and simulator method coverage are not user-facing physical tests. Authentic Story Game Over purchase/continue UI, automatic real Daily completion, full Quest claim screen taps, birthday behavior across actual local travel and accessibility, true final Village/Quest/Journal art, seasonal day/night art and gameplay modes, Build5 Village and quests, Build6 Night Market/Moonberries, game performance, and multi-key crash-safe payment recovery remain open.

**No main merge, IPA, signed or published game build, version increase, save migration or owner data modification from this branch.**
