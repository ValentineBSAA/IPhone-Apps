# 🍓 Berry Berry Blast · Consolidated Seasonal Artwork · Game Integration Guide

**Import status:** GitHub successfully reconstructed all eight parts from Release `berry-h1-approved-all-20261120`, validated the 318,953,250-byte master ZIP against SHA-256 `2e9e321a70aef320e849cd18d82533ae9e86fd6a23a36b02e584a55e25d4c210`, and imported its art source into this staging branch.  
**Validated runs:** [original import](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44860171770) and [idempotent verification](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44860324828).  
**Scope:** source artwork / future integration map; **not an IPA, Xcode runtime switch, or app release**.

## Source layout

```text
StrawberryShortcakeBlockBlast/
  ArtSource/
    README_SEASONAL_STAGING.md             ← this guide
    00_Consolidated_H1_2026-11-20/
      CONSOLIDATED_ASSET_MANIFEST.json     ← authoritative 55 visually approved originals + SHA-256
      CONSOLIDATED_ASSET_INDEX.csv
      APP_ASSET_BINDINGS_DRAFT.json        ← 55 unique, name-safe SwiftUI image asset keys
      IMPORT_PRESERVED_METADATA_MAPPING.json
      Preserved_H1_Batch01_Archive_Metadata/
      README_FIRST.md
      SHA256SUMS.txt                       ← original 150 ZIP entries
    SeasonalGarden/
      Halloween|Christmas|Thanksgiving|Birthday/
        Day|Night/
          Originals/                      ← immutable original PNGs
          RGBA_Candidates/                 ← non-destructive cutouts, not yet owner QA approved
      _Previews/
      00_Specs_And_Ledgers/
    ClockFrames/
      Base|Halloween|Christmas|Thanksgiving|Birthday/
        Day|Night/
          Originals/                      ← clock plaques; no baked time
          RGBA_Candidates/                 ← separate candidates
      _Previews/
      00_Manifests/
```

## Exactly what is verified
- [x] **55 / 55 owner-visually-approved distinct source images present**, each path and byte size checked against consolidated JSON manifest.
- [x] Family counts: 8 Home Classic, 10 digital clock plaques, 8 Berry Story, 8 Daily Harvest, 8 More Adventures, 8 Cottage Decorations, **5 Berry Collection**.
- [x] Original 8 H1-B01 Home Classic images preexisting in GitHub compared byte-identical by Git blob SHA; no replace or regeneration.
- [x] Two different H1-B01 metadata/README revisions preserved in separate archival paths with a valid JSON redirect mapping. Both remain accessible.
- [x] Remaining 147 archive files staged, plus 2 redirect audit variants and the valid mapping; no changed existing originals overwritten.
- [x] 55 unique runtime asset **key suggestions** with canonical source paths in `APP_ASSET_BINDINGS_DRAFT.json`.
- [x] Previous 40 Night Garden sources stay separate under [PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40). Do not regenerate or overwrite.
- [ ] Three remaining Berry Collection visuals: BC-06 Thanksgiving Night, BC-07 Birthday Day and BC-08 Birthday Night; these must be generated and approved individually once available.
- [ ] Every cleaned RGBA candidate still needs owner visual review against light/dark/checker backgrounds, especially halos, fine leaves, snow and delicate ribbon loops.
- [ ] Xcode `Assets.xcassets` imageset creation and runtime integration, saved data regression, adaptive holiday/day-night/locale checks and physical iPhone QA remain pending.

## How the game should consume the artwork later
1. **Do not** point `Image(...)` at source RGB originals with baked white, checkerboard or black corners. Do not treat generated alpha candidates as production-approved. Use approved final RGBA *after visual QA*.
2. Build `.imageset` resources using the unique `asset_key` strings from `APP_ASSET_BINDINGS_DRAFT.json`, with an Xcode `Contents.json` `idiom: universal` and selected PNG.
3. Preserve existing base artwork and menus as fallback. Map semantic names `HomeClassic`, `BerryStory`, `DailyHarvest`, `MoreAdventures`, `CottageDecorations`, `BerryCollection` and `ClockFrame`; do not confuse a mode with a shop or clock plaque.
4. Runtime should select **holiday + Day/Night + semantic tile** based on the device’s current time zone and calendar, using a local, optional user-configured birthday. Halloween October 31, Christmas December 25 and U.S. Thanksgiving the fourth Thursday in November are candidate rules; region-specific holidays and tie-break priority require product acceptance. No precise location/GPS is needed for these standard calendar selections.
5. Render **digital clock numerals in code** over the approved decorative plaque, never fixed digits printed into the image. Maintain agreed placement and readable type.
6. Verify on physical iPhone screens and preserve saved scores, owned decorations, collections and wallet during the eventual runtime change. Use separate Xcode build branch and test the fallback for missing unfinished seasonal variants.

**Not production-ready yet:** This branch holds immutable approved designs and review candidates. No assertion is made that the newly staged artwork is active in the game or that all alpha edges have passed QA.

## Links
- [Release: Approved All App icons so far seasonal home](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/berry-h1-approved-all-20261120)
- [Draft consolidation PR #59](https://github.com/ValentineBSAA/IPhone-Apps/pull/59)
- [Consolidated artwork tracking ledger](../SEASONAL_ALL_APPROVED_CONSOLIDATED_IMPORT_CHECKLIST.md)
