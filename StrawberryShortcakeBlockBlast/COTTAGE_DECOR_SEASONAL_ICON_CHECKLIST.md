# 🍓🏡 Berry Berry Blast · My Strawberry Cottage seasonal Home tile · H1-B05 running checklist

**Opened:** November 20, 2026. **Branch:** `artwork/berry-seasonal-cottage-decor-h1-b05`. **Current visuals:** CD-01 Halloween Day generated in chat, 1/8 generated and 0/8 owner-approved. Binary source not yet staged.
**Semantic use:** `BerryModes.swift` Home tile: `title: "My Strawberry Cottage", detail: "Arrange your purchased garden decorations", art: "CottageDecorations", caption: "Decorate"`; tapping sets `showHomeCottage = true`.

## Why this is a new icon family and NOT H1-B01 again
H1-B01 staged eight Cottage/Home Classic holiday compositions as the **first visual direction test**. The actual “My Strawberry Cottage” Home navigation tile is specifically the **cottage decoration editor** (`CottageDecorations`), not a general Home hero or gameplay mode.

Give this family a distinct, clear **decorating** theme: a cute strawberry-roof cottage **plus a flowerpot/palette, ribbon, garden ornaments and movable furnishing** around it. Do not simply reproduce the H1-B01 cottage thumbnails; these must be distinctly recognizable as “customize/decorate your home”. Holiday festivity alters the decorations around the same home and editor symbolism, not the app logic. No paid inventory, locked reward, ownership state, actual paint color names, fake text or labels are encoded in pixels.

## Art acceptance and non-destructive source process
- Generate precisely **one standalone original image per owner approval**, Day then Night for each holiday.
- Full-resolution premium glossy berry-bakery game icon with dense decoration but an unmistakable cottage and flower-pot/paintbrush/decor symbolic elements, readable at 64/96px.
- Every original remains byte-identical; if RGB source contains generated checkerboard, preserve it and create separate RGBA candidate after approval.
- For all eight: owner visual review, original SHA-256, RGBA alpha/edge QA and preview sheets on checker/light/dark at 64, 96, 144px, then owner matte acceptance and exact archive ZIP verification.
- Stage isolated art sources under `StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/<Holiday>/<Day|Night>/Originals/Season_<Holiday>_<Day|Night>_CottageDecorations_Original.png`, separate `RGBA_Candidates` siblings. No changes to `Assets.xcassets` or code until dedicated release/QA gate.
- Do not replace or mix 40 Night Garden originals/RGBA, previous 10 digital clock frames, H1-B01 eight cottage hero originals, H1-B02 Berry Story, H1-B03 Daily Harvest or H1-B04 More Adventures PNGs. Never touch player-owned decoration inventory, saves, wallet, game modes or birthday rewards.

## Individual seasonal image ledger

| ID | Holiday | Time | Visual direction (decorator/editor semantics) | Generated | Owner visual approval | RGBA matte QA | Binary in GitHub | App/iPhone |
|---|---|---|---|---|---|---|---|---|
| CD-01 | Halloween | Day | Sunny strawberry-roof cottage with flowerpot, paintbrush, ribbon spool, pumpkin lanterns, autumn leaves and sunny orange-lavender gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ original RGB/checkerboard; RGBA edge QA pending | ⬜ original PNG not yet staged | ⬜ |
| CD-02 | Halloween | Night | Moonlit strawberry-roof cottage, glowing windows and pumpkin-berry lanterns, decorating brush, flowerpot, ribbon spool and purple-orange gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ RGB/off-white background; separate RGBA edge QA pending | ⬜ source PNG not yet staged | ⬜ |
| CD-03 | Christmas | Day | Snow-frosted strawberry cottage with wreath, red ribbon, candy canes, festive flowerpot, paintbrush and ribbon spool; SECOND image selected | ✅ GENERATED | ✅ OWNER APPROVED (most recent/second version) | ⚠ checkerboard/alpha edge QA pending | ⬜ source PNG import pending | ⬜ |
| CD-04 | Christmas | Night | Moonlit snowy strawberry cottage, glowing windows, lit evergreen trees, wreath, decorating paintbrush, flowerpot, red check ribbon spool and crescent | 🟡 GENERATED | ⬜ AWAITING OWNER APPROVAL | ⚠ visible checkerboard; verify alpha and clean separately | ⬜ source PNG not staged | ⬜ |
| CD-05 | Thanksgiving | Day | Amber harvest cottage, strawberry pie window display, maple leaf garland, pumpkin planters, cozy decorating details | ⬜ | ⬜ | ⬜ | ⬜ |
| CD-06 | Thanksgiving | Night | Candlelit autumn cottage with pumpkin planters, lanterns, maple wreath and moonlit decorated garden | ⬜ | ⬜ | ⬜ | ⬜ |
| CD-07 | Birthday | Day | Strawberry cottage with frosted cake decorations, party balloons, present planter, bright pink decorating bow | ⬜ | ⬜ | ⬜ | ⬜ |
| CD-08 | Birthday | Night | Moonlit lavender party cottage, candle glow, cake/present floral planters, balloons and decorative ribbons | ⬜ | ⬜ | ⬜ | ⬜ |

## Task gates and handoff
- [x] Verify the separate `CottageDecorations` Home use-site, not to confuse with H1-B01 cottage/Classic hero assets.
- [x] Create isolated H1-B05 branch and eight-image running checklist.
- [x] CD-01 Halloween Day generated individually, shown to owner.
- [ ] Owner explicitly approves CD-01 or requests changes. CD-02 Halloween Night follows approval only.
- [ ] Continue CD-02 through CD-08, one separately reviewed original at a time, preserving previously approved exact files.
- [ ] After 8/8 visual approvals, QA original PNG alpha or RGB checkerboard, non-destructive RGBA derivatives, checker/light/dark contact sheets, 64/96/144px previews, sha manifest and ZIP verification.
- [ ] Owner approves cleaned alpha candidates, then verified release ZIP import into isolated GitHub art branch. No bulk overwrite.
- [ ] Separate app Xcode artwork routing, local holiday calendar appearance and physical iPhone QA.

## Prior family completion ledger
**H1-B04 More Adventures:** 8/8 visually owner-approved. Source + RGBA candidate ZIP `Berry_Berry_Blast_More_Adventures_H1_B04_8_Originals_RGBA_QA.zip` SHA-256 `a505666b3e0afc60f9af9f4a8d2539af2de8d26da7c08ef0d7d284ef0ab4562d`. Only 2 native RGBA, remaining 6 need owner matte review. Import workflow `.github/workflows/berry-more-adventures-h1-b04-import.yml` staged on `main`; actual original binaries still await verified Release upload with tag `berry-more-adventures-h1-b04`.

Links: [H1-B04 checklist](MORE_ADVENTURES_SEASONAL_ICON_CHECKLIST.md) · [Master seasonal matrix](SEASONAL_MASTER_ICON_BATCH_MATRIX.md) · [Seasonal Epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42) · [Night Garden PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40).


### CD-01 visual generation checkpoint
- [x] One Halloween Day cottage-decorating badge displayed with shiny strawberry house, orange autumn foliage, lit pumpkin lanterns, paintbrush, strawberry flower pot, lavender ribbon spool and gingham bow, sunny daylight. Keeps decorating semantics rather than redoing H1-B01 Cottage/Home Classic hero images.
- [ ] **Owner visual approval pending.** Do not count accepted or move to CD-02 until owner responds.
- [ ] PNG is **RGB with checkerboard-looking background**: preserve source byte-for-byte and process as separate RGBA candidate with owner edge review only after design approval.
- [ ] No H1-B05 PNG binaries uploaded to GitHub or routed into game yet; no code, economy, decoration inventory or other art families modified.

**H1-B05: 1/8 generated, 0/8 visually approved.**


### CD-01 owner approval and CD-02 night design next
- [x] CD-01 Halloween Day visually approved by owner (“Good continue”). Freeze the approved original: glossy strawberry roof cottage, bright sun, pumpkin-berry lanterns, autumn florals, decorating brush/flowerpot and purple ribbon spool.
- [ ] **NEXT CD-02 Halloween Night:** generate exactly one owner-review image, preserving a recognizable decorated strawberry cottage, flowerpot, decorating brush or ribbon spool, Halloween lanterns, purple night sky with moon/stars and lit windows. Do not reproduce the generic H1-B01 cottage hero.
- [ ] Design approval is separate from real RGBA alpha/edge verification and GitHub PNG binary staging; source original is immutable and no game code/economy/inventory or earlier artwork families are modified.

**H1-B05 visual approvals: 1/8; CD-02 next.**


### CD-02 Halloween Night original generated, approval pending
- [x] One independent CD-02 Halloween Night decorating badge generated and shown in chat. The recognizable strawberry-roof cottage has golden windows, purple shutters, spooky-cute strawberry lanterns, orange leaves, moon/stars, flowerpot, paintbrush and ribbon spool.
- [ ] **Owner visual approval pending**. Do not mark approved nor generate CD-03 until owner explicitly accepts.
- [ ] Original image is 1254x1254 RGB with an off-white background (not transparent). Preserve original, create a **separate** RGBA background-removed candidate after acceptance, check subtle white halos and at 64/96px before any app import.
- [ ] No source PNG binary uploaded into GitHub yet; real iPhone QA and runtime routing are independent future gates.

**Latest: H1-B05 2/8 generated, 1/8 owner-approved.**


### CD-02 owner approval, Christmas Day next
- [x] **CD-02 Halloween Night** visually approved by owner (“Good continue”). Preserve accepted original as generated with illuminated strawberry cottage, purple Halloween lanterns and decorating props.
- [ ] **NEXT CD-03 Christmas Day:** create one distinct *daytime* snowy holiday decorating cottage with recognizable strawberry roof, sunny winter sky, window wreath, holly, candy canes, floral pots, pink/gold decorating paintbrush, ribbon spool and festive gingham. Keep original editor/decorating meaning; no text or duplicate generic H1-B01 hero house.
- [ ] After owner approval proceed to CD-04 Christmas Night. Original SHA archiving, separate RGBA alpha cleanup and review, checksummed ZIP, GitHub binary staging, Xcode and physical iPhone QA remain future gates.

**Authoritative H1-B05: 2/8 visually approved, 2/8 generated before CD-03.**


### CD-03 Christmas Day generation checkpoint
- [x] Two candidate Christmas Day cottage decorating icons were produced and shown in chat: both show sunlit snow-covered strawberry roof, Christmas wreath/candy canes/evergreens, and clear flowerpot, paintbrush and ribbon spool decor symbols. **Both count toward one CD-03 icon slot only**.
- [ ] Request the owner to approve the **first or second candidate**, or request changes. The second image is the latest displayed and should not be presumed selected until owner responds.
- [ ] Only the chosen full original should enter the production archive; preserve unaltered original PNG bytes and record its SHA-256. Do not claim true transparency from visible checkerboard: check actual alpha and produce separately reviewed RGBA candidate when needed.
- [ ] Once a CD-03 version is approved, proceed to CD-04 Christmas Night, one image at a time. Current approved count remains **2/8** (Halloween Day/Night).

**H1-B05 current: 3/8 slots generated; 2/8 visually approved, CD-03 selection pending.**


### CD-03 owner acceptance and CD-04 Christmas Night queued
- [x] Owner replied “Good continue” after two CD-03 Christmas Day images. Interpret as approval of the **most recently shown (second) version**, while recording that they did not explicitly specify a number. Preserve the second exact original (`a_bright_colorful_highly_polished_cartoon_illust.png`), keep first as unapproved alternate; revise choice if the owner clarifies.
- [ ] NEXT **CD-04 Christmas Night**, one full-res standalone illustration: same strawberry-roof Christmas decorating cottage, frosted roof and evergreens, moonlit indigo-violet night, warm glowing windows and garden lights, wreath, candy canes, painted planter, paintbrush, ribbon spool and red/purple gingham. No text.
- [ ] Do not claim image transparency, GitHub binary staging, game runtime mapping or on-device QA. Background cleanup and RGBA candidates remain independent future gates.

**Current H1-B05 visual approvals: 3/8; Christmas Night generation next.**


### CD-04 Christmas Night generation and review checkpoint
- [x] One new CD-04 Christmas Night image generated in chat, distinct from CD-03 daytime: moonlit violet starry sky, snow-frosted strawberry roof, cozy glowing windows, festive lights and candy canes, strawberry flower pot, pink decorating paintbrush and ribbon spool.
- [ ] **Owner visual approval pending**; do not generate CD-05 Thanksgiving Day or mark CD-04 accepted until response.
- [ ] Original image displays a checkerboard-looking background; actual alpha must be verified and separated non-destructively. Preserve the original unchanged, and prepare light/dark/checker/64px/96px review before committing source and RGBA candidates via checked ZIP import.
- [ ] No CD-04 image binary is uploaded to GitHub yet; game build and iPhone QA are unaffected.

**Current H1-B05: 4/8 generated, 3/8 visually owner-approved, Christmas Night awaiting review.**
