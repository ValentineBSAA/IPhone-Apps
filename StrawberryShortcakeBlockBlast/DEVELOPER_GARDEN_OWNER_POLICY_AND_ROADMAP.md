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

**Optional cheats: intentionally alter the owner's game.** The **Cheat Strawberries** quick card is a real, opt-in cheat. The owner enters any valid positive amount, reviews the exact amount, then **confirms** before coins are added to their actual saved wallet. Declining/canceling makes no change. It logs all grants separately from naturally earned berries. **Before the first cheat in a series it now saves the precise real strawberry count as a durable restore point**. Any following cheat retains the first baseline. A separate **Restore Previous Strawberry Balance** confirmation restores that exact pre-cheat amount after an app relaunch, and only changes the inventory's strawberry field. It does not reset owned tools, skins, scores or game saves. **Important:** restoring a baseline may also overwrite legitimate strawberries earned/spent *after* the cheat; show the current and saved amounts and explicitly warn before confirming. Saving a fresh baseline after restore starts a new cheat cycle. This is a UserDefaults recovery feature, **not** a fully power-loss-atomic transaction journal; backups remain recommended. Future cheats must distinguish isolated vs real-save actions, preserve pre-cheat values where meaningful, and offer confirmation/restore. Do not remove or silently disable voluntary cheats in a Release build.

## What's present in the candidate source now

- **Quick grid:** Cheat Strawberries; Diagnostics / live touch readout; read-only Save Inspector; visual-only Combo Preview ×10/×20/×30/×50.
- **Advanced grid:** Scenario Sandbox; State & Timer Lab; Commerce Lab; Tool Action Lab; Quest & Story Lab; Economy Inspector; Build Information; live device clock; Experimental Features (status); Notification Test (properly marked planned).
- **Persistent access:** Settings version long-press opens PIN, all advanced controls present in an actual `Release` app, no developer dashboard icon on Home.
- **Current verification:** Build 48 native UI/161 gameplay regression + packaging is **pending terminal CI and physical iPhone acceptance**. **Do not mark pass before inspecting logs**.

## One permanent testing system for the WHOLE game

Developer Garden is a **living subsystem**. Every gameplay or economy feature must ship with its own test fixture, a player-view verification, and documentation. A new system is not accepted merely because its Swift code compiles. The menu always retains previously approved tools, existing PIN access, two-column cards, readable labels and Save Inspector.

**Status meanings:** `ACTIVE` = real implemented control in the candidate; `PLANNED` = visible roadmap/placeholder and **not executable**; `BLOCKED` = cannot be declared finished without production feature and regression checks; `HARDWARE QA` = owner still needs to confirm on physical iPhone. Mark each independently.

### Developer Garden inventory

| Area | Current status | What it does or will do |
| --- | --- | --- |
| Settings long-press + PIN 1476 | ACTIVE source, HARDWARE QA pending | Hidden access in **Debug and Release**, no Home button |
| Cheat Strawberries + exact restore | ACTIVE source, HARDWARE QA pending | Saves first pre-cheat balance, confirmed grant, restores exact previous number across launches; preserves other inventory/save fields |
| Touch Diagnostics | ACTIVE source, HARDWARE QA pending | Shows board cell and gesture events; opt-in, no gameplay modification |
| Save Inspector | ACTIVE source | Inspect existence of 8×8 / 12×12 / 24×24 Endless saved games, read-only |
| Combo Preview | ACTIVE source | Show visual ×10/×20/×30/×50 without farming points |
| Scenario Sandbox | ACTIVE source | Isolated seeds/board fixtures; report expected vs actual |
| State & Timer Lab | ACTIVE source | Disposable wallet, charges, game state and virtual clock |
| Commerce Lab | ACTIVE source | Real purchase handler with separate fake wallet/ledger |
| Tool Action Lab | ACTIVE source | Real premium tool engine in isolated throwaway runs |
| Quest & Story Lab | ACTIVE source | One-tap real progression checks in disposable sessions |
| Economy Inspector | ACTIVE source | Existing strawberry earnings/spending audit, no edit |
| Build Information + live clock | ACTIVE source | Actual bundle version/build, local date/time |
| Notifications, new seasons and experimental toggles | PLANNED | Honest Coming Later until their handlers work |
| **Moonberries & Night Market** | **PLANNED visual card added** | No actual Moonberries, Moonberry ledger or cheat yet; separate Build 6 delivery |
| Expanded Village, holiday seasons, cosmetics & achievements | PLANNED | Feature fixtures follow actual systems as they are implemented |

### 1. 🫐 Moonberries, Moonberry cheats and Night Market: priority Build 6

**The Moonberry system is separate from Strawberries.** Moonberries are not aliases for strawberry inventory, nor pretend numbers in the menu. Before Build 6 exists, the **Moonberries & Night Market** card must explicitly say `COMING LATER` and show no actionable grant, test receipt, Moonberry spending or fabricated live balance. The separately approved Moonberry visual asset can be a card icon; art availability does not imply the economy is live.

When real Moonberry game mechanics are implemented, add **all** of these, with independent acceptance:

- [ ] **Cheat Moonberries** beside Cheat Strawberries: choose an amount, inspect the current Moonberry balance and new amount, explicitly confirm or cancel; actual persistent Moonberry balance changes only after confirming. Distinct wallet key and audit `cheat / not naturally earned`; repeat and restart reliably; guard negative, zero, integer overflow and duplicate taps. **Mirror exact pre-cheat restore** with a separate persistent original Moonberry balance and confirmation. Restoring Moonberries must never reset or change Strawberries, owned Night Market products, receipts or other game saves.
- [ ] **Moonberry readout:** genuine authoritative balance, natural earned total, spent total, available rewards and pending receipts; don't misrepresent a summary ledger as authoritative funds.
- [ ] **Earn Moonberries:** single-tap isolated fixtures for actual Endless milestone thresholds, first-time eligibility, repeated event, after Undo, after new season, and after restore/reopen; **never pay a duplicate reward** for the same event identity.
- [ ] **Night Market shop:** load real eligible inventory, prices and owned/unowned cosmetics; exact-price buy, insufficient funds, double taps, sold-out/already-owned, refund/rollback, interrupted purchase journal and fresh launch recovery. Night Market transactions may debit Moonberries ONLY.
- [ ] **Currency isolation:** Moonberry purchases can never charge Strawberry wallet, Strawberry prices/purchases cannot charge Moonberries, and ordinary grants/quest rewards keep their original currency. Verify against two independent injected stores and real owner save snapshots.
- [ ] **Time and visibility:** virtual device-local 5:59:59 AM → 6:00:00 AM and 5:59:59 PM → 6:00:00 PM; daytime Boutique vs nighttime Market presentation, resume from background, time-zone / DST jumps, midnight, offline/device-clock changes. A shop switch must not interrupt a checkout in progress.
- [ ] **Persistent ownership and migration:** old Strawberry saves upgrade without changing totals, Moonberry inventory/receipts survive force-close, rollback recovery leaves exactly one payment and one item grant, no orphan pending transactions. Allow no unverified destructive reset of existing save keys.
- [ ] **Dev-only Moonberry preview:** change virtual date/time and independently preview Day/Night Market, themed illustrations and purchase UI without modifying the actual phone clock or requiring the player to stay awake until night.
- [ ] **Moonberry UI accessibility:** separate distinctive Moonberry icons and labels, never use ambiguous strawberry symbols, two-column controls, readable numbers, voice labels and explicit which currency will be spent.

**Gate:** Moonberry cheat, earning, checkout and virtual clock scenario actions become `ACTIVE` only after the production Moonberry service and independent safe storage actually exist and pass automated XCTest, native UI and real-device checks. The placeholder is a roadmap marker, not a cheat implementation.

### 2. 🍓 Existing Strawberry economy and voluntary owner cheats

- [ ] Keep **Cheat Strawberries** accessible in every installable build behind the PIN; explicit preview → confirmation → one recorded cheat audit entry, no accidental changes when canceled or viewing; reload the real wallet in UI immediately and after restart.
- [ ] **Exact Strawberry Restore:** atomically as practicable save the real pre-first-cheat strawberry amount before editing inventory, retain baseline through multiple grants and force-closes, display **original/current/cheat count**, require separate confirmation to restore, preserve all tool charges, naturally earned counters, skins, scores and active 8×8/12×12/24×24 game saves. Explicitly warn that restoring exact old balance also overrides any *post-cheat* earnings or spending. One restored baseline cannot be applied twice; next cheat creates a fresh baseline. Corrupt restore records must never be silently overwritten with a cheat-inflated new baseline.
- [ ] Allow future *deliberate* owner cheats such as add tool charges or unlock cosmetics, always with clear `CHANGES MY GAME` language, side-effect preview, audit, confirm/cancel and preferably a verified backup/restore path. Never silently interpret test fixtures as owner cheats.
- [ ] Premium shop tests for Undo 40, Shuffle 50 and Hint 35, other approved Special Tools, owned charges, 0-charge and locked states, retry/rollback and failed checkout. Ensure an invalid action consumes no charge.
- [ ] Dedicated restore-safe snapshots of wallet, owned skin inventory, receipts, high scores and 8/12/24 Endless slots before running any advanced QA action; isolated tests must compare before/after hashes.
- [ ] Inspect original boutique skins, Strawberry Jam/Blossom Glass surfaces, decorative frames, prices, accessibility, buy/equip/unequip/revert, plus score continuity after cosmetics.

### 3. 🎮 Every actual gameplay mode and board size

- [ ] **Sweet Endless:** seed deterministic start/midgame/stuck/game-over, board sizes 8×8 / 12×12 / 24×24, seasons and all three saved runs, placement corners/edges and score/moves/lines. Provide one-tap seed fixtures without replacing the owner's own Endless slots.
- [ ] **Berry Story:** pick chapter, set target progress in a sandbox, trigger authentic dialogue, complete/lose, verify unlock, resume, real blocked-board Shuffle (50) rescue and Golden rescue confirm/cancel, exact purchase receipt, reload and rollback.
- [ ] **Daily Harvest:** virtual local date, start/resume/reopen, once-per-day attempt, completed and uncompleted states, streak, calendar view, midnight boundary, repeat attempts and double-reward rejection.
- [ ] **Berry Classic:** original 8×8 pure puzzle, high score, deliberately restricted helpers, fully supported help/pause/restart and clear feedback for unavailable tools.
- [ ] **Cozy Cottage:** decorations, premium cosmetics, storage/flower/seed tools and calm mode rules, milestones and saved inventory, with no owner-data writes from a disposable lab.
- [ ] **Berry Blitz and Strawberry Nightmare:** time attack at supported lengths, hard-mode 12×12, pause/resume, 0-seconds transition, progression and fair scoring, touch/haptics.
- [ ] **Universal:** rapid seeded ×10/×20/×30/×50 combos, clearing, edge/corner touch geometry, zero/invalid tool taps, shuffle and undo charge rules, board skin changes never alter collision cells. No random play for an hour to reach a QA target.

### 4. 📖 Quests, Birthday, Story Journal and Build 5 Village

- [ ] Seed each real Quest objective before/at/after target, claim once only, return after app restart, compare actual display to saved claim ledger and guard double grant.
- [ ] Simulate incomplete/complete Story chapters and Village Level 1–5 unlocks, associated art, dialogue, rewards and claims; preserve old story saves.
- [ ] Birthday month/day setting, not-today vs today, invalid dates and leap day, once-per-year **100-strawberry** gift, duplicate/refund protection, simulated next year without changing device clock.
- [ ] Real Quest Board, Village, Journal and Cottage navigation on-device; current-screen notifications, reward arrival, deferred banners and repeated dismissal. No fake success banners for incomplete features.
- [ ] Build 5 Village expansion must add a new developer card or extend an existing one *in the same change*, not after the game feature is released.

### 5. 🌞🌙 Day/night visuals, seasonal art and clock

**Clock/countdown priority, screenshot follow-up:** [Issue #95](https://github.com/ValentineBSAA/IPhone-Apps/issues/95). The Home header currently displays `1:59 PM` and `Moonlight in 4h 1m` because `BerryDayNightClock.swift` formats only hours/minutes, rounds remaining time to whole minutes, and ticks every 30 seconds. **Implement the second-accurate digital clock/countdown as a separate task before applying the already-approved decorative clock artwork.**

- [ ] Home local time **`h:mm:ss a`** in 12-hour format, real iPhone device time, once per second. Display a stable, monospaced `Moonlight in HH:MM:SS` countdown toward **6 PM** and `Sunrise in HH:MM:SS` toward **6 AM**. Refresh from the real current `Date` + `Calendar` target, never a drifting accumulated decrement; no negative seconds or lingering old phase.
- [ ] Test local 5:59:58/59 PM → 6:00:00 PM and 5:59:58/59 AM → 6:00:00 AM, simulated time zone/DST/calendar, mid-afternoon, app resume/relaunch, offline and manual clock adjustments. Preserve visual-only night status until the real Moonberry market exists.
- [ ] **Developer Garden State & Timer Lab** receives a read-only virtual-date second-tick and 6 AM/6 PM transition preview that proves the actual Home time/countdown policy, without changing system time or owner saves. It must be covered by native Release tests before the task is signed off.
- [ ] When the approved analog clock artwork is added, display it from this **same validated time source and countdown logic**, not a second divergent clock model. Preserve two-column grids, time accessibility, tiny-screen readability and original game economy.



- [ ] Apply all **approved** daytime and matching nighttime game/world illustrations with fallback, without altering original assets or grid geometry; distinguish asset imported vs actually displayed.
- [ ] Preview 6 AM–6 PM day and 6 PM–6 AM night using **injected 12-hour local time**; handle suspended apps, DST, timezone, midnight, manual clock and offline.
- [ ] Add opt-in, non-destructive visual previews for Halloween, Thanksgiving, Christmas, birthdays and other owner-approved holidays, **both day and night**; select themes by controlled date, preview contrast and revert without buying or unlocking anything.
- [ ] Keep separate Day/Night artwork from the eventual Moonberry *currency* implementation: no automatic money changes when a theme or storefront changes.
- [ ] Verify seasonal notification copy, sounds, icon recognition, original background tracks, Reduce Motion, portrait safe areas, accessibility and two-column grids.

### 6. 🧪 Diagnostics quality and repeatability

- [ ] Each diagnostic card must say **what it tests**, its **expected result**, current **PASS/FAIL**, isolation scope, and whether any persistent game data changes. Never label a placeholder OPEN/working if the production handler is missing.
- [ ] One tap to set fixture → inspect the real screen/model → run → expected/actual comparison → repeat → discard/reset. Include transcript/counters, screenshot evidence and optionally export sanitized JSON logs.
- [ ] Keep **two-column** menu cards, never degrade into unstructured lists, and support iPhone 14 Pro and iPhone 16e touch targets, dynamic text, accessible labels and normal B/Done dismissal flow.
- [ ] Version, build and source checkpoint must always reflect actual compiled bundle. No obsolete `B4.6` strings or inaccessible PIN entry.
- [ ] Never change player data during an isolated test. If a cheat intentionally edits player data, confirm first, state which save key/ledger changes, keep a small audit trail and tell owner it cannot be undone without a backup.

### 7. Required feature-completion rule for EVERY future addition

No feature is complete until its *production mechanic*, *visual screen*, *Developer Garden fixture/optional cheat where appropriate*, *automated tests*, *real-device checklist*, and *GitHub roadmap* agree. New developer features are additive, not replacements: check hidden PIN and the old cards each build. If a production mechanic is not ready, keep the matching developer card labelled `COMING LATER` and make no fraudulent one-tap success claims.

**Immediate owner testing gate (Build 48):** verify the real signed iPhoneOS app displays v0.5.16 B48, holding Settings build text opens PIN 1476, developer quick grid includes Cheat Strawberries and Moonberries & Night Market (clearly Coming Later), advanced Commerce/Quest labs open, and old saved Endless games are present. For cheats, record an existing real wallet amount, do one small confirmed addition, force-close/reopen, and confirm the exact original can be restored. **Do not perform irreversible tests without a backup.** Keep a short hardware checklist; exhaustive scenarios belong in GitHub/automated tests.

## Release gate added after owner reported Build46 failure

For every future installable IPA, a **Release-configuration** native simulator UI test must: open Settings, hold the actual version label, see PIN entry, enter 1476, see the full Developer Garden quick grid including **Cheat Strawberries**, open an advanced isolated lab, confirm the cheat is opt-in, then check the real app version and resources. Unit tests alone and simulator Debug alone are insufficient. Owner's **physical iPhone signoff** remains separate.

**No production-main merge, hardware signoff or public release is implied by this roadmap.** This owner-defined product requirement remains active until the owner explicitly changes it.
