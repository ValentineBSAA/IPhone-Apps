# 🍓 Berry Berry Blast | Coordinated Build 4.4–6 Roadmap
## 🌙 Night Garden Overhaul: complete day/night parity and strawberry fireworks

**Updated:** November 20, 2026. This document supersedes the historic "Build 4" pending QA and retired dual-phone statements **for future work only**. Historic screenshots, 30-image import provenance, QA results and decisions are preserved here. **This roadmap is planning, not a shipping build or owner approval of new art.**

**Owner-approved strategy:** Stage the premium night identity across **Build 4.7 (Night Foundation + Gameplay)** and **Build 4.8 (Full Parity + Strawberry Spectacle)**. Keep **Build 5** (progression and feedback) and **Build 6** (real Moonberry economy) independent. Do not stuff all cosmetic work into already-compiled Build 4.6 or break its baseline.

**Issue index:** [Night Garden umbrella #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23) · [S1 asset ledger #24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24) · [S2 themed clocks #25](https://github.com/ValentineBSAA/IPhone-Apps/issues/25) · [S3 gameplay night parity #26](https://github.com/ValentineBSAA/IPhone-Apps/issues/26) · [S4 Home & menus #27](https://github.com/ValentineBSAA/IPhone-Apps/issues/27) · [S5 Boutique & tools #28](https://github.com/ValentineBSAA/IPhone-Apps/issues/28) · [S6 strawberry fireworks #29](https://github.com/ValentineBSAA/IPhone-Apps/issues/29) · [S7 test & release QA #30](https://github.com/ValentineBSAA/IPhone-Apps/issues/30).

## 1. Baselines, what is complete and what is not

| Workstream | Current status (evidence) | Next gate / owner decision |
| --- | --- | --- |
| Builds 3 / 4.0–4.4 | Historical original gameplay/assets QA; historical reports retained in #8 and relevant BUILD4 docs. Not active target | Do not overwrite tested snapshots or infer new acceptance |
| Build 4.5, v0.5.15 | [Fair Play QA #14](https://github.com/ValentineBSAA/IPhone-Apps/issues/14), accepted as development baseline, purchases/ledger audited; [draft PR #15](https://github.com/ValentineBSAA/IPhone-Apps/pull/15) | No economy repricing without independent decision |
| **Build 4.6, v0.5.16** | **GREEN** [CI #44702838659](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44702838659) with quick Linux preflight, iPhone 16e XCTest smoke, full XCTest, screenshots, unsigned IPA. [Draft PR #20](https://github.com/ValentineBSAA/IPhone-Apps/pull/20), unmerged. Owner reported **9/10 physical tests checked** on iPhone 16e, #7 celebration **unchecked**; day/night clock **functionality checked** but **visual approval explicitly withheld**. | Keep Build 4.6 as functional candidate; night art and spectacle are NOT done |
| Build 4.6 layout, hidden QA menu & landing | 92% width cap, top/bottom safe spacing, secret version-label long press, typed grant, block bounce and initial ~44 strawberry particles implemented and owner-tested | Preserve functioning gameplay/saves; document visual shortcomings |
| Historical night art pack | **30 individual `Night_*.imageset` folders present** in current branch plus their daytime source art; import previously verified | Image presence does NOT mean every screen is routed or aesthetically approved |
| **Build 4.7** | PLANNED | Approved day/night asset matrix, premium dual-clock artwork, theme foundation and gameplay icon parity |
| **Build 4.8** | PLANNED | Complete Home, Settings, Boutique and auxiliary parity; dramatically improved celebration; owner approval |
| **Build 5** | PRESERVED backlog | Existing Quest/Village/progression/notification improvements only |
| **Build 6** | PRESERVED backlog | Real Moonberry ledger, earn rules, transactional Night Market, day/night shop switch |

**Current physical device policy:** **iPhone 16e only**, portrait iOS 16.0+ target. Older Build 3 and 4 reports sometimes mention iPhone 14 Pro; those are historical only. Future CI must not schedule an iPhone 14 Pro or make it a release gate. Existing older IPA is unsigned; no hidden merge, release, signing or install claims.

**Screenshot references:** current owner-shared `IMG_9803`–`IMG_9812` (Home, game, effects, story), `IMG_9797`–`IMG_9802` (Developer Garden, QA wallet, settings), historic day-Boutique `IMG_9792`–`IMG_9795` (helpers and tools). They were submitted **in conversation**, not uploaded as GitHub source attachments; use physical captures when implementing.

## 2. Non-negotiable release rules

- **Day and night are visual themes, NOT difficulty modes.** Strawberry Nightmare remains its separate 12×12 timed game regardless of local time. The UI must never imply other modes become Nightmare after 6 PM.
- **Total visual parity:** every **visible** icon, illustrated game/mode card, button, banner, logo treatment, HUD stat, background, shop tile, selected/disabled/locked indicator, board tile/frame, footer, navigation/sheet, and user-facing modal must have an intentional **daylight** and **night** presentation. Shared neutral art is allowed **only if reviewed** and marked intentionally shared.
- Keep 30 existing night assets and original day assets **unchanged until reviewed**. Source PNG import ≠ runtime asset routing ≠ owner aesthetic approval. No low-quality auto recolor or misnamed fallback masquerading as a completed variant.
- All player-facing menus and settings subpages remain **two-column grids** where applicable; don't introduce linear settings lists. Match icon weight/size and readability, not just hue. Make Home tiles more prominent without crowding text.
- Preserve exact 8×8/12×12/24×24 board touch mapping, 3pt touch margin, 8pt exterior Blossom Glass frame and saved scores/strawberries/charges/skins/inventory. Avoid input blockage and unsafe control positioning beneath notch or home gesture bar. Preserve readable disabled tool states.
- Preserve game economy/prices/award-once rules, quests, soundtracks, original audio, accessibility settings and iOS16 compatibility. No real Night Market or Moonberry transactions before Build 6.
- **Never use QA-granted strawberries as real earnings metrics.** Internal Test Strawberries control is permitted only in special `BERRY_INTERNAL_QA` test builds, guarded from release distribution. Require explicit action + expected result before any QA transaction, never surprise spend or require farming combos.
- No milestone is marked done from a passing Swift compile alone. Use three separate states: **asset imported**, **feature routed/tested**, **visual owner approved**. A candidate IPA must pass fast CI, full CI, physical iPhone 16e and explicit release decision.

## 3. Asset baseline and missing night visual parity

### 3.1 Previously imported 30 Nighttime assets
**Source:** [Nighttime release](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/Nighttime) archive `Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip`, validated in [GitHub Actions #44435721368](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44435721368). All 30 image sets exist in `BerryBlockBlast/Assets.xcassets` on the Build 4.6 base. Day versions and audio were not replaced. **This is import verification only.**

```text
Night_Approved_Night_Market_Storefront
Night_Blossom_Decoration
Night_Blossom_Gate
Night_Blossom_Glass_Board_8x8_Concept
Night_Blossom_Glass_Frame_Transparent_Center
Night_Board_Theme_Icon
Night_Developer_Mode_Strawberry_Lock
Night_Flower
Night_Garden_Mode
Night_Help
Night_Home
Night_Moonberry_Currency
Night_Pause
Night_Rocket
Night_Rotate
Night_Seed
Night_Settings
Night_Special_Tools
Night_Storage
Night_Strawberry_Blossom_Decoration
Night_Strawberry_Currency
Night_Sweet_Endless
Night_Tile_Empty
Night_Tile_Green
Night_Tile_Pink
Night_Tile_Purple
Night_Tile_Sparkle
Night_Tile_Strawberry
Night_Tile_Teal
Night_Tile_Yellow
```

**Known runtime integration gap:** `BerryDayNightAppearance.nightCounterpart(for:)` maps only a limited subset (Home, Pause, Settings, Help, Tools, Sweet Endless, Currency, Board, Undo, Seed, Storage) and uses `UndoIcon → Night_Rotate`. That is **not proof** of proper night parity and a rotate symbol may be semantically wrong for Undo. Other visible screen icons show daytime art at night. The approved Night Market storefront pair exists (`Approved_Night_Market_Storefront` and `Night_Approved_Night_Market_Storefront`) but owner says the night shop icon is not yet presented properly in Build 4.6. Inspect real use-site, not filename.

**Do not ship the `Night_Blossom_Glass_Board_8x8_Concept` concept as the real playable board** without separate approved interaction testing. An older `Night_Developer_Mode_Strawberry_Lock` art asset can remain archived even though the visible lock button was intentionally removed; the secret Settings long-press is the approved entry.

**Concrete initial asset register:** [NIGHT_ASSET_PARITY_MATRIX.md](NIGHT_ASSET_PARITY_MATRIX.md), generated from the actual repo catalog, confirms **30/30 existing Night_* files have matching day filenames**, and marks runtime routing/visual acceptance as still unverified. Treat its detailed use-site matrix as a S1 work queue, not a finished art approval.

### 3.2 Required exhaustive asset inventory, S1 [#24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24)

Each row in the planned `NIGHT_ASSET_PARITY_MATRIX.md` (new, generated when S1 begins) must contain:
`screen/section | day asset | night asset | file status | runtime consumer | sizes/alpha | approved? | screenshot/day | screenshot/night | owner outcome | issue`.

Do not mark a group green if ANY visible active state is mismatched. Capture **day and night** for each; use code-level fallback only when art is deliberately marked shared. Review and prioritize these groups, derived from owner screenshots:

| Area | Day ↔ night items to audit/rework | Priority |
| --- | --- | --- |
| **Home top and hero** | v4.6 build badge, currency wallet, **approved Boutique/Shop shortcut**, Settings shortcut, brand/character illustration frame, logo treatment, welcome/header garnish, game title and status highlights | P0 |
| **Home play-mode cards** | **Berry Classic, Sweet Endless, Berry Story, Daily Harvest, My Strawberry Cottage, More Adventures**: new large enough, crisp night-remixed illustrations with aligned daytime size/padding | P0 |
| **Home exploration cards** | **Berry Collection, Strawberry School, Berry Village, Berry Quests, Berry Journal, Daily Streak, Strawberry Jukebox, Berry Boutique**; section headers, icons, badge overlays | P0/P1 |
| **Both live digital clocks** | Full independent **strawberry-themed daytime clock** and **premium nighttime clock**, local 12-hour numeral/AM-PM, styled frame/animation/icons, next scheduled transition. Current plain capsule/SF glyph is visually unapproved | P0 |
| **Gameplay top toolbar** | Pause, Home/Return, Settings, Help; day/night selected/pressed, badge sizes, safe tap targets | P0 |
| **Gameplay bottom toolbar** | Undo, Shuffle, Hint, Stats, Tools, Boutique; charge badges and zero/disabled/locked states; **true Night Undo** art, not `Night_Rotate` unless separately approved | P0 |
| **Gameplay board/HUD** | Score, Best, Combo, story chapter objective, sector/patch, lines/moves, wallet, game-mode label, tray piece cards, used checkmarks, preview/ghost, colored empty/filled cells, corner flourishes; Original vs Blossom Glass frame, selected cosmetics and 8/12/24 geometry | P0 |
| **Settings tiles** | Gameplay, Block Appearance, Audio, Celebrations, Accessibility, Data & Restore; full subpage back/Done, toggles, labels, buttons and header treatment | P1 |
| **Boutique & helper/tool screens** | Extra Undo, Extra Shuffle, Berry Hint, Golden Trowel, Ribbon Twister, Starberry Seed, Golden Strawberry, Picnic Pantry, Berry Spyglass; wallet, prices, item cards, board studio, shop sections, permanent upgrades, notices, disabled states | P1 |
| **Other player screens** | Stats, Help, School/onboarding, Village, Cottage, Daily/Quests, Journal, Streak, Almanac, Collections/Trophies, Jukebox, results, unlock banners and any sheets/cards not pictured | P1 |
| **Internal-only QA** | Developer Garden 4 quick tiles, Test Strawberries, Diagnostics, Save Inspector, Combo Preview, additional economy/build/clock panels; explicit separation of QA grant/normal wallet | P2 |
| **Celebrations** | Berry burst V2 daytime and nighttime sprites, fireworks/rain, combo text, ribbons/petals, Story/milestone glow, Reduced Motion fallback | P0 independent stage |

## 4. Staged build gates (each stage must be independently tested)

### S0: Preserve Build 4.6 as a non-final visual baseline
- [x] Green [source/engine/iPhone16e CI #44702838659](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44702838659), native unsigned test IPA available.
- [x] Owner reports **nine of ten Build 4.6 physical checklist items checked** (saves, QA wallet, board, landing, 12-hour time routing and sheet controls); screenshot data supports presence, while interactive behavior is owner-reported.
- [ ] **Owner withheld artistic acceptance for clock/night**. Don't check "Night Edition done" based on existing functional time flag.
- [ ] **Celebration V1 aesthetic not approved**: #7 still unchecked; visible strawberries appear but are not spectacular enough.
- [ ] Preserve accepted 4.6 source/PR as is; roadmap planning goes to separate branch and must not trigger another expensive 4.6 CI/IPA until code actually changes.

### S1: Full icon inventory / owner approvals, [issue #24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24) • Build 4.7
- [ ] Map every existing day asset, all 30 imported `Night_*` sets and every player-visible use-site, including SVG/SF symbols or gradients not backed by images.
- [ ] Classify `present / needs art / approved in Github but not routed / routed but aesthetically wrong / intentionally shared`.
- [ ] Investigate exact approved Night Market artwork; wire only after review. Recreate **true** missing night icons for Undo/Hint/Shuffle/Home/Boutique, don't mislabel Rotate as Undo.
- [ ] Create batch contact sheets or individual PNGs, request owner approval per group; avoid uncontrolled icon generation.
- [ ] Add fail-fast asset parity manifest/source tests before simulator runs.

### S2: Day/night premium theme and TWO clocks, [issue #25](https://github.com/ValentineBSAA/IPhone-Apps/issues/25) • Build 4.7
- [ ] Commission/approve **two high-quality 12-hour digital clock concepts**, one strawberry-day and one moonlit-night, with polished numerals, AM/PM, ornaments, consistent margins, distinct light/dark contrast and safe legibility.
- [ ] Replace current plain clock pill with theme-aware compact clock component; show **garden-cycle boundary** in clear terms rather than claiming solar sunset/sunrise.
- [ ] Retain local 6:00 AM / 6:00 PM boundaries, `Calendar.autoupdatingCurrent`, offline resume, DST, time zone, midnight, background, 30-second refresh or better efficient boundary scheduling.
- [ ] Add preview time in developer diagnostics instead of asking owner to change phone clock; preview can never alter real clock or economy.
- [ ] Centralize day/night palette for backgrounds, sheets, status cards, selection, disabled state, art routing; verify WCAG-reasonable contrast on real iPhone 16e.

### S3: Gameplay visual parity first, [issue #26](https://github.com/ValentineBSAA/IPhone-Apps/issues/26) • Build 4.7
- [ ] Route top+bottom bar icons, scores/HUD/board/tray through audited day/night variants. Keep `Strawberry Nightmare` difficulty mode visually separate from the night-cycle state.
- [ ] Preserve 92% safe width and exact board touch geometry, Story/Endless sectors/patches, original/Blossom surfaces, selectable skins, oversized piece placement followed by approved shrink/bounce.
- [ ] Verify 8/12/24 and corner/edge hits, selected/disabled/consumed state, game navigation, Reduced Motion, screenshot pairs, saved state.
- [ ] **Build 4.7 QA gate:** source/icon/geometry preflight → dedicated 16e smoke → full XCTest → screenshots → unsigned IPA → focused real-device owner approval; no premature nightly full-test loop.

### S4: Home, menus and Settings parity, [issue #27](https://github.com/ValentineBSAA/IPhone-Apps/issues/27) • Build 4.8
- [ ] Approve and integrate **larger** Home icons in the two-column grids; include all 14 named Home cards and top hero/wallet/banner accents.
- [ ] Settings six cards and nested pages, all other screens, Help, results, challenges, Village/School/Quests/Journal/Streak/Collection/Jukebox, subpage nav and static decorative elements. No daytime leftovers unless explicit approved reuse.
- [ ] Require day/night screenshot comparison and user-approved palette, icon readability, consistent header/sheet title and button states.

### S5: Boutique, tools, stats and developer visual parity, [issue #28](https://github.com/ValentineBSAA/IPhone-Apps/issues/28) • Build 4.8
- [ ] Integrate the already-approved **night shop icon and storefront** in a non-transactional preview; keep real Night Market locked until Build 6.
- [ ] Finish both theme sets for helper cards, premium tools, Board Studio, shop controls, badges, disabled/locked colors, QA tools, save/stats/inspector screens.
- [ ] Preserve known prices (Undo 40, Shuffle 50, Hint 35; Golden Trowel 150, Ribbon Twister 200, Starberry Seed 230, Golden Strawberry 250, Picnic Pantry 600, Berry Spyglass 900); no forced owner purchase.
- [ ] Guard Build 4.6 hidden developer QA input and audit, no QA money in public binary; fix sheet header overlap, ScrollView geometry, Done routing.

### S6: **Strawberry Fireworks V2**, [issue #29](https://github.com/ValentineBSAA/IPhone-Apps/issues/29) • Build 4.8
- [ ] **Small clear:** abundant, obvious **falling strawberries drifting over the board**, visible silhouettes and soft fades.
- [ ] **Multi-line/combo:** distinct **strawberry firework explosions** and radial bursts, with an aerial second wave plus falling berries.
- [ ] **Milestone / Story:** multi-wave board-wide signature berry shower/fireworks celebration; visually grand without blocking next move, Pause, buttons or score.
- [ ] Design strawberry sprites, petals/ribbons/glow or fireworks particles for both day and night; use actual optimized art where emojis look flat, avoid excessive blur/flash.
- [ ] Preview ×10/×20/×30/×50 tiers from Developer Garden **without grinding** and without creating rewards; no artificial boosts in the real economy.
- [ ] Limit allocations / FPS / battery heat on iPhone 16e, handle simultaneous clears and animation cancellation, preserve pause/resume and Reduce Motion fallback.
- [ ] Owner judges short phone recordings, **not only screenshot stills**. Do not check off while the existing 44-tiny-berry effect still feels underpowered.

### S7: Complete Night Garden QA, [issue #30](https://github.com/ValentineBSAA/IPhone-Apps/issues/30) • Build 4.8
- [ ] Per-screen day+night parity matrix (100% of public-facing visible assets intentionally routed or explicitly approved shared) with owner signoff.
- [ ] Clock formatting and day/night boundaries tested without modifying device clock; DST, date change, resume, timezone/offline, VoiceOver and larger text.
- [ ] Physical **iPhone 16e** comparison: Home full scroll, Classic, Endless 8/12/24, Story, Daily, Cozy, Blitz, Nightmare, Settings nested cards, Boutique helpers/tools, Cottage, Quests, School, Journal, Streak, Jukebox, Collection, stats, menus, Board Studio.
- [ ] Touch/HUD/notch safe, 92% board and Blossom edge geometry, save/restore, QA grants not exposed in public builds, no surprise purchase.
- [ ] CI: cheap source/asset/geometry gate before simulator; 16e-specific smoke before comprehensive XCTest; screenshot and FPS/animation evidence; no 14 Pro.
- [ ] Do not merge, publish, or call any visual "finished" without **separate owner visual approval** and explicit go/no-go.

## 5. Builds 5 and 6 are preserved, NOT absorbed by Night Garden

### Build 5: existing notification, quests, Village and progression polish
- [ ] In-context rewards, milestones and celebrations appear in the active page, never behind Settings/Boutique or a blocked modal.
- [ ] Queue and deduplicate notifications; ensure current view survives tab changes/home navigation.
- [ ] Daily Quests and Village progression, rewards, 7-day/365-day records where designed, streaks and calendar have clear state and don't double-credit.
- [ ] Progress and reward once across save/reload, Undo, overnight/midnight and app re-entry; local calendar reset tested independently of Night mode.
- [ ] No feature bloat: existing features get accessible, two-column grid polish with **both day/night asset themes**; integrate new features into completed theme system, not reopen whole art pipeline.
- [ ] Short CI + real iPhone16e owner QA, save migration compatibility and explicit approval.

### Build 6: actual Moonberry currency and transactional Night Market
- [ ] Separate durable Strawberry and Moonberry wallets, transparent earn/spend ledgers, economy migration/rollback, purchase integrity.
- [ ] Earn Moonberries from verified Endless milestones with once-only grant semantics despite Undo, reloading, retries and season changes.
- [ ] True shop switch/availability at scheduled **6 AM / 6 PM device-local garden cycle**; approved storefront artwork reused from Night Garden parity. Real purchases only once complete and owner-approved.
- [ ] Prices, permanent ownership, helpers and inventory persist over shop transitions, midnight, DST, timezone, offline and foreground resume.
- [ ] Finish in-flight purchases before changing shop and don't mutate game mid-move. Graceful error/recovery and rollback.
- [ ] Manual phone time is not authoritative against cheating; document any offline trust policy without pretending device time is secure.
- [ ] Comprehensive test-only economic QA, no interference from developer QA currency, plus real iPhone16e signoff. Nighttime theme by itself must never make Moonberries spendable in Build 4.7/4.8.

## 6. Engineering / release coordination

**Source branches:**
- Build 4.5 functional baseline: `feature/berry-build4-r6-fair-play-lab` ([draft PR #15](https://github.com/ValentineBSAA/IPhone-Apps/pull/15)).
- Build 4.6 tested visual candidate: `feature/berry-build4-r7-night-bounce-qa` ([draft PR #20](https://github.com/ValentineBSAA/IPhone-Apps/pull/20)), verified green [CI #44702838659](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44702838659).
- **Roadmap planning only:** `planning/berry-night-garden-overhaul-v47-v48` (this file). No binary rebuild needed for plan-only changes.
- **Future** Build 4.7/4.8 feature branches should start from a reviewed baseline and use narrow commits/PRs, not silently merge 4.6/night/economy/quest code together.

**Every implementation stage:** owner-approved art list → separate code changes → **fast Linux source/asset/geometry check** → iPhone16e geometry+asset XCTest smoke → comprehensive XCTest and screenshots → unsigned native IPA inspection → focused physical iPhone16e QA → record approval or defect → only then merge/release decision. Count imported/implemented/CI-passed/owner-accepted separately.

**No hidden expenditures:** owner QA instructions must say exactly `starting balance → tap/type → expected amount/result`. Do not require buying tools, grinding high combos or changing phone's clock just to pass a checklist.

**Carry-forward unrelated:** historical AltStore/signing issues belong to their separate installation workflow; do not block art roadmap with unverified old iPhone16 hardware claims. New 4.7/4.8 app versions and build numbers are to be assigned at implementation, not guessed as completed.

## 7. Historic provenance retained

The original [Nighttime source release](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/Nighttime) included 30 named imagesets and prior validation; the old roadmap's import workflow used:

```bash
cd StrawberryShortcakeBlockBlast
python3 Tools/import_night_assets.py /path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip
python3 Tools/import_night_assets.py /path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip --apply
git status --short
```

Import checks were reported green, but runtime mapping and aesthetic acceptance remain separate. Historic plans, especially Build 3/4 device reports and Build 4.4/4.5 checklists, are retained in [master historical Issue #8](https://github.com/ValentineBSAA/IPhone-Apps/issues/8), [Build4 approved assets](BUILD4_APPROVED_ASSETS_AND_QA.md), [Build4.4 QA](BUILD4_4_BOUTIQUE_TOOLS_QA.md) and [Build4.5 QA](BUILD4_5_FAIR_PLAY_QA.md). This document is the **current forward-looking source of truth**.

**Final control:** No Build 4.7/4.8 implementation or image generation has been started by this roadmap update; asset creation requires separate user approval. No PR merge, no app public release, no existing gameplay changes.
