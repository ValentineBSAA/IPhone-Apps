# 🍓 Berry Berry Blast · Seasonal Source Transparency Technical Review

**Audit:** November 20, 2026; sourced only from the immutable checksum-verified [master ZIP](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/berry-h1-approved-all-20261120).  
**Scope:** 55 individually approved artwork *designs*. Technical RGBA file existence and per-pixel alpha examination are **not owner visual approval** and **not proof of iPhone render-quality acceptance**.

## Exact baseline
- [x] **55/55** approved original artwork paths archived and verified.
- [x] **42/55** have separately addressable RGBA candidate files; all 42 confirmed actual RGBA mode. This is **not equivalent** to 42 production-ready icon mattes.
- [x] **20/55** candidate files match original bytes exactly and were originally **native RGBA**.
- [x] **22/55** are **non-destructively generated alpha cutout candidates** (source not overwritten); these need explicit edge/halo and interior-transparent-gap review.
- [ ] **13/55** have **no RGBA candidate**: **8 H1-B01 Home Classic** original RGBs and **5 H1-B06 Berry Collection** original RGBs. Prepare/review separate mattes without new image generation.
- [ ] All candidates must pass light/dark/checker backgrounds at 64, 96 and 144px, plus actual iPhone card rendering and scroll state; source-only alpha coverage is not sufficient.
- [ ] Four native RGBA files contain negligible **alpha value 1** in one corner (Daily Harvest Christmas Night and Thanksgiving Night, More Adventures Halloween Day and Christmas Day). Treat as low-level fringe cleanup warning, **not opaque blocking corners**; these are visually near-transparent but should be checked at phone size.
- [ ] No production `Assets.xcassets` routing or seasonal automation enabled at this QA stage.

## Family breakdown

| Family | Visual designs approved | Native RGBA source | Cutout candidates | Missing RGBA |
|---|---:|---:|---:|---:|
| Home Classic | 8 | 0 | 0 | **8** |
| Digital Clock Frames | 10 | 8 | 2 | 0 |
| Berry Story | 8 | 4 | 4 | 0 |
| Daily Harvest | 8 | 5 | 3 | 0 |
| More Adventures | 8 | 2 | 6 | 0 |
| My Strawberry Cottage Decorations | 8 | 1 | 7 | 0 |
| Berry Collection | 5 | 0 | 0 | **5** |
| **Total** | **55** | **20** | **22** | **13** |

## Recommended non-generative alpha QA order
1. Create non-destructive RGBA cutouts for **13 missing candidates**, keeping exact originals and hashes untouched. Test for baked checkerboard, black/white matte and tiny interior holes.
2. Recheck the **22 derived cutouts** on cream, plum and checkerboard, focusing on thin ribbon loops, flower petals, gold trim and calendar page interior.
3. Check native RGBA against the same backgrounds, with four alpha-1 corner notes above.
4. Assemble one consolidated **review contact sheet** with all 55 semantic variants at true phone-image display sizes; get owner visual signoff separately from previously completed illustration approval.
5. Only then enable typed SwiftUI asset lookup and seasonal app-time policy on a separate test branch; never merge staging images directly into main or substitute unreviewed RGB backgrounds.

## Next checklist while image generation is limited
[Seasonal architecture and calendar issue #47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47). A Foundation-only, non-mutating **H5 image resolver + temporal policy** can be built and tested without generating any new art:
- Preserve the existing 6 AM / 6 PM Day/Night appearance, separate from game mode.
- Calendar regions/time zones are device configuration and not GPS physical presence; avoid location permissions.
- Existing dormant `BerrySeasonalCalendar` correctly addresses Halloween Oct 31, Christmas Dec 25, U.S. Thanksgiving fourth November Thursday and separately opted-in birthday, but no live UI is yet wired.
- **Missing BC-06, BC-07 and BC-08** must fall back to existing artwork, never show blank tiles or pretend they exist.
- Do not change birthday gift, quests, save state, scores or wallet.

**Result:** design inventory passed; transparency/edge QA remains open, and safe non-visual seasonal runtime planning can proceed in parallel.
