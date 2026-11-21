# 🍓 D4 · Approved Village, Quest Board and Journal Artwork Fallbacks

**Status:** Source and four asset-regression XCTest implemented in a separate stacked draft branch; automated and owner physical iPhone16e acceptance pending. **No IPA, merge, version change or artwork regeneration.**

**Baseline:** iOS16+, bundle `com.valentinebsaa.berryblockblast`, v0.5.16/Build46; all prior gameplay modes, saved games, wallet, cosmetics and approved audio/artwork intact.

## Verified missing asset problem

On named iPhone16e simulator GitHub Actions logs, the app reported missing `BerryVillageMap` and `BerryQuestBoardArt`. The original game also references `BerryJournalArt` in live user-facing surfaces. These names were not present in the 150 existing `Assets.xcassets` imageset directory names on the active D3b branch.

Instead of inventing or replacing the user's approved art, D4 adds a central `BerryArtResolver.displayName(for:)` that checks whether the intended image is actually bundled. If it is, it renders the correct original name; otherwise it falls back to one of the already bundled approved images:

| Intended asset | Existing safe temporary fallback |
|---|---|
| `BerryVillageMap` | `BerryStory` |
| `BerryQuestBoardArt` | `HarvestReward` |
| `BerryJournalArt` | `Milestone` |

The resolver is used by the live **Home tiles** in `BerryModes.swift` and by **Village, Quest Board and Journal** screens, quest icon mappings and statistic cards in `BerryProgression.swift`, preserving all existing two-column menu layouts, layout constraints and navigation. The final approved art automatically takes over as soon as a correctly named imageset is added in a future explicitly approved art integration.

No Day/Night image was invented or substituted. No user files, preferences, quest counters or scores changed.

## Four simulator XCTest methods

- [x] Each missing name has an explicitly mapped existing approved image.
- [x] The resolver automatically prefers exact approved imagesets when present, otherwise the matching approved fallback.
- [x] Each Village/Quest/Journal requested name resolves to an **actually loadable UIImage** from the current app bundle.
- [x] Other original approved assets and unknown names remain unchanged.

**CI:** [D4 Actions #44873072496](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873072496) selects **128 XCTest** on named iPhone16e simulator (D0–D3b 124 plus four D4 tests), original iOS16/source/audio/artwork preflight, a production Release compile with internal QA panels absent, and no IPA output.

- [ ] Verify terminal D4 CI conclusion, actual **128 tests/zero failures**, Release compilation and no IPA. Tests authored do not equal tests passed.
- [ ] Verify parent [D3b 124-test gate](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) independently.
- [ ] Owner physical iPhone16e checks: visually acceptable temporary artwork in Home/Village/Quest/Journal two-column grids, accessibility, readability, Day/Night background contrast, full app navigation, no blank frames, no user save modification.
- [ ] Source approved final illustrations from existing GitHub releases/bundles if present; **do not invent or regenerate them**, and preserve intended Day/Night variants and seasonal art approval process.

## Remaining whole-game roadmap

Real Daily/Story quest claims, birthday, user-facing native UI tap QA, Day/Night parity, approved seasonal icon integration, Build5 Strawberry Village and Build6 separate Night Market/Moonberry economy remain on the original project plan.

Issue [#78 missing Village/Quest/Journal artwork](https://github.com/ValentineBSAA/IPhone-Apps/issues/78) can be treated as **source fallback implemented**, but must **not be closed** until final approved artwork and physical owner UX are accepted. No crash-atomic multi-key save guarantee and no public IPA.
