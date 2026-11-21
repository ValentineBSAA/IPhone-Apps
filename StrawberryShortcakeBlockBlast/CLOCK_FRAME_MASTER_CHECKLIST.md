# 🍓 Berry Berry Blast · LIVE DIGITAL CLOCK FRAME MASTER CHECKLIST

**Owner checkpoint:** November 20, 2026 · **Review status:** 2/2 regular Day/Night frames visually approved.
**Staging branch:** `artwork/berry-clock-frames-c-b01-staging` (isolated, not merged).
**Package:** `Berry_Berry_Blast_Base_Clock_Frames_B01_Day_Night_RGBA.zip` · SHA-256 `ef36481929c5db6074d0bda3298614439e298dc4a4ae7f74d5f8e747aa5cd83a` · 9,159,252 bytes.

## CLOCK ART: what is and is not being generated
The approved format is a **wide compact decorative plaque** with a large, completely empty center into which the native iPhone app renders its **actual live local 12-hour digital time** via SwiftUI (e.g. `h:mm a`). The image contains **NO clock hands, analog dial, markings, fixed numbers or time text**. All decorative illustrations and effects are outside the safe digital-text center, and never overlay gameplay controls. Seasonal art is a separate palette/state; it must not tamper with the standard Day/Night system.

**One image generation at a time.** Show each original at full size before marking it approved; only once its owner approves it, advance to the next (Day then Night, repeat for all events). After the family is approved, generate a review PNG, verify true transparency, create ZIP + manifest + checksum, stage source on GitHub, and gate Xcode integration behind phone QA. Never silently approve multiple images or regenerate existing accepted artwork.

## C-B01 · REGULAR/NONSEASONAL LIVE CLOCK PAIR
| ID | Appearance | Description | Owner visual approval | Technical RGBA | GitHub source blob | iPhone/Xcode |
|---|---|---|---|---|---|---|
| C-01 | REGULAR DAY | Strawberry-pink glass, pink gingham bow, white blossoms, scalloped hearts; blank cream center | ✅ APPROVED | ✅ source already RGBA | ⏳ package prepared; release import pending | ⬜ pending |
| C-02 | REGULAR NIGHT | Purple glass, gingham bow, gold crescent and stars; blank lavender center | ✅ APPROVED | ✅ source already RGBA | ⏳ package prepared; release import pending | ⬜ pending |

Source file naming:
- `ArtSource/ClockFrames/Base/Day/Originals/BBB_BaseClock_Day_Original.png` (1774×887, 2,013,557 bytes, SHA-256 `d6b023f8b698f57016a39e8cf63d3954369b176504843aea1dca10cec6fa0d09`)
- `ArtSource/ClockFrames/Base/Night/Originals/BBB_BaseClock_Night_Original.png` (1774×887, 2,214,635 bytes, SHA-256 `eaeebd1fdb168ed26d62f40d2b90cb9849f001dc831a5004ff96428e528d544b`)

Both original image files include true alpha already; byte-identical `RGBA_Candidates` are included only to maintain the approved source/alpha staging convention. **No background-removal or pixel transformation was performed.** 64px/96px small-scale, live SwiftUI overlay readability and iPhone 16e QA remain open.

## C-B02–C-B05 · HOLIDAY LIVE CLOCKS
Each holiday needs a new, individually illustrated **Day** and **Night** counterpart, using C-B01 geometry and ample clean center for digital time.

| ID | Batch | Holiday | Appearance | Illustration | Visual review | RGBA QA | GitHub source | Runtime |
|---|---|---|---|---|---|---|---|---|
| C-03 | C-B02 | Halloween | Day | ✅ generated | ✅ OWNER APPROVED | ⚠ true RGBA source; alpha edge QA pending | ⬜ source package pending | ⬜ |
| C-04 | C-B02 | Halloween | Night | ✅ generated | ✅ OWNER APPROVED | ⚠ true RGBA source; alpha edge QA pending | ⬜ source package pending | ⬜ |
| C-05 | C-B03 | Christmas | Day | ✅ original generated | ✅ OWNER APPROVED | ⬜ RGBA edge/halo QA pending | ⬜ source package pending | ⬜ |
| C-06 | C-B03 | Christmas | Night | ✅ original generated | ✅ OWNER APPROVED | ⬜ RGBA edge/halo QA pending | ⬜ source package pending | ⬜ |
| C-07 | C-B04 | Thanksgiving | Day | ⬜ NEXT: generate one design for review | ⬜ | ⬜ | ⬜ | ⬜ |
| C-08 | C-B04 | Thanksgiving | Night | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| C-09 | C-B05 | Birthday | Day | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| C-10 | C-B05 | Birthday | Night | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

**Thanksgiving reference:** owner previously accepted the harvest-themed wide strawberry clock plaque as the holiday *design baseline*, not as a replacement for the two regular clock images. This does **not** automatically approve both final Thanksgiving clock counterparts.

## Sources and separation
- `SEASONAL_MASTER_ICON_BATCH_MATRIX.md` / draft PR #50 holds the distinct **8/8 visually approved and GitHub-imported** Halloween, Christmas, Thanksgiving and Birthday Day/Night *cottage* originals. They are not clock frames and do not map unreviewed to the actual Berry Classic puzzle icon.
- Night Garden draft PR #40 contains 40 previously approved Night icons and 40 approved RGBA candidates. The preexisting generic Day art and 30 older `Night_*` image sets are immutable.
- H0 date/region policy prototype draft PR #48 is a separate code workstream; birthday reward already exists and must not be duplicated.
- Build 4.7/4.8, Build 5 and Build 6 stay independent. A clock illustration is not a new game version, IPA or a working clock implementation.

## Batch ZIP and import checklist
- [x] C-01 Regular Day original generated and explicitly visually approved.
- [x] C-02 Regular Night original generated and explicitly visually approved.
- [x] Both source files present and validated as full-resolution 1774×887 RGBA PNGs with genuine transparent pixels.
- [x] Source and RGBA candidates stored as separate entries in a checksum-verified downloadable ZIP.
- [x] Two-column proof preview made with checker, cream and dark backgrounds.
- [x] Isolated GitHub branch and running checklist created; no existing artwork overwritten.
- [ ] Owner uploads clock ZIP in a release under tag `berry-base-clocks-b01` and exact filename above.
- [ ] Release-triggered GitHub import succeeds and the two binary original source PNGs are verified in the isolated branch.
- [ ] Native SwiftUI clock overlay integrated and verified at live 12-hour clock, timezone and foreground updates.
- [ ] Test on iPhone 16e: safe height/width, text contrast/size, accessibility, correct automatic 6AM/6PM standard Day/Night transition.
- [x] C-03 Halloween Day generated and owner visually approved. The chosen source is an RGBA PNG, but edge/halo checks and archive staging are still pending.
- [x] C-04 Halloween Night generated and owner visually approved. Preserve the first owner-approved nighttime frame, not later redundant regenerations.
- [ ] Package C-03 and C-04 originals and RGBA QA copies, contact sheets and hashes; upload and verify separately from base clocks.
- [x] C-05 Christmas Day generated and individually visually approved by owner. Keep holiday snow, strawberry in Santa hat and red/gold detailing.
- [x] C-06 Christmas Night generated and individually visually approved by owner. Preserve moonlit snowman-and-evergreen red gingham composition.
- [ ] Package Christmas Day/Night originals + true RGBA/edge QA + previews + SHA manifest before GitHub binary staging.
- [ ] NEXT: C-07 Thanksgiving Day, one image for approval, then C-08 Thanksgiving Night, then C-09/C-10 Birthday.
- [ ] Optional later: seasonal overlay priority/region/holiday calendar QA from H0 without invasive location/GPS.

**Always label each image and status explicitly. Never say source PNGs have landed on GitHub until the import workflow confirms it.**


## Owner approval correction / checkpoint
C-03 Halloween Day and C-04 Halloween Night are approved visual designs by owner in chat. Both images can be opened as RGBA PNGs with transparent pixels, but edge-cleanliness, 64/96px previews, packaging, release import, Xcode integration and device QA remain separate open gates. **One new original per next review.** Any additional Halloween Night duplicates generated after C-04 approval are out-of-sequence and not additional approved semantic assets. Next item: **C-05 Christmas Day**.


## Checkpoint: Christmas Day/Night visual approvals (November 20, 2026)
- [x] **C-05 Christmas Day:** owner's explicit visual approval immediately before Christmas Night generation; glossy snowy red-and-gold strawberry frame, Santa-hat berry, blank cream center.
- [x] **C-06 Christmas Night:** owner: “wonderful now Mark those complete and go onto the next generation”; winter moon, snowman, fir trees and a purple blank center; digitally displayed time will be drawn in SwiftUI, not painted into artwork.
- [ ] Do NOT equate visual approval with verified transparent RGBA edges; inspect halos, render light/dark/checker previews, 64/96px legibility and package original PNGs separately with hashes.
- [ ] Not yet GitHub-uploaded: these two binary PNGs; no Xcode icon import or physical iPhone QA claim.
- [ ] **CURRENT NEXT: C-07 Thanksgiving DAY**, using the previously accepted harvest digital plaque as style reference, with separate C-08 NIGHT to follow.

**Overall clock frame visual approvals: 6/10 (Regular Day/Night + Halloween Day/Night + Christmas Day/Night).** Other family stages are independent. Earlier erroneous extra Halloween generations remain excluded.
