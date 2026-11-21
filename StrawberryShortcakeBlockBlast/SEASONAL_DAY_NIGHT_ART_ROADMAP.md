# 🍓🌙 Berry Berry Blast | Seasonal Garden Day + Night Artwork and Continuity Plan

**Owner-approved planning directive:** November 20, 2026  
**Status:** DOCUMENTED / NOT GENERATED / NOT IMPLEMENTED / NO BUILD ASSIGNED  
**This is an additive extension, not a replacement for the coordinated [Build 4.4–6 and Night Garden roadmap](BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md).**  
**Parent work item:** [Seasonal Garden epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).

## 0. Handoff snapshot: what is already complete vs what is pending

### Approved Night Garden source and transparency
- Owner approved **40/40 individually AI-generated Night Garden icons** across the original eight batches; the final `Night_Build_Information` and approved Batch 2 redo are included. This approval covers the **ARTWORK**, not all runtime visual parity or the separately planned Night mode/story content.
- Owner subsequently reviewed **all 40/40 derived true-RGBA candidate PNGs** (Batch 1 first, Batches 2–8 in the final review) and explicitly stated **all look good**. **RGBA candidate visual approval now 40/40.** This supersedes older ledger wording that 36 were awaiting visual approval.
- Preserve the source master archive from [Release V1](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/V1), SHA-256 `3d4785171fe9ffe5ca019b814bfeb4ceba0663e33362496b1782db5f7f0f807c`; no art regeneration is needed for the existing 40.
- Owner-approved originals are staged under `StrawberryShortcakeBlockBlast/ArtSource/NightGarden/Approved_40_Icon_Batches/`. Derived review-approved RGBA candidates are staged separately under `ArtSource/NightGarden/RGBA_Candidates/` on branch `artwork/berry-night-garden-40-rgba-staging`.
- [CI #44829982427](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44829982427) validated the 40 originals; [CI #44841613153](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44841613153) validated the first four RGBA; [CI #44843011429](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44843011429) green after all 36 remaining conversions, confirming 40 originals + 40 real RGBA image files. [Draft PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40) remains **unmerged**. Do not silently replace the legacy 30 `Night_*` Xcode image sets, original Day icons, the already approved Night Market storefront or other game assets.
- **Still pending:** Xcode `.imageset` creation, precise visible call-site routing, icon-size/device contrast checks, actual iPhone **16e** smoke/physical acceptance, shipping decision. Owner saying “art looks good” is NOT device integration approval.

### Existing Build work (unchanged)
- **Build 4.6 / v0.5.16:** functional iPhone 16e baseline (owner previously checked 9/10, spectacle not accepted; compact day/night digital clock looks provisional); green [CI #44702838659](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44702838659); [draft PR #20](https://github.com/ValentineBSAA/IPhone-Apps/pull/20). Preserve hidden Developer Garden and typed test grants only under QA compile flags; save data, economy and game modes intact.
- **Build 4.7:** Night visual foundation, two premium 12-hour strawberry digital clocks, board/tray/HUD and occupied nighttime blocks. Track S1–S3B under [Night Garden #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23), [asset register](NIGHT_ASSET_PARITY_MATRIX.md) and [owner-approved 40-icon ledger](NIGHT_40_ICON_ART_APPROVAL_LEDGER.md).
- **Build 4.8:** complete Home (large mode icons), Settings, Boutique, tools, remaining page parity and significantly stronger strawberry-firework/board-wide berry-rain effects. Keep user-approved grid-first menus. S4–S7 tickets #27–30. Do not consider 4.7/4.8 fully implemented based on source art approval.
- **Build 5:** existing Quests, Village, notification and progression improvements, not replaced with seasonal scope.
- **Build 6:** real separate Moonberry economy and a genuine Night Market with **different merchandise** from Day Boutique; not merely purple versions of Day items. No premature shop transactions, altered Day prices or cross-wallet charges.
- **Future independently gated Night Story/modes:** architecture [N1 #33](https://github.com/ValentineBSAA/IPhone-Apps/issues/33), distinct game modes and narrative [N2 #34](https://github.com/ValentineBSAA/IPhone-Apps/issues/34), different Night inventory [N3 #35](https://github.com/ValentineBSAA/IPhone-Apps/issues/35), full two-experience QA [N4 #36](https://github.com/ValentineBSAA/IPhone-Apps/issues/36). New Night modes/story implementation build number TBD. `Strawberry Nightmare` is already a named mode and must not be conflated with automatic night, seasonal Halloween or the Night experience.

## 1. New product vision: four season/event packs, each with DAY and NIGHT artwork

Every pack must feel like a **hand-illustrated original Berry Berry Blast world**, not a generic holiday stock sticker pasted over a pink menu. Maintain the existing premium candy-glass, embossed strawberry/pastry, polished highlights, gold detailing, thick readable silhouettes, soft gradients, playful garden shapes and clean two-column cards.

A night counterpart should be a **purposeful remix**: same function and recognizability but distinct lighting, mood, nighttime materials and accent shapes. Never simply darken a Day PNG or turn every icon the same purple. Protect the 40 approved Night originals and the original Day art. Existing strawberry character/world branding must stay original; do not incorporate copyrighted third-party character designs/marks.

| Pack | Day identity | Night identity | Signature details | Linked issue |
| --- | --- | --- | --- | --- |
| **Halloween** | Pumpkin-berry patch in warm pink, violet lilac, apricot, honey orange, playful berry candy cottage | Storybook enchanted moon garden; dark plum velvet, glowing amber, purple glass and magical carved-berry lanterns | Pumpkin-strawberry lantern; golden leaf swirls, little bats as subtle flourishes, candy trails, glowing window silhouettes; **never gory horror** | [H1 #43](https://github.com/ValentineBSAA/IPhone-Apps/issues/43) |
| **Christmas** | Snow-frosted berry bakery with cranberry red, evergreen, whipped-icing white, candy-cane stripes and brushed gold | Frost-blue moonlit winter; dark sapphire/plum, candlelit windows, silver snow crystals, warm gold fairy lights | Berry-tree ornaments, gingerbread/shortcake cottage, gilded ribbon gifts, soft snowberry sparkle; review existing `BBBFrameChristmas` | [H2 #44](https://github.com/ValentineBSAA/IPhone-Apps/issues/44) |
| **Thanksgiving** | Cozy orchard berry harvest with cinnamon, pumpkin/apricot, cranberry, toasted honey gold, maple leaves and pastry basket | Copper-lantern harvest at dusk; mulberry purple, burgundy, chestnut, amber fireflies and warm candlelight | Embroidered leaf wreaths, harvest table, berry-topped pie, wicker baskets and pumpkin squash; **not a Halloween recolor** | [H3 #45](https://github.com/ValentineBSAA/IPhone-Apps/issues/45) |
| **Birthdays** | Strawberry celebration bakery; layered cake, rosy frosting, confetti, balloons, gold bows, candle sparkle | Midnight berry party; pearl-amethyst, lavender velvet, glowing candles, moonlit cake and strawberry fireworks | Owner's original character portrait optional, cake stand, party streamer, balloon bundle; review existing `BBBFrameBirthday`, `BBBIconBirthday` | [H4 #46](https://github.com/ValentineBSAA/IPhone-Apps/issues/46) |

**Mood discipline:** Delightful, cozy, feminine-leaning berry fantasy with polish, legible shape and color separation. Halloween should be enchanting rather than frightening, Christmas warm rather than cluttered, Thanksgiving homey rather than generic autumn stock, and birthdays joyful rather than a low-effort cake emoji. Daylight remains bright; nighttime retains premium contrast and clear interactive controls. Owner reviews all designs before release.

## 2. Full seasonal visual parity inventory: what artwork needs design

**Do not assume the final number of new images.** Audit actual SwiftUI asset use sites before locking counts. Each visible relevant surface receives `Day` and `Night` variants **or** an explicit owner-approved intentionally shared baseline. A seasonal overlay may enhance existing functional icons rather than redraw all 40 Night icons for each holiday.

| Family / use-site | Planned paired seasonal designs | Engineering/UX gate |
| --- | --- | --- |
| **HERO / HOME** | Hero illustration/portrait frame, logo halo/ribbon (logo text remains legible), village background/corners, larger Home cards for Classic/Endless/Story/Daily/Cottage/More Adventures, Collection/School/Village/Quests/Journal/Streak/Jukebox/Boutique | Scroll positions and the already-approved two-column grid retained |
| **Clock + date chip** | Holiday Day clock *frame/face* and Night clock treatment, event badge, sunrise/sunset chip if used; preserve premium 12h AM/PM digital readout | Clock correctness separate from art; no date/time spoof for QA |
| **HUD / NAV** | Pause/Home/Settings/Help/Back/Done, wallet/crown/combo/score headers, objective ribbons, special toolbar icons Undo/Shuffle/Hint/Stats/Tools/Boutique | Meaning must remain instantly recognizable, disabled controls legible |
| **GAMEBOARD** | Seasonal board/frame **exterior only**, empty/occupied tiles, six tints, reward/equipped skins, tray normal/used/ghost/drag, combo landing glints | Exact 8×8/12×12/24×24 touch mapping unchanged; Blossom exterior frame not obscuring cells |
| **STORY + MODES** | Mode illustrations, level/chapter cover treatments, chapter win/lose, Daily Harvest/Blitz/Cozy and existing Nightmare mode card skins | Cosmetic only unless separately approved as new gameplay/story |
| **VILLAGE / COTTAGE** | Seasonal pathways, cottage wreaths/roof/trimmings, garden flower pots, berries, seasonal decorations/overlays | Existing owned decorations and saves unchanged; do not double-spend |
| **QUESTS / JOURNAL / SCHOOL / CALENDAR** | Seasonal quest-board border, check badges, journal/streak/calendar tiles, school lessons, seasonal achievements | Reward/quest schedule unaffected without explicit design approval |
| **BOUTIQUE / NIGHT MARKET** | Day Boutique seasonal merchandise *previews*, separately illustrated Night Market window/display, seasonal item capsules and frames only when approved | **No new purchases, offers, fake price labels or Night Market commerce** before approved shop/catalog work |
| **SETTINGS / SUBMENUS** | Gameplay, Block Appearance, Audio, Celebrations, Accessibility, Data & Restore and inner panels; safe preference toggles, headers, Back/Done | Two-column cards retained, no accidental settings resets |
| **CELEBRATIONS / PARTICLES** | Strawberry firework/star/leaf/snow/balloon confetti and secondary berry rain for each season Day/Night; score milestones, birthday candles | S6 #29 visual spectacle remains independent; Reduce Motion, bounded particles, transparent touches |
| **INTERNAL QA** | Seasonal Theme Preview selector and art parity diagnostic badges when later approved; no need to redraw all developer tools by default | QA-only compilation; previews do not award currency, change saves or purchase anything |

Existing on the planning branch: `Assets.xcassets/BBBFrameBirthday.imageset`, `BBBFrameChristmas.imageset`, `BBBIconBirthday.imageset`, and `BBBIconSeasonal.imageset`. **Reuse/inspect before replacing.** No existing repository filename alone is proof of functional routing, quality, ownership or season-specific Day/Night parity.

## 3. Independent state architecture, event activation and precedence

Do not couple independent values:

```text
selectedExperience = DayGame | NightGame                [future two-games-in-one]
appearance = Daylight | Nighttime                    [6AM/6PM visual foundation]
seasonalTheme = None | Halloween | Christmas | Thanksgiving | Birthday
activeMode = Classic | Endless | Story | ...         [selected experience's mode]
savedGame / wallet / quests / story = preserved independently
resolved art = base appearance + approved seasonal overlay + approved fallback
```

**Explicit decisions not yet approved:** how automatic seasonal schedules work, whether manual theme choice can pin an event all year, whether themes appear in Night Market, seasonal overlay precedence when birthday overlaps another holiday, how long a birthday celebration lasts, opt-out and locale availability. Proposed safe precedence (for review only): **manual selection > opted-in birthday > opted-in date holiday > default Day/Night**. Avoid a timed surprise switch during a move, transaction, chapter or audio playback. User should be able to opt out of holiday visuals in Settings if approved.

Potential date calendar logic **for consideration only**: Halloween Oct 31, Christmas Dec 25, Thanksgiving fourth Thursday of November in the US only, Birthday via explicit profile selection. No assumed global Thanksgiving date; local calendar/timezone/DST/leap-day handling defined and unit-tested before activation. Preview from hidden/internal QA controls without changing device time or modifying wallet, save, or quest rewards. No automatic birthday data collection/notification without explicit opt-in and data-handling approval.

**Holiday ≠ shop:** Optional seasonal cosmetics and unique event shop items are ideas only; define original art, eligibility, currency, ownership, unlock, prices and effect per item with owner approval. Build 6 governs the real Night Market transactional engine; do not let seasonal skins introduce unauthorised Moonberry commerce.

## 4. Artwork generation, file organization and verification contract

**One icon per ChatGPT AI image generation**, never collage contact sheets as the source asset. Generate and approve each element independently with the same subject silhouette for paired Day/Night meaning and a truly redesigned nighttime finish. Batch sizes should be digestible (e.g. 4–6 per review) and owner-approved before the next batch. The number of needed icons is finalized **only after use-site inventory**.

Proposed naming convention (tentative, no new artwork exists):

```text
StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/
  00_Specs_And_Ledgers/
  Halloween/Day/Originals/          Night/Originals/          RGBA_Reviewed/
  Christmas/Day/Originals/          Night/Originals/          RGBA_Reviewed/
  Thanksgiving/Day/Originals/       Night/Originals/          RGBA_Reviewed/
  Birthday/Day/Originals/           Night/Originals/          RGBA_Reviewed/
  _Previews/
  _Source_And_Transparency_Manifest.csv
```

Conceptual Xcode key: `Season_<Event>_<Day|Night>_<SemanticUseSite>` (e.g., `Season_Halloween_Night_HomeClassic`). **No actual key is approved until the audit reconciles all names and existing Xcode collisions.** Avoid `Night_` name collisions with the existing 30 legacy sets or already-approved 40-icon source list.

Source PNGs should be preserved byte-for-byte, SHA-256 recorded, and kept on an isolated branch / draft PR. Transparent RGBA **derivatives** are separate; maintain antialiased glow, gold accents, edge highlights, glass, flowers and shadow. QA each icon against checkerboard/cream/night backgrounds and at 64/96 px plus actual iPhone 16e visual size. Never replace an approved image with cropped collage, batch-generated sticker sheets or generic recoloring. One batch ZIP and contact proof per batch, then owner approval and source GitHub upload. Production Xcode files only modified after separate use-site and alpha QA.

Manifest columns:

```text
Holiday | Day/Night | Semantic key | Screen/subview/state | Existing base asset |
Original source path | Original SHA-256 | RGBA candidate path | Alpha QA |
Owner art approval | Owner RGBA approval | Runtime resolver key | Routed? |
CI test | iPhone 16e screenshot | Visual signoff | Notes/PR/Issue
```

## 5. Safe incremental work stages (NO assigned release version yet)

| Stage | Scope | Output / acceptance |
| --- | --- | --- |
| **H0 / AUDIT** | Review existing assets/UI surfaces, baseline 40-icon visuals and original birthday/Christmas assets; set exceptions/seasonal-use matrix | Site-by-site inventory and exact per-holiday Day/Night asset counts approved |
| **H1 / DESIGN** | Four style bibles and visual hero mockups, seasonal clock shells, one representative Home tile Day+Night per holiday | Owner approves each distinct holiday identity; no vague all-purple variants |
| **H2 / GENERATE** | Individually generate pairs of approved subject assets, 4–6 per batch; store original PNGs and labeled previews | All needed assets exist, semantic identities confirmed, accepted per batch |
| **H3 / RGBA** | Separate alpha derivation/edge QA on light/dark/checker/phone-sized contexts and checksum manifest | True-alpha versions approved without changing source assets |
| **H4 / INTEGRATION** | Add new Xcode imagesets; seasonal appearance resolver & clock/holiday preview; safe fallbacks and opt-out choice | Day/Night/season/experience independent; no game/economy/save regression |
| **H5 / QA & RELEASE** | Fast static asset/date tests then iPhone 16e-only simulator XCTest, screenshots, actual-device testing, accessible motion | Owner accepts visual parity and explicitly authorizes merge/release |

Stages are additive **after** the night visual foundation work has adequate stable routing. They are **not silently inserted into or declared part of Build 4.7/4.8, Build 5 or Build 6**. Implementation build number and any event-specific gameplay/remix belong to later owner decisions. Preview/timeline design can proceed independently when owner wants.

## 6. Complete regression/acceptance list

- Calendar: 6AM/6PM appearance, day/night event image lookup, Oct31/Dec25, Thanksgiving locale and November weekday, birthday leap day, DST, midnight, timezone and offline foreground resume; no changing device clock for manual owner QA.
- Theme selection: seasonal appearance never changes saved mode, gameplay rules, score, owned skins, daily rewards, story chapters, strawberry/Moonberry wallet, current in-game placement or an in-flight purchase.
- Screen parity: full iPhone 16e Home scroll, all mode cards and selected games, Settings grids/subpages, Boutique vs Night Market previews, Board Studio, Blossom rim, Cottage, Village, Quests, School, Journal/Streak, Jukebox, Collection, toolbar and modal dialogs.
- Touch and layout: 8/12/24 board geometry, 92% board display cap, safe area/notch/home bar, tap/drag corner placements, Bounce, pause/resume, compact disabled controls, no decorative layer catches taps.
- Accessibility and quality: VoiceOver labels, Reduce Motion, high contrast, dynamic type, color distinction, crisp 64px and 96px icons, flashlight/snow/firework motion bounded by device thermal constraints, no flashing motion.
- Build safety: originals/40 RGBA night icons/30 legacy Night assets preserve byte hashes; soundtrack 51 M4A and 16 WAV intact; QA wallet not linked to public release; fail fast in Linux asset/manifest/date preflight before costly iPhone16e simulator regression.
- Art approval is separate from imported / code-routed / CI-verified / physical-device accepted. Keep those columns independently in the ledger.

## 7. Links and continuing-work instructions

**Canonical technical plan:** [Build 4.4–6 Night roadmap](BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md)  
**Already approved night originals + RGBA:** [40-icon ledger](NIGHT_40_ICON_ART_APPROVAL_LEDGER.md), [draft PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40), [green Actions #44843011429](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44843011429)  
**Existing night pair source register:** [Night asset matrix](NIGHT_ASSET_PARITY_MATRIX.md)  
**Seasonal tracking:** [epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42), [Halloween #43](https://github.com/ValentineBSAA/IPhone-Apps/issues/43), [Christmas #44](https://github.com/ValentineBSAA/IPhone-Apps/issues/44), [Thanksgiving #45](https://github.com/ValentineBSAA/IPhone-Apps/issues/45), [Birthday #46](https://github.com/ValentineBSAA/IPhone-Apps/issues/46), [Seasonal architecture/QA #47](https://github.com/ValentineBSAA/IPhone-Apps/issues/47).  
**Night technical tickets remain:** [S1–S7 #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23), [S3B occupied Night blocks #32](https://github.com/ValentineBSAA/IPhone-Apps/issues/32), [Night mode/story/economy N1–N4 #33–36](https://github.com/ValentineBSAA/IPhone-Apps/issues/33).

**Starting a fresh ChatGPT conversation:** “Read `StrawberryShortcakeBlockBlast/BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md`, `NIGHT_40_ICON_ART_APPROVAL_LEDGER.md`, and `SEASONAL_DAY_NIGHT_ART_ROADMAP.md` from the planning branch, plus Night Garden draft PR #40 and seasonal issues #42–47. Continue **from the current GitHub status**; do not recreate the already approved 40 Night icons or their RGBA assets. Seasonal artwork is *planned, not generated*. Preserve current Night/Build 5/6 roadmap, keep future seasonal themes a distinct overlay, and ask for visual owner approval before any new art imports or game builds.”

**Stop condition for this documentation task:** Commit/update this plan and existing parent indexes only. **Do not generate new holiday imagery, change Swift/game files, merge PRs, publish an IPA, add a seasonal wallet, or mark any seasonal art completed.**


## H0 continuation status: offline holiday calendar and use-site audit (November 20, 2026)

The previous documentation-only task is complete. A new, **separately isolated, unmerged [draft PR #48](https://github.com/ValentineBSAA/IPhone-Apps/pull/48)** records the first H0 source audit and a **dormant date/region holiday resolver**. Detailed findings and next work queue: [SEASONAL_H0_USE_SITE_AND_CALENDAR_AUDIT.md](SEASONAL_H0_USE_SITE_AND_CALENDAR_AUDIT.md). The code does **not yet enable holiday art in the app**.

- [x] Existing `BBBFrameChristmas`, `BBBFrameBirthday`, `BBBIconBirthday`, and `BBBIconSeasonal` asset files/Swift consumers cross-checked; existing Boutique seasonal category currently hidden.
- [x] Existing birthday local month/day and separate once-per-year **100-strawberry** gift found; no change to that award or its ownership data.
- [x] Isolated `BerrySeasonalCalendar.swift` and `BerrySeasonalCalendarTests.swift` proposal: local Gregorian date + time-zone, device Region or optional country override (not GPS); October 31 Halloween, December 25 Christmas, US fourth-Thursday Thanksgiving, opt-in month/day birthday; Feb 29 exact-date default, overlap preview and preference ordering. Automatic artwork defaults off pending UX approval.
- [ ] Source-only code is not equivalent to a validated iOS build. CI/XCTest on draft PR, exhaustive per-use-site count, owner-approved activation schedule/opt-out, and physical iPhone16e remain OPEN.
- [ ] H1 seasonal icon design/generation is NEXT AFTER H0 approval: one individually generated Day and one Night Home tile for each of four holidays, eight independently approved assets, then clock and full UI parity. **New seasonal PNG count remains zero.**

**The 40 original Night icons and all 40 visually approved RGBA candidates remain separately staged in draft PR #40 and require Xcode/runtime/device QA.** No 4.7/4.8 or Build 5/6 scope is replaced, and no seasonal build number or release is assigned.
