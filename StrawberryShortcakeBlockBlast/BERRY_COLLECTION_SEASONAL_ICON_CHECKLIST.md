# 🍓🏆 Berry Berry Blast | H1-B06 Berry Collection Seasonal Home Icon Running Checklist

**Opened:** November 20, 2026. **Isolated branch:** `artwork/berry-seasonal-berry-collection-h1-b06`.  
**Current status:** 0/8 generated, 0/8 visually approved. Start with **BC-01 Halloween Day**.

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
| BC-01 | Halloween | Day | Sunlit strawberry treasure chest, golden berry medal and sticker award, friendly pumpkin lanterns, autumn gingham | ⬜ NEXT | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-02 | Halloween | Night | Moonlit violet keepsake chest with gold award and collectible, glowing pumpkin-berries and lanterns | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-03 | Christmas | Day | Snow-touched berry keepsake chest, gold medal, candy-cane and holly decorations, red-green ribbon | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-04 | Christmas | Night | Snowy moonlit purple chest with glowing keepsakes, golden prize star, fir lights and berry holly | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-05 | Thanksgiving | Day | Sunlit amber berry treasure chest, medal, harvest sticker, maple leaves, pumpkins and berry pie | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-06 | Thanksgiving | Night | Candlelit plum-and-gold collection chest, moon/stars, pumpkins, leaves, berry harvest accents | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-07 | Birthday | Day | Bright berry keepsake chest, earned medal and collectible, birthday cake, balloons and gifts | ⬜ | ⬜ | ⬜ | ⬜ |
| BC-08 | Birthday | Night | Lavender birthday treasure chest, golden award, candlelit cake, confetti and starry balloons | ⬜ | ⬜ | ⬜ | ⬜ |

## Production ledger
- [x] Verified exact Berry Collection Home role and art string in current tracked SwiftUI code.
- [x] Isolated H1-B06 branch and current 8-image checklist opened.
- [ ] Generate **BC-01 Halloween Day**, show one standalone image and await individual owner approval.
- [ ] BC-02 through BC-08 each receive their own image + explicit approval before proceeding.
- [ ] Process true RGBA and QA at multiple backgrounds/phone UI sizes, then originals/RGBA manifest + ZIP.
- [ ] Review alpha separately, stage binaries to GitHub Release/import and verify, then later Xcode + iPhone appearance QA.

## Prior family status (preserved)
H1-B05 Cottage Decorations: **8/8 visuals approved**. Exact-original/QA archive `Berry_Berry_Blast_Cottage_Decor_H1_B05_8_Originals_RGBA_QA.zip`: 56,158,942 bytes, SHA-256 `78730fd5ee2e1885bd90c2cabdb94e817903e0830c8babc9d10970501a4b7393`. 7 non-destructive cutout candidates still require owner matte review. GitHub import workflow installed on main, but binary PNG upload still pending.

Other batches remain tracked independently in master seasonal matrix; no IPA/build/runtime changes implied by this icon production pass.

References: [Seasonal master icon matrix](SEASONAL_MASTER_ICON_BATCH_MATRIX.md) · [Previous H1-B05 checklist](COTTAGE_DECOR_SEASONAL_ICON_CHECKLIST.md) · [Seasonal epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).
