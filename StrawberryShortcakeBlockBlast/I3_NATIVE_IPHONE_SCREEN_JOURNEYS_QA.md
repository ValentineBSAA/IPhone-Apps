# 🍓 I3 | Real iPhone screen journeys for the whole Berry game

**Source base:** I2 integrated [draft PR #85](https://github.com/ValentineBSAA/IPhone-Apps/pull/85), with **152/152 combined iPhone 16e model tests green** in [Actions #44874405824](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44874405824).

**Current work:** feature/berry-i3-native-ui-navigation-tests. Development draft only, **not** an IPA, signed build, release or physical owner's acceptance.

## What was missing

The I2 simulator suite verifies actual session, Story, Daily, Birthday and Quest handlers, but does not tap the native SwiftUI screens. I3 adds an independent XCUITest scheme to launch the genuine app on a named iPhone 16e simulator, avoiding test-money grants or player-save mutation.

## Implemented in source

- [x] Stable accessibility identifiers on native Home Village/Quest/Journal cards, Quest claim buttons and Done actions, Birthday month/day pickers, and pause-screen Return. Existing human-readable labels remain.
- [x] Actual tap flow: Home → Village → Done → Quest Board → Done → Journal → Done.
- [x] Actual three Quest Board buttons are present, and unearned claims are disabled before gameplay.
- [x] Actual Settings → Celebrations → Birthday Month/Day → All Settings flow; verifies local-only birthday note without changing selections.
- [x] Actual Berry Classic → optional welcome → How to Play → Back to Playing → Pause → Continue → Pause → Return to Village.
- [x] Independent BerryBlockBlastUI scheme. Existing BerryBlockBlast unit tests remain in the original scheme.
- [x] I3 GitHub Actions workflow (workflow YAML on development branch) checks iOS16/art/audio, production Release isolation, named iPhone 16e XCUITest and connected Birthday/Quest/Story/art regression. No IPA is requested.

## Acceptance gates

- [ ] Confirm I3 workflow actually starts; verify terminal results of real XCUITest, not merely that tests were committed.
- [ ] All three named iPhone 16e screen journeys succeed, with genuine simulator screenshots.
- [ ] Birthday/Quest/Story/art connected production regressions succeed.
- [ ] Release excludes internal-only QA panels; original iOS16 identifier, art/audio, 8/12/24 saves and v0.5.16/internal Build46 preserved.
- [ ] Owner physical iPhone QA: tap targets, accessibility/VoiceOver, actual Story/Daily UI, quest claim, birthday payout, wallet and saved Endless games.
- [ ] Follow-on: earned Quest and Birthday payment UI tests in disposable test stores, authentic Story continue and Daily victory journeys.
- [ ] Whole-game roadmap still open: final named Village/Quest/Journal artwork (#78), seasonal day/night, Build 5 Village, Build 6 distinct Night Market/Moonberries, crash-safe multi-key payment recovery.

**Do not merge, publish or create an IPA based solely on these tests.**
