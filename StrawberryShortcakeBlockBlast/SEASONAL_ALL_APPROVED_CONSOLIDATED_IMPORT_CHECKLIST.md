# Berry Berry Blast · Consolidated Seasonal Artwork H1 · Upload and Import Ledger

**Checkpoint:** November 20, 2026. **Staging branch:** `artwork/berry-seasonal-approved-h1-consolidated-20261120`. **Artifact:** `Berry_Berry_Blast_ALL_Approved_Seasonal_Artwork_GitHub_2026-11-20.zip`.

## Original visual approvals frozen

| Family | Exact owner-approved unique original designs | In bundled source ZIP | Technical RGBA review |
|---|---:|---|---|
| H1-B01 Berry Home Classic | 8/8 | ✅ | pending on original RGB sources |
| C-FULL-01 digital clock frames | 10/10 | ✅ | native RGBA or independent cleanup candidates |
| H1-B02 Berry Story | 8/8 | ✅ | four cleaned-matte candidates await owner |
| H1-B03 Daily Harvest | 8/8 | ✅ | three cleaned-matte candidates await owner |
| H1-B04 More Adventures | 8/8 | ✅ | six cleaned-matte candidates await owner |
| H1-B05 My Strawberry Cottage Decorations | 8/8 | ✅ | seven cleaned-matte candidates await owner |
| H1-B06 Berry Collection | **5/8** | ✅ five exact RGB originals | original RGBs; no RGBA generated |
| **Unique visually-approved illustrations total** | **55** | **✅ 55/55** | **not production-approved** |

Source package is created by **extracting the complete contents of all seven earlier source ZIPs**, with all per-family PNG folders, manifests, original/alpha candidate files, existing QA previews and unchanged bytes, then adding the five BC-01..BC-05 approved Berry Collection originals in the canonical `SeasonalGarden/<Holiday>/<Day|Night>/Originals/` path.

The previously supplied **Base Clock two-image ZIP** is also preserved in extracted form as an earlier/duplicate archival reference; **it does not increase 10 clock designs to 12**. It introduces no path collisions.

**Pending artwork generation:** BC-06 Thanksgiving Night, BC-07 Birthday Day, BC-08 Birthday Night; do not invent these images or mark them approved.

**Night Garden:** The earlier 40 approved Night Garden originals and RGBA images were already tracked in separate GitHub [PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40). These were **not inside the seven locally available ZIPs**. They are not claimed included in this consolidated file, nor should the importer overwrite them.

## Package verification
- [x] Seven input ZIPs extracted (not nested); each existing manifest checked against its original PNG SHA-256.
- [x] Five freshly added, individually approved H1-B06 originals checked as 1254 × 1254 PNGs and assigned source hashes.
- [x] **55 unique source PNGs** with a consolidated JSON/CSV manifest, source receipts, checksums and a Berry Collection mini-preview.
- [x] ZIP integrity/readback and each original's digest checked: **150 entries**, **318,953,250 bytes**.
- [x] Consolidated ZIP **SHA-256: `2e9e321a70aef320e849cd18d82533ae9e86fd6a23a36b02e584a55e25d4c210`**.
- [ ] Upload one full ZIP to a new GitHub Release tag `berry-h1-approved-all-20261120`.
- [ ] Confirm checksum-pinned importer workflow stages the actual extracted asset binaries to the isolated branch.
- [ ] Individually review all non-native-alpha cleanup candidates on light/dark/checker and small iPhone sizes. Original source approval is **not** equivalent to alpha approval.
- [ ] Later: code/calendar/birthday/day-night routing, live digital clock overlay, iOS build, and physical device QA. Do not ship the source package as app assets prematurely.

## Safety and use
The paths in the ZIP already begin at `StrawberryShortcakeBlockBlast/ArtSource/`. Upload the ZIP as a **GitHub Release asset**, not a loose file into `main` or into Xcode's `Assets.xcassets`. The importer stages only the ArtSource tree, refuses mismatched bytes on existing files, and verifies all hashes before committing.

**Status:** Complete visually approved source consolidation, pending GitHub binary import and technical transparency approval. No runtime/gameplay/save/economy modifications.
