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
| CD-04 | Christmas | Night | Moonlit snowy strawberry cottage, glowing windows, lit evergreen trees, wreath, decorating paintbrush, flowerpot, red check ribbon spool and crescent | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ checkerboard/true-alpha edge QA pending | ⬜ original PNG not staged | ⬜ |
| CD-05 | Thanksgiving | Day | Sunny strawberry-roof cottage with golden maple wreath, pumpkins, strawberry berry pie, flower pot, paintbrush and orange gingham ribbon spool | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ original RGB/off-white background; RGBA edge QA pending | ⬜ PNG source not staged | ⬜ |
| CD-06 | Thanksgiving | Night | Moonlit autumn strawberry cottage, glowing windows, harvest lanterns, pumpkin planters, berry pie, flowerpot, paintbrush, violet ribbon spool and autumn gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ RGB/off-white background; RGBA edge QA pending | ⬜ source PNG not imported | ⬜ |
| CD-07 | Birthday | Day | Sunny strawberry-roof decorating cottage, birthday cake, balloons, present, floral strawberry planter, pink paintbrush, ribbon spool and gingham bow | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ 1254px RGB, black outside badge; RGBA cutout QA pending | ⬜ source PNG not staged | ⬜ |
| CD-08 | Birthday | Night | Moonlit purple strawberry cottage, glowing windows, lanterns, balloons, cake candle, present, strawberry flowerpot, pink decorating paintbrush, ribbon spool and pink gingham | 🟡 GENERATED | ⬜ AWAITING OWNER APPROVAL | ⚠ native RGBA with transparent corner verified; edge QA pending | ⬜ source PNG not imported | ⬜ |

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


### CD-04 Christmas Night owner approval · CD-05 Thanksgiving Day next
- [x] **CD-04 Christmas Night** owner visually approved (“Good continue”). Preserve exact previously generated snowy moonlit strawberry cottage image with glowing windows, garden lights, flowerpot, paintbrush and ribbon spool.
- [ ] **NEXT CD-05 Thanksgiving Day:** create ONE standalone image, distinctly daytime, centered strawberry-roof cottage surrounded by warm maple foliage, pumpkin planters, harvest wreath and strawberry pie, with visible craft/decorating paintbrush, flowerpot and ribbon spool. Keep it different from original H1-B01 cottage hero assets; no text.
- [ ] Await explicit CD-05 visual approval before CD-06 Thanksgiving Night. Preserve unmodified original; real RGBA alpha verification/cleanup, preview sizes, checksummed ZIP, GitHub source PNG import and iPhone QA remain separate gates.

**Current authoritative H1-B05 visually approved count: 4/8; CD-05 next.**


### CD-05 Thanksgiving Day generation checkpoint
- [x] One original Thanksgiving Day Cottage Decorations illustration generated and shown in chat: sunny strawberry-roof house, autumn leaves and harvest wreath, pumpkin garden ornaments, wicker strawberry basket, pie, decorating brush, strawberry flowerpot, ribbon spool and oversized orange gingham bow.
- [ ] **Owner visual approval pending.** After explicit approval, generate CD-06 Thanksgiving Night individually; do not skip review.
- [ ] Actual PNG inspected: 1254×1254 RGB, top-left (252,253,253), with nontransparent off-white source background. Preserve source original untouched; separate RGBA segmentation and edge QA later.
- [ ] No CD-05 original PNG or RGBA file yet staged on GitHub; checksummed ZIP/import and Xcode/iPhone QA remain open.

**H1-B05 current: 5/8 generated, 4/8 visually approved, CD-05 awaiting owner review.**


### CD-05 accepted, CD-06 Thanksgiving Night next
- [x] CD-05 Thanksgiving Day visually approved by owner (“Good continue”). Preserve its previously generated original PNG exactly, including berry-roof cottage, pie, maple wreath, decorating brush, flowerpot and orange gingham ribbon.
- [ ] NEXT CD-06 Thanksgiving Night: produce ONE independently reviewed moonlit autumn cottage-decorating icon with glowing cottage windows, violet starry sky, amber lanterns, pumpkins, leaves, berry pie and visible paintbrush/potted flower/ribbon spool. No static text.
- [ ] Await explicit owner approval before CD-07 Birthday Day. Original/QA candidate PNG hashing, true background transparency validation, ZIP, GitHub binary staging and iPhone app routing are separate future gates.

**Current H1-B05 visuals approved: 5/8; CD-06 generation next.**


### CD-06 Thanksgiving Night generation checkpoint
- [x] One Thanksgiving Night Cottage Decorations image generated and shown for owner review, with crescent and stars, warm amber window lights, pumpkin decorations, autumn leaf wreath, strawberry lattice pie, berry flowerpot, pink paintbrush, purple ribbon spool and gingham bow.
- [ ] **Await explicit CD-06 owner visual approval** before proceeding to CD-07 Birthday Day.
- [ ] Preserve original PNG untouched; the displayed off-white backdrop is not verified transparency. Non-destructive RGBA edge QA, actual-size light/dark/checker previews, source hash ZIP, GitHub binary import, iOS image mapping and device QA remain pending.

**H1-B05: 6/8 generated, 5/8 visually owner-approved; CD-06 awaiting review.**


### CD-06 approval, CD-07 Birthday Day queued
- [x] CD-06 Thanksgiving Night owner visually approved by “Good continue”. Freeze the accepted moonlit cottage with harvest lanterns, wreath, pumpkins, strawberry pie and gardening/decorating tools.
- [ ] NEXT CD-07 Birthday Day: create exactly one new bright daytime image of the cottage-decorating tile, with recognizable strawberry-roof cottage, decorating brush, flowerpot and ribbon spool, plus birthday cake, balloons, gift and strawberry-pink bow. Obtain owner approval before CD-08 Birthday Night.
- [ ] Original PNG source hashing, non-destructive RGBA cutout and edge QA, contact previews, package ZIP, verified GitHub binary import and real iPhone/Xcode testing are independent later stages. No game data or approved existing art touched.

**H1-B05 current: 6/8 visually owner-approved; CD-07 is the next artwork.**


### CD-07 Birthday Day generation checkpoint
- [x] One Birthday Day cottage decorating icon generated and shown to owner: sunny strawberry-roof cottage, balloons, pink berry cake with candle, gift, garden flowers, strawberry planter, decorating brush, gingham ribbon spool and oversized bow.
- [ ] **Individual owner visual approval pending.** CD-08 Birthday Night comes next only after approval.
- [ ] Inspected exact PNG: **1254×1254 RGB with black pixels at corner**, not true transparency. Freeze source bytes; after acceptance derive a separate RGBA candidate and verify black edge halos on cream, dark and checkerboard backgrounds at 64/96px. Do not claim alpha is complete.
- [ ] Original, matte and preview ZIP/checksums/GitHub binary import and physical iPhone QA remain open.

**H1-B05: 7/8 generated, 6/8 owner-approved.**


### CD-07 Birthday Day approved, CD-08 Birthday Night next
- [x] CD-07 Birthday Day explicitly visually approved by owner (“Good continue”), despite RGB source black background requiring later non-destructive alpha cleanup. Preserve exact original.
- [ ] NEXT CD-08 Birthday Night: exactly one visual candidate, strawberry-roof cottage at night with golden glowing windows, violet/lavender crescent and stars, pink cake/candle, balloons and gifts, strawberry flower pot, pink craft paintbrush, ribbon spool and party bow. Match previously accepted decorating category, no text. Await owner approval before marking 8/8.
- [ ] Later: preserve all original PNGs and SHA-256, separate true RGBA cleanup, light/dark/checker previews at 64/96/144px, archive ZIP, GitHub binary import, and real iPhone QA. No app code or prior original assets changed.

**Current H1-B05: 7/8 visually approved and 7/8 generated before CD-08.**


### CD-08 Birthday Night generated · final visual approval pending
- [x] One standalone birthday-night cottage decorating icon generated and shown in chat. Moonlit purple sky with crescent, glowing strawberry-roof cottage and windows, balloons, party cake with candle, gift, planter, craft brush, ribbon spool and pink gingham bow.
- [x] PNG image observed 1254×1254 RGBA, top-left alpha zero. This checks native alpha existence only, not full fringe/edge QA or final production readiness.
- [ ] **Await explicit CD-08 owner visual approval.** Do not call full family 8/8 owner-approved until accepted; currently 7/8 approved.
- [ ] On approval, preserve all eight exact original PNG bytes and separately derive any needed RGBA candidates, create source SHA-256 manifest, preview sheets against checker/light/dark and at 64/96/144px, then verify a single categorized ZIP and GitHub import. Keep prior artwork and game state unchanged.

**H1-B05 current: 8/8 generated, 7/8 visually approved.**
