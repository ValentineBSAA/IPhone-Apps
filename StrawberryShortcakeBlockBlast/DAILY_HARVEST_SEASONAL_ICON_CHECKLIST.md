# 🍓📅 Berry Berry Blast | Daily Harvest Seasonal Icons | Running Checklist

**Category H1-B03**, semantic family #03 in `SEASONAL_MASTER_ICON_BATCH_MATRIX.md`.
**Opened November 20, 2026.** Isolated development branch `artwork/berry-seasonal-daily-harvest-h1-b03`.
**Current state:** DH-01 Halloween Day generated and presented, owner approval pending. No Daily Harvest PNGs have been imported into GitHub.

## What the actual Home icon means
The in-game Home mode is **Daily Harvest**, resolved by SwiftUI `BerryModes.swift` to the artwork named `DailyHarvest`. It is a **once-per-day block puzzle** with actual saved outcome, today's attempt availability, resume and calendar. This illustration must visually signal **a daily calendar and freshly harvested strawberries**, never a generic basket/shop/berry icon alone.

Use a clear **little tear-off calendar page (without printed numbers)** as the centerpiece, with a strawberry basket and a sparkling sun/gold daily-star stamp. The icon should remain understandable at a 64/96px grid-tile size. Game status text like “Completed Today” and “Resume Today” remains live SwiftUI text and must NEVER be baked into the image.

## Workflow, approval and preservation
- One full-resolution original image per message, not multi-image sheets as source artwork.
- One prompt review -> explicit individual approval -> advance to the next Day/Night holiday counterpart.
- Distinct illustrated Day/Night source per holiday; holiday details surround the same *daily calendar + strawberry harvest* concept.
- Reuse the premium glossy strawberry-bakery visual language of approved H1-B01 and H1-B02 icons, but no commercial characters.
- Preserve unmodified original PNG bytes. After approval, derive independent RGBA candidates, check edges on checkerboard/light/dark backgrounds and at 64/96px.
- Stage source at `StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/<Holiday>/<Day|Night>/Originals/Season_<Holiday>_<Day|Night>_DailyHarvest_Original.png`. RGBA candidates in corresponding `RGBA_Candidates` folders, not replacing originals.
- Keep the full 40 Night Garden art set, all 10 clock-frame designs, the 8 Berry Story designs, the first eight cottage images and current Day art independent.
- No game code, 6AM/6PM clock logic, user saves, economy, birthday rewards or Day/Night auto-switching changes in this art batch.

## Eight separate design/QA gates
| ID | Holiday | Appearance | Design direction | Generated | Owner approved | RGBA edge QA | Source in GitHub | iPhone |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DH-01 | Halloween | Day | Sunny berry calendar, strawberry basket, smiling autumn lantern berries, orange/purple foliage | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ alpha/background QA pending | ⬜ source archive pending | ⬜ |
| DH-02 | Halloween | Night | Indigo moonlit calendar, glowing berry harvest, playful ghosts & pumpkin-berry lanterns | ⬜ NEXT: generate single original | ⬜ owner review pending | ⬜ | ⬜ | ⬜ |
| DH-03 | Christmas | Day | Snow-topped calendar, decorated basket, berry wreath, holly and golden bells | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| DH-04 | Christmas | Night | Moonlit snowy calendar, glowing lights, fir trees, soft frost and festive berries | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| DH-05 | Thanksgiving | Day | Harvest calendar, berry crate, gold maples, pumpkin and berry pie | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| DH-06 | Thanksgiving | Night | Plum/amber moonlit calendar, candlelit harvest baskets, foliage and berry pie | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| DH-07 | Birthday | Day | Pink candy calendar, strawberry cake and gift, confetti, bow and festive harvest basket | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| DH-08 | Birthday | Night | Lavender moonlit calendar, sparkling balloons, cake candle, berries and ribbon | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Current checklist
- [x] Verify actual `DailyHarvest` Home-card code use and daily outcome/resume semantics.
- [x] Create isolated H1-B03 branch with a fresh eight-image checklist.
- [x] Generate **DH-01 Halloween Day** individually and show the original for owner review.
- [ ] Owner review of DH-01; do not advance DH-02 or mark visual approval prematurely.
- [ ] Approve DH-01, then generate DH-02 Halloween Night; continue in order, one artwork at a time.
- [ ] Assemble source PNGs, SHA-256 manifest, preview contact sheets and separately reviewed true RGBA candidate files into ZIP after visual approvals.
- [ ] Owner review of alpha candidates, verified GitHub ZIP import and later Xcode physical iPhone acceptance.
- [ ] Continue H1-B04 after H1-B03; no unnecessary recreation of prior approved art.

**Incoming from previous category:** `H1-B02 Berry Story` is 8/8 visually approved and original/RGBA-QA archive prepared (ZIP SHA-256 `9f70bfd18c267315148ce9fbaf55b7628f98fbccf69c2cdf2ae3670054ab008b`). Four image matte candidates are awaiting visual QA, **no Berry Story PNG blobs are in GitHub yet**.

Links: [H1-B02 Berry Story running checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/artwork/berry-seasonal-berry-story-h1-b02/StrawberryShortcakeBlockBlast/BERRY_STORY_SEASONAL_ICON_CHECKLIST.md) · [H1-B01 cottage PR #50](https://github.com/ValentineBSAA/IPhone-Apps/pull/50) · [Seasonal epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42) · [Night Garden PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40)


## DH-01 generation checkpoint
- [x] Halloween Day generated with golden sunburst, numbered-free tear-off calendar, harvest basket of strawberries, pumpkin-berry witch hats, orange leaves and gingham ribbon.
- [ ] **Awaiting owner approval.** Preserve original in chat; image source ZIP/PNG GitHub import is not yet complete.
- [ ] Check apparent checkerboard: original PNG alpha channel must be verified and matte corrected if necessary after original visual approval.

**Current H1-B03 totals: 1/8 generated, 0/8 approved.**


### DH-01 approved; DH-02 next
- [x] DH-01 Halloween Day visually approved by owner (“Good continue”). Preserve existing approved original with daily calendar, ripe strawberry basket, playful pumpkin berries, sunlight and orange/violet bow.
- [ ] NEXT DH-02 Halloween Night: same Daily Harvest semantic symbols (calendar page plus berry basket), distinct indigo/violet moonlit lighting, stars and friendly jack-o'-lantern strawberry accents, no static date numbers or text. Generate **one** image, wait for owner acceptance before DH-03.
- [ ] Actual source PNG GitHub binary import, RGBA alpha/edge QA, packaging and live app integration remain pending.

**Daily Harvest tally: 1/8 approved, 1/8 generated before DH-02.**
