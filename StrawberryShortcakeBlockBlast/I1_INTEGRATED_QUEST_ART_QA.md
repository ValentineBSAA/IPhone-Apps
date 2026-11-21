# 🍓 I1 · Integrated Quest & Story Lab + Safe Village/Quest/Journal Artwork

**Status:** Combined-source test branch for development review, **not merged or released**. Source integrates the separate D3d [PR #82](https://github.com/ValentineBSAA/IPhone-Apps/pull/82) Quest & Story Lab and D4 [PR #80](https://github.com/ValentineBSAA/IPhone-Apps/pull/80) existing-approved-art fallback while retaining the D3c quest persistence safeguards. Independent parent CI and new integrated CI still require terminal evidence. No IPA, build/version change or physical device approval.

**Baseline:** `com.valentinebsaa.berryblockblast`, iOS16+, v0.5.16/internal Build46, all original 8×8/12×12/24×24 saved gardens, Story/Daily/Cozy/Classic/Blitz/Nightmare modes, art/music and currencies. No image regenerated, renamed, erased or replaced.

## Actual integration work
- [x] Starts from unmerged D3d source that includes D3c's real injectable `BerryProgression(defaults:now:)` model and five-card `BERRY_INTERNAL_QA` Quest & Story Lab in the existing two-column Developer Garden.
- [x] Copies D4 `BerryArtResolver.swift` and four `BerryApprovedArtFallbackTests.swift` unchanged from the independent approved-art branch. Keeps D4 QA evidence file for historical audit.
- [x] Updates only the **three** user-facing Home navigation tiles in `BerryModes.swift` to resolve the missing exact names `BerryVillageMap`, `BerryQuestBoardArt`, `BerryJournalArt` to known bundled images until exact final art arrives.
- [x] Surgically updates **six** references in the `BerryProgression.swift` **views** so Village, Quest, Journal and their in-page information cards resolve bundled art. The D3c model, cross-store payout guard, virtual calendar and original quest reward code are **preserved**, not overwritten by the older D4 branch.
- [x] Exact final approved asset names will automatically take precedence if those imagesets are added later. Current temporary fallbacks are **BerryStory**, **HarvestReward**, **Milestone**, already present in the shipped catalog. The fallback is not a replacement for owner approval of final Village/Quest/Journal illustrations.

## Verification gate
- [ ] [Integrated I1 Actions #44873619553](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873619553): named iPhone16e simulator, **143 selected XCTest** (D0–D3d 139 + D4 artwork 4), source/approved-art/audio/iOS16 preflight, production Release **without internal QA models/panels**, no IPA. Inspect terminal logs for 143/143 and zero failures before acceptance.
- [x] Upstream [D3b 124/124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44872785775) and [D3c 132/132](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873090908) simulator checks verified terminal success.
- [ ] Parent [D3d 139 selected](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873363717) and sibling [D4 128 selected](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873072496) still require terminal log review. Parent pass does not automatically validate integrated image/quest UI.
- [ ] Owner physical iPhone 16e: Home navigation tile images, Quest Board and Journal artwork legibility, native menu taps, test card layouts, VoiceOver, real Story/Daily game progress and saved wallet, existing animations and no blank graphic placeholders. No actual tap-path/physical approval is implied by selected simulator XCTest.
- [ ] D4 missing image issue #78 must stay open until **final approved named art** is integrated and owner accepted; visual fallback tests alone are not final art completion.

## Open work
The source deliberately does not change the original Game Over UI, birthday rewards, Day/Night or seasonal variants, quests' real player-facing tap integration, premium cross-key crash atomicity, Build5 Village evolution or Build6 Night Market/Moonberries. This is one integrated development checkpoint toward the entire game, not a publishable finished game.

**No IPA, release, main merge, current-production replacement, or version bump without owner instruction.**
