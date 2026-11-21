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


## Chat delivery-size fallback (same single master ZIP bytes, split for upload)
- [x] Full master ZIP is verified, 318,953,250 bytes, pinned SHA-256 `2e9e321a70aef320e849cd18d82533ae9e86fd6a23a36b02e584a55e25d4c210`; too large for one ChatGPT downloadable attachment.
- [x] Split exact ZIP bytes into eight *ordered* files `Berry_Berry_Blast_ALL_Approved_Seasonal_Artwork_GitHub_2026-11-20.zip.part01` through `.part08`: first seven 45,000,000 bytes each, eighth 3,953,250 bytes.
- [x] Parts concatenated in order were locally verified to yield exactly the master ZIP SHA-256 above. Optional Windows script `Reassemble_Berry_Berry_Blast_Seasonal_Master.ps1` verifies the reassembled SHA if one physical ZIP is preferred.
- [x] GitHub workflow on `main`: `.github/workflows/berry-approved-h1-consolidated-import.yml` now accepts EITHER the intact ZIP OR all eight parts attached to **one release** with tag `berry-h1-approved-all-20261120`, reassembles in order, checks SHA-256 + 55 original hashes + each archived file and stages only to the isolated branch.
- [ ] User uploads all eight part files to a draft GitHub Release, then publishes it. **Do not publish before all eight attachments are present.** Verify workflow success; no GitHub PNG blob import has been claimed before it runs.

Note: this fallback affects only delivery, not the 55 image designs, approved source bytes, manifest contents or QA status.


## ✅ Actual GitHub import completed and verified
- [x] User published the Release named **Approved All App icons so far seasonal home** with tag `berry-h1-approved-all-20261120`, eight assets of 45,000,000 bytes × 7 and 3,953,250 bytes × 1.
- [x] Release workflow successfully reassembled the ZIP and verified **318,953,250 bytes**, pinned archive hash, all **150 package entries**, and each of 55 approved source-original hashes.
- [x] Existing eight H1-B01 Home Classic PNGs compared Git-object byte hashes and matched archive originals; **not replaced**.
- [x] Two older H1-B01 manifest/README differences archived under `ArtSource/00_Consolidated_H1_2026-11-20/Preserved_H1_Batch01_Archive_Metadata/` rather than overwritten. `IMPORT_PRESERVED_METADATA_MAPPING.json` now valid JSON for auditing.
- [x] Confirmed master tree includes all **55/55 unique original PNG paths** with matching file sizes against `CONSOLIDATED_ASSET_MANIFEST.json`.
- [x] Added **55 unique game-facing image key suggestions** and source path/alpha readiness to `APP_ASSET_BINDINGS_DRAFT.json`, plus integration notes at `ArtSource/README_SEASONAL_STAGING.md`.
- [x] Original import GitHub Actions run [44860171770](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44860171770) **SUCCESS**; patched and idempotent verification run [44860324828](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44860324828) **SUCCESS**.
- [ ] **Still not shipped:** none of the new staged images have been assigned to app `Assets.xcassets`, alpha candidates have not received owner acceptance, and real iPhone QA is still pending. Keep draft PR open for further integration work.
- [ ] Future completion: BC-06 Thanksgiving Night, BC-07 Birthday Day, BC-08 Birthday Night, then updated manifest and a separate QA-approved runtime branch. The separate prior 40 Night Garden images remain preserved.

**Definitive milestone:** *GitHub staging import COMPLETE and verified, 55/55 approved originals present*. *App/runtime integration NOT YET COMPLETE*.


## ✅ One-piece GitHub Release ZIP created successfully
- [x] Workflow run [44860472753](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44860472753) **SUCCESS**: rebuilt and fully validated the master ZIP, detected 55 staged originals unchanged, and uploaded the verified one-piece archive to the same named Release.
- [x] Confirmed GitHub Release now exposes [`Berry_Berry_Blast_ALL_Approved_Seasonal_Artwork_GitHub_2026-11-20.zip`](https://github.com/ValentineBSAA/IPhone-Apps/releases/download/berry-h1-approved-all-20261120/Berry_Berry_Blast_ALL_Approved_Seasonal_Artwork_GitHub_2026-11-20.zip), exact byte count **318,953,250**. The original eight upload parts remain available as backup.
- [x] Source folders and `APP_ASSET_BINDINGS_DRAFT.json` already exist in dedicated staging branch; alpha review and Xcode runtime work remain intentionally separate.

**Current decisive status: Release combined ZIP READY; GitHub organized 55-image asset source import READY; production runtime NOT YET CONNECTED.**
