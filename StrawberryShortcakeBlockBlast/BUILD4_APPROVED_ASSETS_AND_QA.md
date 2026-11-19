# Berry Berry Blast 0.5.14 (Build 4) | Approved Asset Implementation & QA

**Branch:** `feature/berry-build4-approved-assets-foundation`  
**Known-good rollback:** `b4ffda288b7a778a79a860c8d8ebc2cab3e5755b` (Build 3, physical iPhone 14 Pro tested)  
**Release state:** Development candidate, not physically approved or published.

## Approved image assets

All 30 user-approved PNGs are stored separately in `BerryBlockBlast/Assets.xcassets/<asset>.imageset/`, with complete Xcode Contents.json files. They are not flattened UI screenshots. Each image must be requested by the precise `Image("...")` asset name, not filename. Previously approved artwork and audio remain present.

- **Dev/UI:** Developer_Mode_Strawberry_Lock, Help, Home, Pause, Settings.
- **Economy:** Moonberry_Currency, Strawberry_Currency.
- **Gameplay tools:** Blossom_Gate, Flower, Garden_Mode, Rocket, Rotate, Seed, Special_Tools, Storage, Sweet_Endless.
- **Blossom Glass visual experiment:** Blossom_Decoration, Blossom_Glass_Board_8x8_Concept, Blossom_Glass_Frame_Transparent_Center, Board_Theme_Icon, Strawberry_Blossom_Decoration, Tile_Empty, Tile_Green, Tile_Pink, Tile_Purple, Tile_Sparkle, Tile_Strawberry, Tile_Teal, Tile_Yellow.
- **Future Night Market:** Approved_Night_Market_Storefront (approved illustration only; no currency/market engine in this build).

## Build 4 scope

1. Main Village mode entry uses a coherent two-column navigation grid, preserving classic play.
2. Settings has a discreet custom strawberry-lock entry. Developer Garden uses PIN **1476** for casual hiding only, not security. QA dashboard is read-only or safe. This is a test access method, not a protected administrative API.
3. Visible Sweet Endless label accompanies board size/season, separate from temporary gameplay celebration text.
4. Special Tools opens a player-facing two-column grid with readable power-up descriptions and current charges. Existing action implementation and rules must remain unchanged.
5. Native, non-blocking combo celebrations at x10, x20, x30, x50, with approved artwork opt-in when dedicated banner PNGs are available.
6. Version labels read actual CFBundleShortVersionString and CFBundleVersion, now 0.5.14 build 4.
7. Experimental Blossom Glass appearance is **opt-in**, visual only; original Strawberry Jam Garden stays default. Do not change board size, grid geometry, gesture hitboxes or saved game data.

## Deferred intentionally

- Moonberry secondary currency economy and nighttime market hours/switching, owned inventory and rewards: **Build 6** after dedicated persistent-transaction and real-clock testing.
- Notification presentation consistency, Daily Quests and progression expansion, local midnight resets: **Build 5**.
- Physical-device distribution and AltStore signing failures on the iPhone 16: unresolved pending precise error. Existing unsigned IPA still needs signing for AltStore Classic.

## Before approving release

- [ ] CI source + artwork + 67-original-audio integrity pass.
- [ ] Engine regressions pass; iPhone 14 Pro and iPhone 16 simulator suites pass.
- [ ] iOS 16 physical-device-target app builds and unsigned IPA packages cleanly.
- [ ] Launch/resume current Endless saved run, score, line count, moves and purchases on real iPhone 14 Pro.
- [ ] Check accurate placement at all four board corners and no preview/decorations beyond frame.
- [ ] Confirm original and Blossom Glass board appearances can be switched without movement or layout changes.
- [ ] Confirm Developer Garden is reached via Settings lock and PIN. Wrong PIN blocked, settings are normally player-friendly.
- [ ] Confirm Tools rotate/storage/trowel/seed/golden actions work and charges deduct only on success.
- [ ] Confirm home/pause/help/settings entry during gameplay and all modal dismiss paths.
- [ ] Test ×10/20/30/50 celebration briefly; no ghost taps or game interruption.
- [ ] Check exact version on home and settings; ensure TrollStore metadata matches.
- [ ] Examine iPhone 16 AltStore install error; avoid claiming resolved without real signing test.

Do not merge into stable Build 3 or publish until the above gates pass.
