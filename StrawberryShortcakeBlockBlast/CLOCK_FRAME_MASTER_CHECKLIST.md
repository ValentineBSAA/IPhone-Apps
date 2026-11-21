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
| C-03 | C-B02 | Halloween | Day | 🟡 GENERATED, owner review pending | ⬜ NOT APPROVED | ⚠ RGB with checkerboard baked into background, needs RGBA cleanup after approval | ⬜ | ⬜ |
| C-04 | C-B02 | Halloween | Night | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| C-05 | C-B03 | Christmas | Day | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| C-06 | C-B03 | Christmas | Night | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| C-07 | C-B04 | Thanksgiving | Day | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
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
- [x] Produce C-03 Halloween Day **review candidate** (single image only). Not approved until owner responds; source currently RGB and includes checkerboard background, so do NOT present it as true RGBA or import it into Xcode.
- [ ] Owner visually accepts or requests a redo of C-03. After acceptance, remove its baked checkerboard cleanly and audit alpha before packaging.
- [ ] Continue C-04 Halloween Night, then one-by-one through C-10, only after each owner approval.
- [ ] Optional later: seasonal overlay priority/region/holiday calendar QA from H0 without invasive location/GPS.

**Always label each image and status explicitly. Never say source PNGs have landed on GitHub until the import workflow confirms it.**
