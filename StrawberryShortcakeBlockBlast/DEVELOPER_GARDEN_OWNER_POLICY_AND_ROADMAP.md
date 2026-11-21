# 🍓 Developer Garden | Permanent hidden feature & whole-game testing roadmap

**Owner decision (November 21, 2026):** Keep the hidden Developer Garden **inside every installable Berry Berry Blast build, including Release**, until the owner **explicitly requests removal**. This is an ongoing game feature, **not** a temporary debug-only screen. Improvements and new testing controls ship alongside the game mechanics they exercise.

## Entrance and ownership

- Open **Settings** and long-press the version/build label for approximately **two seconds**; enter the existing four-digit PIN **1476**.
- No visible developer button, unwanted list UI, or extra clutter on regular game screens. Use the game's existing **two-column card grid** for both quick and advanced tools.
- The PIN hides the feature from casual exploration; **it is not cryptographic security**. Do not imply otherwise.
- Keep **`BERRY_INTERNAL_QA` enabled in the actual application target for both Debug AND Release** in `project.yml`. Never build an unsigned/signed/public/private IPA that silently strips the hidden menu or its actual tools until the owner changes this requirement. CI must explicitly test PIN/long-press **with the same Release configuration used for the IPA**.
- Always display the actual `CFBundleShortVersionString` / `CFBundleVersion` in both Home and Settings; no stale `B4.6 VISUAL LAB` text.
- Continue protecting the bundle identifier `com.valentinebsaa.berryblockblast`, iOS 16+, original audio/artwork and legacy inventory/Endless save keys.

## Two distinct types of buttons

**Isolated tests: safe to repeat.** Scenario Sandbox, State & Timer Lab, Commerce Lab, Tool Action Lab, and Quest & Story Lab use separate disposable game state / economy ledgers. They must report expected vs actual, PASS/FAIL, and reset/discard. Running an isolated test must **never** change the owner's actual wallet, purchases, current run, saves, trophies or earned progress.

**Optional cheats: intentionally alter the owner's game.** The **Cheat Strawberries** quick card is a real, opt-in cheat. The owner enters any valid positive amount, reviews the exact amount, then **confirms** before coins are added to their actual saved wallet. Declining/canceling makes no change. This cheat has an audit history and must not be mislabeled as naturally earned gameplay berries. Save backups remain recommended. Future cheats, such as manually preparing rare situations, must label whether they are sandbox-only or alter the real game, and require confirmation for persistent changes. Do not remove or silently disable voluntary cheats in a Release build.

## What's present in the candidate source now

- **Quick grid:** Cheat Strawberries; Diagnostics / live touch readout; read-only Save Inspector; visual-only Combo Preview ×10/×20/×30/×50.
- **Advanced grid:** Scenario Sandbox; State & Timer Lab; Commerce Lab; Tool Action Lab; Quest & Story Lab; Economy Inspector; Build Information; live device clock; Experimental Features (status); Notification Test (properly marked planned).
- **Persistent access:** Settings version long-press opens PIN, all advanced controls present in an actual `Release` app, no developer dashboard icon on Home.
- **Current verification:** Build 48 native UI/161 gameplay regression + packaging is **pending terminal CI and physical iPhone acceptance**. **Do not mark pass before inspecting logs**.

## Future developer testing map, built alongside the whole game

- [ ] **All mode fixtures:** instant start/clear/game-over for Endless 8×8/12×12/24×24, Classic, Daily Harvest, Story, Cottage, Blitz and Nightmare; inspect exact scoring/placement/undo rules. Use disposable state by default.
- [ ] **Story rescue:** one tap to create naturally blocked board and test Shuffle/Golden rescue confirm/cancel, charge/debit/receipt/restart without playing for hours.
- [ ] **Quest/Birthday:** seed completed and incomplete objectives, verify earned vs unearned and once-only gift claims, calendar rollovers and real native UI display.
- [ ] **Boutique/economy:** optional player cheats vs isolated testing, earned/spent ledger, tool charges, purchases, recovery, cosmetics, saves and receipts. Clearly mark what touches real saves.
- [ ] **Night/seasonal:** preview each approved daytime/nighttime, holiday/birthday/Thanksgiving/Christmas/Halloween board/village card, device-local 12-hour 6AM/6PM switching, timezone/DST tests.
- [ ] **Build 5 Village and progression:** seed chapters, village levels, inventory, story/cottage quests; inspect every actual on-screen reward.
- [ ] **Build 6 Night Market:** independent Moonberry economy, time-based storefront, receipts, cross-currency safety, all new mechanics and cheat/fixture support.
- [ ] **Regression:** physical iPhone touches, accessibility, two-column grids, no accidental owner data changes, old 8/12/24 Endless saves, accurate version label, diagnostics present after real signed install.

## Release gate added after owner reported Build46 failure

For every future installable IPA, a **Release-configuration** native simulator UI test must: open Settings, hold the actual version label, see PIN entry, enter 1476, see the full Developer Garden quick grid including **Cheat Strawberries**, open an advanced isolated lab, confirm the cheat is opt-in, then check the real app version and resources. Unit tests alone and simulator Debug alone are insufficient. Owner's **physical iPhone signoff** remains separate.

**No production-main merge, hardware signoff or public release is implied by this roadmap.** This owner-defined product requirement remains active until the owner explicitly changes it.
