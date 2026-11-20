# 🌙 Night Garden S1 · Source-derived asset parity register

**Generated from actual GitHub asset-catalog filenames:** November 20, 2026, branch `planning/berry-night-garden-overhaul-v47-v48`, as a **planning scaffold**. **30 of 30** existing `Night_*` image sets have an exact day-name counterpart in `BerryBlockBlast/Assets.xcassets`. Total image sets seen: **152**, including **30 Night_** and **122 other**. **Imported ≠ routed ≠ visually approved.**

Companion issues: [S1 audit #24](https://github.com/ValentineBSAA/IPhone-Apps/issues/24) · [Night Garden epic #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23) · [master roadmap](BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md).

## Verified matching filenames (not runtime proof)

The `Mapped in night resolver` annotation means the *name appears* in `BerryDayNightAppearance.nightCounterpart`. It does **not** establish that the relevant displayed button actually requests that source name, that the art matches its label, or that the owner approved the appearance. All visual approval fields remain open until side-by-side hardware screenshots.

| Existing day image set | Existing night image set | Both imported | Source routing evidence | Important review / approval status |
| --- | --- | --- | --- | --- |
| `Approved_Night_Market_Storefront` | `Night_Approved_Night_Market_Storefront` | Yes | Not shown in known resolver; use-site audit pending | Owner reports approved shop/night icon not surfaced appropriately; preview only until Build 6 |
| `Blossom_Decoration` | `Night_Blossom_Decoration` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Blossom_Gate` | `Night_Blossom_Gate` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Blossom_Glass_Board_8x8_Concept` | `Night_Blossom_Glass_Board_8x8_Concept` | Yes | Not shown in known resolver; use-site audit pending | Concept only, not approved real playable board |
| `Blossom_Glass_Frame_Transparent_Center` | `Night_Blossom_Glass_Frame_Transparent_Center` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Board_Theme_Icon` | `Night_Board_Theme_Icon` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Developer_Mode_Strawberry_Lock` | `Night_Developer_Mode_Strawberry_Lock` | Yes | Not shown in known resolver; use-site audit pending | Legacy lock art only; hidden developer entry replaces visible lock |
| `Flower` | `Night_Flower` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Garden_Mode` | `Night_Garden_Mode` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Help` | `Night_Help` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Home` | `Night_Home` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Moonberry_Currency` | `Night_Moonberry_Currency` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Pause` | `Night_Pause` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Rocket` | `Night_Rocket` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Rotate` | `Night_Rotate` | Yes | Mapped in night resolver; screen proof pending | Resolver uses as UndoIcon; semantic mismatch, needs correct Undo art |
| `Seed` | `Night_Seed` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Settings` | `Night_Settings` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Special_Tools` | `Night_Special_Tools` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Storage` | `Night_Storage` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Strawberry_Blossom_Decoration` | `Night_Strawberry_Blossom_Decoration` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Strawberry_Currency` | `Night_Strawberry_Currency` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Sweet_Endless` | `Night_Sweet_Endless` | Yes | Mapped in night resolver; screen proof pending | Owner visual approval pending |
| `Tile_Empty` | `Night_Tile_Empty` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Green` | `Night_Tile_Green` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Pink` | `Night_Tile_Pink` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Purple` | `Night_Tile_Purple` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Sparkle` | `Night_Tile_Sparkle` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Strawberry` | `Night_Tile_Strawberry` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Teal` | `Night_Tile_Teal` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |
| `Tile_Yellow` | `Night_Tile_Yellow` | Yes | Not shown in known resolver; use-site audit pending | Owner visual approval pending |

## 🌙 Dedicated premium Nighttime Blocks audit · [S3B issue #32](https://github.com/ValentineBSAA/IPhone-Apps/issues/32)

Existing **eight nighttime tile sprites** are present in the 30-asset pack: `Night_Tile_Empty`, `Night_Tile_Green`, `Night_Tile_Pink`, `Night_Tile_Purple`, `Night_Tile_Sparkle`, `Night_Tile_Strawberry`, `Night_Tile_Teal`, and `Night_Tile_Yellow`. However, `BerryBoardVisual` currently uses the night empty-cell art, and `BerryTile` contains a targeted night pink variant; other colored, collectible and trophy tile paths still need individual audit and owner-approved routing.

**S3B is not merely repainting board cells.** The audit needs distinct night counterparts for *occupied* normal tiles in all six tints, current equipped Boutique skins, rewarded/trophy skins, selected tray, dragged and ghost pieces, legal/illegal previews, shrink-and-spring landing, used slots, and default/Blossom Glass rim combinations. Statuses are **imported, runtime-used, aesthetically approved, CI-verified, physical-owner accepted**, separately.

**Unresolved appearance decisions:** moonlit glass/candy shading and glow intensity; visually distinct nighttime reds, violets, blues, teal, green and yellow; whether individual existing cosmetics need newly illustrated night sprites or a documented intentionally shared look. Keep original daytime purchases/skins unaltered, and don't quietly replace them with the same generic purple night block. **Art review first.**

**Test gating:** iPhone 16e only, safe cell mapping for 8/12/24, readable small-sized night tiles, Reduce Motion and rapid taps, no economy/cosmetic ownership mutations on 6AM/6PM transitions. Include cheap tile-asset routing checks before the simulator.

## Additional parity inventory required (screenshots + code route audit)

**P0 Home:** hero logo/character portrait treatment, badge, wallet, section headings and decor; large Berry Classic, Sweet Endless, Berry Story, Daily Harvest, My Strawberry Cottage, More Adventures; Berry Collection, Strawberry School, Berry Village, Berry Quests, Berry Journal, Daily Streak, Strawberry Jukebox, Berry Boutique. Track every Home tile with image source name, whether it even resolves via existing `Night_*` mapping, required new art, device preview and owner approval.

**P0 Gameplay:** `BBBIconHome`, `BBBIconPause`, `BBBIconSettings`, `BBBIconHelp`, `UndoIcon`, `ShuffleIcon`, `BerryHint`, `StatsChart`, `BBBIconTools`, `BBBIconShop`; score/best/combo, game objective, 8/12/24 board sectors, tile states/preview, tray used-slot state, Original and Blossom exterior edge. **Night_Rotate is not an adequate automatic Undo substitute.**

**P1 Settings:** Gameplay, Block Appearance, Audio, Celebrations, Accessibility, Data & Restore cards plus inner pages, toggles, captions, disabled states, native sheet header, icons, Back and Done.

**P1 Boutique and tools:** Garden Helpers Undo/Shuffle/Hint; Golden Trowel, Ribbon Twister, Starberry Seed, Golden Strawberry, Picnic Pantry, Berry Spyglass; Board Studio, permanent upgrades, shop banners, wallet, price badges and empty/locked states. Existing approved Night Market art should be preview-only in Build 4.7/4.8, not live Moonberry commerce.

**P1 Other screens:** Story, Classic, Endless, Daily, Cozy, Blitz, Strawberry Nightmare as separate game mode, Village, Quest board, Journal, streak/calendar, Jukebox, School, collections/trophies, results, stats, credits, tutorials and all shared sheets/dialogs.

**P2 Developer only:** quick Test Strawberries, Diagnostics, Save Inspector, Combo Preview plus advanced build/clock/economy previews and hidden entry. QA grant unchanged; release binary strips injection.

**P0 Celebrations:** day/night independent berry sprites, strawberry fireworks, falling strawberry showers, combo banners, Reduced Motion fallback. Preview test must not alter score or berries.

## Required columns for full S1 handoff

For every visible/interactive element on every user-facing screen, complete:

```text
Screen / Subview / State | Day source set | Night source set | Imported? | Routed in runtime? |
PNG dimensions / alpha | Visual size | Exact code consumer | Correct semantics? |
Day/night iPhone 16e screenshot references | Color/contrast accessibility |
Owner-approved day? | Owner-approved night? | Missing/bug/issue | Test status
```

**Approval policy:** All unresolved entries stay OPEN; no green completion from a filename match alone. Proposed generated/new illustrated icons must be reviewed by owner in deliberate batches. Protect old day source, existing saves and all prices. Always run fast asset routing validation before simulator work.
