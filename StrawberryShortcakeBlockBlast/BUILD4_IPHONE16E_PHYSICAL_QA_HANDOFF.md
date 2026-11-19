# 🍓 Berry Berry Blast — Build 4 physical iPhone 16e QA and next-chat handoff

**Status:** tested gameplay subset works on physical iPhone 16e; **not signed off** for merge or general release.  
**App:** v0.5.14 / build 4, iOS 16+, latest nighttime-inclusive IPA.  
**Stable source:** `feature/berry-build4-approved-assets-foundation`.  
**Known-good rollback:** Build 3 at `b4ffda288b7a778a79a860c8d8ebc2cab3e5755b` (physical iPhone 14 Pro-tested).  
**Testing evidence:** Nine iPhone 16e screenshots `IMG_9619.jpeg` through `IMG_9627.png` in the user-provided new-chat handoff ZIP; screenshots are *not* published by this commit.  
**Live checkboxes:** https://github.com/ValentineBSAA/IPhone-Apps/issues/8  
**Draft PR:** https://github.com/ValentineBSAA/IPhone-Apps/pull/7  
**Successful full Build 4 CI (includes 30 night assets):** https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44435872838

## What the user physically verified on iPhone 16e
- [x] Main menu spacing and overall layout look good.
- [x] Sweet Endless operates on 8×8; visible heading says Sweet Endless, grid size and Season 1 / Spring Bloom.
- [x] Three tray pieces are visibly present.
- [x] Drag/placement works along all four edges and corners; no escaping the frame reported.
- [x] A session progressed through 0, 18, 141 and about 1.35K points, up to 44 cleared lines and 125 moves; strawberries increased 69 → 260.
- [x] Boutique category grid and Special Tools store page display; all items are card/grid-based.
- [x] In-game Special Tools opens with its 2-column tiles; no charges were available, so actual use is **not** proven.
- [x] Settings' discreet strawberry Developer Garden lock gives access to the seven-tile dashboard.
- [x] Home → Resume restored the ongoing Endless game without resetting the score or playfield.

## Requested next focused corrective build (do not silently implement everything at once)

**Visual game identity and layout**
1. Sweet Endless should have a premium decorated **mode-specific title and subtitle** similar in prominence to the Berry Berry Blast heading; keep board-size/season info readable, do not repeat large text twice.
2. Test and enable the previously approved `Blossom_Glass_Frame_Transparent_Center` and opt-in board skin: the current visible 8×8 board still resembles the default pink grid. If the theme is inaccessible or subtle, fix *visual hookup only*, never rewrite input geometry or game engine. Respect 8×8 and later 12×12/24×24.
3. Boutique **Garden Helpers** and **Special Tools** currently share almost identical shop imagery. Give Garden Helpers a distinct watering-can/personal-tools asset and keep a different original image for Special Tools.
4. Use available iPhone 16e vertical room more thoughtfully; improve bottom-area balance and sheet safe-area/header alignment without clipping or reducing tap targets.
5. Add soft pressed glow/scale/haptic (if enabled) and brief screen transitions on Home, Settings, Help, Boutique and other navigation. Honor Reduce Motion; no blocking or accidental duplicate taps.

**Developer Garden / QA usability**
6. Replace seven generic SF Symbol tiles with seven separately exported, standalone, named strawberry-themed assets. Candidate illustrations are available in the companion handoff ZIP, but **await user approval** and are **not in the repository**.
7. Give each dev tile a plain-language description, what it reads, when to use it, whether it is active in this build, and its effects. Show "Coming soon" on unimplemented panels instead of pretending they do a real test.
8. Clarify `Show Touch Diagnostics in Gameplay`: current source uses `@AppStorage("berryblockblast.touchDiagnostics")`; it shows a *small monospaced `touchStatus` readout beneath the tool bar* during gameplay. Explain how placement/gesture status should change as user taps/drags, and verify it is actually updating. Keep disabled by default for ordinary players and hide all developer text from normal play.
9. Add safe combo-preview testing inside Developer Garden. Buttons ×10/×20/×30/×50 should call only a **visual preview path** for the banner. Must not change score, streak, rewards, wallet, stats, achievements, saves, or active run; verify tap-through and dismissal.
10. Retain PIN `1476` for casual access concealment only; it is not a security guarantee. Keep destructive developer actions out of release builds.

## Explicitly unverified on this physical device
- [ ] True Special Tools action use and charge spending: screenshot shows 0 charges or locked.
- [ ] Naturally triggered ×10/×20/×30/×50 celebrations: tester managed about ×4–×5, not 10; do not treat as failure.
- [ ] Actual equip/revert of Blossom Glass board style and other board sizes.
- [ ] Wrong developer PIN rejection and each QA inspector's detailed behavior.
- [ ] Background or force-quit/relaunch persistence, purchases, cosmetics, music/haptics, full menus and every dismiss path.
- [ ] Build 4 iPhone 14 Pro testing (Build 3 had passed, not Build 4).
- [ ] Actual iPhone 16 AltStore signing installation error and diagnosis; successfully installing this IPA on iPhone 16e does **not** prove AltStore Classic fixed.

## Scope and protections
- Only Build 4 **correction / polish / physical retest** is the active development phase.
- Preserve fully working engine, score, audio, tray, touch mapping, save data, shop inventory and economy.
- Keep original board as instant rollback option.
- 30 **day** + 30 **night** art sets exist on Build 4 source; nighttime visual switch is **not yet active**.
- Strawberry-sun and Moonberry-moon icon concepts exist for a future live, 12-hour local menu clock.
- **Build 5 later:** active-screen notifications, Daily Quest/Village progression and timer QA.
- **Build 6 later:** persistent Moonberries, actual nighttime market/daytime shop switching, day/night schedule 6 AM to 6 PM, duplicate-reward safety, DST/timezone and offline tests.
- Keep PR #7 a draft and do not merge or publish until both-device QA is logged.
- For each change: assert source compiles, deterministic engine test, both simulator suites, then iPhone 16e and iPhone 14 Pro inspection.
- Record each verified result as its own GitHub checkbox; do not mark coupled checks by assumption.

## GitHub resources
- Checklist: https://github.com/ValentineBSAA/IPhone-Apps/issues/8
- Draft PR: https://github.com/ValentineBSAA/IPhone-Apps/pull/7
- Source branch: https://github.com/ValentineBSAA/IPhone-Apps/tree/feature/berry-build4-approved-assets-foundation
- Build 4 unsigned IPA: https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44435872838
- Night Edition art release: https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/Nighttime
- Roadmap: StrawberryShortcakeBlockBlast/BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md
- Extended QA: StrawberryShortcakeBlockBlast/BUILD4_APPROVED_ASSETS_AND_QA.md
