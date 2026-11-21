# 🍓🧭 Berry Berry Blast | H1-B04 More Adventures Seasonal Home Icon Checklist

**Opened:** November 20, 2026. **Branch:** `artwork/berry-seasonal-more-adventures-h1-b04`. **Source category:** 04/HOME in `SEASONAL_MASTER_ICON_BATCH_MATRIX.md`.
**Latest status:** MA-01 Halloween Day generated for review; 1/8 generated, 0/8 owner-approved. No H1-B04 source PNG binaries committed.

## Semantic ground truth from app source
In `BerryModes.swift` Home screen, **More Adventures** uses `BerryGridNavigationTile(title: "More Adventures", art: "MoreAdventures", caption: "Explore")`; tapping opens `showMore` and lets the player choose **Berry Blitz**, **Cozy Cottage**, or **Strawberry Nightmare**. It does not start a single book/calendar or automatically change a game mode.

**Design the actual function:** one distinctive strawberry-themed crossroads/garden gateway showing **three routes/options**; the scene may suggest blitz energy (a tiny lightning-star emblem), a cozy miniature cottage, and a playful mysterious moonlit path. The centerpiece must remain readable as **exploration/choices** at 64/96px. No actual text, fixed numbers, button labels, trademark characters, or fake menus inside the PNG. Seasonal celebrations and lighting are decorative around the same silhouette.

## Source/render/QA contract
1. **Generate exactly ONE original image per owner review**, in sequence below (Day, then Night for each event), not a multi-icon source collage.
2. After owner explicitly approves a design, mark its visual approval. Source original PNG bytes are immutable and distinct from alpha processing.
3. Keep all originals in `StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/<Holiday>/<Day|Night>/Originals/Season_<Holiday>_<Day|Night>_MoreAdventures_Original.png`.
4. Create separately processed `RGBA_Candidates` only after visual approvals; visually inspect true transparent edges and any baked checkerboard on light, dark and checker backgrounds, plus small 64/96px readability.
5. Package eight original PNGs, SHA-256 JSON/CSV manifest, checker/light/dark and mobile-size contact sheets in a deterministic ZIP. GitHub binary staging is a separate gate through verified ZIP import.
6. Do not alter existing original 40 Night Garden icons and RGBA, 10 approved clock frames, 8 Berry Story icons, 8 Daily Harvest icons, initial cottage series, current game modes, Xcode assets, saved state or cosmetics.
7. Xcode game integration and in-app holiday calendar activation stay isolated and require device acceptance.

## Eight individual artwork reviews

| ID | Event | Appearance | Distinctive theme and fixed semantic shape | Original image | Owner visual approval | RGBA QA | PNG in GitHub | Xcode/iPhone |
|---|---|---|---|---|---|---|---|---|
| MA-01 | Halloween | Day | Sunlit autumn garden crossroads with strawberry signpost, three icon routes (lightning, cottage, moon), lantern berries, autumn gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ RGBA/edge QA pending | ⬜ original PNG import pending | ⬜ |
| MA-02 | Halloween | Night | Moonlit violet strawberry crossroads with lightning, warm cottage and moon/star arrows; glowing berry lanterns and pumpkins | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ background/alpha QA pending | ⬜ source PNG import pending | ⬜ |
| MA-03 | Christmas | Day | Sunlit snowy strawberry crossroads with lightning, cottage and crescent/star arrows, evergreen lights, holly, candy canes and red-green gingham | ✅ GENERATED | ✅ OWNER APPROVED | ⬜ alpha/edge QA pending | ⬜ original PNG not staged | ⬜ |
| MA-04 | Christmas | Night | Moonlit snow-covered three-way strawberry signpost, luminous holiday pines, cottage windows and red-green gingham; second/latest visual chosen | ✅ GENERATED | ✅ OWNER ACCEPTED (latest shown image) | ⬜ actual alpha/edge QA pending | ⬜ source archive pending | ⬜ |
| MA-05 | Thanksgiving | Day | Sunlit golden strawberry crossroads, three route icons, autumn leaves and trees, pumpkins, lattice berry pie, woven harvest basket and orange gingham bow | ✅ GENERATED | ✅ OWNER APPROVED | ⚠ background/alpha QA pending | ⬜ original PNG not staged | ⬜ |
| MA-06 | Thanksgiving | Night | Moonlit purple/amber garden crossroads, three symbol-only routes, lanterns, pumpkins, maple foliage, berry pie and basket | 🟡 GENERATED | ⬜ AWAITING OWNER | ⚠ checkerboard/alpha edge QA pending | ⬜ original PNG not staged | ⬜ |
| MA-07 | Birthday | Day | Festive pink garden three-way signpost, strawberry cake, present, balloons and gold chapter-style star | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-08 | Birthday | Night | Lavender birthday crossroads, moonlit bunting, candle glow, balloons, strawberry confetti | ⬜ | ⬜ | ⬜ | ⬜ |

## Gates and milestones
- [x] Verify actual Home tile semantics and `MoreAdventures` asset lookup in existing SwiftUI source.
- [x] Create isolated H1-B04 branch and running checklist.
- [x] Generate **MA-01 Halloween Day** as one standalone original and present for review.
- [ ] MA-01 individual owner visual approval; do not advance to MA-02 until expressly accepted.
- [ ] Continue MA-02 through MA-08, one image/owner approval at a time.
- [ ] Prepare non-destructive original/RGBA QA ZIP, source hashes, previews and per-image approval manifest.
- [ ] Verified GitHub Release importer, stage original binaries and inspect results.
- [ ] Separate seasonal runtime integration, fallback, real device iPhone UI/QA and save/regression tests.

## Previous family handoff (unchanged)
- **Daily Harvest H1-B03:** 8/8 visual designs approved; ZIP SHA-256 `e3171cb083d3faf1062dd4d75844082a61506cbe5e3491543370f61fcf59cd24`; five native RGBA and three alpha candidates (DH01, DH03, DH07) require edge review. Release importer installed on main, binary import still awaiting owner release upload.
- **Berry Story H1-B02:** 8/8 visuals approved, source/alpha QA archive prepared, binary import separately pending.
- **Clock frames:** 10/10 visually approved; source and alpha review archive separately staged for owner release upload.
- **H1-B01 cottage originals:** 8 approved PNGs already imported on separate seasonal art branch; do not modify.
- **Night Garden:** previous 40/40 original and RGBA visual approvals retained, with runtime integration still pending.

Links: [Seasonal icon matrix](SEASONAL_MASTER_ICON_BATCH_MATRIX.md) · [Daily Harvest checklist](DAILY_HARVEST_SEASONAL_ICON_CHECKLIST.md) · [Seasonal epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).


### MA-01 artwork generation review gate
- [x] MA-01 Halloween Day generated and displayed in chat, depicting three clearly distinct route symbols on a strawberry garden signpost: Blitz lightning, Cozy Cottage, and Nightmare moon/stars. Seasonal Halloween ornaments surround rather than replace the three-choice meaning.
- [ ] **Owner visual approval pending.** Next item MA-02 Halloween Night only after acceptance.
- [ ] Exact-original PNG hash/archive, true RGBA matte QA, 64/96px scale and GitHub import are not yet done. Existing Night Garden and prior seasonal art untouched.

**H1-B04 tally: 1/8 generated, 0/8 visually approved.**


### MA-01 owner approval · MA-02 Halloween Night next
- [x] MA-01 Halloween Day visually approved by owner (“Good continue”). Preserve its original sunlit three-way signpost with lightning / cozy strawberry cottage / moon-star routes, pumpkins and autumn gingham.
- [ ] NEXT MA-02 Halloween Night: one independent moonlit version with visibly same three route identities, violet sky, lit berry jack-o'-lanterns, strawberry bow and warm cottage glow. Do not print text, render only one candidate, wait for explicit owner approval before MA-03 Christmas Day.
- [ ] All true-alpha and checkerboard edge QA, source/RGBA archival ZIP and GitHub binary import, Xcode integration and real iPhone testing are distinct pending gates.

**H1-B04 More Adventures now 1/8 visually approved; MA-02 generation next.**


### MA-02 Halloween Night generated, review requested
- [x] One Halloween Night crossroads illustration generated and shown to owner. Keeps the three recognizable arrows: lightning for Berry Blitz, strawberry cottage for Cozy Cottage, crescent/stars for Strawberry Nightmare. Features a moonlit purple garden, lanterns, witch-hat berry jack-o'-lanterns and strawberry gingham bow.
- [ ] **MA-02 owner visual approval pending.** MA-03 Christmas Day generation follows explicit acceptance only.
- [ ] Visual checkerboard might be baked: retain original PNG untouched and inspect real alpha, matte edges, then make separate RGBA candidate and light/dark/64px/96px proofs. No image PNG yet imported into GitHub.

**More Adventures: 2/8 generated, 1/8 owner approved.**


### MA-02 approval checkpoint · MA-03 Christmas Day next
- [x] MA-02 Halloween Night owner visually approved (“Good continue”); preserve the original generated three-route moonlit crossroads icon unchanged.
- [ ] NEXT MA-03 Christmas Day: generate exactly one visually distinct *daytime* snowy three-way strawberry signpost showing Berry Blitz lightning, Cozy Cottage house and Strawberry Nightmare crescent/stars, surrounded by festive snowy evergreens, holly, candy canes, red/green gingham and a golden daytime sun. No text or baked-in status.
- [ ] MA-03 requires explicit owner approval before Christmas Night; source/RGBA alpha QA, full-size original archives, ZIP hashes and GitHub binary import are independent future gates.

**H1-B04: 2/8 original designs approved; Christmas Day next.**


### MA-03 Christmas Day generated · owner review gate
- [x] One original MA-03 image created and displayed in chat: snowy sunny garden crossroads with the three distinctive icon arrows (lightning/Blitz, cottage/Cozy Cottage, crescent-star/Nightmare), strawberry-topped signpost, snowy Christmas trees, holly, candy canes and red-green gingham bow.
- [ ] **Await explicit owner visual approval** before generating MA-04 Christmas Night. No unapproved variants counted.
- [ ] Preserve original PNG unchanged; actual RGBA/alpha and edge QA, 64/96px previews, checked source ZIP, binary GitHub upload, Xcode and physical iPhone acceptance still pending.

**Current H1-B04 tally: 3/8 generated, 2/8 visually owner-approved.**


### MA-03 approved · MA-04 Christmas Night queued
- [x] **MA-03 Christmas Day** visually approved by owner (“Good continue”). Freeze the generated bright snow-and-sun three-signpost original; do not overwrite or regenerate.
- [ ] **NEXT MA-04 Christmas Night**: one standalone moonlit companion with three recognizable arrows for Berry Blitz lightning, Cozy Cottage strawberry cottage and Strawberry Nightmare crescent/star, snowy evergreen fairy lights and warm cottage glow. No text or printed status.
- [ ] Await explicit MA-04 visual approval before moving to MA-05 Thanksgiving Day; original file archive, alpha/edge QA, RGBA candidate, ZIP and verified GitHub binary staging remain independent requirements.

**Current More Adventures approvals: 3/8, MA-04 next.**


### MA-04 Christmas Night generation review gate
- [x] Christmas Night More Adventures scene generated and shown in chat. **Two outputs were produced, despite the one-image review protocol; only one MA-04 semantic icon will be approved and staged.** Both depict the three routes, moonlit snowy pines, glowing lanterns and cottage, with Christmas gingham.
- [ ] Owner to accept a specific image (first or second, or request redo) before marking MA-04 approved or advancing to MA-05 Thanksgiving Day. **No automatic approval and no second semantic icon.**
- [ ] Preserve the accepted image's exact PNG bytes when chosen, test real transparency against potential baked checkerboard, and prepare reviewed alpha and 64/96px proofs before GitHub binary import.

**H1-B04 current: 4/8 semantic slots generated, 3/8 visually approved, MA-04 pending owner selection.**


### Latest checkpoint: MA-04 approved, MA-05 next
- [x] Owner responded “Good continue” after two MA-04 Christmas Night designs were displayed. **Interpretation: acceptance of the most recently displayed (second) version**, rather than claiming they specified a number. Preserve the second generated file as the selected original, keep first as an unapproved alternate; change selection if owner later clarifies.
- [ ] NEXT MA-05 Thanksgiving Day: generate one image showing three gold-edged direction arrows for Berry Blitz (lightning), Cozy Cottage (strawberry cottage) and Strawberry Nightmare (crescent and star), with sunny harvest leaves, pumpkin, berry-pie and wheat ornaments, warm orange-gold palette and strawberry gingham. Owner review needed before MA-06.
- [ ] Source and RGBA image binaries not in GitHub; transparent matte verification, 64/96px screen legibility, ZIP checksum import, Xcode integration and physical-device acceptance remain pending.

**Current More Adventures status: 4/8 visually accepted, MA-05 is next.**


### MA-05 Thanksgiving Day generated · review gate
- [x] One image created and shown for MA-05 Thanksgiving Day, retaining all three More Adventures symbols (Blitz lightning, Cozy Cottage building, Nightmare crescent and stars) with warm daytime harvest landscape, maple leaves, pumpkins, strawberry basket, berry pie and orange gingham bow.
- [ ] Await explicit owner visual approval before generating MA-06 Thanksgiving Night. No approval inferred from generation.
- [ ] Image shows checkerboard-style background; verify real PNG alpha rather than treating checkerboard as proof. Source bytes, RGBA candidate, checksum ZIP, 64/96px previews, GitHub binary stage and iPhone QA remain independent pending gates.

**Authoritative latest: 5/8 generated, 4/8 visually accepted; MA-05 pending owner approval.**


### MA-05 approved · MA-06 Thanksgiving Night next
- [x] **MA-05 Thanksgiving Day** explicitly visually approved by owner (“Good continue”). Preserve original daylight three-route strawberry signpost design with golden-orange maple foliage, pumpkins, basket, pie and gingham bow.
- [ ] **NEXT MA-06 Thanksgiving Night**: generate one matching three-route signpost, with Berry Blitz lightning, Cozy Cottage strawberry-roof house, Strawberry Nightmare crescent/stars, moonlit aubergine/plum sky, berry lanterns, pumpkins, pie and warm golden autumn accents. No text or fake interface. Wait for owner approval before MA-07 Birthday Day.
- [ ] Exact source PNG archive, real alpha/background QA, separate RGBA derivative, 64/96px previews, checked ZIP, GitHub binary import, Xcode/runtime and real iPhone approval remain distinct pending gates.

**Current More Adventures 5/8 visually approved; MA-06 next.**


### MA-06 Thanksgiving Night generation review
- [x] One original Halloween? No, **Thanksgiving Night** three-route signpost image generated and shown in chat: Berry Blitz lightning, Cozy Cottage strawberry cottage, Strawberry Nightmare crescent/star; amber lanterns, moonlit violet clouds, pumpkins, maple leaves, harvest basket, berry pie and orange gingham.
- [ ] **Await owner visual approval of MA-06** before generating MA-07 Birthday Day. Preserve MA-05 Thanksgiving Day approval.
- [ ] Source PNG original preserved in chat; actual transparency, RGBA derivative, light/dark/checker and 64/96px previews, checksummed archive, GitHub binary import, Xcode and iPhone QA remain pending.

**H1-B04: 6/8 generated, 5/8 visually approved, MA-06 awaiting owner review.**
