# 🌙 Night Garden: owner-approved 40-icon artwork ledger

**Updated November 20, 2026. Source:** Eight batches of standalone AI-generated artwork approved by the owner in chat. **Status: ARTWORK APPROVED (40/40); 40 ORIGINAL PNG SOURCE FILES IMPORTED ON ISOLATED ARTWORK BRANCH, NOT YET MERGED; XCODE IMPORT / ALPHA DERIVATIVES / RUNTIME / iPHONE 16e QA NOT YET DONE.**

This is a non-destructive addition to [Night Garden master roadmap](BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md), [S1 asset matrix](NIGHT_ASSET_PARITY_MATRIX.md), [S1 issue #24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24) and [epic #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23). The master ZIP is preserved as [GitHub Release V1](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/V1) and staged in an isolated GitHub branch for RGBA preparation. No alpha conversions or Xcode routing have been approved.

**GitHub staging source destination (now populated on [artwork staging branch](https://github.com/ValentineBSAA/IPhone-Apps/tree/artwork/berry-night-garden-40-rgba-staging), draft [PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40)):** `StrawberryShortcakeBlockBlast/ArtSource/NightGarden/Approved_40_Icon_Batches/`. Then integrate independently into `BerryBlockBlast/Assets.xcassets/<asset_name>.imageset` as stages are ready. The existing 30 `Night_*` pairs and existing Day assets **remain untouched**. The legacy 30-image importer validates RGBA and exact day matches; it must NOT be used on this 40-icon ZIP. Most source art is RGB and needs an individual reviewed background/alpha decision before using as overlays.

| Batch | Planned stage | Owner-approved images |
| --- | --- | --- |
| 1 | S4 / Build 4.8 • core Home | `Night_Berry_Classic` · `Night_Berry_Story` · `Night_Daily_Harvest` · `Night_More_Adventures` |
| 2 | S4 / Build 4.8 • Home features | `Night_My_Strawberry_Cottage` · `Night_Berry_Collection` · `Night_Strawberry_School` · `Night_Berry_Village` |
| 3 | S4 / Build 4.8 • Home progression | `Night_Berry_Quests` · `Night_Berry_Journal` · `Night_Daily_Streak` · `Night_Strawberry_Jukebox` |
| 4 | S4 / Build 4.8 • Home modes and shop | `Night_Berry_Boutique` · `Night_Berry_Blitz` · `Night_Cozy_Cottage` · `Night_Strawberry_Nightmare` |
| 5 | S4 / Build 4.8 • Settings | `Night_Gameplay` · `Night_Block_Appearance` · `Night_Audio` · `Night_Celebrations` · `Night_Accessibility` · `Night_Data_Restore` |
| 6 | S3 / Build 4.7 • gameplay toolbar | `Night_Undo` · `Night_Shuffle` · `Night_Hint` · `Night_Stats` · `Night_Tools` · `Night_Boutique` |
| 7 | S5 / Build 4.8 • special tools | `Night_Golden_Trowel` · `Night_Ribbon_Twister` · `Night_Starberry_Seed` · `Night_Golden_Strawberry` · `Night_Picnic_Pantry` · `Night_Berry_Spyglass` |
| 8 | Developer Garden • QA-only | `Night_Test_Strawberries` · `Night_Diagnostics` · `Night_Save_Inspector` · `Night_Combo_Preview` · `Night_Economy_Inspector` · `Night_Build_Information` |

## Integration gates still open

- [x] Owner visually approved **40 original standalone icon illustrations**, including the approved Batch 2 redo and final `Night_Build_Information`.
- [x] One combined ZIP in ChatGPT with 40 unchanged PNGs, batch and master preview sheets, CSV/JSON manifest and SHA-256 checksums; ZIP and per-PNG integrity verified.
- [x] Stage all 40 original source PNG files on isolated artwork branch, SHA-verified by [successful Actions run #44829982427](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44829982427). **These art files are NOT on the shipping/merged branch yet.**
- [ ] Review RGBA alpha for all 40 (2 already have true alpha; 21 dark matte, 13 pale/checkerboard and 4 mixed backgrounds).
- [ ] Review background/alpha on every original and derive transparency only with deliberate QA; check small-scale icon readability on iPhone 16e.
- [ ] Create appropriate new Xcode image sets, verify name consistency and collisions, route actual visible components, create snapshots and physical QA for Build 4.7/4.8.
- [ ] Preserve 30 existing Night assets, untouched daytime art, existing saves, purchase prices and all 67 audio tracks. No automatic release or merge.

**Separate work not completed by the 40 icons:** dual premium digital clocks, occupied night blocks/tray states, all day/night UI surfaces, berry fireworks, separate Night game modes/Story, and unique Night Market item inventory. Follow [S2–S7](BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md) and [N1–N4](https://github.com/ValentineBSAA/IPhone-Apps/issues/23). Build 6 still governs transactional Night Market. `Night_Berry_Boutique` and `Night_Boutique` are two deliberately separate assets (Home vs gameplay toolbar).

**Do not merge or ship from asset approval alone.**

## RGBA conversion update · 20 November 2026

- **40/40 original standalone PNG illustrations:** owner-approved, preserved and staged in isolated [Night Garden artwork branch](https://github.com/ValentineBSAA/IPhone-Apps/tree/artwork/berry-night-garden-40-rgba-staging).
- **40/40 true-RGBA PNG candidates:** generated and committed under `StrawberryShortcakeBlockBlast/ArtSource/NightGarden/RGBA_Candidates/` with exact source checksums, per-batch comparisons and alpha audit. [GitHub Actions #44843011429](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44843011429) **GREEN**.
- **4/40 candidates:** Batch 1 visually approved by owner. **36/40 candidates:** Batches 2–8 **await visual approval**. Image conversion is not integration/approval.
- Batches 2–8 technique audit: 16 dark matte, 13 pale/checkerboard, 5 full-scene rounded cards (night sky deliberately retained), 2 already RGBA. Painted card assets have transparent corner arcs but retain their backgrounds; owner decision about final presentation is pending.
- Next: review for edge artifacts/halo at 64/96px, validate actual iPhone 16e screens, then integrate as separate Xcode image sets in Build 4.7/4.8. No changes to the currently deployed game, Day art, 30 legacy night assets, Night Market transaction rules or save data.
- [Draft source/RGBA PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40) remains unmerged, intentionally separate from the shipping application branch.

## Final owner RGBA visual approval · November 20, 2026

- [x] **All 40/40 RGBA candidate images visually approved by owner.** Batches 1–8, including the 36 later conversions, all reviewed and stated to look good. This supersedes *earlier historic status* in this file that referred to 36 pending.
- [x] Forty full-resolution true-RGBA candidate PNGs verified and committed on the isolated artwork branch; green [Actions #44843011429](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44843011429); [draft PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40) remains **unmerged**.
- [ ] **Still pending:** Xcode import and semantic routing, entire UI Day/Night parity, visual confirmation on actual physical iPhone **16e**, accessibility and safe tap geometry, full tests, owner release approval. “Art approved” does not equal “game finished.”
- [ ] **New, separate Seasonal Garden future art:** Halloween, Christmas, Thanksgiving and birthdays each need a handcrafted Day/Night variant; nothing seasonal has been generated. See [seasonal roadmap](SEASONAL_DAY_NIGHT_ART_ROADMAP.md) and [epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42). Do not use this to derail Night Garden Build 4.7/4.8 or Build 5/6.
