# 🍓 Berry Berry Blast | Release Gates & Night Edition Roadmap

**Single project checklist (updated 2026-11-18 after successful Nighttime release import)**  
**Development branch:** `feature/berry-build4-approved-assets-foundation`  
**Known-good restore point:** Build 3, commit `b4ffda288b7a778a79a860c8d8ebc2cab3e5755b`, physically tested on iPhone 14 Pro.  
**Rule:** A feature is *not complete* because a PNG exists or Swift code compiles. Check off a task only after its stated verification has passed. Never overwrite the tested Build 3 baseline.

> **Permanent owner requirement, updated November 21, 2026:** The PIN-hidden Developer Garden must remain in **every installable build, Debug and Release**, and continue expanding with the game. It must offer opt-in cheats for real owner data **with confirmation** and separate truly isolated test labs. In particular, Build 6 includes a dedicated **Cheat Moonberries** control **once the real Moonberry ledger exists**; do not fake a Moonberry balance in Build 48. [Full Developer Garden inventory, seven-system expansion plan and gates](DEVELOPER_GARDEN_OWNER_POLICY_AND_ROADMAP.md). **No release acceptance** if version-label long-press, PIN 1476, Strawberry cheats, isolated labs or saved games are missing from the actual iPhone IPA.

## Current status

| Area | Status | Next acceptance gate |
| --- | --- | --- |
| Build 3 gameplay, original board and saves | ✅ Hardware-tested baseline | Regression after each release |
| Build 4 player UI, tools, modes, dev lock, Blossom Glass | 🟠 Partially hardware-verified in v0.5.16 Build48 | Owner confirmed hidden Garden + Strawberry cheat/restore; board-skin and full save regressions still open |
| 30 daytime illustrations | ✅ On Build 4 branch in separate Xcode image sets | Appearance / tap testing |
| 30 Night Edition counterparts | ✅ Imported as 30 individual Xcode imagesets on Build 4 development branch | CI + real-device night-visual QA |
| Strawberry sun / moon clock icons | 🎨 Illustrated; not integrated | Independent PNG and UI approval |
| Real live menu clock and day/night presentation | 📋 Planned | Midnight, timezone and app-resume QA |
| **Second-accurate live time and transition countdown** | 📋 [Issue #95](https://github.com/ValentineBSAA/IPhone-Apps/issues/95), independent of decorative clock | 12-hour `h:mm:ss a`, `Moonlight/Sunrise in HH:MM:SS` at 6 PM/6 AM, update each second, real-device QA |
| In-context notices and Daily Quest fixes | 📋 Build 5 scope | In-menu visibility and reward QA |
| Moonberries, night shop transactions and shop switch | 📋 Build 6 scope | Persistent economy + real-clock QA |
| iPhone 16 AltStore install/signing | ⚠️ Unresolved | Capture exact installation error |

## Latest on-device milestone and next step (November 21, 2026)

**Verified CI source:** I6 v0.5.16 Build 48 from [successful run #44947069107](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44947069107), 8/8 actual native iPhone simulator UI checks, 169/169 engine/economy/restore tests, original audio and a private unsigned IPA. **Owner has now installed and verified the hidden Developer Garden opens, one real Cheat Strawberries grant works, and Restore Previous Strawberry Balance works on their physical iPhone.** This is a partial physical-device gate, not sign-off for all game modes or saved-game migration.

**Short remaining Build 48 sanity check:** ensure old Endless saves, owned cosmetics and wallet remained intact through install; open one advanced isolated test lab. Do not mark unrelated Shop/Story/Quest or all device regressions complete without actual owner confirmation.

**Next feature milestone is Gate A2, [Issue #95](https://github.com/ValentineBSAA/IPhone-Apps/issues/95):** implement accurate device-local **12-hour h:mm:ss a** on the existing Home bar and a **seconds-resolution HH:MM:SS** countdown to 6 PM Moonlight / 6 AM Sunrise, with deterministic transition tests and a read-only virtual time fixture in the permanent Developer Garden. This is independent of the approved decorative analog clock artwork, seasonal illustrations and Moonberry economy. Later sequence: **Gate B Night Edition visuals/clock artwork → Gate C Build5 notification/Village/Quest polish → Gate D Build6 real Moonberry Night Market + separate Moonberry cheats/restore**. Each addition keeps all already working Developer Garden controls.

## Night Edition assets: 30 exact pairings

Source artifact: **Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip**, published by the project owner as the GitHub Release asset under tag **[Nighttime](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/Nighttime)**. The uploaded binary was downloaded and validated by [GitHub Actions](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44435721368). It includes 30 separate `Night_*.imageset` folders, each containing its own PNG and `Contents.json`. It was integrity-checked before this roadmap. Preserve both versions side by side; never rewrite the day images.

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

**Safe import (when the approved ZIP is available in your Git checkout):**

```bash
cd StrawberryShortcakeBlockBlast
python3 Tools/import_night_assets.py /path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip
python3 Tools/import_night_assets.py /path/to/Berry_Berry_Blast_Night_Edition_Xcode_Asset_Catalog.zip --apply
git status --short
```

The first command validates only; the second creates 30 distinct `Night_*.imageset` entries without touching daytime art. Commit those resulting PNGs and `Contents.json` files to this development branch, then rerun artwork and app-build checks. **GitHub import completed successfully:** 30 separate PNGs plus their Xcode `Contents.json` metadata were committed by GitHub Actions to Build 4 only, with the daytime originals and audio unchanged.

**Night asset import checklist (GitHub import succeeded; remaining checks retain separate gates):**
- [x] Import all 30 `Night_*.imageset` folders into `StrawberryShortcakeBlockBlast/BerryBlockBlast/Assets.xcassets` on the Build 4 development branch only.
- [x] Validate 30 separate image sets, each with its own correct `Contents.json`, matching named PNG, RGBA transparency, dimensions and nonzero pixel data.
- [x] Validate every day image name still resolves and the 67 original audio files remain unchanged.
- [ ] Ensure an icon shown at night always has a day fallback; never dynamically generate image-name strings for missing assets without fallback.
- [ ] Reject the bonus ornate Moonberry board **concept** from shipping gameplay until separately approved and touch-tested.
- [ ] Verify basic legibility, contrast, tooltip/help readability and icon recognition on a real iPhone.
- [ ] Preserve the existing frame and exact game-grid geometry for every board size.

## Next development steps, in order

### Gate A · Finish Build 4 first (one feature group, no economy changes)
- [ ] Run existing Build 4 engine + iOS16 + art/audio checks; resolve compiler errors or regressions.
- [ ] Check hidden Developer Garden entry and PIN 1476 (not a real security barrier). Test safe controls only.
- [ ] Check player-friendly Special Tools actions and charges; no developer messages shown to players.
- [ ] Confirm mode badge shows **Sweet Endless · board size · season** even while achievement text appears.
- [ ] Confirm non-blocking ×10/20/30/50 combo banners don't obstruct taps.
- [ ] Test original and opt-in Blossom Glass board; Undo, score, edge placement and saves unaffected.
- [ ] Test Home, Pause, Settings, Help and proper grid layouts.
- [ ] On physical iPhone 14 Pro, resume existing endless score, moves, purchases and unlocked cosmetics without reset.
- [ ] Record issues and fix *only* regressions; do not merge until signed off.

### Gate A2 · Live seconds and real transition countdown (independent of approved clock artwork)

**Owner request from real iPhone screenshot, November 21, 2026:** [Issue #95](https://github.com/ValentineBSAA/IPhone-Apps/issues/95). The existing Home header already reads local time and says e.g. `1:59 PM · Day Garden` with `Moonlight in 4h 1m`, but it drops **seconds** and rounds the remaining time to whole minutes. **Fix this digital header independently and before integrating the approved decorative analog clock**. Do not alter the verified v0.5.16 Build 48 IPA; implement this in the next deliberate, separately tested version.

- [ ] Clock should display **12-hour iPhone-local `h:mm:ss a`**, e.g. `1:59:37 PM`, with no switch to a 24-hour display and no need for new artwork.
- [ ] Show an actual **HH:MM:SS second-by-second countdown**: daylight `Moonlight in 04:00:23` until next local **6:00 PM**, nighttime `Sunrise in 11:59:59` until next local **6:00 AM**. Label changes immediately on the boundary and seconds never go negative.
- [ ] Update displayed seconds **once per second**, using `Date()` and `Calendar.nextDate`'s next local 6 AM/6 PM boundary each refresh, **not** a decremented stopwatch or minutes rounded with `ceil(remaining / 60)`. Current source to change: `BerryDayNightClock.swift` (`clockText`, `BerryLiveDayNightClock` minute rounding and 30-second `Timer.publish`).
- [ ] Render compactly on iPhone, with steady monospaced digits, legible seconds at the smallest supported screen and Dynamic Island, no clipping or visual bouncing. Accessibility must say the actual local time and remaining time.
- [ ] Recompute immediately after background/foreground, app sleep/relaunch, midnight, timezone/DST change, manual time adjustment; test 5:59:58 → 6:00:00 in both directions of phase transition, offline and simulated local calendars.
- [ ] **Do not imply the real Night Market is open before Build 6.** `Moonlight` is a day/night visual transition preview. No changes to purchases, Strawberry or Moonberry wallets, save states or selected boards.
- [ ] Add deterministic Swift tests (injectable local Date/Calendar) plus a native iPhone Home screen test for the seconds update and actual 6 PM/6 AM boundary; confirm on physical iPhone.
- [ ] Add a read-only **Developer Garden virtual clock** preview for seconds rollovers and both boundaries, without changing system clock or real player state.

**Phase B later:** the already-approved premium analog clock design must **reuse the verified live time/transition model**, not replace it or reset its countdown. No new art is required for Gate A2.

### Gate B · Night visuals and clock (after Gate A is stable)
- [ ] Integrate nighttime art as visual-only toggles with original daytime art preserved.
- [ ] Put separately generated strawberry-sun and moonberry-moon icons into individual PNG image sets.
- [ ] Integrate the **already-approved compact decorative clock design** later, reusing the second-accurate local time and 6 AM/6 PM countdown delivered by Gate A2. No full-screen clock, and do not regress to a minutes-only countdown.
- [ ] Define day as **6:00 AM–5:59:59 PM**, night **6:00 PM–5:59:59 AM**, using local calendar/date boundaries rather than timer tick counting.
- [ ] Test clock while app foregrounded, backgrounded, suspended, resumed, offline, across midnight and timezone/DST changes.
- [ ] Do not change Night Market inventory, prices or currency in this gate. Show a preview/coming-soon state until shop functionality is truly complete.
- [ ] Verify both light/day and dark/night text contrast and Board theme selection accessibility.

### Gate C · Build 5: notification and progression polish
- [ ] In-app rewards and milestones appear in the current active screen, not hidden behind Shop/Settings.
- [ ] Queue notifications until safe to show, not while a modal/checkout is obstructed.
- [ ] Daily Quests and Village reward progress are inspectable and do not double-grant.
- [ ] Verify local-midnight reset policies independently from shop transitions.
- [ ] Repeat device save/restart/regression QA before approving.

### Gate D · Build 6: actual Moonberry Night Market

- [ ] **Developer Garden counterpart required:** implement and test a separate **Cheat Moonberries** card (voluntary real balance edit only after confirmation/audit) and isolated fixtures for Moonberry earning, first-time milestones, store purchases, duplicate receipts, crash recovery, cross-currency safety and day/night time boundaries. Its current B48 **Coming Later** card is NOT a functional cheat or a real Moonberry economy.
- [ ] Every Build 6 feature delivers its matching two-column developer fixture in the same development milestone, never as a detached follow-up.
- [ ] Separate durable Strawberry and Moonberry ledgers; earn Moonberries via real Endless milestones.
- [ ] Prevent duplicate milestone rewards after Undo, reload, session restart and season transition.
- [ ] Daytime Berry Boutique and nighttime Moonberry Market use scheduled local time and the approved separate shop illustration.
- [ ] Purchases and ownership persist across 6 AM/6 PM switch and device restarts.
- [ ] Advance through real-world 24h timing without relying on a running app or fixed 24-hour timer callbacks.
- [ ] Never let a shop swap interrupt an ongoing purchase; switch at the next safe point.
- [ ] Test DST jumps, midnight, manual system-clock changes and airplane mode (offline device time is not tamper-proof).
- [ ] Real-device sign-off and an economy migration/rollback plan before release.

## Regression strategy: short and deliberate

1. **Source / CI**: compiles, asset names resolve, tests, artwork/audio counts, no accidental changes to the game engine.
2. **Simulation**: iPhone 14 Pro / iPhone 16; top and bottom board corners, dynamic island, landscape/safe areas only when supported.
3. **Physical iPhone 14 Pro**: gameplay and touch, controls, saves, shops, audio and menus.
4. **Distribution**: capture and diagnose the exact AltStore failure on iPhone 16; do not assume a packaged unsigned IPA is already signed.

For each stage: file one small GitHub issue for confirmed regressions, fix it, rerun the affected tests, and update this checklist. **One gate open at a time.** Mark an asset *imported*, a feature *implemented*, and a release *tested* as three different statuses.

## Don't accidentally expand scope

- Keep Build 3 untouched and Build 4 a draft until approved.
- Don't couple board art to touch/gesture geometry.
- Don't mix the visual Night Edition with the Moonberry economy in the same build.
- Don't rebuild working mechanics to make the UI prettier.
- Don't treat local PIN 1476 as secure storage or expose destructive developer controls.
- No publication, merger or 'finished IPA' claim without passing actual QA.
