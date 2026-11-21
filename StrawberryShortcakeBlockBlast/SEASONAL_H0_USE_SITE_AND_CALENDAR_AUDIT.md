# Berry Berry Blast | H0 seasonal use-site and calendar audit

Snapshot: November 20, 2026. Branch: feature/berry-seasonal-h0-calendar-audit.
State: PARTIAL H0 CODE AUDIT + DORMANT CALENDAR PROTOTYPE. No new holiday art, live activation, build/version bump, release or merge.

References: SEASONAL_DAY_NIGHT_ART_ROADMAP.md, Seasonal epic #42, calendar/QA #47, artwork #43-46, Night Garden PR #40.

## Critical preservation
- Build 4.6 remains unchanged. Preserve the 40/40 visually approved Night Garden source icons, 40/40 approved RGBA candidates, and 30 legacy Night image sets. Do not regenerate or overwrite them.
- Preserve day gameplay, music, scores, economy and saved runs. Keep Build 4.7 and 4.8 art foundation, Build 5 quests/progression, Build 6 separate Night Market, and future Night Story/modes distinct.
- The current seasonal branch adds only one pure Foundation resolver, one XCTest file and this audit; there are NO holiday PNG imports, source-game UI edits, wallet mutations or GPS APIs.

## Existing real image sets and consumers (verified against GitHub catalog)
| Image set | Existing PNG | Current code site |
| --- | --- | --- |
| BBBFrameChristmas | yes, 201271 bytes | BerryBoardStudio.swift lines 18-21; optional exterior frame through BerryDecorativeBoardFrame |
| BBBFrameBirthday | yes, 165867 bytes | BerryBoardStudio.swift lines 22-25; optional exterior frame |
| BBBIconBirthday | yes, 208860 bytes | BerrySettingsHub.swift celebrations category and BerryModes.swift birthday banner |
| BBBIconSeasonal | yes, 194401 bytes | BerryBoutiqueView.swift seasonal category definition, currently filtered out from Boutique grid |
| 30 legacy Night image sets | in catalog | Limited mapping in BerryDayNightClock.swift, not full visual parity |

Existing asset presence is NOT source art approval, visual integration or evidence of a holiday automatically activating. Review the originals and on-device crop/alpha before reusing them.

## Initial SwiftUI and artwork use-site inventory
| Area | Current code | Seasonal day/night design candidate | Restrictions |
| --- | --- | --- | --- |
| Home banner, clock, logo, mascot | BerryModes.swift lines 145-198; BerryLiveDayNightClock | seasonal hero trim, event badge and 12h digital clock face | Text clock is dynamic, avoid baked-in digits |
| Home games and Village grid | BerryModes.swift lines 200-305 and 435+ | representative Home Classic card first, then each approved seasonal mode/nav card | Keep two columns and same active mode |
| Birthday settings and local date | BerrySettingsHub.swift lines 269-301, 333-339 | profile birthday art/opt-in, calendar controls | Month/day saved locally, day selector currently permits 1-31 for any month |
| Birthday home gift | BerryModes.swift lines 103-113, 167-193 | optional banner styling only | Existing awardOnce 100 strawberries per year already exists; never duplicate |
| Boutique and frame shop | BerryBoutiqueView.swift lines 49-95, 223-224, 366-372; BerryBoardStudio.swift lines 15-27, 69-169 | preview-only seasonal exterior frame and storefront | Seasonal category currently hidden; do not activate purchases |
| Board and tiles | BerryStyle.swift, BerryBoardVisual.swift, BerryBoardStudio.swift | board exterior, eligible optional skin and transparent particles | Keep 8x8, 12x12, 24x24 touch mapping and chosen cosmetics |
| Game HUD/toolbar | BerryGameView.swift, BerryUIAssets.swift | event icons and trim after art approvals | Keep Pause/Home/Settings/Help legible; no hit-test overlays |
| Cottage and Village | BerryCottageGardenView.swift and BerryProgression.swift | original village wreaths, exterior decor and path art | Preserve ownership and saved progress |
| Collection / Quests / Journal / Streak / School | BerryCollectionView.swift, BerryProgression.swift, BerryDailyHarvestView.swift, BerrySchoolView.swift | themed header and badge accents | Do not alter rewards, streaks or story |
| Effects | BerryStrawberryRain.swift, BerryComboMilestoneBanner.swift, BerryGameView.swift | seasonal Day/Night berry rainfall and fireworks | Separate existing Build 4.8 S6 effect task and Reduce Motion |
| Developer Garden | BerryDeveloperGardenView.swift | QA-only preview selector for date/region | No clock spoof, QA grants, live economy writes or release UI |
| Night-only gameplay | future N1-N4 #33-36 | event art later where actual Night modes and Story exist | No automatic Nightgame switch or Night Market transactions |

Full exhaustive per-asset call-site count and intentionally shared variants remain open; no final total of new PNGs is claimed here.

## Calendar and regional holiday watching, proposed (currently dormant)
New pure resolver: BerryBlockBlast/BerrySeasonalCalendar.swift.
Tests: Tests/BerrySeasonalCalendarTests.swift.

- WHEN: Local wall date in the device's current time zone using Gregorian holiday rules; existing 6am/6pm visual clock stays independent. Correct behavior on travel, midnight, DST and background-to-foreground resumption.
- WHERE: iOS Region (not current physical coordinates) or future explicit country override. A US-configured phone outside the US still reports a US region unless the player selects another country. No GPS permission, server, tracking or internet.
- Halloween Oct 31, Christmas Dec 25; US Thanksgiving fourth Thursday in November (November 26, 2026). Unknown/non-US location does not inherit US Thanksgiving. Canada's different holiday timing requires separate approved rule.
- BIRTHDAY: Existing stored month and day can be reused only after separate consent to seasonal birthday visuals. Leap day is supported and fires on Feb 29 only until a fallback day is approved. Do not request birth year.
- PROVISIONAL precedence: temporary manual preview > Off > opted-in birthday > opted-in date holiday > normal Day/Night. No forced year-round pin, automatic pre-holiday weeks, push notification, bonus award or game-mode switch.
- DEFAULT: automatic holiday art is OFF in the model until an opt-in UI is designed and approved. New birthday styling does not touch the already wired annual 100-strawberry gift.
- ACTIVATION PLAN: when later approved, recalculate on app launch, foreground, local midnight, clock/region/time-zone changes, and a light interval. Never swap art while dragging a puzzle piece or during a purchase; no 24-hour fixed day assumption.
- All rules are injectable in tests. No season theme is currently routed into Home/Settings/Board; this branch MUST NOT be described as player-ready.

## H0 checklist
- [x] Locate current planning branch, issue #47 and 40 Night art RGBA status; preserve unmerged draft PR #40.
- [x] Verify existing birthday/Christmas/season icon PNGs and actual source call sites.
- [x] Find and document existing birthday 100-strawberry annual gift and legacy local month/day keys.
- [x] Initial code audit of Home, Settings, Boutique, Board, Village, Collection, gameplay and QA.
- [x] Add source-only locale/time-zone-aware holiday policy and XCTest cases, separate from shipping app.
- [ ] Finish exhaustive per-image/source-use-site inventory, missing image name fallback audit, intentional shared artwork, precise per-event Day/Night asset totals.
- [ ] Run Swift compile/XCTest/CI and physical iPhone 16e calendar/preview QA after integration approval.
- [ ] Approve event activation durations, region rules, birthday Feb 29 behavior, opt-out and temporary preview UX.
- [ ] Next H1 artwork: four distinct illustrated style guides + individual Home Classic hero icon Day and Night per holiday (eight original images, one per generation) for owner review. After art approval, pair clock shells and remaining semantic use sites.
- [ ] Stage unchanged source files, hashes, RGBA derivatives and alpha proofs before importing any imagesets.
- [ ] Ship only after separately approved iPhone 16e acceptance, nonblocking hit targets, audio, rewards and save regression.

No build number has been assigned and no existing branch has been merged.
