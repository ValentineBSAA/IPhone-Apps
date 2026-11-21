# 🍓🏆 Berry Berry Blast | H1-B06 Berry Collection Seasonal Home Icon Running Checklist

**Opened:** November 20, 2026. **Isolated branch:** `artwork/berry-seasonal-berry-collection-h1-b06`.  
**Current status:** BC-01 Halloween Day generated; 1/8 image slots generated and 0/8 visually owner-approved. Await explicit owner review.

## Actual app semantics
In `BerryModes.swift` the Home grid tile resolves to:
`BerryGridNavigationTile(title: "Berry Collection", detail: "Inventory, awards and personal records", art: "BerryCollection", caption: "My Treasures") { showCollection = true }`.

This is the player's **owned inventory, achievements, awards and personal records**, *not* an in-app shop (`Berry Boutique`), chapter/storybook (`Berry Story`) or daily calendar (`Daily Harvest`).

**Central motif:** a glossy **strawberry treasure keepsake chest** with an open lid, visible gold berry medallion/trophy and a little collectible sticker/award card on a stand. All icons must read as a collection of earned treasures, not a purchase storefront; avoid readable scores, counts, fake awards, names, prices or interactive controls baked into art. Preserve original strawberry game icon visual language and make core treasure chest/award readable at 64/96px. Event ornaments and Day/Night lighting are secondary.

## Approval and source integrity
- Generate **exactly one standalone original per user approval**. Sequence is Halloween Day → Night, Christmas Day → Night, Thanksgiving Day → Night, Birthday Day → Night.
- Preserve owner-approved exact source PNG bytes. The original and RGBA candidate are two separate files, never destructively overwrite.
- Source location: `StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/<Holiday>/<Day|Night>/Originals/Season_<Holiday>_<Day|Night>_BerryCollection_Original.png`; RGBA candidates in sibling `RGBA_Candidates/`.
- Native RGBA requires real alpha, not merely image of checkerboard; for RGB or black/white backgrounds, perform separate alpha segmentation and visually inspect edge halos, missing interior details, flower petals, metal scrollwork and ribbon loops.
- After all eight design approvals: SHA-256 manifest, eight originals + eight RGBA candidates, checker/cream/dark proofs, 64/96/144px readability, checked ZIP and separate owner alpha approval.
- Only then GitHub Release ZIP staging through checksum-pinned isolated importer. App asset routing, local holiday and Day/Night scheduling, iPhone testing and rollout have their own future gates.
- Do NOT overwrite H1-B01 Cottage/Home Classic originals, H1-B02 Berry Story, H1-B03 Daily Harvest, H1-B04 More Adventures, H1-B05 My Strawberry Cottage, 10 clock frames or previous 40 Night Garden originals. Do not alter live in-app collection ownership, progress, save files or wallet.

## Eight visual review gates

| ID | Holiday | Lighting | Visual direction | Generated | Owner approved | RGBA candidate QA | Source PNG GitHub | Runtime/iPhone QA |
|---|---|---|---|---|---|---|---|---|
| BC-01 | Halloween | Day | Sunlit pink strawberry treasure chest with gold earned medal and award card, orange leaves, pumpkin-berries, purple hat, autumn gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ RGB checkerboard backdrop; RGBA cleanup pending | ⬜ source PNG not staged | ⬜ |
| BC-02 | Halloween | Night | Moonlit violet strawberry keepsake chest with gold medal and collectible card, glowing berry jack-o'-lanterns, autumn foliage and orange-purple gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ 1254px RGB, off-white baked background; RGBA QA pending | ⬜ original PNG not staged | ⬜ |
| BC-03 | Christmas | Day | Sunny snowy strawberry keepsake chest, earned gold berry medal and trophy card, gold bells, decorated evergreens, candy canes and red-green gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ RGB checkerboard; separate RGBA cleanup/edge QA pending | ⬜ source PNG not staged | ⬜ |
| BC-04 | Christmas | Night | Moonlit snowy strawberry keepsake chest, gold berry medal and trophy card, glowing decorated evergreens, bells, candy canes, crescent and red-green gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ RGB/off-white background; separate RGBA cleanup/edge QA pending | ⬜ original PNG not staged | ⬜ |
| BC-05 | Thanksgiving | Day | Sunlit amber harvest strawberry treasure chest with golden berry medal, collectible award card, maple leaves, pumpkins, berry pie and orange gingham | ⬜ NEXT: single original generation | ⬜ awaiting owner approval | ⬜ | ⬜ | ⬜ |
| BC-06 | Thanksgiving | Night | Candlelit plum-and-gold collection chest, moon/stars, pumpkins, leaves, berry harvest accents | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-07 | Birthday | Day | Bright berry keepsake chest, earned medal and collectible, birthday cake, balloons and gifts | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-08 | Birthday | Night | Lavender birthday treasure chest, golden award, candlelit cake, confetti and starry balloons | ⬜ | ⬜ | ⬜ | ⬜ |

## Production ledger
- [x] Verified exact Berry Collection Home role and art string in current tracked SwiftUI code.
- [x] Isolated H1-B06 branch and current 8-image checklist opened.
- [x] Generate **BC-01 Halloween Day** as one standalone image and show it to owner.
- [ ] Obtain explicit BC-01 owner visual approval before BC-02 Halloween Night.
- [ ] BC-02 through BC-08 each receive their own image + explicit approval before proceeding.
- [ ] Process true RGBA and QA at multiple backgrounds/phone UI sizes, then originals/RGBA manifest + ZIP.
- [ ] Review alpha separately, stage binaries to GitHub Release/import and verify, then later Xcode + iPhone appearance QA.

## Prior family status (preserved)
H1-B05 Cottage Decorations: **8/8 visuals approved**. Exact-original/QA archive `Berry_Berry_Blast_Cottage_Decor_H1_B05_8_Originals_RGBA_QA.zip`: 56,158,942 bytes, SHA-256 `78730fd5ee2e1885bd90c2cabdb94e817903e0830c8babc9d10970501a4b7393`. 7 non-destructive cutout candidates still require owner matte review. GitHub import workflow installed on main, but binary PNG upload still pending.

Other batches remain tracked independently in master seasonal matrix; no IPA/build/runtime changes implied by this icon production pass.

References: [Seasonal master icon matrix](SEASONAL_MASTER_ICON_BATCH_MATRIX.md) · [Previous H1-B05 checklist](COTTAGE_DECOR_SEASONAL_ICON_CHECKLIST.md) · [Seasonal epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).


### BC-01 Halloween Day generation checkpoint
- [x] One Halloween Day Berry Collection icon presented in chat: a large open red strawberry keepsake chest, gold berry achievement medallion, trophy award card, sunny harvest decoration, friendly jack-o'-lantern berries and autumn gingham bow. No fake score or price text.
- [ ] Individual owner visual approval pending; do not advance to BC-02 until accepted.
- [ ] Generated original is 1254×1254 RGB with light checkerboard-style background (not verified alpha). Freeze exact original; future separate RGBA cutout candidate with light/dark/small-scale QA after approval. No binary uploaded to GitHub and no game asset routing yet.

**H1-B06 latest tally: 1/8 generated, 0/8 visually approved.**


### BC-01 approved and BC-02 Halloween Night next
- [x] **BC-01 Halloween Day** visually approved by owner (“Good continue”): open strawberry keepsake chest with gold strawberry achievement medallion and award card, sunny fall decor and pumpkin berries. Preserve exact original; design approval is not alpha or production approval.
- [ ] **NEXT BC-02 Halloween Night:** generate one separate original with same recognizably open strawberry treasure chest, earned gold medal and collectible award card, violet moonlit sky, glowing berry pumpkin lanterns, golden stars and purple/orange accents. No text, fake prices or scores. Request owner visual approval before BC-03 Christmas Day.
- [ ] Source original GitHub import, true alpha/edge QA, separately processed RGBA, 64/96px previews, ZIP manifest and physical iPhone/Xcode QA remain open; no app or prior artwork touched.

**Berry Collection H1-B06: 1/8 visually approved; BC-02 next.**


### BC-02 Halloween Night generation checkpoint
- [x] One Halloween Night Berry Collection original generated and shown in chat: open strawberry treasure chest with gold achievement medal and trophy collectible card, purple velvet lining, crescent moon and stars, harvest leaves, hanging luminous strawberry jack-o'-lanterns, pumpkins and orange-purple gingham ribbon.
- [x] Actual source metadata checked: 1254×1254 RGB, off-white top-left pixels (252,253,253), **not native transparent**. Preserve this approved-if-selected original byte-for-byte; later create a separate RGBA cleanup candidate and review edges against light/dark/checker and at small phone sizes.
- [ ] **Await explicit BC-02 owner visual approval** before generating BC-03 Christmas Day.
- [ ] No BC-02 source PNG binary committed to GitHub or imported into iOS assets; checksum/archive, separate cleanup, integration and physical iPhone QA pending.

**H1-B06 latest: 2/8 originals generated, 1/8 visually approved, BC-02 owner review pending.**


### BC-02 approved; BC-03 Christmas Day next
- [x] BC-02 Halloween Night explicitly visually approved by owner (“Good continue”). Preserve open strawberry keepsake chest, gold berry medallion and trophy card, moonlit purple sky, harvest leaves and glowing berry lanterns as originally generated.
- [ ] NEXT **BC-03 Christmas Day**: generate only one original of same recognizably open strawberry keepsake chest with gold earned achievement medallion and separate collectible award card; sunlight and gentle snow, wreath/holly, evergreen ornaments, candy canes, strawberry berries and red/green gingham bow. No words, score numbers or price tags.
- [ ] Await explicit BC-03 visual approval before BC-04 Christmas Night. Originals, actual RGBA alpha edge QA, source hashes, preview sheets, ZIP GitHub import and iPhone runtime QA remain separate incomplete gates.

**Current Berry Collection owner approvals: 2/8, generated 2/8 prior to BC-03.**


### BC-03 Christmas Day generated · owner review gate
- [x] Exactly one Christmas Day Berry Collection image generated and shown in chat. Open strawberry chest with lush purple interior and clear gold berry medal plus collectible trophy card; snowy pines, evergreen ornaments, festive bells, candy canes, sunshine, berries and red-green gingham bow.
- [x] Source technical observation: 1254×1254 RGB PNG with light checkerboard pixels (top-left RGB 243,245,246), **not true transparent RGBA**. Preserve this exact source unchanged; only after visual approval create a separately reviewed RGBA cleanup candidate.
- [ ] **BC-03 owner visual approval pending.** Do not start BC-04 Christmas Night until explicit acceptance.
- [ ] Source PNG Github staging, hash manifest, checker/light/dark/64/96px alpha proofs, ZIP, Xcode import and physical iPhone QA remain separate gates.

**Berry Collection H1-B06 current: 3/8 image designs generated, 2/8 visually approved; BC-03 awaits review.**


### BC-03 Christmas Day approved; BC-04 Christmas Night next
- [x] **BC-03 Christmas Day** visually approved by owner (“Good continue”). Freeze the exact previously generated original with snow-touched strawberry keepsake chest, earned medal, trophy card, bells and red-green gingham. Do not regenerate or overwrite source bytes.
- [ ] **NEXT BC-04 Christmas Night**: generate exactly ONE standalone image with an open strawberry treasure chest and gold medal plus trophy award card, moonlit blue-violet snowy sky, crescent, glowing firs, Christmas bells and candy canes, red-green gingham; no text or fake earnings. Await owner approval before BC-05 Thanksgiving Day.
- [ ] True alpha/edge and checkerboard cleanup, exact PNG originals, source manifest and organized ZIP, verified GitHub binary staging, Xcode routing and physical-device testing are distinct pending tasks.

**Authoritative Berry Collection H1-B06: 3/8 visually approved; BC-04 next.**


### BC-04 Christmas Night generated; owner review gate
- [x] One standalone Christmas Night Berry Collection icon generated and shown in chat: open strawberry treasure chest with golden strawberry medal and collectible trophy award card, plum-purple cushioned interior, glowing snow-topped fir trees, Christmas bells and candy canes, crescent moon, stars and red-green gingham bow.
- [x] Actual source inspected: **1254×1254 RGB** PNG, top-left pixel **(253,253,253)**; its background is not actual transparency. Preserve exact original and later make a separately QA-reviewed RGBA matte candidate; do not equate visual checkerboard with alpha.
- [ ] **Owner visual approval of BC-04 pending.** No BC-05 Thanksgiving Day generation until accepted.
- [ ] Source archive/hashes, RGBA alpha/edge cleanup, light/dark/checkerboard and 64/96px QA, verified GitHub image binary import, Xcode/iPhone integration remain separate pending tasks.

**H1-B06 now 4/8 generated, 3/8 visually approved.**


### BC-04 approved and BC-05 Thanksgiving Day next
- [x] **BC-04 Christmas Night** visually approved by owner (“Good continue”). Preserve previously generated moonlit Christmas strawberry keepsake chest with earned medal and collectible trophy card; source RGB/checkerboard cleanup remains separate.
- [ ] NEXT **BC-05 Thanksgiving Day**: generate exactly one standalone sunny autumn icon featuring an open strawberry keepsake chest, gold strawberry achievement medal, separate collectible trophy/award card, golden maple leaves, harvest pumpkins, berry pie and warm gingham ribbons; no text or prices. Await individual owner visual approval before BC-06 Thanksgiving Night.
- [ ] True-alpha QA, exact original archiving/hashes, separate RGBA candidates, 64/96px previews, ZIP, GitHub binary source staging and physical-device Xcode QA remain pending and do not affect existing families.

**Berry Collection H1-B06 now 4/8 visually approved, BC-05 next.**
