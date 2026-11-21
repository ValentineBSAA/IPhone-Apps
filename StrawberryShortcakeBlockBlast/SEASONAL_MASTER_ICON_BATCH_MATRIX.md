# 🍓 Seasonal Garden · Master icon coverage and repeatable generation plan

**Status:** Planning + H1-B01 visual artwork approval. Zero seasonal production Xcode imports. Keep the generic Day assets, 30 legacy Night Xcode sets, and all 40 Night Garden source/RGBA images **untouched**.

## User direction
Every actual user-facing icon or screen state should receive a purposeful **Halloween, Christmas, Thanksgiving, and Birthday** design, each separately crafted in both **Day** and **Night** (8 treatments per semantic use-site), not just tinting the current Day or Night artwork. Preserve original meaning and consistent scale, silhouette, labels and app touch behavior.

Use one standalone image-generation output per asset, never collage-generated source art. Stage original full-resolution files in the appropriate event/appearance folder; track approval, alpha, Xcode routing and iPhone QA independently.

**Volume planning:** the previously approved 40 Night Garden icons are a **seed taxonomy only**, not the final seasonal count. At full parity, 40 × 4 holidays × 2 appearances = **320 candidate seasonal images**, including **48 internal QA-only variants** that may eventually be deemed intentionally shared. Other actual UI elements (mode cards, clocks, board blocks/tray, village structures and fireworks) are additional and may not all warrant individual icons. Final totals cannot be locked until exhaustive source/use-site audit and owner intent.

## Repeated batch protocol
1. **Batch number / family / semantic role**: e.g. H1-B02: Berry Story Home tile.
2. Generate one independent **Day and Night** original for each holiday, eight files in total. Name `Season_<Holiday>_<Day|Night>_<Semantic>_Original.png`.
3. Show a labeled, 2-column 4-row **review sheet only as a derivative**. Keep eight source PNGs unchanged.
4. Capture owner decision per individual image: APPROVED / REDO / HOLD. Do not claim unreviewed art approved.
5. ZIP source PNGs + SHA-256 JSON/CSV manifest + proof contact sheet. Upload it as a new GitHub release asset. Verify exact ZIP and per-image hashes through a dedicated imported staging branch.
6. Derive RGBA candidates **separately** after the source batch is approved; inspect against light/dark/checker at 64/96 px and on actual phone. No destructive replacement.
7. Only after source/alpha/asset-resolution tests, make a separate integration PR. Preserve player saves, purchases and original game logic.

## First 40 semantic families to cross-check against actual screen use-sites
| ID | Group | Existing Night taxonomy counterpart | Seasonal target status |
| ---: | --- | --- | --- |
| 01 | HOME | Berry Classic | 8/8 visual samples approved; exact Classic vs Home mapping to confirm |
| 02 | HOME | Berry Story | H1-B02: **8/8 visual designs approved**; [checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/artwork/berry-seasonal-berry-story-h1-b02/StrawberryShortcakeBlockBlast/BERRY_STORY_SEASONAL_ICON_CHECKLIST.md), original/RGBA QA ZIP ready; binary GitHub import and four cleanup mattes pending |
| 03 | HOME | Daily Harvest | H1-B03: **8/8 visual designs approved**; [checklist](DAILY_HARVEST_SEASONAL_ICON_CHECKLIST.md), checked source/RGBA QA ZIP ready, 3 alpha candidates require review, binary import pending |
| 04 | HOME | More Adventures | H1-B04: **8/8 visuals approved**; [checklist](MORE_ADVENTURES_SEASONAL_ICON_CHECKLIST.md) and SHA-256 verified original+RGBA ZIP ready; 6 alpha candidates pending owner review and GitHub binary upload |
| 05 | HOME | My Strawberry Cottage | H1-B05: **8/8 visuals approved**; [checklist](COTTAGE_DECOR_SEASONAL_ICON_CHECKLIST.md); original + 7 RGBA cleanup candidates packaged, alpha review and binary import pending |
| 06 | HOME | Berry Collection | H1-B06: [new eight-image checklist](BERRY_COLLECTION_SEASONAL_ICON_CHECKLIST.md) created; BC-01 Halloween Day next, 0/8 visually approved |
| 07 | HOME | Strawberry School | Not generated |
| 08 | HOME | Berry Village | Not generated |
| 09 | HOME | Berry Quests | Not generated |
| 10 | HOME | Berry Journal | Not generated |
| 11 | HOME | Daily Streak | Not generated |
| 12 | HOME | Strawberry Jukebox | Not generated |
| 13 | HOME | Berry Boutique | Not generated |
| 14 | HOME | Berry Blitz | Not generated |
| 15 | HOME | Cozy Cottage | Not generated |
| 16 | HOME | Strawberry Nightmare | Not generated |
| 17 | SETTINGS | Gameplay | Not generated |
| 18 | SETTINGS | Block Appearance | Not generated |
| 19 | SETTINGS | Audio | Not generated |
| 20 | SETTINGS | Celebrations | Not generated |
| 21 | SETTINGS | Accessibility | Not generated |
| 22 | SETTINGS | Data & Restore | Not generated |
| 23 | HUD | Undo | Not generated |
| 24 | HUD | Shuffle | Not generated |
| 25 | HUD | Hint | Not generated |
| 26 | HUD | Stats | Not generated |
| 27 | HUD | Tools | Not generated |
| 28 | HUD | Boutique | Not generated |
| 29 | TOOLS | Golden Trowel | Not generated |
| 30 | TOOLS | Ribbon Twister | Not generated |
| 31 | TOOLS | Starberry Seed | Not generated |
| 32 | TOOLS | Golden Strawberry | Not generated |
| 33 | TOOLS | Picnic Pantry | Not generated |
| 34 | TOOLS | Berry Spyglass | Not generated |
| 35 | QA INTERNAL | Test Strawberries | Not generated |
| 36 | QA INTERNAL | Diagnostics | Not generated |
| 37 | QA INTERNAL | Save Inspector | Not generated |
| 38 | QA INTERNAL | Combo Preview | Not generated |
| 39 | QA INTERNAL | Economy Inspector | Not generated |
| 40 | QA INTERNAL | Build Information | Not generated |

**Important:** H1-B01 generated and approved eight *berry-pastry cottage images* that were prompted as Home Classic representative artwork, not the puzzle-block icon itself. Before wiring to `BerryClassic` or `Home`, inspect the actual displayed Classic/home icon and confirm that cottages convey the intended function. No runtime name or production asset claim is made yet.

## Additional visible art families to audit and pair
- Base Home and village hero backgrounds, mascot frame, logo ribbon and decorative edge assets.
- Distinct premium live **12-hour** Day and Night clock faces for seasonal event mode, icon, badge and sunrise/sunset chip.
- Mode cards and progression subpage visual states (selected, disabled, locked, completed and empty).
- Gameplay HUD, score/combo/crown, Pause/Home/Settings/Help, toolbars, button press/disabled states.
- Six tile colors, empty/occupied/ghost blocks and tray, board exterior and safe frames in **8×8/12×12/24×24**.
- Cottage, Village, Quests, Streak, Journal, Collection, School, Jukebox and trophy/achievement art.
- Boutique preview-only holiday dressings and later distinct Night Market storefront visuals, no premature shop transactions.
- Seasonal berry fireworks, petals/leaves/snow/confetti and reduced-motion treatments; no overlays intercept taps.
- Existing birthday/Christmas image sets `BBBFrameBirthday`, `BBBFrameChristmas`, `BBBIconBirthday`, `BBBIconSeasonal` remain preserved until carefully audited.

## Current gate
- [x] H1-B01: Halloween / Christmas / Thanksgiving / Birthday **Day + Night** cottage Home/Classic representatives generated and visually accepted (8 images).
- [x] Original full-resolution images organized into checked ZIP with checksum manifest, downloadable in ChatGPT.
- [x] Isolated art branch + draft PR #50 and a GitHub Release-ingest workflow installed, ZIP **not yet uploaded to GitHub Release**.
- [x] GitHub Release import passed (Actions #44847067327); all eight source PNG blobs are staged in isolated seasonal art branch.
- [ ] Check actual Home/Classic semantic routing and alpha quality; no Xcode integration yet.
- [ ] H1-B02 after review: Story Home tile Day+Night × four holidays, or another approved semantic family based on H0 use-site audit.
- [ ] Continue batches per this matrix until **all actual visible** seasonal icon use-sites have approved Day+Night art.
- [ ] Complete calendar/region/opt-in behavior separately via draft PR #48, preserving existing birthday gift.

See [H1-B01 art manifest](ArtSource/SeasonalGarden/00_Specs_And_Ledgers/H1_Batch01_Manifest.json), [source import PR #50](https://github.com/ValentineBSAA/IPhone-Apps/pull/50), [Night originals PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40), [Seasonal Epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).


## Approved live digital clock frame workflow (November 20, 2026)
- [x] The **standard NONSEASONAL clock Day frame** is visually approved: glossy strawberry-pink, gingham bow, flowers and blank center for native `h:mm a` text.
- [x] The **standard NONSEASONAL clock Night frame** is visually approved: violet, moon, stars, purple bow and completely blank center.
- [x] Both source PNGs are already true RGBA; 1774×887 originals, exact duplicates as QA candidates, checker/cream/dark proof + ZIP verified.
- [x] Clock-specific [running checklist](https://github.com/ValentineBSAA/IPhone-Apps/blob/artwork/berry-clock-frames-c-b01-staging/StrawberryShortcakeBlockBlast/CLOCK_FRAME_MASTER_CHECKLIST.md) committed; isolated [draft PR #53](https://github.com/ValentineBSAA/IPhone-Apps/pull/53). No clock binaries committed yet.
- [ ] Upload the base clock ZIP to GitHub Release `berry-base-clocks-b01` with checksum `ef36481929c5db6074d0bda3298614439e298dc4a4ae7f74d5f8e747aa5cd83a`; import workflow on main verifies and stages only this separate clock branch.
- [ ] Four holiday digital clock pairs after base frame: Halloween Day/Night, Christmas Day/Night, Thanksgiving Day/Night, Birthday Day/Night. **Generate ONE image at a time, with explicit approval per image**, not a batch of unapproved analog clocks.
- [ ] Code renders live time in the clear blank central space; these are purely exterior frame illustrations. No analog clock faces, hands, tick marks, baked-in time, house backgrounds or app integration now.

### GitHub seasonal cottage import correction
- [x] The original eight seasonal cottage Home/Classic concept PNGs were actually imported successfully via [Actions run #44847067327](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44847067327). They remain **separate** from clock frame art and require Xcode/device QA.



## H1-B03 Daily Harvest seasonal Home tiles
New isolated [Daily Harvest H1-B03 running checklist](DAILY_HARVEST_SEASONAL_ICON_CHECKLIST.md). Center a calendar page plus harvested berry basket, because the live Home tile represents daily attempt/resume/outcome status; do not invent dates or hardcode completion or reward text. Generate the eight variants one-by-one for owner approval. The prior H1-B02 Berry Story pack has eight approved designs and a verified 56,975,792-byte QA ZIP; four alpha candidates require owner visual QA and binary import to GitHub is still open.


## H1-B03 Daily Harvest completed visual originals / verified archive
- [x] Daily Harvest eight seasonal Home calendar-and-basket icon designs explicitly visually approved.
- [x] Original/RGBA candidate QA ZIP prepared, SHA-256 `e3171cb083d3faf1062dd4d75844082a61506cbe5e3491543370f61fcf59cd24`. Five native transparency originals, three individually separated alpha candidates (DH01, DH03, DH07) still require edge approval.
- [x] Release ZIP importer workflow installed on `main`: `.github/workflows/berry-daily-harvest-h1-b03-import.yml`. It checks the pinned archive and updates ONLY isolated Daily Harvest art branch when tag `berry-daily-harvest-h1-b03` is published.
- [ ] User uploads verified ZIP as release asset; confirm importer success and original PNG staging, then conduct real iPhone image QA. **None of these have been staged merely by installing workflow.**
- [ ] Next semantic source family: More Adventures Home tile H1-B04; distinguish navigation to Berry Blitz / Cozy Cottage / Nightmare from one game mode icon.


## Next family H1-B04: More Adventures
Grounded in the actual SwiftUI More Adventures Home tile with `showMore` navigation to Berry Blitz, Cozy Cottage and Strawberry Nightmare. Each seasonal Day/Night icon must communicate a branching choice of **three paths**, not a calendar or book. Start at [MA-01 Halloween Day](MORE_ADVENTURES_SEASONAL_ICON_CHECKLIST.md), one image per owner approval. Existing approved art packs and future runtime logic stay separate.


## H1-B05 Home / My Strawberry Cottage decorating icons
Different from the eight H1-B01 cottage/Classic visual direction originals: this family follows actual `art: "CottageDecorations"` in Home, whose destination is the decoration editor. [Dedicated checklist](COTTAGE_DECOR_SEASONAL_ICON_CHECKLIST.md) created; one source image per owner approval, exact originals and RGBA candidate files kept separate. H1-B04 More Adventures 8/8 visual design complete with checked archive SHA `a505666b3e0afc60f9af9f4a8d2539af2de8d26da7c08ef0d7d284ef0ab4562d`; GitHub release binary import and 6 matte candidate reviews are still pending.


## H1-B06 Berry Collection family next
Source semantics in `BerryModes.swift`: `art: "BerryCollection"`, `caption: "My Treasures"`, opens `showCollection` for inventory/awards/personal records. The new family uses earned keepsake chest + medal/collectible motif, **not a shop**. [Dedicated H1-B06 checklist](BERRY_COLLECTION_SEASONAL_ICON_CHECKLIST.md), starting BC-01 Halloween Day, exactly one image per owner approval. Previous H1-B05 was 8/8 visual designs approved and fully source+RGBA review-packaged (7 cleaned mattes still require inspection), workflow exists but binaries still require release upload.
