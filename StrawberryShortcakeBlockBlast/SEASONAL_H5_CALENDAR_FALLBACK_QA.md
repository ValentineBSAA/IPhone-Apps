# 🍓🗓️ Berry Berry Blast H5: Seasonal Calendar, Local Time and Safe Artwork Fallbacks

**Opened:** November 20, 2026.  
**Branch:** `feature/berry-seasonal-h5-asset-fallback-lab`.  
**Parent ticket:** [Seasonal Garden S0–S6 issue #47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47).  
**Sources:** earlier dormant H0 audit + `BerrySeasonalCalendar.swift`; 55 owner-approved art originals staged under [PR #59](https://github.com/ValentineBSAA/IPhone-Apps/pull/59); [alpha audit](https://github.com/ValentineBSAA/IPhone-Apps/blob/artwork/berry-seasonal-approved-h1-consolidated-20261120/StrawberryShortcakeBlockBlast/SEASONAL_ALPHA_TECHNICAL_REVIEW_H1.md).

## Why this is the right next checklist during the image-generation limit
The game must show correct events automatically by **local calendar date + device timezone + configured region**, then choose an approved Day/Night image, without confusing *appearance* with future Night gameplay, Story, purchases, birthday gift, daily runs, owned decorations or saved progress. This can be proved with deterministic tests today without generating artwork or enabling any UI.

## Existing baseline already in repository
- [x] `BerrySeasonalCalendar.swift` H0 policy prototype: Oct 31, Dec 25, fourth Thursday of November **for U.S. region only**, separately opted-in Birthday and local-timezone date handling.
- [x] Existing 6AM/6PM cosmetic Day/Night clock implementation in `BerryDayNightClock.swift`. The 12-hour digits are *live code*, never printed onto a generated clock plaque.
- [x] Existing birthday yearless month/day and separately awarded 100-strawberry annual gift preserved.
- [x] User approved 55 designs across seven families and uploaded all eight archive parts to GitHub. GitHub rebuilt their combined master ZIP and staged exact original PNGs. **Three Berry Collection designs BC-06/07/08 remain missing.**
- [x] Technical review found 20 native RGBA, 22 cleaned RGBA candidates requiring owner edge approval, 13 originals lacking a separate RGBA version (8 Home Classic + 5 Berry Collection). Artwork is not yet live in game.

## H5 non-visual engineering and regression checklist
- [x] Create separate `BerrySeasonalAssetResolver.swift` Foundation-only, offline read-only resolver for 7 semantic tiles including the decorative clock frame.
- [x] Use the existing date/region policy and independent **6AM/6PM lighting** so Christmas night is not a Christmas day image.
- [x] Require approved+installed assets to be passed as a set. Missing ungenerated art safely falls back to **existing game art**, never a broken/blank image.
- [x] Include proposed naming scheme compatible with `APP_ASSET_BINDINGS_DRAFT.json`: `BBB_Season_<Holiday>_<Day|Night>_<Role>`; clocks `BBB_Clock_<Holiday|Base>_<Day|Night>_ClockFrame`.
- [x] Add **9 deterministic XCTest scenarios** for dormant default, local clock boundaries, Thanksgiving, missing Berry Collection variants, birthday overlaps, manual preview/Off, base clock frames, time-zone travel and nonmutating data.
- [x] Clean Swift/Foundation type-check and separate deterministic smoke tests passed in [GitHub Actions #44861283856](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861283856); **nine iPhone XCTest methods were authored but have not yet run through iOS XCTest**.
- [ ] Add compile-time validated manifest and `Assets.xcassets` name reconciliation against actual reviewed RGBA candidates. Never expose unreviewed matte images as installed/approved.
- [ ] Visual alpha sign-off: 22 derived RGBA candidates against light/dark/checker at 64/96/144 px; create/review 13 missing candidate mattes. Existing 40 Night Garden art stays untouched.
- [ ] Agree with owner: event duration (day-only vs lead-in weeks), birthday vs same-day Christmas priority, leap-day choice, holidays by region, manual preview semantics, default-on vs opt-in. **Current values are dormant proposals, not accepted live-app policy.**
- [ ] Add Settings-only seasonal opt-in + local birthday art controls, with no birth year, GPS, internet or push permission, and ability to turn the appearance off.
- [ ] Add demo/preview and verify 12-hour numerals overlay the approved wide decorative clock frame in SwiftUI at iPhone 16e scale, not baked digits.
- [ ] Add safe main-thread appearance refresh on app foreground, local midnight and 6AM/6PM, with time-zone/region changes and no fixed 24h UTC-day assumption; avoid swaps mid-drag, mid-purchase.
- [ ] Only after owner asset and code sign-off, connect semantic Home tiles to reviewed imagesets; keep original art fallback and never alter wallet, modes, save keys, purchases, daily/streak rewards, Night Market or distinct Night Story.
- [ ] Named iPhone 16e CI, UI screenshot parity and manual physical-owner QA, then decide build/version/release separately.

## QA acceptance examples (no system clock changes required)
| Scenario | Expected behavior |
| --- | --- |
| H5 disabled by default | Existing game art unchanged |
| Oct 31, 5:59 / 6:00 / 17:59 / 18:00 local | Halloween Night / Day / Day / Night |
| Christmas 6AM UTC in Phoenix vs New York | Different local holiday dates handled |
| US Nov 26, 2026 | Thanksgiving Day/Night, separately from Halloween |
| Canada Nov 26, 2026 without override | No U.S. Thanksgiving skin applied |
| BC-06 Thanksgiving Night absent | Existing BerryCollection icon instead of wrong-day image or blank |
| BC-07/08 Birthday absent | Existing BerryCollection icon, while birthday date logic still resolves correctly |
| Birthday Dec 25 with art opted-in | Birthday has proposed priority; preview can test Christmas without modifying birthday gift |
| Optional user-selected region | Not derived from GPS or IP location, no tracking |
| No installed seasonal PNGs | Existing icons remain usable in all modes |

## Stage boundaries
**Current milestone:** source-only H5 resolver and offline test plan. **Not a merged app feature, live seasonal appearance change, new IPA, or claim of production image approval.**

Keep Build 4.7 Night Garden polish, Build 4.8 celebrations, Build 5 Quests/Village and Build 6 separate Moonberry commerce on their own independent feature tracks.


## First CI proof checkpoint
- [x] New read-only resolver type-checked on Swift/Foundation and deterministic tests executed without iOS app launch.
- [x] GitHub Actions [#44861283856](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861283856) **SUCCESS**: checkout H5 branch, Swift toolchain, source type-check, compile and run offline policy smoke.
- [ ] Nine new XCTest cases require a named **iPhone 16e** simulator CI and eventual physical QA; smoke alone does not assert they ran.
- [ ] No source artwork transferred into `Assets.xcassets`, no Settings activation, no release/IPA/version bump. PR [#60](https://github.com/ValentineBSAA/IPhone-Apps/pull/60) deliberately draft.


## Initial iPhone 16e XCTest run detail
- [x] First simulator job [run #44861437030, attempt 1](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861437030) ran **20** selected XCTests (11 H0 calendar, 9 H5 resolver). **19 passed, one failed**.
- [x] The one failure was a **test fixture expectation error** in `testLocalRegionAndTimeZoneChangesNoNetworkOrGPSRequired`: at 06:00 UTC on Dec 25 New York is **01:00 AM local**, so its appropriate approved asset is `BBB_Season_Christmas_Night_HomeClassic`, not `..._Day_...`. The production resolver correctly fell back when the night image was omitted from the fixture.
- [x] Corrected that test fixture only, without changing the resolver, the game, the artwork or any saves. [Commit in H5 branch](https://github.com/ValentineBSAA/IPhone-Apps/blob/feature/berry-seasonal-h5-asset-fallback-lab/StrawberryShortcakeBlockBlast/Tests/BerrySeasonalAssetResolverTests.swift).
- [x] Rerun **attempt 2** completed successfully in [GitHub Actions #44861437030](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861437030): **20/20 selected XCTest cases passed**, with 0 failures. Both source-only Foundation smoke and selected iPhone 16e tests are green. This does not constitute full application/gameplay or physical-device sign-off.
- [ ] The log also mentioned missing `BerryVillageMap` and `BerryQuestBoardArt` assets at app launch; those are separate asset/catalog warnings and must not be misreported as the calendar test failure. Audit in dedicated app image QA before runtime activation.


## Final selected iPhone 16e regression result · November 20, 2026
- [x] GitHub [run #44861437030, attempt 2](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44861437030) final status **SUCCESS**; log contains `** TEST SUCCEEDED **`.
- [x] `BerrySeasonalCalendarTests`: **11 tests, 0 failures**; `BerrySeasonalAssetResolverTests`: **9 tests, 0 failures**. **20 selected H5/H0 tests, 0 failures** on named iPhone 16e simulator.
- [x] Initial 19/20 failure resolved by correcting the test fixture: 06:00 UTC on Dec 25 is **01:00 EST**, so New York Christmas artwork should be **Night**. No production resolver or live game behavior needed modification.
- [ ] This was intentionally a **selected suite**, not a full-game regression, real-device acceptance, live seasonal UI activation, alpha-quality approval or release build.
- [ ] Simulator logs separately mentioned missing `BerryVillageMap` and `BerryQuestBoardArt` names; retain in independent asset use-site audit, not as failures of these 20 holiday tests.
