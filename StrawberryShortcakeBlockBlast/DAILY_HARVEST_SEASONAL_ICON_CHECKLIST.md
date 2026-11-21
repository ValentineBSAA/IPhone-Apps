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
| DH-02 | Halloween | Night | Moonlit calendar, basket of strawberries, crescent and stars, glowing witch-hat jack-o'-lantern berries | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ alpha/edge QA pending | ⬜ source import pending | ⬜ |
| DH-03 | Christmas | Day | Snow-topped red/green calendar, harvested strawberry basket, holly, bells, candy canes; approved second generated variant | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ baked checkerboard possible; alpha QA pending | ⬜ source import pending | ⬜ |
| DH-04 | Christmas | Night | Moonlit snowy calendar with strawberry basket, glowing firs, gold crescent and stars, holly and bells | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ alpha/edge QA pending | ⬜ original import pending | ⬜ |
| DH-05 | Thanksgiving | Day | Warm sunlit calendar, harvested strawberries, berry pie, pumpkins, corn, autumn maple leaves and orange gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ true-alpha/edge QA pending | ⬜ original source not staged | ⬜ |
| DH-06 | Thanksgiving | Night | Moonlit calendar, harvest basket, berry pie, corn, pumpkins, lanterns and plum-orange gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ RGBA/edge QA pending | ⬜ original source not staged | ⬜ |
| DH-07 | Birthday | Day | Pink birthday calendar, strawberry cake, balloons, gifts, confetti, sunny berry basket and gingham bow | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ background/alpha QA pending | ⬜ source import pending | ⬜ |
| DH-08 | Birthday | Night | Moonlit birthday calendar, strawberry basket, golden moon and stars, glowing cake candle, balloons and pink-lavender ribbon | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ alpha/edge QA pending | ⬜ original binary import pending | ⬜ |

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


### DH-02 Halloween Night generation checkpoint
- [x] DH-02 generated as one original review image in chat: gold crescent and stars, magenta calendar without static dates, strawberry basket, friendly purple witch-hat pumpkin berries and orange/purple gingham bow.
- [ ] Individual owner approval pending. Do not mark DH-02 approved or generate DH-03 until owner responds.
- [ ] Original PNG and RGBA derivative files not yet uploaded; later alpha inspection, separate packaging, checksums, small-scale QA and on-device integration remain open.

**Daily Harvest tally: 2/8 generated, 1/8 visually approved.**


### DH-02 owner approval / DH-03 next
- [x] DH-02 Halloween Night visually approved by owner (“Good continue”). Preserve the existing generated original: a clear daily calendar, strawberry basket, glowing witch-hat berries, crescent and stars.
- [ ] **NEXT DH-03 Christmas Day**: one independently illustrated sunny snowy strawberry daily calendar, woven harvested berry basket, snowy evergreens, candy canes, holly and red-green bow. No printed dates or fake UI text; await owner approval before DH-04 Night.
- [ ] Alpha/edge QA, exact original archive, RGBA version, preview sheet, source ZIP and verified GitHub binary upload are separate pending gates.

**Daily Harvest visuals approved: 2/8.**


### DH-03 Christmas Day generation review gate
- [x] Christmas Day calendar + strawberry basket art generated; final review candidate is the red-green gingham bow version with snow, holly, bells, candy canes and a golden sun. An additional alternate render exists, **not approved nor counted** as another semantic use-site.
- [ ] Owner must explicitly approve the chosen DH-03 visual before DH-04 Christmas Night. No automatic approvals.
- [ ] The generated PNG shows a checkerboard-like background; preserve the original untouched and inspect alpha data, perform non-destructive RGBA extraction if baked, then checker/light/dark/64/96px QA.
- [ ] These art PNGs have not been uploaded to GitHub; only the checklist and separate in-progress design tracking are committed.

**Latest H1-B03 tally: 3/8 icon slots generated, 2/8 visual designs approved; 0/8 binary PNGs imported.**


### DH-03 owner approval, DH-04 Christmas Night queued
- [x] **DH-03 Christmas Day**: owner visually approved the second generated variant with red-green gingham ribbon, red calendar, harvest basket, golden sun, holly, snow, Christmas bells and candy canes. Preserve that specific original, not the first alternative.
- [ ] **DH-04 Christmas Night**: generate exactly one companion showing the same daily calendar and strawberry harvest basket, moonlit sapphire-violet winter sky, lit snowy firs, a glowing crescent and festive decorations. Keep date numerals and labels out of static image.
- [ ] Christmas Day background appears checkerboard in review; independently verify alpha and remove any baked backdrop non-destructively before RGBA candidate approval. No PNG bytes have been committed to GitHub yet.
- [ ] Source/RGBA ZIP, checksums, transparency QA, and iPhone integration remain separate future gates.

**Latest H1-B03 status: DH-01 Halloween Day, DH-02 Halloween Night, and DH-03 Christmas Day visually approved (3/8). DH-04 generation next.**


### DH-04 Christmas Night generated, approval pending
- [x] One Christmas Night original generated and shown in chat: gold crescent and stars in purple cloud sky, snowy evergreen fairy lights, strawberry date-free calendar, snow-capped harvested berry basket, gold bells and red/green gingham ribbon.
- [ ] Await explicit owner visual approval for DH-04 before DH-05 Thanksgiving Day; **do not mark approved** from generation alone.
- [ ] Inspect actual PNG alpha and edges, preserve exact original, then create separate RGBA candidates, 64/96px and light/dark/checker proofs, checksum ZIP and verified GitHub binary import.

**Daily Harvest now 4/8 generated, 3/8 visually approved; PNG GitHub import and iPhone QA pending.**


### DH-04 approved / Thanksgiving Day next
- [x] DH-04 Christmas Night visually approved by owner (“Good continue”). Preserve its original moonlit Christmas harvest-calendar artwork, do not regenerate.
- [ ] **NEXT DH-05 Thanksgiving Day**: one original square Home tile with centered day-calendar page and fresh strawberry basket, gold maple leaves, pumpkins, berry pie, harvest gingham and sunny amber accents, without printed dates/words. Owner approval required before DH-06 Thanksgiving Night.
- [ ] All source PNG binary import, actual alpha/edge verification, RGBA candidates, checker/light/dark and small-scale proofs, ZIP manifest and Xcode/physical iPhone QA remain separate open gates.

**Current Daily Harvest: 4/8 visually approved; DH-05 next.**


### DH-05 Thanksgiving Day candidate generated
- [x] One individually generated image shown in chat: cream-faced number-free spiral calendar, gold sunlight, woven strawberry basket, orange checkered bow, pumpkins, corn, maple leaves and lattice strawberry pie.
- [ ] Await explicit visual approval before DH-06 Thanksgiving Night.
- [ ] Keep exact source image intact and inspect true transparency rather than assuming image background is transparent; RGBA QA/ZIP/GitHub binary import/Xcode device QA remain separate.

**Current Daily Harvest: 5/8 designs generated, 4/8 visually approved, DH-05 awaiting review.**


### Owner approval checkpoint: DH-05 Thanksgiving Day
- [x] **DH-05 Thanksgiving Day** visually approved by owner (“Good continue”). Preserve the generated sunlit calendar-and-basket art featuring strawberry pie, pumpkins, corn and orange maple leaves.
- [ ] **NEXT DH-06 Thanksgiving Night**: one matching calendar plus wicker strawberry harvest basket with warm candle/lantern light, crescent moon, stars, pumpkins, berry pie and plum-amber foliage. Await explicit owner approval before DH-07 Birthday Day.
- [ ] PNG source hashing, true RGBA and edge assessment, separate candidates, checked ZIP, GitHub binary import, and iPhone runtime QA remain open.

**Current Daily Harvest visual approvals: 5/8.**


### DH-06 Thanksgiving Night generation checkpoint
- [x] Independently generated one Thanksgiving Night calendar-and-basket icon in chat: illuminated golden crescent and stars, burgundy clouds, strawberry calendar with no date text, pumpkin, corn, maple leaves, lattice berry pie and candle lanterns. This is a review candidate.
- [ ] **Awaiting explicit owner visual approval for DH-06.** Do not proceed to DH-07 Birthday Day until accepted.
- [ ] Preserve exact PNG source; source import, true-alpha validation, checker/light/dark and 64/96px previews, and separately approved RGBA candidate remain open.

**H1-B03 current: 6/8 generated, 5/8 owner visually approved.**


### Latest owner checkpoint: DH-06 Thanksgiving Night approved, DH-07 next
- [x] DH-06 Thanksgiving Night visually approved by owner (“Good continue”). Preserve existing generated moonlit calendar-and-harvest-basket design with berry pie, pumpkins, lanterns and plum-orange gingham.
- [ ] **NEXT DH-07 Birthday Day**: one standalone glossy strawberry calendar + basket icon; birthday cake, balloons, gifts, confetti and pink gingham in a cheerful daytime setting. No printed date, numbers, status text or rewards. Owner approval required before DH-08 Birthday Night.
- [ ] All source-image archival, RGBA/edge QA, contact sheets, ZIP checksums, GitHub binary import, Xcode integration and device QA remain separate pending steps.

**Current tally: Daily Harvest 6/8 visually approved; DH-07 next.**


### DH-07 Birthday Day generation checkpoint
- [x] One standalone Birthday Day icon generated and shown in chat: golden daytime sun over a text-free strawberry calendar, wicker strawberry basket, pink birthday cake with lit candle, gift box, balloons, ribbons, flowers and pink gingham bow.
- [ ] **Await owner visual approval**; do not mark approved or proceed to DH-08 Birthday Night until the owner accepts the current source.
- [ ] Visible checkerboard may be baked into RGB pixels. Preserve exact original PNG and inspect true alpha before creating a separate RGBA cleanup candidate. Later preview light/dark/checker and 64/96px, ZIP/checksum GitHub import and iPhone QA are still open.

**Current H1-B03: 7/8 generated; 6/8 visually approved; DH-07 awaiting owner.**


### Owner checkpoint: Birthday Day approved, final Birthday Night queued
- [x] **DH-07 Birthday Day** visually approved by owner (“Good continue”). Preserve the original image exactly, including golden sun over date-free strawberry calendar, full harvest basket, balloons, cake candle and pink ribbon.
- [ ] **NEXT DH-08 Birthday Night:** generate one matching moonlit calendar plus strawberry basket with glowing candle, balloons, crescent/stars and lavender/magenta bow. Await explicit owner acceptance before marking family 8/8 approved.
- [ ] No original PNGs claimed GitHub-imported; alpha/edge QC, RGBA derivatives, separate 64/96px proofs, ZIP/manifest, GitHub binary upload and real iPhone testing remain open.

**Daily Harvest H1-B03: 7/8 generated, 7/8 approved.**


### DH-08 Birthday Night generation checkpoint
- [x] One matching birthday-night calendar and harvested strawberry basket original generated and shown in chat, with gold crescent, purple clouds, star sparkles, pink party cake and candle, balloons, birthday present and strawberry-pink/lavender bow.
- [ ] **Owner visual approval of DH-08 pending.** Do not declare 8/8 owner approved until acceptance.
- [ ] Source PNG on GitHub, RGBA alpha proof/cleanup if required, source+RGBA ZIP and iPhone QA are independently pending.

**Daily Harvest H1-B03: 8/8 original designs generated, 7/8 owner approved.**


### DH-08 final visual approval · family completion checkpoint
- [x] **DH-08 Birthday Night** expressly visually approved by owner ("Good continue"). Keep its original moonlit calendar, pink cake, balloon cluster, woven harvest basket and strawberry-themed ribbon.
- [x] **H1-B03 Daily Harvest visually approved 8/8**, all four holidays (Halloween / Christmas / Thanksgiving / Birthday) and Day/Night paired.
- [ ] Verify and archive **all eight exact original PNG bytes** with SHA-256 and original/alpha-candidate separation before making any claim of RGB-to-RGBA success.
- [ ] Generate QA previews (checker, light, dark and 64/96px), package in a verified ZIP, stage through isolated GitHub binary import. No source PNGs considered in GitHub until import reports success.
- [ ] Obtain separate alpha edge review and real iPhone appearance/routing acceptance before shipping.
- [ ] Next distinct category from seasonal master matrix: **More Adventures** Home tile, H1-B04, eight separate original images, one generated per approval.

**Latest authoritative status:** 8/8 visuals owner-approved; RGB/RGBA QC and GitHub binary staging are pending; do not overwrite earlier Night Garden, clocks, Story or H1-B01 cottage assets.
